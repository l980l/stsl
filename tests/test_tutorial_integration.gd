# Run with an isolated user directory; see docs/tutorial-validation.md.
# Uses the real scene, battle queue, card effects, input handlers and scene transitions.
extends SceneTree

var failed: int = 0
var passed: int = 0
var gm: Node
var bm: Node
var dm: Node
var pm: Node
var saved_run: String
var save_path: String
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)

func _wait_for(predicate: Callable, label: String, seconds: float = 12.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000)
	while not predicate.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	var ok: bool = predicate.call()
	_check(ok, label)
	return ok

func _at_selector() -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with("tutorial_select_scene.tscn") \
		and root.get_node("SceneTransition")._overlay.modulate.a < 0.001

func _lesson_ready() -> bool:
	return current_scene != null and current_scene.scene_file_path.ends_with("battle_scene.tscn") \
		and current_scene.get("_tutorial_driver") != null and bm.is_player_turn

func _run() -> void:
	# Never change a developer's existing progress/save files when running this test.
	var progress_path: String = ProjectSettings.globalize_path(root.get_node("ProgressManager").PROGRESS_PATH)
	save_path = ProjectSettings.globalize_path(root.get_node("SaveManager").SAVE_PATH)
	if not progress_path.get_base_dir().get_file().begins_with("STSL-tutorial-validation-") \
		or progress_path.get_base_dir() != save_path.get_base_dir():
		printerr("Use an isolated STSL-tutorial-validation-* user directory (docs/tutorial-validation.md).")
		quit(2)
		return
	gm = root.get_node("GameManager")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
			DirAccess.make_dir_recursive_absolute(capture_dir)
	bm = root.get_node("BattleManager")
	dm = root.get_node("DeckManager")
	pm = root.get_node("ProgressManager")
	var tm := root.get_node("TeamManager")
	var sm := root.get_node("SaveManager")
	var settings := root.get_node("GameSettings")
	Engine.time_scale = 8.0
	gm.reset()
	tm.clear()
	dm.clear()
	tm.add_hero(gm._make_hero_by_id("napoleon"))
	dm.add_card_to_deck(load("res://scenes/tutorial/lessons/lesson_basics.gd").build_deck()[0])
	gm.gold = 321
	sm.save()
	saved_run = FileAccess.get_file_as_string(save_path)
	pm.reset_progress()
	for frame in ["classic", "modern"]:
		settings.card_frame_key = frame
		for lesson in ["basics", "counter", "status"]:
			await _complete_lesson(lesson, frame)
			if failed > 0:
				break
		if failed > 0:
			break
	if failed == 0:
		await _test_exit()
		await _test_loss()
	_check(FileAccess.get_file_as_string(save_path) == saved_run, "tutorial leaves saved run unchanged")
	_check(sm.load_save(), "saved run can be resumed after tutorial")
	_check(gm.gold == 321 and gm.tutorial_lesson_id == "", "resume restores original run without tutorial state")
	pm.load_progress()
	for lesson in ["basics", "counter", "status"]:
		_check(pm.is_tutorial_completed(lesson), "completion persists: " + lesson)
	print("=== Tutorial integration: %d passed, %d failed ===" % [passed, failed])
	bm.is_battle_active = false
	if current_scene:
		current_scene.queue_free()
	await process_frame
	# Give the audio mixer time to release active MP3 playback before engine shutdown.
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		elif child is Timer:
			child.stop()
	await create_timer(0.1, true, false, true).timeout
	await process_frame
	quit(1 if failed else 0)

func _click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = position
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)

