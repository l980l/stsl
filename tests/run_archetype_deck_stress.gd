extends "res://tests/run_archetype_deck_balance.gd"

# Post-hoc wounded-entry boundary, not the normal difficulty target.
# STSL_STRESS_SEED_COUNT=N widens the sample to seeds 101, 202, ... 101*N (default 2).
func _stress_seeds() -> Array:
	var count := maxi(2, int(OS.get_environment("STSL_STRESS_SEED_COUNT")))
	var seeds: Array = []
	for i in range(count):
		seeds.append(101 * (i + 1))
	return seeds

# Every deck meets every pair of the other five heroes, so no deck is judged by
# a partner set the others never face. STSL_STRESS_PARTNERS=fixed restores the
# old napoleon/yi_sun_sin/cleopatra fill for comparison with earlier reports.
func _partner_pairs(owner: String) -> Array:
	if OS.get_environment("STSL_STRESS_PARTNERS") == "fixed":
		var fixed: Array = []
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner != owner and fixed.size() < 2:
				fixed.append(partner)
		return [fixed]
	var others: Array = []
	for definition in Definitions.DECKS:
		if definition.hero != owner and definition.hero not in others:
			others.append(definition.hero)
	var pairs: Array = []
	for i in range(others.size()):
		for j in range(i + 1, others.size()):
			pairs.append([others[i], others[j]])
	return pairs

func _party_summary(rows: Array) -> Dictionary:
	var out := {}
	for row in rows:
		var key: String = "%s|%s" % [row.deck, ",".join(row.partners)]
		if not out.has(key):
			out[key] = {"n": 0, "wins": 0}
		out[key].n += 1
		out[key].wins += int(row.result.won)
	return out

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
	var expected := 0
	for definition in Definitions.DECKS:
		_owner = definition.hero
		_package = definition.cards
		for partners in _partner_pairs(_owner):
			var heroes: Array = [_owner] + partners
			expected += 2 * _stress_seeds().size()
			for encounter in ["sekhmet", "surtr"]:
				_encounter = [enemies["enemy." + ("egyptian." if encounter == "sekhmet" else "norse.") + encounter]]
				for seed_value in _stress_seeds():
					var segment := {"label": definition.id, "hero_ids": heroes, "probe_card": ""}
					_revert_martyr = false
					var result := await _simulate(_encounter[0], segment, 0, seed_value, true)
					var row := {"deck": definition.id, "hero": _owner, "archetype": definition.archetype, "heroes": heroes.duplicate(), "cards": _package.duplicate(), "partners": partners.duplicate(), "encounter": encounter, "initial_hp_percent": 25, "grade": 0, "seed": seed_value, "result": result}
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
	var report := {"schema": 1, "contract": "docs/game_design/archetype_deck_balance_evaluation.md", "post_hoc": true, "seeds": _stress_seeds(), "partners": "fixed" if OS.get_environment("STSL_STRESS_PARTNERS") == "fixed" else "all pairs of the other five heroes", "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "boundary": "25 percent wounded entry; base cards; same hand-order policy; not a normal target win-rate", "integrity_failures": invalid, "summary": _deck_summary(rows), "by_party": _party_summary(rows), "runs": rows}
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
	quit(0 if invalid == 0 and rows.size() == expected else 1)
