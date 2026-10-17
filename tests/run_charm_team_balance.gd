extends "res://tests/run_poison_charm_balance.gd"

const Decisions = preload("res://tools/charm_decision_policy.gd")
const SCENARIOS := [
	{"id": "egyptian_trio", "enemies": ["egyptian.anubis_guard", "egyptian.sand_scout", "egyptian.nile_crocodile"]},
	{"id": "norse_trio", "enemies": ["norse.frost_wight", "norse.bone_archer", "norse.dark_elf"]},
	{"id": "sekhmet", "enemies": ["egyptian.sekhmet"]},
	{"id": "fjorgynn", "enemies": ["norse.fjorgynn"]},
	{"id": "osiris", "enemies": ["egyptian.osiris"]},
	{"id": "surtr", "enemies": ["norse.surtr"]},
]
var _policy := "hand_order"
var _enemy_sources: Array = []
var _source_cards := {}
var _decisions := {}
var _failures: Array = []

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 96
	for card in Catalog.get_all_cards():
		_source_cards[card.card_name] = card
	var enemies := {}
	for enemy in Monsters.get_all_monsters():
		enemies[enemy.enemy_name] = enemy
	var rows: Array = []
	for scenario in SCENARIOS:
		_enemy_sources.clear()
		for id in scenario.enemies:
			if not enemies.has("enemy." + id):
				push_error("Missing encounter enemy: " + id)
				quit(1)
				return
			_enemy_sources.append(enemies["enemy." + id])
		for build in BUILDS:
			_build = build
			var policies := ["hand_order", "consume_first", "threshold_aware"] if build == "charm_damage" else ["hand_order"]
			for policy in policies:
				_policy = policy
				for grade in [0, 1]:
					for seed_value in DEFAULT_SEEDS:
						rows.append(await _run_pair(scenario.id, ["napoleon", "cleopatra", "yi_sun_sin"], grade, seed_value))
		print("Team balance completed: " + scenario.id)
	# Replay the previous solo bottleneck without changing its deck or enemy.
	_enemy_sources = [enemies["enemy.norse.fjorgynn"]]
	_build = "charm_damage"
	for policy in ["hand_order", "consume_first", "threshold_aware"]:
		_policy = policy
		for grade in [0, 1]:
			for seed_value in DEFAULT_SEEDS:
				rows.append(await _run_pair("solo_fjorgynn", ["cleopatra"], grade, seed_value))
	var hashes := _fingerprints()
	for path in ["res://tests/run_charm_team_balance.gd", "res://tests/run_poison_charm_balance.gd", "res://tools/charm_decision_policy.gd"]:
		hashes[path] = FileAccess.get_sha256(path)
	var report := {"schema": 1, "contract": "docs/game_design/charm_team_policy_evaluation.md", "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "source_dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"), "source_sha256": hashes, "builds": BUILDS, "scenarios": SCENARIOS, "seeds": DEFAULT_SEEDS, "cap": _cap, "critical_hits": false, "summary": _summarize(rows), "integrity_failures": _failures, "runs": rows}
	if rows.size() != 234:
		_failures.append("Expected 234 paired runs, got %d" % rows.size())
	var path := "user://charm_team_balance.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write team balance report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print(JSON.stringify(report.summary))
	print("Team balance report: " + ProjectSettings.globalize_path(path))
	print("Integrity failures: %d" % _failures.size())
	quit(0 if _failures.is_empty() else 1)

func _run_pair(encounter: String, heroes: Array, grade: int, seed_value: int) -> Dictionary:
	var segment := {"label": _build + ":" + _policy, "hero_ids": heroes, "probe_card": ""}
	var row := await _paired_run(_enemy_sources[0], segment, grade, seed_value)
	row["encounter"] = encounter
	row["build"] = _build
	row["policy"] = _policy
	row["heroes"] = heroes
	for side in ["legacy", "candidate"]:
		if row[side].outcome == "incomplete":
			_failures.append("Incomplete: %s/%s/%s/%s/%d/%d" % [encounter, _build, _policy, side, grade, seed_value])
	return row

func _catalog_card(card_name: String) -> Resource:
	return _source_cards.get(card_name)

func _starter_cards(hero_id: String, grade: int, candidate: bool) -> Array:
	if hero_id == "cleopatra":
		return super._starter_cards(hero_id, grade, candidate)
	var script: GDScript = load("res://resources/cards/cards_%s.gd" % hero_id)
	var result: Array = []
	for card in script.starter_deck():
		result.append(_variant_card(card, grade, candidate))
	return result

func _battle_enemies(_enemy_source: Resource, candidate: bool) -> Array:
	var result: Array = []
	for source in _enemy_sources:
		result.append(_variant_enemy(source, candidate))
	return result

func _on_battle_ready(bm: Object) -> void:
	_attach_meters(bm)
	_decisions[bm.get_instance_id()] = []

func _play_hand_order(bm: Object, hero_id: String) -> int:
	var played := 0
	var log_entries: Array = _decisions[bm.get_instance_id()]
	while bm.is_player_turn:
		var choice := Decisions.choose(bm, hero_id, _policy)
		if choice.is_empty():
			break
		var card: Resource = choice.card
		var target: int = choice.target
		var entry := {"hero": hero_id, "card": card.card_name if card != null else "", "target": target, "reason": choice.reason, "held": choice.held, "charm_before": bm._enemy_status[target].get("charm", 0) if target >= 0 else 0, "enthrall_before": bm._enemy_status[target].get("enthrall", 0) if target >= 0 else 0, "consumer": card != null and Decisions.is_consumer(card)}
		if card == null:
			entry["played"] = false
			log_entries.append(entry)
			break
		entry["played"] = bm.play_card(card, target)
		entry["charm_after"] = bm._enemy_status[target].get("charm", 0) if target >= 0 else 0
		log_entries.append(entry)
		if not entry.played:
			break
		played += 1
		_resolve_pending_discard(bm)
	_meters[bm.get_instance_id()].cards_played += played
	return played

func _result(bm: Object, hero_input_turns: int, trace: Array, incomplete_reason: String = "") -> Dictionary:
	var result := super._result(bm, hero_input_turns, trace, incomplete_reason)
	result["decisions"] = _decisions.get(bm.get_instance_id(), []).duplicate(true)
	_decisions.erase(bm.get_instance_id())
	result["enemy_hp_by_index"] = bm._enemy_hp.duplicate()
	result.enemy_hp = 0
	for i in range(bm._enemy_hp.size()):
		if bm._enemy_alive[i]:
			result.enemy_hp += bm._enemy_hp[i]
	return result
