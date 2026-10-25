extends "res://tests/run_archetype_deck_balance.gd"

# Paired policy evaluator.  It reuses the production ATB sampler and the
# authored 16-card decks; it never reimplements combat state or card effects.
const Policy = preload("res://tools/synergy_decision_policy.gd")
const POLICY_SCENARIOS := {
	"sekhmet": ["egyptian.sekhmet"],
	"surtr": ["norse.surtr"],
}
const FULL_SEEDS := [101, 202]
const FULL_GRADES := [0, 1]
const FULL_HP := [100, 50, 25]

var _policy_name := "baseline_hand_order"
var _decisions := {}

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_revert_martyr = false
	for card in Catalog.get_all_cards():
		_sources[card.card_name] = card
	var errors := _validate_decks()
	if not errors.is_empty():
		push_error(JSON.stringify(errors))
		quit(1)
		return
	var enemies := {}
	for enemy in Monsters.get_all_monsters():
		enemies[enemy.enemy_name] = enemy
	var smoke := OS.get_environment("STSL_POLICY_SMOKE") == "1"
	var definitions: Array = [Definitions.DECKS[0]] if smoke else Definitions.DECKS
	var seeds: Array = [101] if smoke else FULL_SEEDS
	var grades: Array = [0] if smoke else FULL_GRADES
	var hp_values: Array = [25, 100] if smoke else FULL_HP
	var rows: Array = []
	var invalid: Array = []
	for definition in definitions:
		_owner = definition.hero
		_package = definition.cards
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		for encounter in POLICY_SCENARIOS:
			_encounter.clear()
			for id in POLICY_SCENARIOS[encounter]:
				if not enemies.has("enemy." + id):
					invalid.append("Missing enemy: " + id)
					continue
				_encounter.append(enemies["enemy." + id])
			if _encounter.is_empty():
				continue
			for hp_percent in hp_values:
				_hp_percent = hp_percent
				for grade in grades:
					for seed_value in seeds:
						var segment := {"label": definition.id, "hero_ids": heroes, "probe_card": ""}
						_policy_name = "baseline_hand_order"
						_revert_martyr = false
						var baseline := await _simulate(_encounter[0], segment, grade, seed_value, true)
						_policy_name = "synergy_policy"
						_revert_martyr = false
						var candidate := await _simulate(_encounter[0], segment, grade, seed_value, true)
						var initial_equal: bool = baseline.initial_hash == candidate.initial_hash
						if not initial_equal:
							invalid.append("Initial mismatch: %s/%s/%d/%d/%d" % [definition.id, encounter, hp_percent, grade, seed_value])
						if baseline.outcome == "incomplete" or candidate.outcome == "incomplete":
							invalid.append("Incomplete: %s/%s/%d/%d/%d" % [definition.id, encounter, hp_percent, grade, seed_value])
						rows.append({"deck": definition.id, "hero": _owner, "archetype": definition.archetype, "heroes": heroes.duplicate(), "cards": _package.duplicate(), "encounter": encounter, "initial_hp_percent": hp_percent, "grade": grade, "seed": seed_value, "baseline": baseline, "candidate": candidate, "initial_equal": initial_equal, "paired_trajectory_hash": JSON.stringify([baseline.trace, candidate.trace]).sha256_text(), "hp_delta": candidate.remaining_hp - baseline.remaining_hp, "input_delta": candidate.hero_input_turns - baseline.hero_input_turns})
		print("Synergy policy completed: " + definition.id)
	var expected_pairs := definitions.size() * POLICY_SCENARIOS.size() * hp_values.size() * grades.size() * seeds.size()
	if rows.size() != expected_pairs:
		invalid.append("Expected %d pairs, got %d" % [expected_pairs, rows.size()])
	var hashes := _fingerprints()
	for path in ["res://tests/run_synergy_policy_balance.gd", "res://tools/synergy_decision_policy.gd", "res://tools/charm_decision_policy.gd", "res://tests/run_archetype_deck_balance.gd", "res://tests/archetype_balance_decks.gd", "res://tests/run_block_balance.gd", "res://tests/block_balance_battle_manager.gd", "res://tests/run_archetype_playtest.gd", "res://tools/simulate_small_number_battles.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/synergy_policy_evaluation.md", "mode": "smoke" if smoke else "full", "smoke_declared": smoke, "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "decks": definitions, "scenarios": POLICY_SCENARIOS, "seeds": seeds, "grades": grades, "hp_percent": hp_values, "cap": _cap, "expected_pairs": expected_pairs, "full_expected_pairs": Definitions.DECKS.size() * POLICY_SCENARIOS.size() * FULL_HP.size() * FULL_GRADES.size() * FULL_SEEDS.size(), "policy": {"baseline": "inherited first affordable hand-order; first living enemy; lowest-HP ally; transfers exclude self", "candidate": "synergy_decision_policy.choose plus policy discard_choice"}, "fixtures": "18 owner starter10+6 distinct rewards, two partners starter10; current small-number production rules on both sides; no relic, crit off", "boundary": "policy ablation only, not a card-buff ablation; adoption is not automatic when new losses occur; no fun or campaign claim", "integrity_failures": invalid, "summary": _summary(rows), "runs": rows}
	var path := "user://synergy_policy_balance.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write synergy policy report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Synergy policy report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if invalid.is_empty() else 1)

func _on_battle_ready(bm: Object) -> void:
	super._on_battle_ready(bm)
	bm.set_meta("initial_hash", JSON.stringify(_snapshot(bm, "initial", "", 0)).sha256_text())
	_decisions[bm.get_instance_id()] = []

func _play_hand_order(bm: Object, hero_id: String) -> int:
	if _policy_name == "baseline_hand_order":
		return super._play_hand_order(bm, hero_id)
	var played := 0
	var log_entries: Array = _decisions.get(bm.get_instance_id(), [])
	while bm.is_player_turn:
		var choice: Dictionary = Policy.choose(bm, hero_id)
		var card: Resource = choice.get("card", null)
		var entry := {"hero": hero_id, "card": card.card_name if card != null else "", "target": int(choice.get("target", -1)), "ally": str(choice.get("ally", "")), "reason": str(choice.get("reason", "")), "score": float(choice.get("score", 0.0))}
		if card == null:
			entry["played"] = false
			log_entries.append(entry)
			break
		entry["played"] = bm.play_card(card, entry.target, entry.ally)
		log_entries.append(entry)
		if not entry.played:
			break
		played += 1
		_resolve_policy_discard(bm)
	return played

func _resolve_policy_discard(bm: Object) -> void:
	if bm._pending_discard_pick.is_empty():
		return
	var owner: String = bm.get_pending_discard_owner()
	bm.resolve_pending_discard_pick(Policy.discard_choice(bm, owner))

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	result["initial_hash"] = bm.get_meta("initial_hash")
	result["trajectory_hash"] = JSON.stringify(trace).sha256_text()
	result["decisions"] = _decisions.get(bm.get_instance_id(), []).duplicate(true)
	_decisions.erase(bm.get_instance_id())
	return result

func _summary(rows: Array) -> Dictionary:
	var out := {"pairs": rows.size(), "initial_unique": 0, "paired_unique_trajectories": 0, "outcomes": {"baseline": {}, "candidate": {}}, "caps": {"baseline": 0, "candidate": 0}, "incomplete": {"baseline": 0, "candidate": 0}, "new_wins": 0, "new_losses": 0, "common_win_hp_delta": {"count": 0, "sum": 0, "min": 0, "max": 0}, "common_win_action_delta": {"count": 0, "sum": 0, "min": 0, "max": 0}, "by_hp_deck_encounter": {}}
	var initial := {}
	var trajectories := {}
	for row in rows:
		initial[row.baseline.initial_hash] = true
		trajectories[row.paired_trajectory_hash] = true
		for side in ["baseline", "candidate"]:
			var result: Dictionary = row[side]
			out.outcomes[side][result.outcome] = int(out.outcomes[side].get(result.outcome, 0)) + 1
			out.caps[side] += int(result.capped)
			out.incomplete[side] += int(result.outcome == "incomplete")
		out.new_wins += int(not row.baseline.won and row.candidate.won)
		out.new_losses += int(row.baseline.won and not row.candidate.won)
		var key := "%s|HP%d|%s" % [row.deck, row.initial_hp_percent, row.encounter]
		if not out.by_hp_deck_encounter.has(key):
			out.by_hp_deck_encounter[key] = {"pairs": 0, "baseline": {"wins": 0, "losses": 0, "caps": 0, "incomplete": 0}, "candidate": {"wins": 0, "losses": 0, "caps": 0, "incomplete": 0}, "new_wins": 0, "new_losses": 0, "common_win_hp_delta_sum": 0, "common_win_action_delta_sum": 0}
		var bucket: Dictionary = out.by_hp_deck_encounter[key]
		bucket.pairs += 1
		for side in ["baseline", "candidate"]:
			var side_result: Dictionary = row[side]
			bucket[side].wins += int(side_result.won)
			bucket[side].losses += int(side_result.outcome == "loss")
			bucket[side].caps += int(side_result.capped)
			bucket[side].incomplete += int(side_result.outcome == "incomplete")
		bucket.new_wins += int(not row.baseline.won and row.candidate.won)
		bucket.new_losses += int(row.baseline.won and not row.candidate.won)
		if row.baseline.won and row.candidate.won:
			for metric in [["common_win_hp_delta", row.hp_delta], ["common_win_action_delta", row.input_delta]]:
				out[metric[0]].count += 1
				out[metric[0]].sum += metric[1]
				out[metric[0]].min = mini(out[metric[0]].min, metric[1])
				out[metric[0]].max = maxi(out[metric[0]].max, metric[1])
			bucket.common_win_hp_delta_sum += row.hp_delta
			bucket.common_win_action_delta_sum += row.input_delta
	out.initial_unique = initial.size()
	out.paired_unique_trajectories = trajectories.size()
	return out
