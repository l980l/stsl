# scenes/chapter_select/chapter_select_scene.gd
extends Node2D

const _ROMAN  := ["", "I", "II", "III", "IV", "V", "VI"]
const _CRESTS := ["", "✦", "†", "❀", "☩", "∞", "?"]

const _CHAPTERS := [
	{"id": 1, "name_key": "ui.chapter_select.chapter1.name", "desc_key": "ui.chapter_select.chapter1.desc"},
	{"id": 2, "name_key": "ui.chapter_select.chapter2.name", "desc_key": "ui.chapter_select.chapter2.desc"},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

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

	# 상단 eyebrow
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— THE PILGRIMAGE —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(660, 80)
	eyebrow.size = Vector2(600, 24)
	add_child(eyebrow)

	# 타이틀
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", P.BONE_100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = tr("ui.chapter_select.title")
	title.position = Vector2(560, 138)
	title.size = Vector2(800, 80)
	add_child(title)
	LabelUtils.fit_text(title, 56, 28)

	var div := TextureRect.new()
	div.texture = SacredTheme.make_center_bright_h_tex()
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_SCALE
	div.position = Vector2(580, 226)
	div.size = Vector2(760, 1)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(div)

	# 서브 타이틀
	var sub := Label.new()
	sub.theme_type_variation = "SubLabel"
	sub.text = "Each verdict opens the next door."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(660, 244)
	sub.size = Vector2(600, 30)
	add_child(sub)

	for i in range(_CHAPTERS.size()):
		_make_chapter_card(_CHAPTERS[i], i)

	# 뒤로 버튼 (Vow)
	var btn_back := Button.new()
	btn_back.theme_type_variation = "VowButton"
	btn_back.text = tr("ui.chapter_select.back")
	btn_back.position = Vector2(60, 960)
	btn_back.size = Vector2(200, 52)
	btn_back.add_theme_font_size_override("font_size", 14)
	btn_back.pressed.connect(_on_back)
	add_child(btn_back)
	LabelUtils.fit_text(btn_back, 14, 11)
	SacredTheme.animate_button(btn_back)

func _make_chapter_card(chapter: Dictionary, idx: int) -> void:
	var P := SacredPalette
	var card_x := 300 + idx * 700
	var card_y := 300
	var card_w  := 600
	var card_h  := 560

	var _pm = get_node_or_null("/root/ProgressManager")
	var unlocked: bool = _pm.is_chapter_unlocked(int(chapter["id"])) if _pm else true
	var roman: String = _ROMAN[chapter["id"]] if chapter["id"] < _ROMAN.size() else str(chapter["id"])
	var crest: String = _CRESTS[chapter["id"]] if chapter["id"] < _CRESTS.size() else "✦"

	# ── 카드 버튼 (전체가 클릭 영역) ──
	var card := Button.new()
	card.theme_type_variation = "ChapterButton" if unlocked else "ChapterButtonLocked"
	card.position = Vector2(card_x, card_y)
	card.size = Vector2(card_w, card_h)
	card.flat = false
	card.clip_contents = false
	card.set_meta("_base_y", float(card_y))
	if unlocked:
		var chapter_id: int = chapter["id"]
		card.pressed.connect(func(): _on_chapter_selected(chapter_id))
	else:
		card.disabled = true
	add_child(card)

	# ── 잠금 상태 오버레이 ──
	if not unlocked:
		var overlay := ColorRect.new()
		overlay.color = Color(0.05, 0.04, 0.09, 0.5)
		overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(overlay)

	# ── 완료 상태 상단 황금선 ──
	if unlocked:
		var top_glow := ColorRect.new()
		top_glow.color = P.BRASS_400
		top_glow.position = Vector2(0, 0)
		top_glow.size = Vector2(card_w, 2)
		top_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(top_glow)

		# ── 호버 halo (방사형 금빛 후광) — 이른 add_child로 후속 자식들 뒤에 렌더링 ──
		var halo := SacredTheme.make_halo()
		halo.position = Vector2.ZERO
		halo.size = Vector2(card_w, card_h)
		card.add_child(halo)

	# ── 로마 숫자 뱃지 (좌상단) ──
	var numeral_bg := ColorRect.new()
	numeral_bg.color = P.INK_1000
	numeral_bg.position = Vector2(14, 14)
	numeral_bg.size = Vector2(50, 34)
	numeral_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(numeral_bg)

	var numeral := Label.new()
	numeral.theme_type_variation = "AccentLabel"
	numeral.add_theme_font_size_override("font_size", 16)
	numeral.text = roman
	numeral.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numeral.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	numeral.position = Vector2(14, 14)
	numeral.size = Vector2(50, 34)
	numeral.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(numeral)

	# ── 상태 뱃지 (우상단) ──
	var status_bg := ColorRect.new()
	status_bg.color = P.INK_1000
	status_bg.position = Vector2(card_w - 130, 14)
	status_bg.size = Vector2(116, 26)
	status_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status_bg)

	var status_lbl := Label.new()
	status_lbl.theme_type_variation = "EyebrowLabel"
	status_lbl.text = "OPEN" if unlocked else "SEALED"
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_lbl.position = Vector2(card_w - 130, 14)
	status_lbl.size = Vector2(116, 26)
	status_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status_lbl)

	# ── 아치 장식선 ──
	var arch_panel := Panel.new()
	arch_panel.position = Vector2(card_w / 2.0 - 140, 55)
	arch_panel.size = Vector2(280, 200)
	arch_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arch_style := StyleBoxEmpty.new()
	arch_panel.add_theme_stylebox_override("panel", arch_style)
	card.add_child(arch_panel)

	# ── 크레스트 글리프 ──
	var crest_lbl := Label.new()
	crest_lbl.text = crest
	crest_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crest_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crest_lbl.add_theme_font_size_override("font_size", 96)
	crest_lbl.add_theme_color_override("font_color",
			P.BRASS_300 if unlocked else P.FG_4)
	crest_lbl.position = Vector2(0, 60)
	crest_lbl.size = Vector2(card_w, 220)
	crest_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(crest_lbl)

	# ── 잠금 아이콘 (잠긴 경우) ──
	if not unlocked:
		var lock_lbl := Label.new()
		lock_lbl.text = "⛨"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 32)
		lock_lbl.add_theme_color_override("font_color", P.BRASS_600)
		lock_lbl.position = Vector2(card_w / 2.0 - 30, 165)
		lock_lbl.size = Vector2(60, 50)
		lock_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock_lbl)

	# ── 하단 플레이트 구분선 ──
	var plate_line := ColorRect.new()
	plate_line.color = P.BRASS_700
	plate_line.position = Vector2(0, 295)
	plate_line.size = Vector2(card_w, 1)
	plate_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(plate_line)

	# ── eyebrow ──
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— CHAPTER %s —" % roman
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(20, 310)
	eyebrow.size = Vector2(card_w - 40, 24)
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(eyebrow)

	# ── 챕터 이름 ──
	var name_box := Control.new()
	name_box.position = Vector2(20, 340)
	name_box.size = Vector2(card_w - 40, 60)
	name_box.clip_contents = true
	name_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_box)
	var name_lbl := Label.new()
	name_lbl.theme_type_variation = "TitleLabel"
	name_lbl.add_theme_font_size_override("font_size", 26)
	name_lbl.text = tr(chapter["name_key"])
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_box.add_child(name_lbl)
	name_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LabelUtils.fit_text(name_lbl, 26, 14)

	# ── 설명 ──
	var desc_box := Control.new()
	desc_box.position = Vector2(20, 408)
	desc_box.size = Vector2(card_w - 40, 90)
	desc_box.clip_contents = true
	desc_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(desc_box)
	var desc_lbl := Label.new()
	desc_lbl.theme_type_variation = "SubLabel"
	desc_lbl.text = tr(chapter["desc_key"])
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_box.add_child(desc_lbl)
	desc_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LabelUtils.fit_text(desc_lbl, 13, 10)

	# ── 잠금 힌트 ──
	if not unlocked:
		var hint := Label.new()
		hint.theme_type_variation = "SubLabel"
		hint.add_theme_color_override("font_color", P.BLOOD_300)
		hint.text = tr("ui.chapter_select.unlock_hint")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.position = Vector2(20, 500)
		hint.size = Vector2(card_w - 40, 40)
		hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(hint)
		LabelUtils.fit_text(hint, 12, 10)

	# ── 모서리 L자 브라켓 ──
	var bracket_color := P.BRASS_500 if unlocked else P.BRASS_700
	SacredTheme.add_corner_brackets(card, bracket_color, 14, 8)

	# ── 호버 애니메이션 ──
	if unlocked:
		card.mouse_entered.connect(func(): _hover_card(card, true))
		card.mouse_exited.connect(func(): _hover_card(card, false))
		# PrimaryButton과 동일 — 기본 희미한 후광, 호버 시 0.375
		SacredTheme.attach_outer_glow(card, 20.0, 0.1, 0.3)

