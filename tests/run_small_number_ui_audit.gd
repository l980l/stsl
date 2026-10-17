extends SceneTree

# Text/data contract audit. Rendered layout is sampled separately, not inferred
# from a string match. All artifacts stay inside the isolated test user://.
const Catalog = preload("res://resources/card_catalog.gd")
const GM = preload("res://autoload/game_manager.gd")
const Classic = preload("res://scenes/card/card_scene.gd")
const Modern = preload("res://scenes/card/card_scene_v2.gd")
const Relics = preload("res://resources/relics/relics.gd")
const Effect = preload("res://resources/effect_resource.gd")
const Monsters = preload("res://resources/monster_catalog.gd")
const LOCALES = ["ko", "en", "fr", "it", "es", "ja", "el", "zh", "zh_TW", "ru", "pt", "pl", "de"]
var passed := 0
var failed := 0
var issues: Array = []
var rows: Array = []
var intent_states := 0
var captures: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String, text: String = "") -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		issues.append({"case": label, "text": text})
		if failed <= 30:
			printerr("FAIL: ", label, " => ", text)

func _text_ok(text: String, label: String) -> void:
	_check(not text.is_empty() and not text.contains("{") and not text.contains("%d") and not text.contains("%s") and not text.contains("%%") and not text.begins_with("effect.") and not text.begins_with("power.") and not text.begins_with("enemy."), label, text)

