extends "res://tests/run_synergy_policy_balance.gd"

# Paired, actual-ATB policy evaluator. This deliberately measures early owner
# turn checkpoints rather than treating every deck as having the same tempo.
const Guard = preload("res://tools/guard_decision_policy.gd")
const CardRes = preload("res://resources/card_resource.gd")
const TEMPO_PATH := "res://tools/tempo_decision_policy.gd"
const TEMPO_SCENARIOS := {
	"sekhmet": ["egyptian.sekhmet"],
	"surtr": ["norse.surtr"],
	"egyptian_trio": ["egyptian.anubis_guard", "egyptian.sand_scout", "egyptian.nile_crocodile"],
	"norse_trio": ["norse.jotun_soldier", "norse.garmr", "norse.nidhogg_scale"],
}
const SEEDS := [101, 505]
const HP_VALUES := [100, 50, 25]
const CHECKPOINTS := [1, 2, 4, 8]

var _use_tempo := false
var _telemetry := {}
var _tempo_policy: GDScript

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_revert_martyr = false
	_tempo_policy = load(TEMPO_PATH)
	if _tempo_policy == null:
		push_error("Missing tempo policy: " + TEMPO_PATH)
		quit(1)
		return
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	var fixture_errors := _validate_decks()
	if not fixture_errors.is_empty():
		push_error(JSON.stringify(fixture_errors))
		quit(1)
		return
	var enemies := {}
	for enemy in Monsters.get_all_monsters(): enemies[enemy.enemy_name] = enemy
	var smoke := OS.get_environment("STSL_TEMPO_SMOKE") == "1"
	var source_paths := _source_paths()
	var source_start := _source_hashes(source_paths)
	var definitions: Array = [Definitions.DECKS[0]] if smoke else Definitions.DECKS
	var seed_values: Array = [101] if smoke else SEEDS
	var hp_values: Array = [50] if smoke else HP_VALUES
	var scenarios := {"surtr": TEMPO_SCENARIOS.surtr, "norse_trio": TEMPO_SCENARIOS.norse_trio} if smoke else TEMPO_SCENARIOS
	var compositions := ["solo", "team"]
	var rows: Array = []
	var invalid: Array = []
	for definition in definitions:
		_owner = definition.hero
		_package = definition.cards
		for composition in compositions:
			var heroes := _heroes_for(_owner, composition)
			for encounter in scenarios:
				_encounter.clear()
				for id in scenarios[encounter]:
					var key: String = "enemy." + str(id)
					if not enemies.has(key):
						invalid.append("Missing enemy: " + id)
					else: _encounter.append(enemies[key])
				if _encounter.is_empty(): continue
				for hp in hp_values:
					_hp_percent = hp
					for seed_value in seed_values:
						var segment := {"label": definition.id + ":" + composition, "hero_ids": heroes, "probe_card": ""}
						_use_tempo = false
						var baseline := await _simulate(_encounter[0], segment, 0, seed_value, true)
						_use_tempo = true
						var candidate := await _simulate(_encounter[0], segment, 0, seed_value, true)
						var label := "%s/%s/%s/HP%d/%d" % [definition.id, composition, encounter, hp, seed_value]
						if baseline.initial_hash != candidate.initial_hash: invalid.append("Initial mismatch: " + label)
						for result in [baseline, candidate]:
							if result.outcome == "incomplete": invalid.append("Incomplete: " + label)
							if result.capped: invalid.append("Capped: " + label)
							for decision in result.decisions:
								if decision.card != "" and not decision.played: invalid.append("Rejected: " + label)
						var paired := JSON.stringify([baseline.trace, candidate.trace]).sha256_text()
						if encounter in ["sekhmet", "surtr"] and JSON.stringify(baseline.trace) != JSON.stringify(candidate.trace): invalid.append("Single-enemy delegation drift: " + label)
						baseline.erase("trace")
						candidate.erase("trace")
						rows.append({"deck": definition.id, "hero": _owner, "archetype": definition.archetype, "composition": composition, "heroes": heroes.duplicate(), "encounter": encounter, "initial_hp_percent": hp, "grade": 0, "seed": seed_value, "seed_segment": "development" if seed_value == 101 else "validation", "baseline": baseline, "candidate": candidate, "initial_equal": baseline.initial_hash == candidate.initial_hash, "paired_trajectory_hash": paired, "hp_delta": candidate.remaining_hp - baseline.remaining_hp, "input_delta": candidate.hero_input_turns - baseline.hero_input_turns})
		print("Tempo policy completed: " + definition.id)
	var expected := definitions.size() * compositions.size() * scenarios.size() * hp_values.size() * seed_values.size()
	if rows.size() != expected: invalid.append("Expected %d pairs, got %d" % [expected, rows.size()])
	var hashes := _source_hashes(source_paths)
	if source_start != hashes: invalid.append("Source fingerprint changed during evaluation")
	var summary := _tempo_summary(rows)
	var report := {"schema": 1, "mode": "smoke" if smoke else "full", "policy": {"baseline": Guard.VERSION, "candidate": _tempo_policy.get("VERSION")}, "source_commit": _source_commit, "dirty": _dirty, "source_sha256_start": source_start, "source_sha256_end": hashes, "decks": definitions, "scenarios": scenarios, "compositions": compositions, "seeds": seed_values, "hp_percent": hp_values, "grade": 0, "cap": _cap, "expected_pairs": expected, "full_expected_pairs": 864, "metric_contract": _metric_contract(), "integrity_failures": invalid, "summary": summary, "runs": rows}
	var file := FileAccess.open("user://tempo_policy_balance.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write tempo policy report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Tempo policy report: " + ProjectSettings.globalize_path("user://tempo_policy_balance.json"))
	print(JSON.stringify(summary))
	quit(0 if invalid.is_empty() else 1)