func _hover_card(card: Button, entering: bool) -> void:
	# Y 트윈 — base_y 기준으로 드리프트 없이 안정적 동작
	if card.has_meta("_ytween"): card.get_meta("_ytween").kill()
	var base_y: float = card.get_meta("_base_y") if card.has_meta("_base_y") else card.position.y
	var target_y := base_y + (-5.0 if entering else 0.0)
	var yt := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	yt.tween_property(card, "position:y", target_y, 0.18)
	card.set_meta("_ytween", yt)

	# halo 트윈 — opacity + radius 동시 트윈 (안→밖 wave)
	for child in card.get_children():
		if child.get_meta("_halo", false):
			if child.has_meta("_htween"): child.get_meta("_htween").kill()
			var mat := child.material as ShaderMaterial
			if mat:
				var target_op := 1.0 if entering else 0.0
				var target_r := 1.0 if entering else 0.0
				var ht := SacredTheme.tween_glow_material(self, mat, target_op, target_r, 0.25, not entering)
				child.set_meta("_htween", ht)
			break

func _on_chapter_selected(chapter_id: int) -> void:
	GameManager.current_chapter = chapter_id
	SceneTransition.go("res://scenes/hero_select/hero_select_scene.tscn")

func _on_back() -> void:
	SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn")
