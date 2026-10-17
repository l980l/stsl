extends "res://tests/run_archetype_deck_balance.gd"

# Post-hoc wounded-entry boundary, not the normal difficulty target.
func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_keep = false
	_cap = 120
	_hp_percent = 25
	for card in Catalog.get_all_cards():
		_sources[card.card_name] = card
	if not _validate_decks().is_empty():
		push_error("Invalid stress deck definitions")
		quit(1)
		return
	var enemies := {}
	for enemy in Monsters.get_all_monsters():
		enemies[enemy.enemy_name] = enemy
	var rows: Array = []
	var invalid := 0
	for definition in Definitions.DECKS:
		_owner = definition.hero
		_package = definition.cards
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		for encounter in ["sekhmet", "surtr"]:
			_encounter = [enemies["enemy." + ("egyptian." if encounter == "sekhmet" else "norse.") + encounter]]
			for seed_value in [101, 202]:
				var segment := {"label": definition.id, "hero_ids": heroes, "probe_card": ""}
				_revert_martyr = false
				var result := await _simulate(_encounter[0], segment, 0, seed_value, true)
				var row := {"deck": definition.id, "hero": _owner, "archetype": definition.archetype, "heroes": heroes.duplicate(), "cards": _package.duplicate(), "encounter": encounter, "initial_hp_percent": 25, "grade": 0, "seed": seed_value, "result": result}
				if definition.id == "joan_martyr":
					_revert_martyr = true
					var before := await _simulate(_encounter[0], segment, 0, seed_value, true)
					_revert_martyr = false
					row["before_buff"] = before
					row["initial_equal"] = before.initial_hash == result.initial_hash
					row["hp_delta"] = result.remaining_hp - before.remaining_hp
					row["input_delta"] = result.hero_input_turns - before.hero_input_turns
					if not row.initial_equal or before.outcome == "incomplete":
						invalid += 1
					before.erase("trace")
				if result.outcome == "incomplete":
					invalid += 1
				result.erase("trace")
				rows.append(row)
		print("Archetype stress completed: " + definition.id)
	var hashes := _fingerprints()
	for path in ["res://tests/run_archetype_deck_stress.gd", "res://tests/run_archetype_deck_balance.gd", "res://tests/archetype_balance_decks.gd", "res://tests/run_block_balance.gd", "res://tests/block_balance_battle_manager.gd", "res://tests/run_archetype_playtest.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/archetype_deck_balance_evaluation.md", "post_hoc": true, "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "boundary": "25 percent wounded entry; base cards; same hand-order policy; not a normal target win-rate", "integrity_failures": invalid, "summary": _deck_summary(rows), "runs": rows}
	var path := "user://archetype_deck_stress.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write archetype stress")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Archetype stress report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if invalid == 0 and rows.size() == 72 else 1)
