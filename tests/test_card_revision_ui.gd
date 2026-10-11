extends SceneTree

var passed := 0
var failed := 0
var bm
var dm
var tm
var gm

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)

func _run() -> void:
	var sm = root.get_node("SaveManager")
	if not ProjectSettings.globalize_path(sm.SAVE_PATH).get_base_dir().get_file().begins_with("STSL-tutorial-validation-"):
		printerr("Use an isolated STSL-tutorial-validation-* project.")
		quit(2)
		return
	bm = root.get_node("BattleManager")
	dm = root.get_node("DeckManager")
	tm = root.get_node("TeamManager")
	gm = root.get_node("GameManager")
	gm.reset()
	tm.clear()
	dm.clear()
	for id in ["musashi", "yi_sun_sin", "napoleon"]:
		tm.add_hero(gm._make_hero_by_id(id))
		for card in load("res://resources/card_catalog.gd")._HERO_CARDS[id].starter_deck():
			dm.add_card_to_deck(card)
	var enemy = load("res://resources/enemy_resource.gd").new()
	enemy.max_hp = 5000
	enemy.speed = 1
	enemy.signatures_enabled = false
	enemy.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	var intent = load("res://resources/intent_resource.gd").new()
	intent.action_type = 3
	enemy.intent_pattern = [intent]
	gm.pending_enemies = [enemy]
	Engine.time_scale = 8.0
	change_scene_to_file("res://scenes/battle/battle_scene.tscn")
	var deadline := Time.get_ticks_msec() + 15000
	while not bm.is_player_turn and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bm.is_player_turn, "real battle starts an owner turn")
	var scene = current_scene
	var cards: Dictionary = {}
	for card in load("res://resources/card_catalog.gd").get_all_cards():
		cards[card.card_name] = card
	for frame in ["classic", "modern"]:
		root.get_node("GameSettings").card_frame_key = frame
		bm._current_actor_id = "hero:musashi"
		var meditation = cards["card.musashi.meditation.name"].duplicate(true)
		var sword = cards["card.musashi.void_sword.name"].duplicate(true)
		dm._heroes["musashi"]["hand"] = [meditation, sword]
		dm.set_energy_h("musashi", 3)
		scene._refresh_hand()
		await process_frame
		bm.turn_interval = 0.0
		_check(bm.play_card(meditation, -1), frame + " meditation playable")
		while not bm.is_discard_pick_optional():
			await process_frame
		_check(scene._card_pick_in_progress and scene._pick_owner_id == "musashi", frame + " optional own-hand selector opens")
		_check(scene._pick_overlay != null, frame + " skip overlay present")
		scene._on_optional_pick_skipped()
		_check(dm.get_hand("musashi").has(sword) and bm._pending_discard_pick.is_empty(), frame + " actual skip handler preserves sword")
		dm.reserve_cost_reduction("musashi", 1, 1, true)
		scene._refresh_hand()
		await process_frame
		var button = scene._card_buttons[0]
		if frame == "classic":
			_check(button.get_node("Container/CostLabel").text == "0", "classic displays effective discounted cost")
		else:
			_check(button.get_node("CostLabel").text == "0", "modern displays effective discounted cost")
	_check(scene._card_target_type(cards["card.yi_sun_sin.bloody_battle.name"]) == "enemy_ally", "bloodbattle requests enemy then ally")
	_check(scene._card_target_type(cards["card.joan_of_arc.shield_prayer.name"]) == "ally", "prayer targets living ally")
	_check(scene._card_target_type(cards["card.genghis_khan.horde_volley.name"]) == "none", "area volley does not require a single target")
	_check(scene._is_counter_card(cards["card.counter.name"]), "counter retains charge highlight classification")
	scene._show_enemy_ally_target_dialog(cards["card.yi_sun_sin.bloody_battle.name"], 0)
	await process_frame
	var found := false
	for child in scene.get_children():
		if child is ConfirmationDialog:
			found = true
			child.canceled.emit()
	_check(found, "actual dual-target dialog opens and cancels")
	bm.is_battle_active = false
	current_scene.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		elif child is Timer:
			child.stop()
	await create_timer(0.1, true, false, true).timeout
	await process_frame
	print("Card revision UI: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
