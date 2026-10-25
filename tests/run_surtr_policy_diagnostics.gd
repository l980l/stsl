extends "res://tests/run_synergy_policy_balance.gd"

const Variants = preload("res://tests/surtr_policy_variants.gd")
var _variant := "synergy"
var _events := {}

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_keep = false
	_hp_percent = 25
	_cap = 120
	var reference_path := OS.get_environment("STSL_SURTR_REFERENCE")
	if reference_path.is_empty() or not FileAccess.file_exists(reference_path):
		push_error("STSL_SURTR_REFERENCE must point to the frozen full synergy_policy_balance.json")
		quit(1)
		return
	var reference = JSON.parse_string(FileAccess.get_file_as_string(reference_path))
	if not reference is Dictionary or reference.get("mode") != "full" or reference.get("expected_pairs", 0) != 432:
		push_error("Reference must be the full432 comparison, not smoke")
		quit(1)
		return
	var references := {}
	var regression_count := 0
	for row in reference.runs:
		if row.encounter != "surtr" or int(row.initial_hp_percent) != 25: continue
		var key := "%s:%d:%d" % [row.deck, row.grade, row.seed]
		var regression: bool = row.baseline.won and not row.candidate.won
		regression_count += int(regression)
		references[key] = {"initial": row.baseline.initial_hash, "trace": row.candidate.trajectory_hash, "hand_order_won": row.baseline.won, "original_won": row.candidate.won, "regression": regression}
	var old_hashes: Dictionary = reference.source_sha256.duplicate()
	reference = null # do not keep the large historical traces in memory
	var invalid: Array = []
	for path in old_hashes:
		if FileAccess.get_sha256(path) != old_hashes[path]: invalid.append("Frozen source changed: " + path)
	if references.size() != 72 or regression_count != 12 or not invalid.is_empty():
		push_error("Reference/source mismatch: " + JSON.stringify(invalid))
		quit(1)
		return
	for card in Catalog.get_all_cards(): _sources[card.card_name] = card
	if not _validate_decks().is_empty():
		push_error("Invalid deck fixtures")
		quit(1)
		return
	for enemy in Monsters.get_all_monsters():
		if enemy.enemy_name == "enemy.norse.surtr": _encounter = [enemy]
	var rows: Array = []
	var smoke := OS.get_environment("STSL_SURTR_SMOKE") == "1"
	var fixtures := 0
	for definition in Definitions.DECKS:
		_owner = definition.hero
		_package = definition.cards
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3: heroes.append(partner)
		for grade in [0, 1]:
			for seed_value in [101, 202]:
				var key := "%s:%d:%d" % [definition.id, grade, seed_value]
				var old: Dictionary = references[key]
				if smoke and key != "napoleon_charge:1:101": continue
				fixtures += 1
				for mode in Variants.MODES:
					_variant = mode
					_policy_name = "synergy_policy"
					_revert_martyr = false
					var result := await _simulate(_encounter[0], {"label": key, "hero_ids": heroes, "probe_card": ""}, grade, seed_value, true)
					if result.initial_hash != old.initial: invalid.append("Initial mismatch: " + key + ":" + mode)
					if mode == "synergy" and result.trajectory_hash != old.trace: invalid.append("Original policy replay mismatch: " + key)
					if result.outcome == "incomplete": invalid.append("Incomplete: " + key + ":" + mode)
					for decision in result.decisions:
						if decision.card != "" and not decision.played: invalid.append("Rejected play: " + key + ":" + mode)
					result.erase("trace")
					rows.append({"key": key, "deck": definition.id, "grade": grade, "seed": seed_value, "regression": old.regression, "hand_order_won": old.hand_order_won, "original_won": old.original_won, "mode": mode, "result": result})
		print("Surtr diagnostics completed: " + definition.id)
	var expected := (1 if smoke else 72) * Variants.MODES.size()
	if rows.size() != expected or fixtures != (1 if smoke else 72): invalid.append("Missing fixtures")
	var hashes := _fingerprints()
	for path in old_hashes: hashes[path] = FileAccess.get_sha256(path)
	for path in ["res://tests/run_surtr_policy_diagnostics.gd", "res://tests/surtr_policy_variants.gd"]: hashes[path] = FileAccess.get_sha256(path)
	var summary := {}
	for mode in Variants.MODES:
		var counts := {"battles": 0, "wins": 0, "losses": 0, "caps": 0, "regression_n": 0, "recovered": 0, "control_n": 0, "control_new_losses": 0, "control_new_wins": 0, "unique_trajectories": 0}
		var unique := {}
		for row in rows:
			if row.mode != mode: continue
			counts.battles += 1
			counts.wins += int(row.result.won)
			counts.losses += int(row.result.outcome == "loss")
			counts.caps += int(row.result.capped)
			if row.regression:
				counts.regression_n += 1
				counts.recovered += int(row.result.won)
			else:
				counts.control_n += 1
				counts.control_new_losses += int(row.original_won and not row.result.won)
				counts.control_new_wins += int(not row.original_won and row.result.won)
			unique[row.result.trajectory_hash] = true
		counts.unique_trajectories = unique.size()
		summary[mode] = counts
	var report := {"schema": 1, "contract": "docs/game_design/surtr_policy_diagnostics.md", "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "reference_sha256": FileAccess.get_sha256(reference_path), "mode": "smoke" if smoke else "full", "expected_battles": expected, "regression_fixtures": regression_count, "fixture_count": fixtures, "integrity_failures": invalid, "summary": summary, "runs": rows}
	var file := FileAccess.open("user://surtr_policy_diagnostics.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write diagnostics")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Surtr diagnostics report: " + ProjectSettings.globalize_path("user://surtr_policy_diagnostics.json"))
	print(JSON.stringify(summary))
	quit(0 if invalid.is_empty() else 1)

func _on_battle_ready(bm: Object) -> void:
	super._on_battle_ready(bm)
	_events[bm.get_instance_id()] = []
	bm.turn_ended.connect(func(actor: String) -> void:
		if actor.begins_with("enemy:"):
			var entry := _snapshot(bm, "enemy_ended", actor, 0)
			entry["enemy_phases"] = bm._enemy_phase.duplicate()
			entry["queue"] = bm.get_turn_queue_preview(8)
			_events[bm.get_instance_id()].append(entry))

func _play_hand_order(bm: Object, hid: String) -> int:
	var played := 0
	var log_entries: Array = _decisions[bm.get_instance_id()]
	while bm.is_player_turn:
		var choice := Variants.choose(bm, hid, _variant)
		var card: Resource = choice.get("card")
		var entry := {"hero": hid, "card": card.card_name if card else "", "target": choice.get("target", -1), "ally": choice.get("ally", ""), "reason": choice.get("reason", ""), "score": choice.get("score", 0.0), "before": _snapshot(bm, "decision", hid, 0), "enemy_phases": bm._enemy_phase.duplicate(), "queue": bm.get_turn_queue_preview(8)}
		if card == null:
			entry["played"] = false
			log_entries.append(entry)
			break
		entry["played"] = bm.play_card(card, entry.target, entry.ally)
		log_entries.append(entry)
		if not entry.played: break
		played += 1
		_resolve_policy_discard(bm) # identical discard policy in every arm
	return played

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	result["enemy_events"] = _events.get(bm.get_instance_id(), [])
	_events.erase(bm.get_instance_id())
	return result
