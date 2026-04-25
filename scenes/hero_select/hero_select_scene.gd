# scenes/hero_select/hero_select_scene.gd
extends Control

const _HR = preload("res://resources/heroes/hero_registry.gd")

const CARD_W := 290
const CARD_H := 340
const COLS := 3

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette
	var is_recruit: bool = GameManager.pending_boss_recruit
	var pm = get_node_or_null("/root/ProgressManager")

	var owned_ids: Array = []
	if is_recruit:
		var tm = get_node_or_null("/root/TeamManager")
		if tm:
			for h in tm.heroes:
				owned_ids.append(h.hero_id)

	var bg := ColorRect.new()
	bg.color = P.INK_1000
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— RECRUIT —" if is_recruit else "— CHOOSE YOUR HERO —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.custom_minimum_size = Vector2(0, 28)
	root_vbox.add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = tr("ui.hero_select.title_recruit") if is_recruit else tr("ui.hero_select.title_start")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(0, 60)
	root_vbox.add_child(title)
	LabelUtils.fit_text(title, 36, 22)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 50)
	grid.add_theme_constant_override("v_separation", 40)
	hbox.add_child(grid)

	for hid in _HR.all_hero_ids():
		var info: Dictionary = _HR.get_display_info(hid)
		var already_owned: bool = is_recruit and hid in owned_ids
		var is_locked: bool = (not is_recruit) and pm != null and not pm.is_hero_unlocked(hid)
		var inactive: bool = already_owned or is_locked

		var tooltip: String = info.get("desc", "") as String
		if is_locked:
			var unlock_desc_key: String = info.get("unlock_description", "") as String
			var unlock_desc: String = tr(unlock_desc_key) if unlock_desc_key != "" else ""
			tooltip += "\n\n🔒 " + (unlock_desc if unlock_desc != "" else tr("ui.hero_select.unlock_condition_none"))

		# 카드 패널 (Sacred 톤 StyleBox)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
		panel.tooltip_text = tooltip
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		panel.clip_contents = false
		var style := StyleBoxFlat.new()
		style.bg_color = P.INK_1000 if inactive else P.INK_800
		style.set_border_width_all(1)
		style.border_color = P.BRASS_700 if inactive else P.BRASS_500
		style.set_content_margin(SIDE_LEFT, 0)
		style.set_content_margin(SIDE_RIGHT, 0)
		style.set_content_margin(SIDE_TOP, 0)
		style.set_content_margin(SIDE_BOTTOM, 0)
		panel.add_theme_stylebox_override("panel", style)
		grid.add_child(panel)

		var card_vbox := VBoxContainer.new()
		panel.add_child(card_vbox)

		var name_lbl := Label.new()
		name_lbl.theme_type_variation = "AccentLabel"
		name_lbl.text = "%s\nHP %d" % [tr(info.get("name", hid) as String), info.get("hp", 0) as int]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.custom_minimum_size = Vector2(0, 70)
		if inactive:
			name_lbl.modulate = Color(1, 1, 1, 0.45)
		card_vbox.add_child(name_lbl)

		var illust := ColorRect.new()
		illust.color = P.INK_1000 if is_locked else P.INK_900
		illust.size_flags_vertical = Control.SIZE_EXPAND_FILL
		illust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(illust)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 55)
		if already_owned:
			btn.text = tr("ui.hero_select.already_owned")
			btn.disabled = true
		elif is_locked:
			btn.text = tr("ui.hero_select.locked")
			btn.disabled = true
		else:
			btn.theme_type_variation = "PrimaryButton"
			btn.text = tr("ui.hero_select.btn_recruit") % tr(info.get("name", hid) as String) if is_recruit \
					else tr("ui.hero_select.btn_select") % tr(info.get("name", hid) as String)
			var captured_id: String = hid
			btn.pressed.connect(func(): _on_hero_selected(captured_id))
		card_vbox.add_child(btn)

		# PanelContainer는 직접 자식을 풀사이즈로 강제하므로, 브라켓은 overlay Control에 붙임
		var bracket_overlay := Control.new()
		bracket_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(bracket_overlay)
		var bracket_color: Color = P.BRASS_700 if inactive else P.BRASS_500
		SacredTheme.add_corner_brackets(bracket_overlay, bracket_color, 10, 4)
		if not inactive:
			SacredTheme.animate_button(btn)

func _on_hero_selected(hero_id: String) -> void:
	if GameManager.pending_boss_recruit:
		GameManager.complete_hero_recruit(hero_id)
	else:
		GameManager.start_run(hero_id, GameManager.current_chapter)
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
