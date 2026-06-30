# scenes/tutorial/tutorial_select_scene.gd
# 튜토리얼 레슨 선택 — "B · The Index" 레이아웃 (메인메뉴와 동일 디자인 시스템, SacredPalette 유지).
# 넓은 장부형 목차: 번호 · 레슨명 · 한 줄 설명 · 메타. 좌하단 뒤로가기 아이콘.
extends Node2D

const MONO_FONT := preload("res://assets/fonts/SpaceMono-Regular.ttf")

# 레슨 목록 — basics 만 활성, 나머지는 준비 중(잠금).
const LESSONS := [
	{"num": "01", "name": "tutorial.lesson.basics.name", "desc": "tutorial.lesson.basics.desc", "meta": "tutorial.lesson.basics.meta", "id": "basics"},
	{"num": "02", "name": "tutorial.lesson.counter.name", "desc": "tutorial.lesson.counter.desc", "meta": "", "id": ""},
	{"num": "03", "name": "tutorial.lesson.status.name", "desc": "tutorial.lesson.status.desc", "meta": "", "id": ""},
	{"num": "04", "name": "tutorial.lesson.team.name", "desc": "tutorial.lesson.team.desc", "meta": "", "id": ""},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	var root := Control.new()
	root.size = Vector2(1920, 1080)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	SacredTheme.add_corner_brackets(root, P.LINE_2, 20, 42, 1)
	_stamp(root, "TUTORIAL · INDEX", Vector2(96, 40), HORIZONTAL_ALIGNMENT_LEFT, true)
	_stamp(root, "IV LESSONS", Vector2(1224, 40), HORIZONTAL_ALIGNMENT_RIGHT, false)
	_stamp(root, "THE SCHOOLING · I", Vector2(1224, 1012), HORIZONTAL_ALIGNMENT_RIGHT, false)

	var body := MarginContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_theme_constant_override("margin_left", 168)
	body.add_theme_constant_override("margin_right", 168)
	body.add_theme_constant_override("margin_top", 132)
	body.add_theme_constant_override("margin_bottom", 132)
	root.add_child(body)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	body.add_child(col)

	# ── 헤더: 좌측 eyebrow+타이틀 / 우측 태그라인, 아래 굵은 구분선 ──
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 40)
	col.add_child(head)

	var head_left := VBoxContainer.new()
	head_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_left.add_theme_constant_override("separation", 12)
	head.add_child(head_left)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.add_theme_color_override("font_color", P.FG_3)
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.text = tr("tutorial.select.eyebrow")
	head_left.add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", P.BONE_100)
	title.text = tr("tutorial.select.heading")
	head_left.add_child(title)

	var tag := Label.new()
	tag.theme_type_variation = "TitleLabel"
	tag.add_theme_font_size_override("font_size", 22)
	tag.add_theme_color_override("font_color", P.FG_3)
	tag.text = tr("tutorial.select.tagline")
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.size_flags_vertical = Control.SIZE_SHRINK_END
	head.add_child(tag)

	var head_rule := ColorRect.new()
	head_rule.color = P.LINE_2
	head_rule.custom_minimum_size = Vector2(0, 1)
	var head_rule_mc := MarginContainer.new()
	head_rule_mc.add_theme_constant_override("margin_top", 26)
	head_rule_mc.add_theme_constant_override("margin_bottom", 8)
	head_rule_mc.add_child(head_rule)
	col.add_child(head_rule_mc)

	# ── 장부 행 ──
	for l in LESSONS:
		_add_index_row(col, l)

	# ── 좌하단 뒤로가기 아이콘 (영웅/챕터 선택씬과 동일 위치·스타일) ──
	var btn_back := TextureButton.new()
	btn_back.texture_normal = load("res://assets/art/ui/back_arrow.svg")
	btn_back.ignore_texture_size = true
	btn_back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	btn_back.position = Vector2(60, 960)
	btn_back.size = Vector2(64, 44)
	btn_back.pressed.connect(_on_back)
	add_child(btn_back)
	SacredTheme.attach_icon_hover_anim(btn_back)

func _add_index_row(parent: VBoxContainer, data: Dictionary) -> void:
	var P := SacredPalette
	var lesson_id: String = data["id"]
	var locked: bool = lesson_id == ""
	var done: bool = (not locked) and ProgressManager.is_tutorial_completed(lesson_id)

	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 96)
	row.focus_mode = Control.FOCUS_NONE
	row.disabled = locked
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus", "disabled"]:
		row.add_theme_stylebox_override(s, empty)
	parent.add_child(row)

	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.add_theme_constant_override("separation", 28)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hb)

	var num := Label.new()
	num.add_theme_font_override("font", MONO_FONT)
	num.add_theme_font_size_override("font_size", 15)
	num.add_theme_color_override("font_color", P.BRASS_400 if not locked else P.FG_4)
	num.text = data["num"]
	num.custom_minimum_size = Vector2(64, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(num)

	var label := Label.new()
	label.theme_type_variation = "TitleLabel"
	label.add_theme_font_size_override("font_size", 38)
	label.add_theme_color_override("font_color", P.BONE_100 if not locked else P.FG_4)
	label.text = tr(data["name"]) + ("   ✓" if done else "")
	label.custom_minimum_size = Vector2(360, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(label)

	var desc := Label.new()
	desc.add_theme_font_size_override("font_size", 17)
	desc.add_theme_color_override("font_color", P.FG_3 if not locked else P.FG_4)
	desc.text = tr(data["desc"])
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(desc)

	var meta := Label.new()
	meta.add_theme_font_override("font", MONO_FONT)
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", P.FG_4)
	meta.text = (tr("tutorial.select.locked") if locked else tr(data["meta"]))
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(meta)

	var rule := ColorRect.new()
	rule.color = P.LINE_1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(rule)
	rule.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	rule.offset_top = -1.0
	rule.offset_bottom = 0.0

	if locked:
		return
	row.mouse_entered.connect(func() -> void:
		label.add_theme_color_override("font_color", P.BRASS_300)
		desc.add_theme_color_override("font_color", P.FG_2)
		rule.color = P.BRASS_400)
	row.mouse_exited.connect(func() -> void:
		label.add_theme_color_override("font_color", P.BONE_100)
		desc.add_theme_color_override("font_color", P.FG_3)
		rule.color = P.LINE_1)
	row.pressed.connect(func() -> void: GameManager.start_tutorial(lesson_id))

func _on_back() -> void:
	SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn")

# 프레임 chrome 스탬프 (모노 ASCII). dot=true 면 앞에 황동 점. (main_menu 패턴)
func _stamp(parent: Control, text: String, pos: Vector2, halign: int, dot: bool) -> void:
	var P := SacredPalette
	if dot:
		var d := ColorRect.new()
		d.color = P.BRASS_400
		d.position = Vector2(pos.x, pos.y + 7)
		d.size = Vector2(4, 4)
		parent.add_child(d)
	var lbl := Label.new()
	lbl.add_theme_font_override("font", MONO_FONT)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", P.FG_4)
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = Vector2(pos.x + (12 if dot else 0), pos.y)
	lbl.size = Vector2(600, 18)
	lbl.horizontal_alignment = halign
	if halign == HORIZONTAL_ALIGNMENT_RIGHT:
		lbl.position = Vector2(1824 - 600, pos.y)
	parent.add_child(lbl)
