extends SceneTree

const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const Catalog = preload("res://resources/card_catalog.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		print("FAIL: " + label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var fixture = Fixture.new()
	for source in Catalog.get_all_cards():
		if source.card_name != "card.genghis_khan.desert_cavalry.name":
			continue
		var pair: Dictionary = Profile.candidate_pair(source)
		for grade in [0, 1]:
			var card = pair.base if grade == 0 else pair.upgraded
			for draws in range(11):
				var bm = fixture._battle(["genghis_khan"])
				bm.combat_unit_divisor = 10
				bm.deck_mgr._heroes.genghis_khan.draws_this_turn = draws
				bm._hero_status.genghis_khan = {"strength": 99, "weak": 1}
				@warning_ignore("integer_division")
				var expected: int = (draws / 2) * 5 + (draws % 2) * 2 + (grade if draws > 0 else 0)
				_check(bm.estimate_effect_damage(card.effects[0], "genghis_khan", 0) == expected, "preview ignores strength/weak, draws%d grade%d" % [draws, grade])
				_check(bm._estimate_card_damage(card, 0).get(0, 0) == expected, "queued preview matches paired formula")
				bm._apply_card_effects(card, 0)
				_check(bm.get_enemy_hp(0) == 5000 - expected, "actual draw damage matches preview")
				fixture._free(bm)
		var bm = fixture._battle(["genghis_khan"])
		bm.deck_mgr._heroes.genghis_khan.draws_this_turn = 3
		bm._enemy_status[0].vulnerable = 1
		_check(bm.estimate_effect_damage(pair.upgraded.effects[0], "genghis_khan", 0) == 12, "receiver vulnerable preview")
		bm._apply_card_effects(pair.upgraded, 0)
		_check(bm.get_enemy_hp(0) == 4988, "receiver vulnerable actual")
		fixture._free(bm)
		for locale in ["ko", "en"]:
			TranslationServer.set_locale(locale)
			var description: String = pair.upgraded.effects[0].display_text()
			_check(not description.contains("{") and not description.contains("effect.v3") and description.contains("5") and description.contains("2") and description.contains("1"), "localized integer pair description")
	print("Small-number tuning: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
