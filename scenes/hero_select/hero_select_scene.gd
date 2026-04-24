# scenes/hero_select/hero_select_scene.gd
extends Control

const _HR = preload("res://resources/heroes/hero_registry.gd")

const CARD_W := 290
const CARD_H := 340
const COLS := 3

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var is_recruit: bool = GameManager.pending_boss_recruit
	var pm = get_node_or_null("/root/ProgressManager")

	var owned_ids: Array = []
	if is_recruit:
		var tm = get_node_or_null("/root/TeamManager")
		if tm:
			for h in tm.heroes:
				owned_ids.append(h.hero_id)

	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 루트 레이아웃
	var root_vbox := VBoxContainer.new()
	root_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root_vbox)

	# 타이틀
	var title := Label.new()
	title.text = tr("ui.hero_select.title_recruit") if is_recruit else tr("ui.hero_select.title_start")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.custom_minimum_size = Vector2(0, 80)
	root_vbox.add_child(title)
	LabelUtils.fit_text(title, 36, 22)

	# 스크롤 컨테이너 (세로 스크롤, 가로 고정)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	# 스크롤 내부: 여백 컨테이너
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_right", 60)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	scroll.add_child(margin)

	# 카드 그리드를 가로 중앙 정렬
	var hbox := HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(hbox)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 50)
	grid.add_theme_constant_override("v_separation", 40)
	hbox.add_child(grid)

	# 카드 생성
	for hid in _HR.all_hero_ids():
		var info: Dictionary = _HR.get_display_info(hid)
		var already_owned: bool = is_recruit and hid in owned_ids
		var is_locked: bool = (not is_recruit) and pm != null and not pm.is_hero_unlocked(hid)

		# 툴팁: 설명 + 잠금 조건
		var tooltip: String = info.get("desc", "") as String
		if is_locked:
			var unlock_desc: String = info.get("unlock_description", "") as String
			tooltip += "\n\n🔒 " + (unlock_desc if unlock_desc != "" else tr("ui.hero_select.unlock_condition_none"))

		# 카드 패널
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
		panel.tooltip_text = tooltip
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.05, 0.08) if (already_owned or is_locked) else Color(0.1, 0.1, 0.2)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		panel.add_theme_stylebox_override("panel", style)
		grid.add_child(panel)

		var card_vbox := VBoxContainer.new()
		panel.add_child(card_vbox)

		# 이름 + HP
		var name_lbl := Label.new()
		name_lbl.text = "%s\nHP %d" % [info.get("name", hid) as String, info.get("hp", 0) as int]
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 22)
		name_lbl.custom_minimum_size = Vector2(0, 70)
		card_vbox.add_child(name_lbl)

		# 일러스트 플레이스홀더
		var illust := ColorRect.new()
		illust.color = Color(0.06, 0.06, 0.12) if is_locked else Color(0.08, 0.08, 0.18)
		illust.size_flags_vertical = Control.SIZE_EXPAND_FILL
		illust.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_vbox.add_child(illust)

		# 선택 버튼
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 55)
		btn.add_theme_font_size_override("font_size", 18)
		if already_owned:
			btn.text = tr("ui.hero_select.already_owned")
			btn.disabled = true
		elif is_locked:
			btn.text = tr("ui.hero_select.locked")
			btn.disabled = true
		elif is_recruit:
			btn.text = tr("ui.hero_select.btn_recruit") % (info.get("name", hid) as String)
		else:
			btn.text = tr("ui.hero_select.btn_select") % (info.get("name", hid) as String)
		if not already_owned and not is_locked:
			var captured_id: String = hid
			btn.pressed.connect(func(): _on_hero_selected(captured_id))
		card_vbox.add_child(btn)

func _on_hero_selected(hero_id: String) -> void:
	if GameManager.pending_boss_recruit:
		GameManager.complete_hero_recruit(hero_id)
	else:
		GameManager.start_run(hero_id, GameManager.current_chapter)
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