func _complete_lesson(lesson: String, frame: String) -> void:
	print("[Tutorial integration] " + lesson + " / " + frame)
	gm.start_tutorial(lesson)
	if not await _wait_for(_lesson_ready, "lesson starts: " + lesson):
		return
	var scene = current_scene
	var driver = scene._tutorial_driver
	_check(driver._exit_button.tooltip_text != "tutorial.exit", "exit button translation imported")
	_check(driver._label.text != driver.current_step().get("text"), "lesson instruction translation imported")
	if capture_dir != "" and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		_check(screenshot.save_png(capture_dir.path_join(lesson + "-" + frame + ".png")) == OK, "capture tutorial")
	root.get_node("SaveManager").save()
	_check(FileAccess.get_file_as_string(save_path) == saved_run, "save is ignored during practice")
	var seen: Array = [driver.current_step().get("text", "")]
	driver.step_changed.connect(func(): seen.append(driver.current_step().get("text", "")))
	var first_hand: Array = dm.get_hand(bm.get_current_hero_id())
	_check(not first_hand.is_empty(), "opening hand exists")
	if not first_hand.is_empty():
		_check(not bm.play_card(first_hand[0], 0), "intro rejects card use")
	var turn: int = bm.turn_count
	scene._on_end_turn_pressed()
	_check(bm.turn_count == turn and bm.is_player_turn, "intro rejects premature end turn")
	var deadline := Time.get_ticks_msec() + 20000
	var actions: int = 0
	while is_instance_valid(driver) and not driver.is_finished() and Time.get_ticks_msec() < deadline and actions < 40:
		await process_frame
		if not bm.is_player_turn or bm.tutorial_effect_pending:
			continue
		var step: Dictionary = driver.current_step()
		if step.get("complete_event") == "screen_clicked":
			_click_at(root.get_visible_rect().size * 0.5)
			_check(driver.current_step() != step, "viewport click advances instruction")
			if driver.current_step() == step:
				print("Input diagnostic: viewport=%s catcher=%s overlay=%s" % [root.get_visible_rect(), driver._click_catcher.get_global_rect(), root.get_node("SceneTransition")._overlay.modulate.a])
				break
			actions += 1
			continue
		var chosen: Resource = null
		for card in dm.get_hand(bm.get_current_hero_id()):
			if card.card_name in driver.current_allowed_cards() and dm.can_play(card):
				chosen = card
				break
		if chosen:
			scene._on_card_drag_started(chosen, Vector2(960, 700))
			_check(scene._drag_card == chosen, "allowed card starts drag")
			if scene._drag_card == null:
				break
			var target: Vector2 = Vector2(960, 600)
			if scene._card_target_type(chosen) == "enemy":
				target = scene._enemy_nodes[0]["panel"].get_global_rect().get_center()
			scene._finish_drag(target)
			_check(not dm.get_hand(chosen.owner_id).has(chosen), "played card leaves hand")
			if bm.tutorial_effect_pending:
				for other in dm.get_hand(chosen.owner_id):
					_check(not bm.play_card(other, 0), "additional cards blocked during effects")
				bm.end_player_turn()
				_check(bm.is_player_turn, "end turn blocked during card effects")
			actions += 1
		elif step.get("end_turn", "free") != "lock":
			scene._on_end_turn_pressed()
			actions += 1
		else:
			_check(false, "no legal action at " + str(step))
			break
	_check(is_instance_valid(driver) and driver.is_finished(), "lesson completes: " + lesson + " seen=" + str(seen) \
		+ " actions=%d hp=%d status=%s actor=%s pending=%s" % [actions, bm.get_enemy_hp(0), bm.get_enemy_status(0), bm.get_current_actor_id(), bm.tutorial_effect_pending])
	for step in load("res://scenes/tutorial/lessons/lesson_%s.gd" % lesson).steps():
		_check(step["text"] in seen, "visited " + step["text"])
	if await _wait_for(_at_selector, "returns to lesson selector"):
		_check(pm.is_tutorial_completed(lesson), "records completed lesson")
		_check(not bm.tutorial_active and not bm.tutorial_force_crit, "tutorial flags cleared")

func _test_exit() -> void:
	pm.tutorial_completed.erase("counter")
	gm.start_tutorial("counter")
	if not await _wait_for(_lesson_ready, "exit test starts"):
		return
	var button: Button = current_scene._tutorial_driver._exit_button
	var driver = current_scene._tutorial_driver
	var original_locale := TranslationServer.get_locale()
	for locale in ["ko", "en", "fr", "it", "es", "ja", "el", "zh", "zh_TW", "ru", "pt", "pl", "de"]:
		TranslationServer.set_locale(locale)
		driver._refresh_localized_text()
		await process_frame
		var rect := button.get_global_rect()
		var codex_rect: Rect2 = current_scene.get_node("CodexButton/Btn").get_global_rect()
		_check(rect.size == codex_rect.size and rect.size == Vector2(40, 40), "exit matches codex size: " + locale)
		_check(is_equal_approx(rect.end.x + 10.0, codex_rect.position.x) \
			and is_equal_approx(rect.position.y, codex_rect.position.y), "exit sits left of codex: " + locale)
		_check(button.icon != null and button.text.is_empty() and button.tooltip_text == tr("tutorial.exit"), \
			"exit icon and translated tooltip: " + locale)
		for control in [driver._progress_label, current_scene.get_node("SettingsButton/Btn"), current_scene.get_node("CodexButton/Btn")]:
			_check(not rect.intersects(control.get_global_rect()), "exit separate from " + control.name + ": " + locale)
	TranslationServer.set_locale(original_locale)
	driver._refresh_localized_text()
	_click_at(button.get_global_transform_with_canvas() * (button.size * 0.5))
	await _wait_for(_at_selector, "exit returns to selector")
	_check(not pm.is_tutorial_completed("counter"), "exit does not award completion")
	_check(gm.tutorial_lesson_id == "" and not bm.tutorial_active, "exit clears tutorial state")
	await _complete_lesson("counter", "replay after exit")

func _test_loss() -> void:
	pm.tutorial_completed.erase("status")
	gm.start_tutorial("status")
	if not await _wait_for(_lesson_ready, "loss test starts"):
		return
	root.get_node("TeamManager").take_damage("cleopatra", 99999)
	bm._check_lose_condition()
	await _wait_for(_at_selector, "loss returns to selector")
	_check(is_equal_approx(Engine.time_scale, 8.0), "leaving death camera restores game speed")
	_check(not pm.is_tutorial_completed("status"), "loss does not award completion")
	await _complete_lesson("status", "replay after loss")
