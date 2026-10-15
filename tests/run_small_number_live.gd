extends SceneTree

const Catalog = preload("res://resources/card_catalog.gd")
const Profile = preload("res://resources/balance/small_number_profile.gd")
const GM = preload("res://autoload/game_manager.gd")
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
	else:
		failed += 1
		push_error(label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var gm := GM.new()
	OS.set_environment("STSL_LEGACY_COMBAT", "1")
	var expected: Dictionary = {}
	for card in Catalog.get_all_cards():
		expected[Catalog.card_key(card)] = Profile.candidate_pair(card, gm)
	OS.set_environment("STSL_LEGACY_COMBAT", "0")
	var cards := Catalog.get_all_cards()
	_check(cards.size() == 216, "catalog coverage")
	for card in cards:
		var key: String = Catalog.card_key(card)
		var pair: Dictionary = expected[key]
		_check(Profile.is_candidate(card), key + " live marker")
		_check(Profile._candidate_signature(card) == Profile._candidate_signature(pair.base), key + " base")
		_check(card.has_explicit_upgrade, key + " fixed upgrade")
		var upgraded: Resource = card.duplicate(true)
		gm.upgrade_card(upgraded)
		if card.card_name == "card.cleopatra.poison_purge.name":
			_check(upgraded.effects[0].target == "ALL" and upgraded.effects[1].value == card.effects[1].value, "poison purge upgrades scope without DOT inflation")
		_check(Profile._candidate_signature(upgraded) == Profile._candidate_signature(pair.upgraded), key + " upgrade")
		_check(Profile.is_upgrade_meaningful(card, upgraded), key + " meaningful upgrade")
		var again: Resource = load("res://resources/cards/card_revision_v3.gd").apply(card)
		_check(Profile._candidate_signature(again) == Profile._candidate_signature(card), key + " idempotent")
	var bm: Node = load("res://autoload/battle_manager.gd").new()
	_check(bm.combat_unit_divisor == 10, "live battle units")
	_check(bm._combat_literal(100) == 10, "charm threshold")
	_check(gm.generate_shop_inventory().heal_amount == 2, "shop healing units")
	_check(preload("res://resources/balance/combat_scale.gd").accumulated(4) == 0, "small repeated bonus can remain zero")
	_check(preload("res://resources/balance/combat_scale.gd").accumulated(50) == 5, "repeated bonus rounds total")
	var ui: Node = load("res://scenes/battle/battle_scene.gd").new()
	for myth in ["greek", "norse", "egyptian", "buddhist", "daoist", "japanese"]:
		var text: String = ui._trf("signature.%s.desc" % myth, ui._signature_desc_args(myth))
		_check(not "%d" in text and not "%s" in text, "signature tooltip " + myth)
	for synergy in ["yi_cleopatra", "joan_yi", "joan_genghis", "joan_cleopatra", "napoleon_cleopatra", "genghis_cleopatra", "napoleon_yi"]:
		var key: String = "synergy.%s.desc" % synergy
		var text: String = ui._trf(key, ui._battle_sig_desc_args(key))
		_check(not "%d" in text and not "%s" in text, "synergy tooltip " + synergy)
	ui.free()
	var dm: Node = load("res://autoload/deck_manager.gd").new()
	for card in cards:
		dm.add_card_to_deck(card)
	var saved: Dictionary = dm.to_dict()
	dm.from_dict(saved)
	_check(dm.get_full_deck().size() == 216, "live deck roundtrip size")
	for i in range(cards.size()):
		_check(Profile._candidate_signature(dm.get_full_deck()[i]) == Profile._candidate_signature(cards[i]), "live deck no double scale %d" % i)
	dm.free()
	_test_save_roundtrip(cards[0])
	await _test_detached_stun()
	_test_repeated_strength()
	_test_small_damage_floor()
	_test_power_cadence()
	_test_percentage_pipeline(cards)
	bm.free()
	gm.free()
	print("LIVE SMALL NUMBERS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _test_repeated_strength() -> void:
	var bm: Node = load("res://autoload/battle_manager.gd").new()
	bm._enemy_status = [{}]
	for amount in [1, 2, 5]:
		var total := 0
		for step in range(1, 21):
			total += bm.gain_authored_enemy_strength(0, amount, str(amount))
			_check(total == int(floor(float(step * amount) / 10.0)), "repeated strength %d step %d" % [amount, step])
	bm.combat_unit_divisor = 1
	_check(bm.gain_authored_enemy_strength(0, 2, "legacy") == 2, "legacy repeated strength unchanged")
	bm.clear()
	_check(bm._enemy_strength_remainders.is_empty(), "repeated strength remainder resets")
	bm.free()

func _test_small_damage_floor() -> void:
	var script = load("res://autoload/battle_manager.gd")
	var ctx = script.DamageContext.new()
	ctx.base = 1
	ctx.mitigation = [0.2]
	_check(script.compute_damage(ctx) == 1, "positive resisted chip damage remains 1")
	ctx.invuln = true
	_check(script.compute_damage(ctx) == 0, "immunity still blocks chip damage")
	ctx.invuln = false
	ctx.mitigation = [0.0]
	_check(script.compute_damage(ctx) == 0, "true zero mitigation remains zero")
	ctx.base = 0
	ctx.mitigation = []
	_check(script.compute_damage(ctx) == 0, "zero base never invents damage")

func _test_save_roundtrip(card: Resource) -> void:
	var sm: Node = root.get_node("SaveManager")
	var tm: Node = root.get_node("TeamManager")
	var dm: Node = root.get_node("DeckManager")
	var gm: Node = root.get_node("GameManager")
	var save_path: String = ProjectSettings.globalize_path(sm.SAVE_PATH)
	if not save_path.get_base_dir().get_file().begins_with("STSL-tutorial-validation-"):
		_check(false, "save integration requires isolated validation directory")
		return
	gm.reset()
	tm.clear()
	dm.clear()
	var hero: Resource = load("res://resources/heroes/hero_registry.gd").make_hero(card.owner_id)
	tm.add_hero(hero)
	tm.take_damage(hero.hero_id, 25)
	var upgraded: Resource = card.duplicate(true)
	gm.upgrade_card(upgraded)
	dm.add_card_to_deck(upgraded)
	sm.save()
	var text: String = FileAccess.get_file_as_string(save_path)
	var data: Dictionary = JSON.parse_string(text)
	_check(data.combat_unit_version == 2, "new save marks combat units")
	_check(sm.load_save() and tm.get_current_hp(hero.hero_id) == 75, "new save reload preserves 75 HP")
	_check(Profile._candidate_signature(dm.get_full_deck()[0]) == Profile._candidate_signature(upgraded), "new save upgraded card preserved")
	data.combat_unit_version = 1
	data.team_manager.heroes[0].max_hp = 1000
	data.team_manager.heroes[0].current_hp = 750
	data.deck_manager.erase("combat_units")
	var old_text := JSON.stringify(data)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(old_text)
	file.close()
	_check(sm.load_save() and tm.get_hero(hero.hero_id).max_hp == 100 and tm.get_current_hp(hero.hero_id) == 75, "legacy save actual load migrates HP once")
	_check(FileAccess.get_file_as_string(save_path) == old_text, "legacy load preserves source file")
	sm.save()
	_check(sm.load_save() and tm.get_current_hp(hero.hero_id) == 75, "migrated resave reload does not divide again")

func _test_percentage_pipeline(cards: Array) -> void:
	var fixture = load("res://tests/test_card_revision_runtime.gd").new()
	var bm = fixture._battle(["musashi"], 1)
	bm._hero_status["musashi"] = {"weak": 1}
	bm._enemy_status[0]["vulnerable"] = 1
	for card in cards:
		if card.card_name != "card.musashi.niten_starter.name":
			continue
		var preview: Dictionary = bm._estimate_card_damage(card, 0)
		var before: int = bm.get_enemy_hp(0)
		bm._apply_card_effects(card, 0)
		_check(before - bm.get_enemy_hp(0) == 10, "weak plus vulnerable rounds only the final hit")
		_check(int(preview.get(0, 0)) == before - bm.get_enemy_hp(0), "percentage preview matches real damage")
		_check(bm._enemy_hp[0] is int, "combat HP remains an integer")
		bm._enemy_hp[0] = before
		bm._register_power("power.echo_next_attack", "musashi", 1)
		bm._apply_card_effects(card, 0)
		_check(before - bm.get_enemy_hp(0) == 20, "echo preserves the same final-only percentage rounding")
		_check(not bm._active_powers.has("power.echo_next_attack:musashi"), "echo is consumed once")
	fixture._free(bm)

func _test_power_cadence() -> void:
	var bm: Node = load("res://autoload/battle_manager.gd").new()
	bm.team_mgr = load("res://autoload/team_manager.gd").new()
	for id in ["napoleon", "cleopatra"]:
		bm.team_mgr.add_hero(load("res://resources/heroes/hero_registry.gd").make_hero(id))
	for type in ["power.poison_per_turn", "power.block_per_turn", "power.heal_team_per_turn"]:
		bm._active_powers.clear()
		bm._hero_block = {"napoleon": 0, "cleopatra": 0}
		bm._enemy_status = [{}]
		bm._enemies = [load("res://resources/enemy_resource.gd").new()]
		bm._enemy_alive = [true]
		bm.team_mgr._hero_hp = {"napoleon": 50, "cleopatra": 50}
		bm._register_power(type, "napoleon", 1, {"upgrade_tick_period": 5, "upgrade_tick_bonus": 1})
		for step in range(1, 11):
			bm._trigger_active_powers("player_turn_start", {"hero_id": "cleopatra"})
			_check(int(bm._active_powers[type + ":napoleon"].params.get("_upgrade_tick_count", 0)) == step - 1, "cadence only advances for owner")
			bm._trigger_active_powers("player_turn_start", {"hero_id": "napoleon"})
			var expected: int = step + int(floor(float(step) / 5.0))
			var actual: int = bm._enemy_status[0].get("poison_dmg", 0) if type == "power.poison_per_turn" else (bm._hero_block["napoleon"] if type == "power.block_per_turn" else bm.team_mgr.get_current_hp("napoleon") - 50)
			_check(actual == expected, "cadence %s step %d" % [type, step])
	bm.team_mgr.free()
	bm.free()

func _test_detached_stun() -> void:
	var bm: Node = load("res://autoload/battle_manager.gd").new()
	bm.team_mgr = load("res://autoload/team_manager.gd").new()
	bm.deck_mgr = load("res://autoload/deck_manager.gd").new()
	bm.turn_interval = 0.0
	bm._test_disable_crit = true
	var hero: Resource = load("res://resources/heroes/hero_registry.gd").make_hero("napoleon")
	bm.team_mgr.add_hero(hero)
	for card in load("res://resources/cards/cards_napoleon.gd").starter_deck():
		bm.deck_mgr.add_card_to_deck(card)
	var enemy: Resource = load("res://resources/enemy_resource.gd").new()
	enemy.max_hp = 100
	enemy.signatures_enabled = false
	var intent: Resource = load("res://resources/intent_resource.gd").new()
	intent.value = 10
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm._hero_status["napoleon"] = {"stun": 1}
	await bm.start_player_turn()
	_check(bm._hero_status["napoleon"].get("stun", 0) == 0, "detached stun expires")
	_check(bm.is_player_turn and bm.get_current_hero_id() == "napoleon", "detached stun advances to next valid input")
	bm.deck_mgr.free()
	bm.team_mgr.free()
	bm.free()
