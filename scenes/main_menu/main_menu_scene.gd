# scenes/main_menu/main_menu_scene.gd
# 타이틀 화면 — Ledger(B) 레이아웃: 좌측 워드마크 / 우측 장부형 메뉴(번호·라벨·메타).
# 색감은 SacredPalette 유지. 호버 시 행 = 황동 테두리 + 본 강조.
extends Node2D

const CreditsOverlay := preload("res://scenes/ui/credits_overlay.gd")
const CodexOverlayScene := preload("res://scenes/ui/codex_scene.tscn")
const MONO_FONT := preload("res://assets/fonts/SpaceMono-Regular.ttf")

func _ready() -> void:
	AudioManager.play_bgm_dynamic("menu", "")
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

	# HUD 코너 브래킷 4종 (맵 노드와 동일 어휘)
	SacredTheme.add_corner_brackets(root, P.LINE_2, 20, 42, 1)

	# 상단 프레임 스탬프 (브랜드/기술 chrome — ASCII)
	_stamp(root, "STSL · MAIN", Vector2(96, 40), HORIZONTAL_ALIGNMENT_LEFT, true)
	_stamp(root, "DECKBUILDING ROGUELIKE", Vector2(1224, 40), HORIZONTAL_ALIGNMENT_RIGHT, false)
	# 하단 프레임 스탬프
	_stamp(root, "V 0.1 · BUILD 2026.06", Vector2(96, 1012), HORIZONTAL_ALIGNMENT_LEFT, false)
	_stamp(root, "STUDIO · UNSIGNED IMPRINT", Vector2(1224, 1012), HORIZONTAL_ALIGNMENT_RIGHT, false)

	# ── 본문 2열 (좌: 워드마크 / 우: 메뉴) ──
	var body := MarginContainer.new()
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_theme_constant_override("margin_left", 144)
	body.add_theme_constant_override("margin_right", 144)
	body.add_theme_constant_override("margin_top", 120)
	body.add_theme_constant_override("margin_bottom", 120)
	root.add_child(body)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 144)
	body.add_child(cols)

	# 좌측 — 워드마크 상단, 장르 스탬프 하단
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.2
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 0)
	cols.add_child(left)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.add_theme_color_override("font_color", P.FG_3)
	eyebrow.add_theme_font_size_override("font_size", 15)
	eyebrow.text = "— THE CARD GAME —"
	left.add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 120)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.add_theme_constant_override("line_spacing", -8)
	# 긴 워드마크는 좌측 컬럼 폭에 맞춰 단어 단위로 스택
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = tr("ui.main_menu.title")
	left.add_child(title)

	var brass_rule := ColorRect.new()
	brass_rule.color = P.BRASS_600
	brass_rule.custom_minimum_size = Vector2(320, 1)
	var rule_mc := MarginContainer.new()
	rule_mc.add_theme_constant_override("margin_top", 24)
	rule_mc.add_child(brass_rule)
	left.add_child(rule_mc)

	var lspacer := Control.new()
	lspacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(lspacer)

	left.add_child(_make_stamp_label("DECKBUILDING · TEAMBUILDING · ROGUELIKE", P.FG_4))

	# 우측 — 장부형 메뉴 (하단 정렬)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 0)
	cols.add_child(right)

	var rspacer := Control.new()
	rspacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(rspacer)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 0)
	right.add_child(rows)

	# 메뉴 항목 — 번호 자동 부여
	var idx := 1
	_add_ledger_row(rows, "%02d" % idx, tr("ui.main_menu.new_game"), "", true, _on_new_game); idx += 1
	if SaveManager.has_save():
		_add_ledger_row(rows, "%02d" % idx, tr("ui.main_menu.continue"), "", true, _on_continue); idx += 1
	_add_ledger_row(rows, "%02d" % idx, tr("ui.main_menu.codex"), _codex_meta(), false, _on_codex); idx += 1
	_add_ledger_row(rows, "%02d" % idx, tr("ui.main_menu.credits"), "", false, _on_credits); idx += 1
	_add_ledger_row(rows, "%02d" % idx, tr("ui.main_menu.quit"), "", false, _on_quit)

