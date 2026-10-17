extends "res://tests/run_block_balance.gd"

const Definitions = preload("res://tests/archetype_balance_decks.gd")
const BUFFED := ["martyrdom_steps", "last_shield", "saints_revelation", "martyrs_light"]
var _revert_martyr := false

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_keep = false
	_cap = 120
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
	var rows: Array = []
	var invalid := 0
	for definition in Definitions.DECKS:
		_owner = definition.hero
		_package = definition.cards
		var heroes: Array = [_owner]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		var affected := _owner == "joan_of_arc" and _package.any(func(slug: String) -> bool: return slug in BUFFED)
		for encounter in SCENARIOS:
			_encounter.clear()
			for id in SCENARIOS[encounter]:
				_encounter.append(enemies["enemy." + id])
			for hp_percent in [100, 50]:
				_hp_percent = hp_percent
				for grade in [0, 1]:
					for seed_value in [101, 202]:
						var segment := {"label": definition.id, "hero_ids": heroes, "probe_card": ""}
						_revert_martyr = false
						var result := await _simulate(_encounter[0], segment, grade, seed_value, true)
						var row := {"deck": definition.id, "hero": _owner, "archetype": definition.archetype, "heroes": heroes.duplicate(), "cards": _package.duplicate(), "encounter": encounter, "initial_hp_percent": hp_percent, "grade": grade, "seed": seed_value, "result": result}
						if affected:
							_revert_martyr = true
							var before := await _simulate(_encounter[0], segment, grade, seed_value, true)
							_revert_martyr = false
							row["before_buff"] = before
							row["initial_equal"] = before.initial_hash == result.initial_hash
							row["hp_delta"] = result.remaining_hp - before.remaining_hp
							row["input_delta"] = result.hero_input_turns - before.hero_input_turns
							row["paired_hash"] = JSON.stringify([before.trace, result.trace]).sha256_text()
							if not row.initial_equal or before.outcome == "incomplete":
								invalid += 1
							before.erase("trace")
						if result.outcome == "incomplete":
							invalid += 1
						result.erase("trace")
						rows.append(row)
		print("Archetype deck completed: " + definition.id)
	var hashes := _fingerprints()
	for path in ["res://tests/run_archetype_deck_balance.gd", "res://tests/archetype_balance_decks.gd", "res://tests/run_block_balance.gd", "res://tests/block_balance_battle_manager.gd", "res://tests/run_archetype_playtest.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/archetype_deck_balance_evaluation.md", "source_commit": _source_commit, "dirty": _dirty, "source_sha256": hashes, "decks": Definitions.DECKS, "scenarios": SCENARIOS, "seeds": [101, 202], "grades": [0, 1], "hp_percent": [100, 50], "cap": _cap, "policy": "first affordable hand-order; first living enemy; ally lowest HP; transfer excludes self", "boundary": "owner starter10+6 distinct rewards, two partners starter10; no relic, crit off; not campaign acquisition or expert-policy proof", "integrity_failures": invalid, "summary": _deck_summary(rows), "runs": rows}
	var path := "user://archetype_deck_balance.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write archetype deck report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Archetype deck report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if invalid == 0 and rows.size() == 576 else 1)

func _validate_decks() -> Array:
	var errors: Array = []
	var ids := {}
	var hero_counts := {}
	for definition in Definitions.DECKS:
		if ids.has(definition.id):
			errors.append("Duplicate deck: " + definition.id)
		ids[definition.id] = true
		hero_counts[definition.hero] = int(hero_counts.get(definition.hero, 0)) + 1
		var factory: GDScript = load("res://resources/cards/cards_%s.gd" % definition.hero)
		var starters: Array = factory.starter_deck().map(func(card: Resource) -> String: return card.card_name)
		var names := {}
		var rare := 0
		var legendary := 0
		if definition.cards.size() != 6:
			errors.append("Need six rewards: " + definition.id)
		for slug in definition.cards:
			var name: String = "card.%s.%s.name" % [definition.hero, slug]
			if not _sources.has(name) or name in starters or names.has(name):
				errors.append("Missing/starter/duplicate: " + name)
				continue
			names[name] = true
			var card: Resource = _sources[name]
			rare += int(card.rarity == 2)
			legendary += int(card.rarity == 3)
			if card.owner_id != definition.hero or card.rarity == 4:
				errors.append("Wrong owner/divine: " + name)
		if rare > 2 or legendary > 1:
			errors.append("Rarity budget exceeded: " + definition.id)
	if Definitions.DECKS.size() != 18 or hero_counts.size() != 6:
		errors.append("Expected18 decks/6 heroes")
	for hero in hero_counts:
		if hero_counts[hero] != 3:
			errors.append("Expected3 decks: " + hero)
	return errors

func _variant_card(card: Resource, grade: int, candidate: bool) -> Resource:
	var source: Resource = card.duplicate(true)
	if _revert_martyr:
		match source.card_name:
			"card.joan_of_arc.martyrdom_steps.name":
				source.effects[0].rule_params.bonus_draw = 1
				source.effects[0].upgrade_rule_params.bonus_draw = 2
			"card.joan_of_arc.last_shield.name":
				source.effects[1].rule_params.base = 0
				source.effects[1].upgrade_rule_params.base = 0
			"card.joan_of_arc.saints_revelation.name":
				source.effects[0].value = 70
				source.effects[0].base_value = 70
				source.effects[0].upgrade_value = 100
			"card.joan_of_arc.martyrs_light.name":
				source.effects[0].rule_params.base = 60
				source.effects[0].upgrade_rule_params.base = 90
	return super._variant_card(source, grade, candidate)

func _deck_summary(rows: Array) -> Dictionary:
	var out := {"battles": rows.size(), "unique_trajectories": 0, "outcomes": {}, "decks": {}, "buff_pairs": 0, "buff_before_outcomes": {}, "buff_after_outcomes": {}, "buff_new_losses": 0, "buff_new_caps": 0}
	var unique := {}
	for row in rows:
		var result: Dictionary = row.result
		unique[result.trajectory_hash] = true
		out.outcomes[result.outcome] = int(out.outcomes.get(result.outcome, 0)) + 1
		if not out.decks.has(row.deck):
			out.decks[row.deck] = {"n": 0, "wins": 0, "losses": 0, "caps": 0, "hp_sum": 0, "input_sum": 0, "reward_plays": {}}
		var deck: Dictionary = out.decks[row.deck]
		deck.n += 1
		deck.wins += int(result.won)
		deck.losses += int(result.outcome == "loss")
		deck.caps += int(result.capped)
		deck.hp_sum += result.remaining_hp
		deck.input_sum += result.hero_input_turns
		for slug in result.package_plays:
			deck.reward_plays[slug] = int(deck.reward_plays.get(slug, 0)) + int(result.package_plays[slug])
		if row.has("before_buff"):
			out.buff_pairs += 1
			for pair in [["buff_before_outcomes", row.before_buff.outcome], ["buff_after_outcomes", result.outcome]]:
				out[pair[0]][pair[1]] = int(out[pair[0]].get(pair[1], 0)) + 1
			out.buff_new_losses += int(row.before_buff.won and result.outcome == "loss")
			out.buff_new_caps += int(row.before_buff.won and result.outcome == "capped")
	out.unique_trajectories = unique.size()
	return out
