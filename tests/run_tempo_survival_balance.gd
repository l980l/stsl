extends "res://tests/run_tempo_policy_balance.gd"

const Prior = preload("res://tools/tempo_decision_policy.gd")
const Safe = preload("res://tools/tempo_survival_decision_policy.gd")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_revert_martyr = false
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	var fixture_errors := _validate_decks()
	if not fixture_errors.is_empty():
		push_error(JSON.stringify(fixture_errors))
		quit(1)
		return
	var mode := OS.get_environment("STSL_TEMPO_SURVIVAL_MODE")
	if mode == "": mode = "full"
	if mode not in ["full", "holdout", "regressions", "smoke"]:
		push_error("Unknown survival evaluation mode")
		quit(1)
		return
	var definitions: Array = Definitions.DECKS
	var seeds: Array = [909] if mode == "holdout" else [101, 505]
	var hp_values: Array = HP_VALUES
	var compositions := ["solo", "team"]
	var scenarios: Dictionary = TEMPO_SCENARIOS
	if mode == "regressions":
		definitions = definitions.filter(func(d: Dictionary) -> bool: return d.id in ["joan_martyr", "genghis_horde"])
		seeds = [505]
		compositions = ["solo"]
		scenarios = {"egyptian_trio": TEMPO_SCENARIOS.egyptian_trio}
	elif mode == "smoke":
		definitions = [definitions[0]]
		seeds = [101]
		hp_values = [50]
		scenarios = {"surtr": TEMPO_SCENARIOS.surtr, "norse_trio": TEMPO_SCENARIOS.norse_trio}
	var monsters := {}
	for enemy in Monsters.get_all_monsters(): monsters[enemy.enemy_name] = enemy
	var paths := _source_paths() + ["res://tools/tempo_survival_decision_policy.gd", "res://tests/run_tempo_survival_balance.gd"]
	var start := _source_hashes(paths)
	var rows := []
	var invalid := []
	for definition in definitions:
		_owner = definition.hero
		_package = definition.cards
		for composition in compositions:
			var heroes := _heroes_for(_owner, composition)
			for encounter in scenarios:
				_encounter.clear()
				for id in scenarios[encounter]: _encounter.append(monsters["enemy." + id])
				var health_values: Array = [50 if definition.id == "joan_martyr" else 25] if mode == "regressions" else hp_values
				for hp in health_values:
					_hp_percent = hp
					for seed_value in seeds:
						var segment := {"label": definition.id + ":" + composition, "hero_ids": heroes, "probe_card": ""}
						_use_tempo = false
						var baseline := await _simulate(_encounter[0], segment, 0, seed_value, true)
						_use_tempo = true
						var candidate := await _simulate(_encounter[0], segment, 0, seed_value, true)
						var key := "%s/%s/%s/HP%d/%d" % [definition.id, composition, encounter, hp, seed_value]
						if baseline.initial_hash != candidate.initial_hash: invalid.append("Initial mismatch:" + key)
						for result in [baseline, candidate]:
							if result.capped or result.outcome == "incomplete": invalid.append("Censored:" + key)
							for decision in result.decisions:
								if decision.card != "" and not decision.played: invalid.append("Rejected:" + key)
						if encounter in ["sekhmet", "surtr"] and baseline.trajectory_hash != candidate.trajectory_hash: invalid.append("Single-enemy drift:" + key)
						var pair_hash := JSON.stringify([baseline.trace, candidate.trace]).sha256_text()
						baseline.erase("trace")
						candidate.erase("trace")
						rows.append({"deck": definition.id, "hero": _owner, "composition": composition, "encounter": encounter, "initial_hp_percent": hp, "grade": 0, "seed": seed_value, "baseline": baseline, "candidate": candidate, "initial_equal": baseline.initial_hash == candidate.initial_hash, "paired_trajectory_hash": pair_hash, "hp_delta": candidate.remaining_hp - baseline.remaining_hp, "input_delta": candidate.hero_input_turns - baseline.hero_input_turns})
		print("Tempo survival completed: ", definition.id)
	var expected := 2 if mode == "regressions" else definitions.size() * compositions.size() * scenarios.size() * hp_values.size() * seeds.size()
	if rows.size() != expected: invalid.append("Unexpected sample count")
	var end := _source_hashes(paths)
	if start != end: invalid.append("Source drift")
	var summary := _tempo_summary(rows)
	var report := {"contract": "docs/game_design/tempo_survival_v4.md", "mode": mode, "source_commit": _source_commit, "dirty": _dirty, "source_sha256_start": start, "source_sha256_end": end, "policy": {"baseline": Prior.VERSION, "candidate": Safe.VERSION}, "metric_contract": _metric_contract(), "expected_pairs": expected, "seeds": seeds, "cap": _cap, "integrity_failures": invalid, "rollout_high_hp_gate": summary.new_high_hp_losses == 0, "summary": summary, "runs": rows}
	var output := FileAccess.open("user://tempo_survival_balance.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	print("Tempo survival report: ", ProjectSettings.globalize_path("user://tempo_survival_balance.json"))
	print(JSON.stringify(summary))
	# Outcome gates are reported separately from engine/integrity validity.
	quit(0 if invalid.is_empty() else 1)

func _play_hand_order(bm: Object, hid: String) -> int:
	if hid == _owner: _record_checkpoint(bm, hid)
	var played := 0
	while bm.is_player_turn:
		var choice: Dictionary = Safe.choose(bm, hid) if _use_tempo else Prior.choose(bm, hid)
		var card: Resource = choice.get("card")
		var entry := {"hero": hid, "card": card.card_name if card else "", "target": choice.get("target", -1), "ally": choice.get("ally", ""), "reason": choice.get("reason", ""), "score": choice.get("score", 0.0), "version": choice.get("version", ""), "played": false}
		if card == null:
			_decisions[bm.get_instance_id()].append(entry)
			break
		var cost: int = bm.deck_mgr.get_effective_cost(hid, card)
		if hid == _owner: _queue_energy_metric(bm, card, cost)
		entry.played = bm.play_card(card, entry.target, entry.ally)
		_decisions[bm.get_instance_id()].append(entry)
		if not entry.played: break
		if hid == _owner: _record_play_metrics(bm, card, cost)
		played += 1
		_resolve_policy_discard(bm)
	return played