# 도감 메타 — 카드 수집 진행도 (보유 / 전체)
func _codex_meta() -> String:
	var pm := get_node_or_null("/root/ProgressManager")
	if pm == null:
		return ""
	var total: int = CardCatalog.get_all_cards().size()
	return "%d / %d" % [pm.discovered_card_count(), total]

# 프레임 chrome 스탬프 (모노, ASCII). dot=true 면 앞에 황동 점.
func _stamp(parent: Control, text: String, pos: Vector2, halign: int, dot: bool) -> void:
	var P := SacredPalette
	if dot:
		var d := ColorRect.new()
		d.color = P.BRASS_400
		d.position = Vector2(pos.x, pos.y + 7)
		d.size = Vector2(4, 4)
		parent.add_child(d)
	var lbl := _make_stamp_label(text, P.FG_4)
	lbl.position = Vector2(pos.x + (12 if dot else 0), pos.y)
	lbl.size = Vector2(600, 18)
	lbl.horizontal_alignment = halign
	# 우측 정렬은 pos.x 를 우측 끝(1824)에 맞추기 위해 폭 기준 보정
	if halign == HORIZONTAL_ALIGNMENT_RIGHT:
		lbl.position = Vector2(1824 - 600, pos.y)
	parent.add_child(lbl)

func _make_stamp_label(text: String, color: Color) -> Label:
	var lbl := Label.new()
	lbl.add_theme_font_override("font", MONO_FONT)
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_constant_override("line_spacing", 0)
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl

# 장부형 메뉴 행 — 번호 + 라벨 + 메타 + 하단 구분선. 호버 시 황동 강조.
func _add_ledger_row(parent: VBoxContainer, num_str: String, label_text: String, meta_text: String, primary: bool, handler: Callable) -> void:
	var P := SacredPalette
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 92)
	row.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "focus"]:
		row.add_theme_stylebox_override(s, empty)
	parent.add_child(row)

	var hb := HBoxContainer.new()
	hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hb.add_theme_constant_override("separation", 24)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hb)

	var num := Label.new()
	num.add_theme_font_override("font", MONO_FONT)
	num.add_theme_font_size_override("font_size", 16)
	num.add_theme_color_override("font_color", P.BRASS_400 if primary else P.FG_4)
	num.text = num_str
	num.custom_minimum_size = Vector2(56, 0)
	num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(num)

	var lbl := Label.new()
	lbl.theme_type_variation = "TitleLabel"
	lbl.add_theme_font_size_override("font_size", 46)
	lbl.add_theme_color_override("font_color", P.BONE_100 if primary else P.FG_2)
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(lbl)

	var meta := Label.new()
	meta.add_theme_font_override("font", MONO_FONT)
	meta.add_theme_font_size_override("font_size", 15)
	meta.add_theme_color_override("font_color", P.FG_4)
	meta.text = meta_text
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

	row.mouse_entered.connect(func() -> void:
		lbl.add_theme_color_override("font_color", P.BONE_100)
		num.add_theme_color_override("font_color", P.BRASS_400)
		rule.color = P.BRASS_400)
	row.mouse_exited.connect(func() -> void:
		lbl.add_theme_color_override("font_color", P.BONE_100 if primary else P.FG_2)
		num.add_theme_color_override("font_color", P.BRASS_400 if primary else P.FG_4)
		rule.color = P.LINE_1)
	row.pressed.connect(handler)

func _on_new_game() -> void:
	SaveManager.clear_save()
	SceneTransition.go("res://scenes/chapter_select/chapter_select_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	SceneTransition.go("res://scenes/map/map_scene.tscn")

func _on_codex() -> void:
	if get_node_or_null("CodexOverlay") != null:
		return
	var ov := CodexOverlayScene.instantiate()
	ov.name = "CodexOverlay"
	add_child(ov)

func _on_credits() -> void:
	if get_node_or_null("CreditsOverlay") != null:
		return
	var overlay := CreditsOverlay.new()
	overlay.name = "CreditsOverlay"
	add_child(overlay)

func _on_quit() -> void:
	get_tree().quit()