func _heroes_for(owner: String, composition: String) -> Array:
	if composition == "solo": return [owner]
	var heroes: Array = [owner]
	for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
		if partner not in heroes and heroes.size() < 3: heroes.append(partner)
	return heroes

func _source_paths() -> Array:
	return [TEMPO_PATH, "res://tools/guard_decision_policy.gd", "res://tools/synergy_decision_policy.gd", "res://tests/run_tempo_policy_balance.gd", "res://tests/run_guard_policy_balance.gd", "res://tests/run_synergy_policy_balance.gd", "res://tests/run_archetype_deck_balance.gd", "res://tests/run_block_balance.gd", "res://tests/run_archetype_playtest.gd", "res://tests/archetype_balance_decks.gd", "res://tests/block_balance_battle_manager.gd"]

func _source_hashes(paths: Array) -> Dictionary:
	var hashes := _fingerprints()
	for path in paths: hashes[path] = FileAccess.get_sha256(path)
	return hashes

func _on_battle_ready(bm: Object) -> void:
	super._on_battle_ready(bm)
	_telemetry[bm.get_instance_id()] = {"owner_inputs": 0, "checkpoints": {}, "first_enemy_removal_owner_input": null, "first_enemy_removal_observation": "unobserved", "first_power_play_owner_input": null, "power_effective_cost_spent": 0, "setup_effective_cost_spent": 0, "power_energy_net_delta": 0, "setup_energy_net_delta": 0, "pending_energy": {}, "last_living_enemies": _living_enemy_count(bm)}
	bm.card_effects_resolved.connect(func(card: Resource) -> void: _record_resolved_energy(bm, card))

func _play_hand_order(bm: Object, hid: String) -> int:
	if hid == _owner:
		_record_checkpoint(bm, hid)
	var played := 0
	var entries: Array = _decisions[bm.get_instance_id()]
	while bm.is_player_turn:
		var choice: Dictionary = Guard.choose(bm, hid) if not _use_tempo else _tempo_policy.choose(bm, hid)
		var card: Resource = choice.get("card", null)
		var entry := {"hero": hid, "card": card.card_name if card != null else "", "target": int(choice.get("target", -1)), "ally": str(choice.get("ally", "")), "reason": str(choice.get("reason", "")), "score": float(choice.get("score", 0.0)), "version": str(choice.get("version", Guard.VERSION if not _use_tempo else "tempo"))}
		if card == null:
			entry["played"] = false
			entries.append(entry)
			break
		var cost: int = bm.deck_mgr.get_effective_cost(hid, card)
		if hid == _owner: _queue_energy_metric(bm, card, cost)
		entry["played"] = bm.play_card(card, entry.target, entry.ally)
		entries.append(entry)
		if not entry.played: break
		if hid == _owner: _record_play_metrics(bm, card, cost)
		played += 1
		_resolve_policy_discard(bm)
	return played

func _record_checkpoint(bm: Object, hid: String) -> void:
	var data: Dictionary = _telemetry[bm.get_instance_id()]
	data.owner_inputs += 1
	var count: int = data.owner_inputs
	var living := _living_enemy_count(bm)
	if data.first_enemy_removal_owner_input == null and living < int(data.last_living_enemies): data.first_enemy_removal_owner_input = count
	if data.first_enemy_removal_owner_input != null and data.first_enemy_removal_observation == "unobserved": data.first_enemy_removal_observation = "owner_input_boundary"
	data.last_living_enemies = living
	if count in CHECKPOINTS:
		data.checkpoints[str(count)] = _tempo_snapshot(bm, hid, count)

