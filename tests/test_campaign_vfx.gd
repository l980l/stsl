extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		printerr("Use a fresh isolated campaign-bot project")
		quit(2)
		return
	root.get_node("AudioManager").set_bus_volume("master", 0.0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), true)
	var gm = root.get_node("GameManager")
	var tm = root.get_node("TeamManager")
	var dm = root.get_node("DeckManager")
	var bm = root.get_node("BattleManager")
	gm.reset()
	tm.clear()
	dm.clear()
	tm.add_hero(gm._make_hero_by_id("napoleon"))
	var enemy = load("res://resources/enemy_resource.gd").new()
	enemy.max_hp = 5000
	enemy.speed = 1
	enemy.signatures_enabled = false
	var intent = load("res://resources/intent_resource.gd").new()
	intent.action_type = 3
	enemy.intent_pattern = [intent]
	gm.pending_enemies = [enemy]
	change_scene_to_file("res://scenes/battle/battle_scene.tscn")
	await process_frame
	await process_frame
	var fallback = current_scene._enemy_char_nodes[0]
	var ok: bool = fallback is Node2D
	var power_item = current_scene._make_power_item("power.every_nth_attack_bonus", 160, "napoleon", {"bonus_value": 4})
	current_scene.add_child(power_item)
	var expected: String = tr("power.every_nth_attack_bonus.label") % [4, 160]
	var matched := false
	for child in power_item.get_children():
		if child is Label and child.text == expected:
			matched = true
	ok = ok and matched
	# Scene replacement can free emitters before their delayed stop callbacks.
	var phase = load("res://scenes/vfx/monster_phase_changed_gpu.gd").new()
	current_scene.add_child(phase)
	phase._spawn_inward_motes()
	phase._spawn_embers()
	var acid = load("res://scenes/vfx/acid_spray_gpu.gd").new()
	current_scene.add_child(acid)
	acid._spawn_drool()
	acid._spawn_pool()
	acid._spawn_burns()
	phase.queue_free()
	acid.queue_free()
	await create_timer(4.0).timeout
	if ok:
		current_scene._play_hit_flash(fallback)
		current_scene._foot_pos(fallback)
	var morale = load("res://scenes/vfx/morale_boost.gd").new()
	current_scene.add_child(morale)
	morale._target = Vector2(1900, 900)
	# Exercise zero/subpixel unfurl and visible flag geometry at screen edges.
	for age in [0.0, 0.0001, 0.001, 0.15001, 0.151, 0.16, 0.2, 0.7]:
		morale._age = age
		morale._ground_layer.queue_redraw()
		morale._glow_layer.queue_redraw()
		await process_frame
		await process_frame
	var summon = load("res://scenes/vfx/summon_burst.gd").new()
	current_scene.add_child(summon)
	summon._caster = Vector2(1900, 900)
	summon.set_spawn_positions([Vector2(1800, 900)])
	for age in [0.0, 0.5, 0.7, 0.76]:
		summon._ring_age = age
		summon._pillar_age = 0.0
		summon._glow_layer.queue_redraw()
		await process_frame
		await process_frame
	var taiji = load("res://scenes/vfx/sig_yin_yang.gd").new()
	current_scene.add_child(taiji)
	taiji._target = Vector2(1900, 900)
	for age in [0.01, 0.18, 1.34, 1.365, 1.368]:
		taiji._age = age
		taiji._glow_layer.queue_redraw()
		await process_frame
		await process_frame
	var karma = load("res://scenes/vfx/sig_karma.gd").new()
	current_scene.add_child(karma)
	karma._caster = Vector2(1900, 900)
	for age in [0.0001, 0.01, 0.1, 0.5]:
		karma._age = age
		karma._glow_layer.queue_redraw()
		await process_frame
		await process_frame
	var particle_helpers = load("res://scenes/vfx/gpu_particle_helpers.gd")
	particle_helpers.circle_tex()
	ok = ok and particle_helpers._circle_tex != null
	particle_helpers.release_cached_textures()
	ok = ok and particle_helpers._circle_tex == null
	print("Campaign VFX fallback: ", "PASS" if ok else "FAIL (character fallback is not Node2D)")
	bm.is_battle_active = false
	current_scene.queue_free()
	await process_frame
	await process_frame
	particle_helpers.release_cached_textures()
	var classic = load("res://scenes/card/card_scene.gd")
	classic._art_cache.clear()
	classic._frame_cache.clear()
	load("res://scenes/card/card_scene_v2.gd").release_cached_textures()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	root.get_node("SacredTheme")._cursor_textures_cache.clear()
	root.get_node("SacredTheme")._cursor_hotspots_cache.clear()
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		elif child is Timer:
			child.stop()
	await create_timer(0.1, true, false, true).timeout
	quit(0 if ok else 1)
