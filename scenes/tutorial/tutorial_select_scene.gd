# scenes/tutorial/tutorial_select_scene.gd
# 튜토리얼 레슨 선택 메뉴 — 메뉴에서 옵트인 진입. 완료 레슨은 ✓ 표시.
extends Node2D

func _ready() -> void:
	var P := SacredPalette
	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	vb.offset_left = -300
	vb.offset_right = 300
	root.add_child(vb)
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.text = tr("tutorial.select.title")
	vb.add_child(title)
	_add_lesson_row(vb, "tutorial.lesson.basics.name", "basics")
	_add_back_row(vb)

func _add_lesson_row(parent: VBoxContainer, name_key: String, lesson_id: String) -> void:
	var P := SacredPalette
	var b := Button.new()
	b.text = tr(name_key) + ("  ✓" if ProgressManager.is_tutorial_completed(lesson_id) else "")
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_color_override("font_color", P.BONE_100)
	parent.add_child(b)
	b.pressed.connect(func() -> void: GameManager.start_tutorial(lesson_id))

func _add_back_row(parent: VBoxContainer) -> void:
	var b := Button.new()
	b.text = tr("tutorial.select.back")
	b.custom_minimum_size = Vector2(0, 48)
	parent.add_child(b)
	b.pressed.connect(func() -> void: SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn"))