func _flatten_intents(enemy: Resource) -> Array:
	var pending: Array = enemy.intent_pattern.duplicate()
	for phase in enemy.phase_patterns:
		pending.append_array(phase)
	if enemy.death_trigger != null:
		pending.append(enemy.death_trigger)
	if not enemy.card_count_trigger.is_empty():
		pending.append(enemy.card_count_trigger.intent)
	var out: Array = []
	var seen: Dictionary = {}
	while not pending.is_empty():
		var intent: Resource = pending.pop_back()
		if intent == null or seen.has(intent.get_instance_id()):
			continue
		seen[intent.get_instance_id()] = true
		out.append(intent)
		pending.append_array(intent.payoff_intents)
	return out

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var gm := GM.new()
	var classic := Classic.new()
	var modern := Modern.new()
	var battle = load("res://scenes/battle/battle_scene.gd").new()
	var tutorial = load("res://scenes/tutorial/tutorial_driver.gd").new()
	tutorial._steps = load("res://scenes/tutorial/lessons/lesson_status.gd").steps()
	tutorial._idx = 4
	var all_cards: Array = []
	for card in Catalog.get_all_cards():
		all_cards.append(card)
		var upgrade: Resource = card.duplicate(true)
		gm.upgrade_card(upgrade)
		all_cards.append(upgrade)
	var relics: Array = Relics.build_pool()
	var monsters: Array = Monsters.get_all_monsters()
	var bm: Node = root.get_node("BattleManager")
	var codex = load("res://scenes/ui/codex_scene.gd").new()
	root.add_child(codex)
	codex.set_process(false)
	# Discovery is local synthetic state, not a write to real player progress.
	root.get_node("ProgressManager").seen_cards = all_cards.map(func(card): return Catalog.card_key(card))
	root.get_node("ProgressManager").seen_relics = relics.map(func(relic): return relic.relic_name)
	for locale in LOCALES:
		TranslationServer.set_locale(locale)
		var lesson_text: String = tutorial.localized_step_text()
		_text_ok(lesson_text, locale + "/tutorial-poison-refresh")
		_check(lesson_text.contains("1") and lesson_text.contains("2") and not lesson_text.contains("10") and not lesson_text.contains("20"), locale + "/tutorial-actual-poison", lesson_text)
		for card in all_cards:
			var label: String = "%s/%s/+%d" % [locale, card.card_name, card.upgrade_level]
			classic._card = card
			modern._card_res = card
			classic._mode = Classic.Mode.REWARD
			modern._mode = Modern.Mode.REWARD
			var old_text: String = classic._build_desc()
			var new_text: String = modern._build_desc()
			_text_ok(old_text, label + "/classic")
			_text_ok(new_text, label + "/modern")
			_check(old_text == new_text, label + "/frame-parity")
			for effect in card.effects:
				if effect.effect_type in [Effect.EffectType.DAMAGE, Effect.EffectType.BLOCK, Effect.EffectType.HEAL, Effect.EffectType.HEAL_ALL, Effect.EffectType.CHARM, Effect.EffectType.SACRIFICE_HP] and effect.rule_id == "" and effect.value > 0:
					_check(effect.display_text().contains(str(effect.value)), label + "/effect-value", effect.display_text())
			rows.append({"locale": locale, "card": card.card_name, "grade": card.upgrade_level, "text": old_text})
		for relic in relics:
			_text_ok(relic.format_description(tr(relic.display_description_key())), locale + "/" + relic.relic_name)
		for myth in ["greek", "norse", "egyptian", "buddhist", "daoist", "japanese"]:
			_text_ok(battle._trf("signature.%s.desc" % myth, battle._signature_desc_args(myth)), locale + "/signature/" + myth)
		for key in ["battle.signature.hubris.desc", "battle.signature.ragnarok.desc", "battle.signature.egyptian_curse.desc", "battle.signature.karma.desc", "battle.signature.yin_yang.desc", "battle.signature.kekkai.desc", "synergy.napoleon_yi.desc", "synergy.yi_cleopatra.desc", "synergy.joan_yi.desc", "synergy.joan_genghis.desc", "synergy.joan_cleopatra.desc", "synergy.napoleon_cleopatra.desc", "synergy.genghis_cleopatra.desc"]:
			_text_ok(battle._trf(key, battle._battle_sig_desc_args(key)), locale + "/" + key)
		for key in ["weak", "vulnerable", "strength", "counter_pending", "poison_dmg", "charm_resistance"]:
			var badge: Control = battle._make_status_label(key, 3, {"poison_dur": 2})
			_text_ok(badge.get_meta("_sacred_tip", ""), locale + "/status/" + key)
			badge.free()
		for enemy in monsters:
			bm._enemies = [enemy]
			bm._enemy_status = [{}]
			for intent in _flatten_intents(enemy):
				intent_states += 1
				_text_ok(battle._format_intent_label(0, intent), locale + "/intent-label/" + enemy.enemy_name)
				_text_ok(battle._format_intent_tooltip(0, intent), locale + "/intent-tip/" + enemy.enemy_name)
			if not enemy.card_count_trigger.is_empty():
				_text_ok(battle._counter_tooltip_text(enemy.card_count_trigger), locale + "/counter/" + enemy.enemy_name)
		codex._tab = "card"
		for card in all_cards:
			codex._search = card.effects[0].display_text().to_lower()
			_check(codex._passes_card(card), locale + "/codex-card-search/" + card.card_name)
		codex._tab = "relic"
		for relic in relics:
			codex._r_search = relic.format_description(tr(relic.display_description_key())).to_lower()
			_check(codex._passes_relic(relic), locale + "/codex-relic-search/" + relic.relic_name)
	TranslationServer.set_locale("ko")
	codex.queue_free()
	await process_frame
	if DisplayServer.get_name() != "headless":
		await _capture_samples(all_cards, battle)
	var sources: Dictionary = {}
	for path in ["res://autoload/battle_manager.gd", "res://autoload/debug_manager.gd", "res://resources/effect_resource.gd", "res://resources/balance/small_number_profile.gd", "res://resources/translations/strings_card.csv", "res://resources/translations/strings_status.csv", "res://resources/translations/strings_synergy.csv", "res://resources/translations/strings_tutorial.csv", "res://resources/translations/strings_relic.csv", "res://scenes/battle/battle_scene.gd", "res://scenes/card/card_scene.gd", "res://scenes/card/card_scene_v2.gd", "res://scenes/ui/codex_scene.gd", "res://scenes/tutorial/tutorial_driver.gd", "res://scenes/tutorial/lessons/lesson_status.gd"]:
		sources[path] = FileAccess.get_sha256(path)
	var file := FileAccess.open("user://small-number-ui-audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema": 1, "unit": "localized card-grade description, both frames", "unique_cards": all_cards.size() / 2, "card_grade_locale_states": rows.size(), "frame_descriptions": rows.size() * 2, "unique_monsters": monsters.size(), "intent_locale_states": intent_states, "relics": relics.size(), "passed": passed, "failed": failed, "issues": issues, "rows": rows, "sources": sources, "captures": captures, "boundary": "text/data and formatter contracts; rendered samples are real card/badge components, not whole-game pointer/layout/human comprehension coverage"}, "\t"))
	file.close()
	classic.free()
	modern.free()
	battle.free()
	tutorial.free()
	await process_frame
	Classic._art_cache.clear()
	Classic._frame_cache.clear()
	Modern.release_cached_textures()
	preload("res://scenes/vfx/gpu_particle_helpers.gd").release_cached_textures()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var theme := root.get_node_or_null("SacredTheme")
	if theme != null:
		theme._cursor_textures_cache.clear()
		theme._cursor_hotspots_cache.clear()
	await process_frame
	await create_timer(0.1, true, false, true).timeout
	gm.free()
	print("UI AUDIT: %d passed, %d failed; report: %s" % [passed, failed, ProjectSettings.globalize_path("user://small-number-ui-audit.json")])
	quit(1 if failed else 0)

