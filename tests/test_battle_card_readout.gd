extends SceneTree

const Readout = preload("res://scenes/battle/battle_card_readout.gd")
const Card = preload("res://resources/card_resource.gd")
const Effect = preload("res://resources/effect_resource.gd")
var passed := 0
var failed := 0
var bm: Node
var dm: Node
var captures: Array = []

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + label)

func _card(kind: int, rule: String = "", params: Dictionary = {}) -> Resource:
	var card := Card.new()
	card.owner_id = "musashi"
	card.card_name = "card.musashi.void_sword.name"
	var effect := Effect.new()
	effect.effect_type = kind
	effect.value = 7
	effect.rule_id = rule
	effect.rule_params = params
	card.effects = [effect]
	return card

func _text(card: Resource, target: int = 0) -> String:
	return "\n".join(Readout.describe(card, bm, dm, target).lines)

func _run() -> void:
	var sm := root.get_node("SaveManager")
	if not ProjectSettings.globalize_path(sm.SAVE_PATH).get_base_dir().get_file().begins_with("STSL-tutorial-validation-"):
		printerr("Use tools/run_live_balance_checks.sh for isolated storage.")
		quit(2)
		return
	AudioServer.set_bus_mute(0, true)
	bm = root.get_node("BattleManager")
	dm = root.get_node("DeckManager")
	var gm := root.get_node("GameManager")
	var tm := root.get_node("TeamManager")
	gm.reset()
	tm.clear()
	dm.clear()
	tm.add_hero(gm._make_hero_by_id("musashi"))
	for card in load("res://resources/cards/cards_musashi.gd").starter_deck():
		dm.add_card_to_deck(card)
	var enemy = load("res://resources/enemy_resource.gd").new()
	enemy.max_hp = 1000
	enemy.speed = 1
	enemy.signatures_enabled = false
	enemy.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	var intent = load("res://resources/intent_resource.gd").new()
	intent.action_type = 3
	enemy.intent_pattern = [intent]
	gm.pending_enemies = [enemy]
	Engine.time_scale = 8
	change_scene_to_file("res://scenes/battle/battle_scene.tscn")
	var deadline := Time.get_ticks_msec() + 15000
	while not bm.is_player_turn and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bm.is_player_turn, "real battle reaches player input")
	if not bm.is_player_turn:
		quit(1)
		return
	var scene = current_scene
	var attack := _card(Effect.EffectType.DAMAGE)
	attack.cost = 2
	attack.effects[0].hit_count = 3
	dm._heroes.musashi.hand = [attack]
	dm.set_energy_h("musashi", 1)
	TranslationServer.set_locale("en")
	_check(_text(attack).contains("Not enough energy"), "insufficient energy is explicit")
	dm.reserve_cost_reduction("musashi", 1, 1, true)
	var snapshot := JSON.stringify([dm._heroes, bm._hero_status, bm._enemy_status, bm._hero_block])
	seed(7391)
	var expected_random := randi()
	seed(7391)
	var data := Readout.describe(attack, bm, dm, 0)
	_check(data.cost == 1 and data.energy == 1, "uses actual discounted cost without consuming it")
	_check("\n".join(data.lines).contains("7 × 3 hits = 21"), "first-effect hit sum is explicit")
	_check(_text(attack).contains("not HP loss"), "reference is not presented as HP loss")
	_check(_text(attack, -1).contains("Select an enemy") and not _text(attack, -1).contains("= 21"), "no target means no target-specific damage")
	_check(JSON.stringify([dm._heroes, bm._hero_status, bm._enemy_status, bm._hero_block]) == snapshot, "preview does not mutate hand energy resources or statuses")
	_check(randi() == expected_random, "preview does not consume global RNG")
	attack.effects[0].condition = "hand_size_0"
	_check(_text(attack).contains("gate: met"), "last-card gate accounts for played-card removal")
	dm._heroes.musashi.hand = [attack, attack.duplicate(true)]
	_check(_text(attack).contains("gate: not met") and not _text(attack).contains("= 21"), "unmet gate does not show damage")
	attack.effects[0].condition = "future_unknown"
	_check(_text(attack).contains("resolved during play") and not _text(attack).contains("= 21"), "unknown condition is not asserted")
	attack.effects[0].condition = ""
	var block := _card(Effect.EffectType.BLOCK)
	block.effects[0].target = "SELF"
	_check(_text(block).contains("gain 7 Block") and _text(block).contains("expires"), "plain Block includes lifetime reminder")
	bm._hero_block.musashi = 4
	var consume_block := _card(Effect.EffectType.DAMAGE, "consume_own_block", {"consume_cap": 6, "multiplier": 1})
	_check(_text(consume_block).contains("Block may spend up to 4"), "Block spending is capped by available amount")
	bm._hero_status["musashi"] = {}
	bm._hero_status.musashi["tokens"] = 8
	var tokens := _card(Effect.EffectType.DAMAGE, "consume_own_tokens", {"consume_cap": 3})
	_check(_text(tokens).contains("Soldier may spend up to 3"), "token spending is capped by rule limit")
	bm._hero_status.musashi["morale"] = 1
	var morale := _card(Effect.EffectType.DAMAGE, "morale_spend_damage", {"consume": 2})
	_check(_text(morale).contains("may spend up to 0"), "insufficient morale does not pretend it can be spent")
	bm._hero_status.musashi["sacrifice_bank"] = 9
	var sacrifice := _card(Effect.EffectType.DAMAGE, "sacrifice_bank_payoff", {"consume_cap": 5})
	_check(_text(sacrifice).contains("Sacrifice Bank may spend up to 5"), "sacrifice bank uses real current amount and cap")
	bm._enemy_status[0]["charm"] = 2
	var charm := _card(Effect.EffectType.DAMAGE, "consume_charm_damage", {"consume_cap": 4})
	_check(_text(charm).contains("may spend up to 2") and not _text(charm).contains("reference damage"), "conditional charm follow-up has no invented damage total")
	_check(not _text(charm, -1).contains("may spend up to"), "no target means no target charm consumption")
	var second: Resource = block.effects[0].duplicate(true)
	attack.effects.append(second)
	_check(not _text(attack).contains("gain 7 Block"), "later effect is not projected from stale current state")
	# Freeze a small layout matrix before captures: 2 frames × 2 languages ×
	# 2 requested window sizes; dense gated attack and resource-spend state.
	# These are real scene / handler fixtures, not human or pointer E2E tests.
	attack.effects.resize(1)
	attack.effects[0].condition = "hand_size_0"
	dm._heroes.musashi.hand = [attack, block, tokens, sacrifice, charm]
	dm.set_energy_h("musashi", 3)
	for frame in ["classic", "modern"]:
		root.get_node("GameSettings").card_frame_key = frame
		scene._refresh_hand(true)
		await process_frame
		for locale in ["ko", "en"]:
			TranslationServer.set_locale(locale)
			for window_size in [Vector2i(1920, 1080), Vector2i(1280, 720)]:
				root.size = window_size
				for variant in ["gate", "consume"]:
					var card: Resource = attack if variant == "gate" else charm
					scene._on_card_hovered(card, scene._card_buttons[0 if variant == "gate" else 4])
					scene._show_card_readout(card, 0)
					await process_frame
					await process_frame
					var panel: Control = scene._card_readout
					var body: Label = scene._card_readout_body
					var rect: Rect2 = panel.get_global_rect()
					_check(panel.visible and panel.get_parent() == scene._ui_layer, "readout is camera-independent " + frame + locale)
					_check(panel.mouse_filter == Control.MOUSE_FILTER_IGNORE and body.mouse_filter == Control.MOUSE_FILTER_IGNORE, "readout cannot steal target input")
					_check(Rect2(Vector2.ZERO, Vector2(1920, 1080)).encloses(rect), "panel stays inside design viewport")
					_check(rect.end.y < 830, "panel stays above hand/power HUD")
					_check(body.get_visible_line_count() == body.get_line_count(), "body has no truncated lines")
					_check(not body.text.contains("battle.readout."), "localized readout has no missing keys")
					var id := "%s-%s-%dx%d-%s" % [frame, locale, window_size.x, window_size.y, variant]
					var capture := {"id": id, "requested_width": window_size.x, "requested_height": window_size.y, "language": locale, "text": body.text, "panel_canvas_rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y], "body_lines": body.get_line_count(), "body_visible_lines": body.get_visible_line_count(), "driver": "real-scene handler fixture"}
					if DisplayServer.get_name() != "headless":
						await RenderingServer.frame_post_draw
						var image := root.get_texture().get_image()
						capture["width"] = image.get_width()
						capture["height"] = image.get_height()
						capture["screenshot"] = id + ".png"
						_check(image.save_png(_output().path_join(capture.screenshot)) == OK, "save actual rendered capture")
					captures.append(capture)
					scene._on_card_unhovered(card)
					_check(not panel.visible, "unhover clears readout")
	# Actual drag handlers update target and reset on cancellation.
	scene._start_drag(charm)
	scene._set_drag_card_target(0)
	_check(scene._readout_target == 0 and scene._card_readout.visible, "drag target updates readout")
	scene._cleanup_drag()
	_check(not scene._card_readout.visible and scene._readout_card == null, "cancel clears readout and target")
	scene._show_card_readout(attack)
	bm.is_player_turn = false
	await process_frame
	await process_frame  # scene._process runs after process_frame emission
	_check(not scene._card_readout.visible, "enemy turn clears readout")
	var report := {"passed": passed, "failed": failed, "captures": captures, "engine": Engine.get_version_info(), "display": DisplayServer.get_name(), "timestamp": Time.get_datetime_string_from_system(), "scope": "UI presentation only; no balance simulation"}
	FileAccess.open(_output().path_join("readout-results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	bm.is_battle_active = false
	scene.queue_free()
	await process_frame
	await process_frame
	for child in root.get_node("AudioManager").get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
		elif child is Timer:
			child.stop()
	print("Battle card readout: %d passed, %d failed; output %s" % [passed, failed, _output()])
	quit(1 if failed else 0)

func _output() -> String:
	var directory := OS.get_environment("STSL_READOUT_OUTPUT")
	if directory == "":
		directory = "user://readout-ui"
	DirAccess.make_dir_recursive_absolute(directory)
	return directory
