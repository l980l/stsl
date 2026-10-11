extends SceneTree

const CARD := preload("res://scenes/card/card_scene_v2.tscn")
const SCRIPT := preload("res://scenes/card/card_scene_v2.gd")
var _checks := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failed += 1
		printerr("FAIL: ", label)

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		quit(2)
		return
	var card = CARD.instantiate()
	root.add_child(card)
	await process_frame
	var before: PackedByteArray = card._cost_bg.texture.get_image().get_data()
	var texture = card._cost_bg.texture
	var style = card._frame.get_theme_stylebox("panel")
	card._cost = 3
	card._desc = "Updated description"
	card.refresh()
	_check(card._cost_label.text == "3" and card._desc_label.text == "Updated description", "dynamic text")
	_check(card._cost_bg.texture.get_image().get_data() == before, "unchanged ornament pixels")
	_check(card._cost_bg.texture == texture and card._frame.get_theme_stylebox("panel") == style, "refresh reuses decoration")
	var second = CARD.instantiate()
	root.add_child(second)
	_check(second._cost_bg.texture == texture, "instances share immutable ornament")
	second.queue_free()
	var old_gem: PackedByteArray = card._gem_tr.texture.get_image().get_data()
	card._rarity_key = "rare"
	card.refresh()
	_check(card._gem_tr.texture.get_image().get_data() != old_gem, "rarity invalidation")
	card._hero_key = "cleopatra"
	card.refresh()
	_check(card._cost_bg.texture.get_image().get_data() != before, "hero invalidation")
	# Every supported palette/rarity must retain the original generator's pixels.
	for hero in SCRIPT._HERO_PALETTES:
		for rarity in SCRIPT._GEM_COLORS:
			card._hero_key = hero
			card._rarity_key = rarity
			card.refresh()
			var frame: Color = SCRIPT._HERO_PALETTES[hero].frame
			var gem: Dictionary = SCRIPT._GEM_COLORS[rarity]
			var expected = card._make_circle_texture(gem.hi, gem.mid, gem.lo, frame, 0.08, 64, 0.65)
			_check(card._gem_tr.texture.get_image().get_data() == expected.get_image().get_data(), "gem pixels " + hero + rarity)
	card.queue_free()
	await process_frame
	var bm = root.get_node("BattleManager")
	var dm = root.get_node("DeckManager")
	var hand_scene = load("res://scenes/battle/battle_scene.gd").new()
	hand_scene._ui_layer = CanvasLayer.new()
	root.add_child(hand_scene._ui_layer)
	var starter: Array = load("res://resources/cards/cards_cleopatra.gd").starter_deck()
	bm._current_actor_id = "hero:cleopatra"
	dm._heroes["cleopatra"] = {"hand": [starter[0], starter[1]], "energy": 3,
		"pending_all_cost_zero": false, "pending_cost_reduction": 0}
	hand_scene._refresh_hand()
	var first = hand_scene._card_buttons[0]
	hand_scene._refresh_hand()
	_check(hand_scene._card_buttons[0] == first and first._owner_dead, "same hand preserves nodes and reapplies gating")
	dm._heroes["cleopatra"].pending_all_cost_zero = true
	hand_scene._refresh_hand()
	_check(hand_scene._card_buttons[0] == first and first._cost_label.text == "0", "same hand updates effective cost")
	var settings = root.get_node("GameSettings")
	var saved_frame: String = settings.card_frame_key
	settings.card_frame_key = "classic"
	hand_scene._on_card_frame_changed_battle("classic")
	_check(hand_scene._card_buttons[0].get_script() == load("res://scenes/card/card_scene.gd"), "frame change rebuilds classic nodes")
	settings.card_frame_key = "modern"
	hand_scene._on_card_frame_changed_battle("modern")
	_check(hand_scene._card_buttons[0].get_script() == SCRIPT, "frame change rebuilds modern nodes")
	first = hand_scene._card_buttons[0]
	settings.card_frame_key = saved_frame
	dm._heroes["cleopatra"].hand.reverse()
	hand_scene._refresh_hand()
	_check(hand_scene._card_buttons[0] != first and hand_scene._card_buttons[0].get_meta("_card_res") == starter[1], "reordered hand rebuilds")
	bm._current_actor_id = "enemy:0"
	hand_scene._refresh_hand()
	_check(hand_scene._card_buttons.is_empty(), "enemy turn clears hand")
	hand_scene._ui_layer.queue_free()
	hand_scene.free()
	await process_frame
	texture = null
	style = null
	SCRIPT.release_cached_textures()
	for shape in range(Input.CURSOR_ARROW, Input.CURSOR_HELP + 1):
		Input.set_custom_mouse_cursor(null, shape)
	var theme = root.get_node_or_null("SacredTheme")
	if theme:
		theme._cursor_textures_cache.clear()
		theme._cursor_hotspots_cache.clear()
	await process_frame
	print("Card refresh regression: ", _checks, " checks, ", _failed, " failures")
	quit(0 if _failed == 0 else 1)
