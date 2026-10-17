extends "res://tools/simulate_small_number_battles.gd"

# Bounded integration sample, not a fun or draft-economy score.
const PACKAGES := {
	"napoleon": [["cavalry_threat", "arcole_breakthrough"], ["artillery_gather", "grand_armee_shield"], ["line_reform", "charge_bugle"]],
	"cleopatra": [["poison_seed", "poison_party"], ["snake_gaze", "pharaoh_fury"], ["nile_whisper", "charming_perfume"]],
	"yi_sun_sin": [["consecutive_defense", "charge_stance"], ["formation_boost", "naval_training"], ["all_in", "crisis_breakthrough"]],
	"joan_of_arc": [["holy_bolt", "orleans_charge"], ["holy_touch", "communion"], ["martyrdom_steps", "last_shield"]],
	"genghis_khan": [["swift_raid", "cavalry_crossing"], ["arrow_volley", "cavalry_retreat"], ["loot", "war_tribute"]],
	"musashi": [["niten_slash", "whirlwind_cut"], ["courage", "single_cut"], ["empty_state", "empty_guard"]],
}
var _owner := ""
var _package: Array = []
var _sources := {}
var _encounter: Array = []

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	_set_legacy_combat(true)
	_all_enemies = true
	_cap = 96
	for card in Catalog.get_all_cards():
		_sources[card.card_name] = card
	var enemies := {}
	for enemy in Monsters.get_all_monsters():
		enemies[enemy.enemy_name] = enemy
	var scenarios := {
		"authored_egyptian_trio": ["anubis_guard", "sand_scout", "nile_crocodile"],
		"act1_sekhmet": ["sekhmet"],
	}
	var rows: Array = []
	var failed := 0
	for hero_id in PACKAGES:
		_owner = hero_id
		var heroes: Array = [hero_id]
		for partner in ["napoleon", "yi_sun_sin", "cleopatra"]:
			if partner not in heroes and heroes.size() < 3:
				heroes.append(partner)
		for package in PACKAGES[hero_id]:
			_package = package
			for encounter_name in scenarios:
				_encounter.clear()
				for id in scenarios[encounter_name]:
					_encounter.append(enemies["enemy.egyptian." + id])
				for seed_value in [101, 202]:
					var row := await _paired_run(_encounter[0], {"label": hero_id + ":" + ",".join(package), "hero_ids": heroes, "probe_card": ""}, 0, seed_value)
					row["encounter"] = encounter_name
					rows.append(row)
					for side in ["legacy", "candidate"]:
						if row[side].outcome == "incomplete":
							failed += 1
		print("Archetype sample completed: " + hero_id)
	var sources := _fingerprints()
	sources["res://tests/run_archetype_playtest.gd"] = FileAccess.get_sha256("res://tests/run_archetype_playtest.gd")
	var report := {"schema": 1, "source_commit": OS.get_environment("STSL_BOT_SOURCE_COMMIT"), "dirty": OS.get_environment("STSL_BOT_SOURCE_DIRTY"), "sources_sha256": sources, "contract": "docs/game_design/archetype_synergy_revision.md", "unit": "paired battle with NEW rules in both unit systems, not a pre/post redesign comparison", "fixtures": "18 packages x 2 authored encounters x seeds101/202; owner starter10+reward2, partners starter10; base grade; full HP; crit off", "policy": "first affordable hand-order card, first living enemy; ALLY selects lowest-HP living hero (transfer excludes self)", "cap": _cap, "summary": _summarize(rows), "incomplete_failures": failed, "runs": rows}
	var path := "user://archetype_playtest.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write archetype sample")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Archetype report: " + ProjectSettings.globalize_path(path))
	print(JSON.stringify(report.summary))
	quit(0 if failed == 0 and rows.size() == 72 else 1)

func _starter_cards(hero_id: String, grade: int, candidate: bool) -> Array:
	var result := super._starter_cards(hero_id, grade, candidate)
	if hero_id == _owner:
		for slug in _package:
			result.append(_variant_card(_sources["card.%s.%s.name" % [hero_id, slug]], grade, candidate))
	return result

func _battle_enemies(_source: Resource, candidate: bool) -> Array:
	var result: Array = []
	for enemy in _encounter:
		result.append(_variant_enemy(enemy, candidate))
	return result

func _play_hand_order(bm: Object, hero_id: String) -> int:
	var played := 0
	while bm.is_player_turn:
		var selected: Resource = null
		for card in bm.deck_mgr.get_hand(hero_id):
			if bm.deck_mgr.can_play_hero(hero_id, card):
				selected = card
				break
		if selected == null:
			break
		var ally := ""
		var transfer := false
		var needs_ally := false
		for effect in selected.effects:
			needs_ally = needs_ally or effect.target == "ALLY"
			transfer = transfer or effect.rule_id == "block_transfer"
		var lowest := 2147483647
		if needs_ally:
			for hero in bm.team_mgr.get_living_heroes():
				if transfer and hero.hero_id == hero_id:
					continue
				var hp: int = bm.team_mgr.get_current_hp(hero.hero_id)
				if hp < lowest:
					lowest = hp
					ally = hero.hero_id
		if not bm.play_card(selected, _first_living_enemy(bm), ally):
			break
		played += 1
		_resolve_pending_discard(bm)
	return played

func _result(bm: Object, turns: int, trace: Array, reason: String = "") -> Dictionary:
	var result := super._result(bm, turns, trace, reason)
	var plays := {}
	for snapshot in trace:
		if snapshot.phase == "card_resolved":
			for slug in _package:
				if snapshot.actor == "card.%s.%s.name" % [_owner, slug]:
					plays[slug] = int(plays.get(slug, 0)) + 1
	result["package_plays"] = plays
	result["enemy_hp_by_index"] = bm._enemy_hp.duplicate()
	result.enemy_hp = 0
	for i in range(bm._enemy_hp.size()):
		if bm._enemy_alive[i]:
			result.enemy_hp += bm._enemy_hp[i]
	return result
