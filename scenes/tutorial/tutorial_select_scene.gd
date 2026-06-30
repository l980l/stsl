# scenes/tutorial/tutorial_select_scene.gd
# 튜토리얼 레슨 선택 메뉴 — 메뉴에서 옵트인 진입. 완료 레슨은 ✓ 표시.
extends Node2D

func _ready() -> void:
	var P := SacredPalette
	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# 화면 전체를 채우는 세로 박스 — 중앙 정렬로 해상도 무관하게 화면 안에 배치.
	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 14)
	add_child(vb)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title.text = tr("tutorial.select.title")
	vb.add_child(title)

	_add_lesson_row(vb, "tutorial.lesson.basics.name", "basics")
	_add_back_row(vb)

func _make_menu_button(label: String, primary: bool) -> Button:
	var P := SacredPalette
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(420, 60)
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_color_override("font_color", P.BONE_100 if primary else P.FG_2)
	b.add_theme_color_override("font_hover_color", P.BONE_100)
	return b

func _add_lesson_row(parent: VBoxContainer, name_key: String, lesson_id: String) -> void:
	var done: bool = ProgressManager.is_tutorial_completed(lesson_id)
	var b := _make_menu_button(tr(name_key) + ("   ✓" if done else ""), true)
	parent.add_child(b)
	b.pressed.connect(func() -> void: GameManager.start_tutorial(lesson_id))

func _add_back_row(parent: VBoxContainer) -> void:
	var b := _make_menu_button(tr("tutorial.select.back"), false)
	parent.add_child(b)
	b.pressed.connect(func() -> void: SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn"))
