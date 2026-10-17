extends SceneTree

# Fixed card-role probes, not a win-rate or universal card-value estimate.
const Catalog = preload("res://resources/card_catalog.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const GM = preload("res://autoload/game_manager.gd")
const NAMES = ["strike", "niten_starter", "niten_slash", "whirlwind_cut", "flying_swallow", "twin_blades_basic", "blood_path"]
var failed := 0
var checked := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	checked += 1
	if not ok:
		failed += 1
		push_error(label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var gm := GM.new()
	var fixture := Fixture.new()
	var rows: Array = []
	for card in Catalog.get_all_cards():
		if card.owner_id != "musashi" or card.card_name.trim_prefix("card.musashi.").trim_suffix(".name") not in NAMES:
			continue
		for grade in [0, 1]:
			var probe: Resource = card.duplicate(true)
			if grade == 1:
				gm.upgrade_card(probe)
			for strength in [0, 1, 3]:
				for modifiers in [0, 1, 2, 3]:
					for ids in [["musashi"], ["musashi", "napoleon", "cleopatra"]]:
						var bm = fixture._battle(ids, 1)
						bm._hero_status["musashi"] = {"strength": strength, "weak": 1 if modifiers & 1 else 0}
						bm._enemy_status[0]["vulnerable"] = 1 if modifiers & 2 else 0
						var preview: Dictionary = bm._estimate_card_damage(probe, 0)
						var hp: int = bm.get_enemy_hp(0)
						bm._apply_card_effects(probe, 0)
						var damage: int = hp - bm.get_enemy_hp(0)
						_check(damage == int(preview.get(0, 0)), probe.card_name + " preview/actual")
						_check(bm._enemy_hp[0] is int and bm.get_hero_block("musashi") is int, "integer outcomes")
						rows.append({"card": probe.card_name, "grade": grade, "strength": strength, "weak": bool(modifiers & 1), "vulnerable": bool(modifiers & 2), "party_size": ids.size(), "cost": probe.cost, "damage": damage, "block": bm.get_hero_block("musashi"), "energy_refund_empty_hand": bm.deck_mgr.get_energy("musashi")})
						fixture._free(bm)
	_check(rows.size() == 336, "seven cards x grades2 x strength3 x modifiers4 x parties2")
	for card in Catalog.get_all_cards():
		if card.card_name != "card.musashi.flying_swallow.name":
			continue
		var bm = fixture._battle(["musashi"], 1)
		bm.deck_mgr.get_hand("musashi").append(card)
		bm._apply_card_effects(card, 0)
		_check(bm.deck_mgr.get_energy("musashi") == 0, "swallow no refund with another card in hand")
		bm.deck_mgr.get_hand("musashi").clear()
		bm._apply_card_effects(card, 0)
		bm._apply_card_effects(card, 0)
		_check(bm.deck_mgr.get_energy("musashi") == 1, "swallow refund only once per owner turn")
		fixture._free(bm)
	for row in rows:
		if row.card == "card.musashi.whirlwind_cut.name":
			_check(row.block == 0, "synergy whirlwind cannot invent block when no block was supplied")
		if row.card == "card.musashi.flying_swallow.name":
			_check(row.energy_refund_empty_hand == 1, "swallow empty-hand refund")
		if row.strength == 0 and not row.weak and not row.vulnerable and row.party_size == 1:
			print("ROLE ", JSON.stringify(row))
	var sources: Dictionary = {}
	for path in ["res://autoload/battle_manager.gd", "res://autoload/game_manager.gd", "res://resources/balance/small_number_profile.gd", "res://resources/cards/cards_musashi.gd", "res://resources/cards/card_revision_v3.gd", "res://tests/test_card_revision_runtime.gd", "res://tests/run_musashi_role_checks.gd"]:
		sources[path] = FileAccess.get_sha256(path)
	sources["res://resources/cards/archetype_synergy_revision.gd"] = FileAccess.get_sha256("res://resources/cards/archetype_synergy_revision.gd")
	var report_path := "user://musashi-role-checks.json"
	var file := FileAccess.open(report_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema": 1, "unit": "fixed immediate card-effect state", "cases": rows.size(), "crit": false, "boundary": "empty hand; no active powers or enemy defense; controlled role comparison, not universal dominance or fun", "source_files_sha256": sources, "rows": rows}, "\t"))
	file.close()
	print("MUSASHI REPORT: ", ProjectSettings.globalize_path(report_path))
	gm.free()
	print("MUSASHI ROLE CHECKS: %d checks, %d failed, %d states" % [checked, failed, rows.size()])
	quit(1 if failed else 0)
