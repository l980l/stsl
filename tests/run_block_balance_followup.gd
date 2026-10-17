extends "res://tests/run_block_balance.gd"

# Explicit post-hoc diagnostic, not an independent extension of the initial
# sample: five seed101/base states overlap the first report.
const FOCUS := [
	["genghis_khan", ["arrow_volley", "cavalry_retreat"]],
	["genghis_khan", ["loot", "war_tribute"]],
	["yi_sun_sin", ["consecutive_defense", "charge_stance"]],
	["yi_sun_sin", ["formation_boost", "naval_training"]],
	["joan_of_arc", ["holy_touch", "communion"]],
]

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 120
	_hp_percent = 50
	for card in Catalog.get_all_cards():
		_sources[card.card_name] = card
	for enemy in Monsters.get_all_monsters():
		if enemy.enemy_name == "enemy.norse.surtr":
			_encounter = [enemy]
	var rows: Array = []
	var invalid := 0
	for focus in FOCUS:
		_owner = focus[0]
		_package = focus[1]
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		var segment := {"label": _owner + ":" + ",".join(_package), "hero_ids": heroes, "probe_card": ""}
		for grade in [0, 1]:
			for seed_value in [101, 202, 303]:
				_keep = true
				var before := await _simulate(_encounter[0], segment, grade, seed_value, true)
				_keep = false
				var after := await _simulate(_encounter[0], segment, grade, seed_value, true)
				var initial_equal: bool = before.initial_hash == after.initial_hash
				if not initial_equal or before.outcome == "incomplete" or after.outcome == "incomplete":
					invalid += 1
				var trajectory := JSON.stringify([before.trace, after.trace]).sha256_text()
				before.erase("trace")
				after.erase("trace")
				rows.append({"hero": _owner, "package": _package.duplicate(), "heroes": heroes.duplicate(), "encounter": "surtr", "initial_hp_percent": 50, "seed": seed_value, "grade": grade, "before": before, "after": after, "initial_equal": initial_equal, "trajectory_hash": trajectory, "hp_delta": after.remaining_hp - before.remaining_hp, "input_delta": after.hero_input_turns - before.hero_input_turns})
		print("Block followup completed: " + segment.label)
	var hashes := _fingerprints()
	for path in ["res://tests/run_block_balance_followup.gd", "res://tests/run_block_balance.gd", "res://tests/block_balance_battle_manager.gd", "res://tests/run_archetype_playtest.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/block_balance_evaluation.md", "post_hoc": true, "overlap_with_initial": 5, "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "seeds": [101, 202, 303], "grades": [0, 1], "policy": "unchanged first affordable hand-order", "cap": _cap, "integrity_failures": invalid, "summary": _summary(rows), "runs": rows}
	var path := "user://block_balance_followup.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write followup")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Block followup report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if invalid == 0 and rows.size() == 30 else 1)

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	result["enemy_turn_ends"] = trace.filter(func(snapshot: Dictionary) -> bool:
		return snapshot.phase == "turn_ended" and snapshot.actor.begins_with("enemy:"))
	return result