func _capture_samples(cards: Array, battle: Node) -> void:
	Engine.max_fps = 60
	var examples: Array = cards.filter(func(card): return card.upgrade_level == 1 and card.card_name in ["card.cleopatra.venom_needle.name", "card.cleopatra.poison_purge.name", "card.musashi.whirlwind_cut.name", "card.yi_sun_sin.decisive_strike.name"])
	if OS.get_environment("STSL_UI_SYNERGY_SAMPLES") == "1":
		examples = cards.filter(func(card): return card.upgrade_level == 1 and card.card_name in ["card.cleopatra.charming_perfume.name", "card.genghis_khan.war_tribute.name", "card.yi_sun_sin.naval_training.name", "card.cleopatra.poison_party.name"])
	for requested in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = requested
		root.content_scale_size = requested
		for locale in ["ko", "en"]:
			TranslationServer.set_locale(locale)
			for style in ["classic", "modern"]:
				root.get_node("GameSettings").card_frame_key = style
				var group := Control.new()
				root.add_child(group)
				var bg := ColorRect.new()
				bg.color = Color("18222b")
				bg.size = Vector2(requested)
				group.add_child(bg)
				var heading := Label.new()
				heading.text = "LIVE NUMBERS / %s / %s / +1" % [style, locale]
				heading.position = Vector2(24, 20)
				heading.add_theme_font_size_override("font_size", 24)
				group.add_child(heading)
				var measured: Array = []
				for index in examples.size():
					var node: Control = load("res://scenes/card/card_scene%s.tscn" % ("_v2" if style == "modern" else "")).instantiate()
					group.add_child(node)
					node.setup(examples[index], 1)
					node.position = Vector2(30 + index * 300, 100)
					node.scale = Vector2.ONE * (2.0 / 1.4 if style == "modern" else 2.0)
					var label: Label = node.get_node("DescLabel" if style == "modern" else "Container/DescLabel")
					measured.append({"card": examples[index].card_name, "text": label.text, "rect_canvas": [label.get_global_rect().position.x, label.get_global_rect().position.y, label.get_global_rect().size.x, label.get_global_rect().size.y]})
				var badges := HBoxContainer.new()
				badges.position = Vector2(30, 550)
				badges.add_theme_constant_override("separation", 24)
				group.add_child(badges)
				badges.add_child(battle._make_status_label("poison_dmg", 3, {"poison_dur": 2}))
				badges.add_child(battle._make_power_item("power.block_per_turn", 1, "", {"upgrade_tick_period": 5, "upgrade_tick_bonus": 1, "_upgrade_tick_count": 3}))
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var screenshot := root.get_texture().get_image()
				var path := "user://ui-numbers-%s-%s-%d.png" % [style, locale, requested.x]
				_check(screenshot.save_png(path) == OK, "save rendered number sample")
				captures.append({"style": style, "locale": locale, "requested": [requested.x, requested.y], "viewport_canvas": [root.get_visible_rect().size.x, root.get_visible_rect().size.y], "image_px": [screenshot.get_width(), screenshot.get_height()], "screenshot": ProjectSettings.globalize_path(path), "descriptions": measured})
				group.queue_free()
				await process_frame