func _record_play_metrics(bm: Object, card: Resource, cost: int) -> void:
	var data: Dictionary = _telemetry[bm.get_instance_id()]
	if card.card_type == CardRes.CardType.POWER:
		if data.first_power_play_owner_input == null: data.first_power_play_owner_input = data.owner_inputs
		data.power_effective_cost_spent += cost
	elif _is_setup(card):
		data.setup_effective_cost_spent += cost
	var living := _living_enemy_count(bm)
	if data.first_enemy_removal_owner_input == null and living < int(data.last_living_enemies):
		data.first_enemy_removal_owner_input = data.owner_inputs
		data.first_enemy_removal_observation = "owner_card_resolution"
	data.last_living_enemies = living

func _queue_energy_metric(bm: Object, card: Resource, cost: int) -> void:
	var tag := "power" if card.card_type == CardRes.CardType.POWER else ("setup" if _is_setup(card) else "")
	if tag == "": return
	var data: Dictionary = _telemetry[bm.get_instance_id()]
	data.pending_energy[card.get_instance_id()] = {"tag": tag, "before": bm.deck_mgr.get_energy(_owner), "cost": cost}

func _record_resolved_energy(bm: Object, card: Resource) -> void:
	var data: Dictionary = _telemetry.get(bm.get_instance_id(), {})
	var pending: Dictionary = data.get("pending_energy", {})
	if not pending.has(card.get_instance_id()): return
	var entry: Dictionary = pending[card.get_instance_id()]
	# This is net energy change from immediately before play through effect
	# resolution; it intentionally includes spending/refunds such as all-energy
	# conversion, and is not a gross-cost or return-on-investment measure.
	var net_delta: int = int(entry.before) - bm.deck_mgr.get_energy(_owner)
	if entry.tag == "power": data.power_energy_net_delta += net_delta
	else: data.setup_energy_net_delta += net_delta
	pending.erase(card.get_instance_id())

func _is_setup(card: Resource) -> bool:
	for effect in card.effects:
		if effect.effect_type in [EffectResource.EffectType.APPLY_STATUS, EffectResource.EffectType.GAIN_MORALE, EffectResource.EffectType.SUMMON_TOKEN, EffectResource.EffectType.CHARM, EffectResource.EffectType.COST_NEXT, EffectResource.EffectType.COST_ZERO_TURN, EffectResource.EffectType.BUFF_SPEED, EffectResource.EffectType.MARK_ENEMY]: return true
	return false

func _tempo_snapshot(bm: Object, hid: String, owner_input: int) -> Dictionary:
	var owner_state: Dictionary = bm._hero_status.get(hid, {})
	var enemy_status := {"poison": 0, "charm": 0}
	var enemy_hp := 0
	for index in range(bm._enemy_alive.size()):
		if bm._enemy_alive[index]:
			enemy_hp += bm._enemy_hp[index]
			enemy_status.poison += int(bm._enemy_status[index].get("poison_dmg", 0)) if int(bm._enemy_status[index].get("poison_dur", 0)) > 0 else 0
			enemy_status.charm += int(bm._enemy_status[index].get("charm", 0))
	return {"owner_input": owner_input, "enemy_hp": enemy_hp, "owner_hp": bm.team_mgr.get_current_hp(hid), "team_hp": _team_hp(bm), "living_enemies": _living_enemy_count(bm), "owner_strength": bm._hero_strength(hid), "owner_morale": int(owner_state.get("morale", 0)), "owner_tokens": int(owner_state.get("tokens", 0)), "owner_sacrifice_bank": int(owner_state.get("sacrifice_bank", 0)), "enemy_poison": enemy_status.poison, "enemy_charm": enemy_status.charm}

func _living_enemy_count(bm: Object) -> int:
	var count := 0
	for alive in bm._enemy_alive: count += int(alive)
	return count

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	var data: Dictionary = _telemetry.get(bm.get_instance_id(), {})
	var living := _living_enemy_count(bm)
	if data.first_enemy_removal_owner_input == null and living < int(data.last_living_enemies):
		data.first_enemy_removal_owner_input = data.owner_inputs
		data.first_enemy_removal_observation = "battle_end"
	data["censored_checkpoints"] = CHECKPOINTS.filter(func(checkpoint: int) -> bool: return not data.checkpoints.has(str(checkpoint)))
	result["tempo_metrics"] = data.duplicate(true)
	_decisions.erase(bm.get_instance_id())
	_telemetry.erase(bm.get_instance_id())
	return result

