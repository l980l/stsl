# scenes/chapter_clear/chapter_clear_scene.gd
extends Node2D

const _ROMAN := ["", "I", "II", "III", "IV", "V", "VI"]
const _ToastScene = preload("res://scenes/ui/hero_unlock_toast.tscn")

func _ready() -> void:
	add_child(_ToastScene.instantiate())
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette
	var cleared: int = GameManager.current_chapter
	var has_next: bool = cleared < GameManager.MAX_CHAPTERS
	var roman: String = _ROMAN[cleared] if cleared < _ROMAN.size() else str(cleared)

	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var bloom := SacredTheme.make_top_ellipse_bloom(0.31, Vector2(2.0, 0.8))
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920, 820)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	# eyebrow
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = tr("ui.chapter_clear.eyebrow")
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(660, 80)
	eyebrow.size = Vector2(600, 24)
	add_child(eyebrow)

	# 타이틀
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", P.BONE_100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = tr("ui.chapter_clear.title_chapter") % roman if has_next \
			else tr("ui.chapter_clear.title_all_complete")
	title.position = Vector2(560, 138)
	title.size = Vector2(800, 80)
	add_child(title)
	LabelUtils.fit_text(title, 60, 28)

	# 디바이더
	var div := TextureRect.new()
	div.texture = SacredTheme.make_center_bright_h_tex()
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_SCALE
	div.position = Vector2(580, 226)
	div.size = Vector2(760, 1)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(div)

	# 서브
	var sub := Label.new()
	sub.theme_type_variation = "SubLabel"
	sub.text = tr("ui.chapter_clear.subtitle_next") if has_next \
			else tr("ui.chapter_clear.subtitle_all_complete")
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(580, 244)
	sub.size = Vector2(760, 30)
	add_child(sub)

	# 통계 패널
	const PANEL_X := 660
	const PANEL_Y := 300
	const PANEL_W := 600
	const PANEL_H := 280

	var panel_bg := ColorRect.new()
	panel_bg.color = Color(P.INK_1000.r, P.INK_1000.g, P.INK_1000.b, 0.7)
	panel_bg.position = Vector2(PANEL_X, PANEL_Y)
	panel_bg.size = Vector2(PANEL_W, PANEL_H)
	panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_bg)

	var panel_top_line := ColorRect.new()
	panel_top_line.color = P.BRASS_500
	panel_top_line.position = Vector2(PANEL_X, PANEL_Y)
	panel_top_line.size = Vector2(PANEL_W, 2)
	panel_top_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel_top_line)

	var chapter_name_lbl := Label.new()
	chapter_name_lbl.theme_type_variation = "EyebrowLabel"
	chapter_name_lbl.text = tr("ui.chapter_select.chapter%d.name" % cleared)
	chapter_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_name_lbl.position = Vector2(PANEL_X + 20, PANEL_Y + 14)
	chapter_name_lbl.size = Vector2(PANEL_W - 40, 24)
	chapter_name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(chapter_name_lbl)
	LabelUtils.fit_text(chapter_name_lbl, 10, 8)

	var inner_line := ColorRect.new()
	inner_line.color = Color(P.BRASS_700.r, P.BRASS_700.g, P.BRASS_700.b, 0.5)
	inner_line.position = Vector2(PANEL_X + 20, PANEL_Y + 46)
	inner_line.size = Vector2(PANEL_W - 40, 1)
	inner_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inner_line)

	var stats := [
		[tr("ui.chapter_clear.stat_floor"), str(GameManager.current_floor)],
		[tr("ui.chapter_clear.stat_gold"), str(GameManager.gold)],
		[tr("ui.chapter_clear.stat_relics"), str(GameManager.relics.size())],
		[tr("ui.chapter_clear.stat_survivors"), _get_survivor_count()],
	]
	for i in range(stats.size()):
		var row_y := PANEL_Y + 60 + i * 52

		var key_lbl := Label.new()
		key_lbl.theme_type_variation = "SubLabel"
		key_lbl.text = stats[i][0]
		key_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		key_lbl.position = Vector2(PANEL_X + 30, row_y)
		key_lbl.size = Vector2(280, 36)
		key_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(key_lbl)

		var val_lbl := Label.new()
		val_lbl.theme_type_variation = "AccentLabel"
		val_lbl.text = stats[i][1]
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.position = Vector2(PANEL_X + 320, row_y)
		val_lbl.size = Vector2(250, 36)
		val_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(val_lbl)

	var bracket_ctrl := Control.new()
	bracket_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bracket_ctrl.position = Vector2(PANEL_X, PANEL_Y)
	bracket_ctrl.size = Vector2(PANEL_W, PANEL_H)
	add_child(bracket_ctrl)
	SacredTheme.add_corner_brackets(bracket_ctrl, P.BRASS_500, 14, 8)

	# 버튼 영역
	var btn_y := PANEL_Y + PANEL_H + 60
	if has_next:
		var btn_next := Button.new()
		btn_next.theme_type_variation = "PrimaryButton"
		btn_next.text = tr("ui.chapter_clear.btn_next_chapter")
		btn_next.position = Vector2(740, btn_y)
		btn_next.size = Vector2(240, 52)
		btn_next.add_theme_font_size_override("font_size", 18)
		btn_next.pressed.connect(_on_next_chapter)
		add_child(btn_next)
		LabelUtils.fit_text(btn_next, 18, 12)
		SacredTheme.animate_button(btn_next)

		var btn_menu := Button.new()
		btn_menu.theme_type_variation = "VowButton"
		btn_menu.text = tr("ui.chapter_clear.btn_main_menu")
		btn_menu.position = Vector2(1000, btn_y)
		btn_menu.size = Vector2(180, 52)
		btn_menu.add_theme_font_size_override("font_size", 14)
		btn_menu.pressed.connect(_on_main_menu)
		add_child(btn_menu)
		LabelUtils.fit_text(btn_menu, 14, 11)
		SacredTheme.animate_button(btn_menu)
	else:
		var btn_menu := Button.new()
		btn_menu.theme_type_variation = "PrimaryButton"
		btn_menu.text = tr("ui.chapter_clear.btn_main_menu")
		btn_menu.position = Vector2(810, btn_y)
		btn_menu.size = Vector2(300, 52)
		btn_menu.add_theme_font_size_override("font_size", 20)
		btn_menu.pressed.connect(_on_main_menu)
		add_child(btn_menu)
		LabelUtils.fit_text(btn_menu, 20, 14)
		SacredTheme.animate_button(btn_menu)

func _get_survivor_count() -> String:
	var tm = get_node_or_null("/root/TeamManager")
	if tm:
		return str(tm.get_living_heroes().size())
	return "?"

func _on_next_chapter() -> void:
	SceneTransition.go("res://scenes/chapter_select/chapter_select_scene.tscn")

func _on_main_menu() -> void:
	SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn")
