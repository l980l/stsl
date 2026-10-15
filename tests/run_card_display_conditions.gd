extends SceneTree

const Catalog = preload("res://resources/card_catalog.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")
const GM = preload("res://autoload/game_manager.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var fixture := Fixture.new()
	var gm := GM.new()
	for source in Catalog.get_all_cards():
		if source.card_name not in ["card.yi_sun_sin.death_or_glory.name", "card.yi_sun_sin.crisis_breakthrough.name", "card.yi_sun_sin.decisive_strike.name", "card.yi_sun_sin.phoenix.name", "card.yi_sun_sin.hold_formation.name"]:
			continue
		for grade in [0, 1]:
			var card: Resource = source.duplicate(true)
			if grade: gm.upgrade_card(card)
			for hp in [1, 20, 30, 31, 50, 51, 100]:
				var bm = fixture._battle(["napoleon", "yi_sun_sin", "cleopatra"], 1)
				bm.team_mgr.get_hero("yi_sun_sin").max_hp = 100
				bm.team_mgr._hero_hp["yi_sun_sin"] = hp
				bm.team_mgr._hero_hp["napoleon"] = 1
				for _i in 10:
					bm.deck_mgr._heroes["yi_sun_sin"]["draw"].append(card.duplicate(true))
				var before: int = bm.get_enemy_hp(0)
				var preview: Dictionary = bm._estimate_card_damage(card, 0)
				bm._apply_card_effects(card, 0)
				var first: Resource = card.effects[0]
				if first.effect_type == first.EffectType.CONDITIONAL_DMG:
					var threshold := 30 if first.status_type == "very_low_hp" else 50
					var damage: int = first.bonus_value if hp <= threshold else first.value
					_check(before - bm.get_enemy_hp(0) == damage, card.card_name + " actual own HP %d grade%d" % [hp, grade])
					_check(int(preview.get(0, 0)) == damage, card.card_name + " preview HP%d" % hp)
					if card.card_name.contains("decisive_strike"):
						_check(bm.get_hero_block("yi_sun_sin") == (card.effects[1].value if hp <= 50 else 0), "low HP conditional block")
				elif card.card_name.contains("hold_formation"):
					_check(bm.deck_mgr.get_hand("yi_sun_sin").size() == card.effects[1].value, "living team3 conditional draw")
				elif card.card_name.contains("phoenix"):
					# Authored effects resolve sequentially: heal, then evaluate draw.
					var after_heal: int = mini(100, hp + first.value)
					_check(bm.deck_mgr.get_hand("yi_sun_sin").size() == (card.effects[1].value if after_heal <= 50 else 0), "phoenix checks HP after preceding heal")
				fixture._free(bm)
			if card.card_name.contains("hold_formation"):
				var bm = fixture._battle(["yi_sun_sin", "napoleon"], 1)
				bm.deck_mgr._heroes["yi_sun_sin"]["draw"].append(card)
				bm._apply_card_effects(card, 0)
				_check(bm.deck_mgr.get_hand("yi_sun_sin").is_empty(), "team2 does not get team3 draw")
				fixture._free(bm)
				bm = fixture._battle(["yi_sun_sin", "napoleon", "cleopatra"], 1)
				bm.team_mgr._hero_alive["napoleon"] = false
				bm.team_mgr._hero_hp["napoleon"] = 0
				bm.deck_mgr._heroes["yi_sun_sin"]["draw"].append(card)
				bm._apply_card_effects(card, 0)
				_check(bm.deck_mgr.get_hand("yi_sun_sin").is_empty(), "dead roster member does not satisfy living team3")
				fixture._free(bm)
	gm.free()
	print("CARD DISPLAY CONDITIONS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
