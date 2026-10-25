extends "res://tests/run_synergy_policy_balance.gd"

const Guard = preload("res://tools/guard_decision_policy.gd")
const SEEDS := [101, 202, 303, 404]
var _use_guard := false

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_keep = false
	_cap = 120
	_revert_martyr = false
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	if not _validate_decks().is_empty():
		push_error("Invalid deck fixtures")
		quit(1)
		return
	var enemies := {}
	for enemy in Monsters.get_all_monsters(): enemies[enemy.enemy_name] = enemy
	var smoke := OS.get_environment("STSL_GUARD_SMOKE") == "1"
	var definitions: Array = [Definitions.DECKS[0]] if smoke else Definitions.DECKS
	var seeds: Array = [101, 303] if smoke else SEEDS
	var hp_values: Array = [25] if smoke else [100, 50, 25]
	var grades: Array = [0] if smoke else [0, 1]
	var rows: Array = []
	var invalid: Array = []
	for definition in definitions:
		_owner = definition.hero
		_package = definition.cards
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3: heroes.append(partner)
		for encounter in POLICY_SCENARIOS:
			_encounter.clear()
			for id in POLICY_SCENARIOS[encounter]: _encounter.append(enemies["enemy." + id])
			for hp in hp_values:
				_hp_percent = hp
				for grade in grades:
					for seed_value in seeds:
						var segment := {"label": definition.id, "hero_ids": heroes, "probe_card": ""}
						_policy_name = "synergy_policy"
						_use_guard = false
						var before := await _simulate(_encounter[0], segment, grade, seed_value, true)
						_use_guard = true
						var after := await _simulate(_encounter[0], segment, grade, seed_value, true)
						var key := "%s:%s:%d:%d:%d" % [definition.id, encounter, hp, grade, seed_value]
						if before.initial_hash != after.initial_hash: invalid.append("Initial mismatch:" + key)
						for result in [before, after]:
							if result.outcome == "incomplete": invalid.append("Incomplete:" + key)
							for decision in result.decisions:
								if decision.card != "" and not decision.played: invalid.append("Rejected:" + key)
						var paired := JSON.stringify([before.trace, after.trace]).sha256_text()
						before.erase("trace")
						after.erase("trace")
						rows.append({"key": key, "deck": definition.id, "hero": _owner, "encounter": encounter, "initial_hp_percent": hp, "grade": grade, "seed": seed_value, "seed_segment": "development" if seed_value in [101, 202] else "additional", "baseline": before, "candidate": after, "initial_equal": before.initial_hash == after.initial_hash, "paired_trajectory_hash": paired, "hp_delta": after.remaining_hp - before.remaining_hp, "input_delta": after.hero_input_turns - before.hero_input_turns})
		print("Guard policy completed: " + definition.id)
	var expected := definitions.size() * POLICY_SCENARIOS.size() * hp_values.size() * grades.size() * seeds.size()
	if rows.size() != expected: invalid.append("Expected %d pairs, got%d" % [expected, rows.size()])
	var hashes := _fingerprints()
	for path in ["res://tools/synergy_decision_policy.gd", "res://tools/charm_decision_policy.gd", "res://tools/guard_decision_policy.gd", "res://tests/run_guard_policy_balance.gd", "res://tests/run_synergy_policy_balance.gd", "res://tests/run_archetype_deck_balance.gd", "res://tests/run_block_balance.gd", "res://tests/run_archetype_playtest.gd", "res://tests/archetype_balance_decks.gd", "res://tests/block_balance_battle_manager.gd"]: hashes[path] = FileAccess.get_sha256(path)
	var summary := {"all": _summary(rows)}
	for segment_name in ["development", "additional"]:
		summary[segment_name] = _summary(rows.filter(func(row: Dictionary) -> bool: return row.seed_segment == segment_name))
	var report := {"schema": 2, "contract": "docs/game_design/guard_policy_v2_evaluation.md", "mode": "smoke" if smoke else "full", "policy_version": Guard.VERSION, "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "seeds": seeds, "hp_percent": hp_values, "grades": grades, "decks": definitions, "scenarios": POLICY_SCENARIOS, "cap": _cap, "expected_pairs": expected, "full_expected_pairs": 864, "integrity_failures": invalid, "summary": summary, "runs": rows}
	var file := FileAccess.open("user://guard_policy_balance.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write guard report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Guard policy report: " + ProjectSettings.globalize_path("user://guard_policy_balance.json"))
	for group in summary:
		var compact: Dictionary = summary[group].duplicate()
		compact.erase("by_hp_deck_encounter")
		print(group + ":" + JSON.stringify(compact))
	quit(0 if invalid.is_empty() else 1)

func _play_hand_order(bm: Object, hid: String) -> int:
	if not _use_guard: return super._play_hand_order(bm, hid)
	var played := 0
	var entries: Array = _decisions[bm.get_instance_id()]
	while bm.is_player_turn:
		var choice := Guard.choose(bm, hid)
		var card: Resource = choice.get("card")
		var entry := {"hero": hid, "card": card.card_name if card else "", "target": choice.get("target", -1), "ally": choice.get("ally", ""), "reason": choice.get("reason", ""), "score": choice.get("score", 0.0)}
		if card == null:
			entry["played"] = false
			entries.append(entry)
			break
		entry["played"] = bm.play_card(card, entry.target, entry.ally)
		entries.append(entry)
		if not entry.played: break
		played += 1
		_resolve_policy_discard(bm) # v1 discard is held fixed for both arms
	return played