func _metric_contract() -> Dictionary:
	return {"owner_turn_checkpoints": CHECKPOINTS, "checkpoint_boundary": "before the owner's 1st/2nd/4th/8th input; ally inputs do not advance it", "measures": ["alive-enemy HP sum", "owner/team HP", "living enemies", "owner strength/morale/tokens/sacrifice bank", "alive-enemy poison/charm", "first enemy-removal observation by owner-input count", "first owner POWER play input", "effective printed cost and net energy delta for POWER/setup-tagged cards"], "setup_tag": "card has status/morale/token/charm/cost/speed/mark setup effect; descriptive proxy only, not ROI", "energy_net_delta": "energy immediately before play minus energy after its effects resolve; includes spend/refund/conversion and is not gross spending or ROI", "enemy_removal": "observed at an owner-input boundary (or battle end), not asserted as causal owner damage", "censoring": "unreached checkpoints are listed explicitly and never imputed as zero", "aggregate_bias": "checkpoint totals include only runs that reached that boundary; compare matched paired reachers for policy differences", "boundary": "policy telemetry observes outcomes post hoc; it is not policy input and does not inspect future draws"}

func _tempo_summary(rows: Array) -> Dictionary:
	var out := {"pairs": rows.size(), "initial_unique": 0, "paired_unique_trajectories": 0, "outcomes": {"baseline": {}, "candidate": {}}, "caps": {"baseline": 0, "candidate": 0}, "rejected": {"baseline": 0, "candidate": 0}, "new_wins": 0, "new_losses": 0, "new_high_hp_losses": 0, "checkpoint_aggregates": {"baseline": {}, "candidate": {}}, "segments": {}}
	var initials := {}
	var trajectories := {}
	for row in rows:
		initials[row.baseline.initial_hash] = true
		trajectories[row.paired_trajectory_hash] = true
		for side in ["baseline", "candidate"]:
			var result: Dictionary = row[side]
			out.outcomes[side][result.outcome] = int(out.outcomes[side].get(result.outcome, 0)) + 1
			out.caps[side] += int(result.capped)
			for decision in result.decisions: out.rejected[side] += int(decision.card != "" and not decision.played)
			_add_checkpoint_aggregates(out.checkpoint_aggregates[side], result.tempo_metrics.checkpoints)
		out.new_wins += int(not row.baseline.won and row.candidate.won)
		out.new_losses += int(row.baseline.won and not row.candidate.won)
		out.new_high_hp_losses += int(row.initial_hp_percent >= 50 and row.baseline.won and not row.candidate.won)
		var key := "%s|%s|%s|HP%d" % [row.deck, row.encounter, row.composition, row.initial_hp_percent]
		if not out.segments.has(key): out.segments[key] = {"pairs": 0, "baseline_wins": 0, "candidate_wins": 0, "new_wins": 0, "new_losses": 0, "baseline_censored": 0, "candidate_censored": 0}
		var segment: Dictionary = out.segments[key]
		segment.pairs += 1
		segment.baseline_wins += int(row.baseline.won)
		segment.candidate_wins += int(row.candidate.won)
		segment.new_wins += int(not row.baseline.won and row.candidate.won)
		segment.new_losses += int(row.baseline.won and not row.candidate.won)
		segment.baseline_censored += row.baseline.tempo_metrics.censored_checkpoints.size()
		segment.candidate_censored += row.candidate.tempo_metrics.censored_checkpoints.size()
	out.initial_unique = initials.size()
	out.paired_unique_trajectories = trajectories.size()
	return out

func _add_checkpoint_aggregates(destination: Dictionary, checkpoints: Dictionary) -> void:
	for checkpoint in checkpoints:
		if not destination.has(checkpoint): destination[checkpoint] = {"observed": 0, "enemy_hp_sum": 0, "owner_hp_sum": 0, "team_hp_sum": 0, "living_enemies_sum": 0, "owner_strength_sum": 0, "owner_morale_sum": 0, "owner_tokens_sum": 0, "owner_sacrifice_bank_sum": 0, "enemy_poison_sum": 0, "enemy_charm_sum": 0}
		var aggregate: Dictionary = destination[checkpoint]
		var snapshot: Dictionary = checkpoints[checkpoint]
		aggregate.observed += 1
		for metric in ["enemy_hp", "owner_hp", "team_hp", "living_enemies", "owner_strength", "owner_morale", "owner_tokens", "owner_sacrifice_bank", "enemy_poison", "enemy_charm"]:
			aggregate[metric + "_sum"] += int(snapshot.get(metric, 0))
