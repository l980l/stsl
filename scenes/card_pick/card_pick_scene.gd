# scenes/card_pick/card_pick_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")

var _picked_count: int = 0
var _pick_max: int = 1
var _progress_lbl: Label = null
var _cells: Array = []
var _cell_base_rects: Array = []
var _cell_apply_hover: Array = []
var _cell_apply_unhover: Array = []
var _hovered_idx: int = -1

func _ready() -> void:
	if GameManager.card_rewards.is_empty():
		GameManager.complete_card_pick()
		return
	_pick_max = GameManager.card_rewards_pick_count
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette
	var cx: float = 960.0
	var stage_x: float = 320.0
	var stage_w: float = 1280.0

	var bg := ColorRect.new()
	bg.color = P.INK_1000
	bg.size = Vector2(1920.0, 1080.0)
	add_child(bg)

	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920.0, 560.0)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	_build_header(stage_x, stage_w, cx)
	_build_tally(cx)
	_build_section_header(stage_x, stage_w, cx)
	_build_card_grid(cx)
	_build_skip(cx)

func _build_header(sx: float, sw: float, cx: float) -> void:
	var P := SacredPalette

	var eyebrow := Label.new()
	eyebrow.text = tr("ui.reward.eyebrow")
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(sx, 62.0)
	eyebrow.size = Vector2(sw, 18.0)
	add_child(eyebrow)

	var title := Label.new()
	title.text = tr("ui.reward.title")
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(sx, 86.0)
	title.size = Vector2(sw, 68.0)
	add_child(title)
	LabelUtils.fit_text(title, 52, 28)

	var sub := Label.new()
	sub.text = tr("ui.reward.subtitle")
	sub.theme_type_variation = "SubLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(sx, 162.0)
	sub.size = Vector2(sw, 26.0)
	add_child(sub)
	LabelUtils.fit_text(sub, 15, 11)

	# 수평 룰 라인
	var rule_w: float = 280.0
	var rule_y: float = 200.0
	var rule := TextureRect.new()
	rule.texture = SacredTheme.make_center_bright_h_tex(SacredPalette.BRASS_400, 0.9)
	rule.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rule.stretch_mode = TextureRect.STRETCH_SCALE
	rule.position = Vector2(cx - rule_w * 0.5, rule_y)
	rule.size = Vector2(rule_w, 1.0)
	add_child(rule)

	# ✦ 배경 마스크 (INK_1000으로 룰 선을 가림)
	var orn_h: float = 20.0
	var orn_w: float = 32.0
	var orn_bg := ColorRect.new()
	orn_bg.color = P.INK_1000
	orn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orn_bg.position = Vector2(cx - orn_w * 0.5, rule_y - orn_h * 0.5)
	orn_bg.size = Vector2(orn_w, orn_h)
	add_child(orn_bg)

	# ✦ 글리프 — 룰 라인 중앙에 정확히 정렬
	var orn := Label.new()
	orn.text = "✦"
	orn.theme_type_variation = "AccentLabel"
	orn.add_theme_color_override("font_color", P.BRASS_300)
	orn.add_theme_font_size_override("font_size", 14)
	orn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orn.position = Vector2(cx - orn_w * 0.5, rule_y - orn_h * 0.5)
	orn.size = Vector2(orn_w, orn_h)
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(orn)

func _build_tally(cx: float) -> void:
	var P := SacredPalette
	var tally_data := [
		{"key": "ui.reward.tally.turns",  "val": "%02d" % GameManager.last_battle_turns},
		{"key": "ui.reward.tally.damage", "val": str(GameManager.last_battle_damage)},
		{"key": "ui.reward.tally.gold",   "val": "+ %d" % GameManager.last_battle_gold},
	]
	var box_w: float = 190.0
	var box_h: float = 62.0
	var gap: float = 28.0
	var total_w: float = box_w * 3.0 + gap * 2.0
	var start_x: float = cx - total_w * 0.5

	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var display_font := SacredTheme.theme.get_font("font", "TitleLabel") as Font

	for i in tally_data.size():
		var d: Dictionary = tally_data[i]
		var box := Panel.new()
		box.position = Vector2(start_x + i * (box_w + gap), 226.0)
		box.size = Vector2(box_w, box_h)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.027, 0.020, 0.012, 0.6)
		sb.border_color = P.BRASS_700
		sb.set_border_width_all(1)
		box.add_theme_stylebox_override("panel", sb)
		add_child(box)
		SacredTheme.add_corner_brackets(box, P.BRASS_500, 8, 3)

		var lbl := Label.new()
		lbl.text = tr(d["key"])
		lbl.add_theme_font_override("font", mono_font)
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", P.BONE_400)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(0.0, 7.0)
		lbl.size = Vector2(box_w, 16.0)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(lbl)

		var num := Label.new()
		num.text = d["val"]
		num.add_theme_font_override("font", display_font)
		num.add_theme_font_size_override("font_size", 24)
		num.add_theme_color_override("font_color", P.BONE_100)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.position = Vector2(0.0, 28.0)
		num.size = Vector2(box_w, 28.0)
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(num)

func _build_section_header(sx: float, sw: float, cx: float) -> void:
	var P := SacredPalette

	_progress_lbl = Label.new()
	_progress_lbl.text = tr("ui.reward.progress") % [_picked_count, _pick_max]
	_progress_lbl.theme_type_variation = "EyebrowLabel"
	_progress_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_progress_lbl.position = Vector2(sx, 314.0)
	_progress_lbl.size = Vector2(sw, 18.0)
	add_child(_progress_lbl)

	var row_y: float = 344.0
	var row_w: float = 1080.0
	var row_x: float = cx - row_w * 0.5

	# HBoxContainer: 텍스트 블록 중앙 고정 + 양쪽 가로선이 텍스트 길이에 맞게 자동 조절
	var row_hbox := HBoxContainer.new()
	row_hbox.position = Vector2(row_x, row_y)
	row_hbox.size = Vector2(row_w, 26.0)
	row_hbox.add_theme_constant_override("separation", 0)
	add_child(row_hbox)

	var line_l := TextureRect.new()
	line_l.texture = SacredTheme.make_center_bright_h_tex(P.BRASS_700, 0.75)
	line_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line_l.stretch_mode = TextureRect.STRETCH_SCALE
	line_l.custom_minimum_size = Vector2(40.0, 1.0)
	line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_hbox.add_child(line_l)

	var pad_l := Control.new()
	pad_l.custom_minimum_size = Vector2(16.0, 0.0)
	row_hbox.add_child(pad_l)

	var idx_lbl := Label.new()
	idx_lbl.text = tr("ui.reward.section.card_index")
	idx_lbl.theme_type_variation = "EyebrowLabel"
	idx_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	idx_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	idx_lbl.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	idx_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row_hbox.add_child(idx_lbl)

	var pad_mid := Control.new()
	pad_mid.custom_minimum_size = Vector2(10.0, 0.0)
	row_hbox.add_child(pad_mid)

	var sec_title := Label.new()
	sec_title.text = tr("ui.reward.section.card_title")
	sec_title.theme_type_variation = "AccentLabel"
	sec_title.add_theme_font_size_override("font_size", 19)
	sec_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sec_title.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sec_title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row_hbox.add_child(sec_title)
	LabelUtils.fit_text(sec_title, 19, 13, 480.0)

	var pad_r := Control.new()
	pad_r.custom_minimum_size = Vector2(16.0, 0.0)
	row_hbox.add_child(pad_r)

	var line_r := TextureRect.new()
	line_r.texture = SacredTheme.make_center_bright_h_tex(P.BRASS_700, 0.75)
	line_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line_r.stretch_mode = TextureRect.STRETCH_SCALE
	line_r.custom_minimum_size = Vector2(40.0, 1.0)
	line_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row_hbox.add_child(line_r)

func _build_card_grid(cx: float) -> void:
	var P := SacredPalette
	var cards: Array = GameManager.card_rewards
	var count: int = cards.size()

	var cell_w: float = 240.0
	var cell_h: float = 432.0
	var gap: float = 36.0
	var total_w: float = count * cell_w + (count - 1) * gap
	var start_x: float = cx - total_w * 0.5
	# 섹션 헤더 하단(~372) ~ 스킵 버튼 상단(940) 균등 분할
	# 여백 = (940 - 372 - 432) / 2 ≈ 68 → cell_y = 372 + 68 = 440
	var cell_y: float = 440.0

	var card_scale: float = 1.5
	var scaled_w: float = 140.0 * card_scale  # 210
	var scaled_h: float = 200.0 * card_scale  # 300

	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font

	for i in range(count):
		var card: Resource = cards[i]

		var cell := Panel.new()
		cell.position = Vector2(start_x + i * (cell_w + gap), cell_y)
		cell.size = Vector2(cell_w, cell_h)
		var cell_sb := StyleBoxFlat.new()
		cell_sb.bg_color = Color(0.078, 0.063, 0.047, 0.4)
		cell_sb.border_color = P.BRASS_700
		cell_sb.set_border_width_all(1)
		cell.add_theme_stylebox_override("panel", cell_sb)
		add_child(cell)
		_cells.append(cell)
		SacredTheme.add_corner_brackets(cell, P.BRASS_500, 12, 6)

		var halo_lbl := Label.new()
		halo_lbl.text = "✦"
		halo_lbl.theme_type_variation = "AccentLabel"
		halo_lbl.add_theme_color_override("font_color", P.BRASS_300)
		halo_lbl.add_theme_font_size_override("font_size", 28)
		halo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		halo_lbl.position = Vector2(0.0, 12.0)
		halo_lbl.size = Vector2(cell_w, 36.0)
		halo_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_child(halo_lbl)

		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(scaled_w, scaled_h)
		wrapper.position = Vector2((cell_w - scaled_w) * 0.5, 52.0)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		cell.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.position = Vector2(70.0 * (card_scale - 1.0), 200.0 * (card_scale - 1.0))
		card_node.pivot_offset = Vector2(70.0, 200.0)
		card_node.scale = Vector2(card_scale, card_scale)
		card_node.setup(card, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var cta := Button.new()
		cta.text = tr("ui.reward.btn_take").to_upper()
		cta.theme_type_variation = "VowButton"
		cta.add_theme_font_override("font", mono_font)
		cta.add_theme_font_size_override("font_size", 10)
		cta.position = Vector2(16.0, 52.0 + scaled_h + 20.0)
		cta.size = Vector2(cell_w - 32.0, 36.0)
		SacredTheme.animate_button(cta)
		cell.add_child(cta)

		# 캡처 (for 루프 클로저 안전)
		var cap_card      := card
		var cap_cell      := cell
		var cap_cta       := cta
		var cap_sb        := cell_sb
		var cap_card_node := card_node
		var orig_y        := cell_y
		var h_tw: Array   = [null]

		_cell_base_rects.append(Rect2(
			Vector2(start_x + i * (cell_w + gap), cell_y),
			Vector2(cell_w, cell_h)
		))

		_cell_apply_hover.append(func():
			if h_tw[0] and h_tw[0].is_valid():
				h_tw[0].kill()
			h_tw[0] = cap_cell.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			h_tw[0].tween_property(cap_cell, "position:y", orig_y - 8.0, 0.18)
			cap_sb.border_color = P.BRASS_400
			cap_card_node.set_glow_color(P.BRASS_300)
			cap_card_node.tween_glow(1.0, 0.20)
		)

		_cell_apply_unhover.append(func():
			if h_tw[0] and h_tw[0].is_valid():
				h_tw[0].kill()
			h_tw[0] = cap_cell.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			h_tw[0].tween_property(cap_cell, "position:y", orig_y, 0.18)
			cap_sb.border_color = P.BRASS_700
			cap_card_node.tween_glow(0.0, 0.20)
		)

		cta.pressed.connect(func(): _on_card_selected(cap_card, cap_cell, cap_cta, cap_card_node))
		card_node.card_clicked.connect(func(_c): _on_card_selected(cap_card, cap_cell, cap_cta, cap_card_node))

func _build_skip(cx: float) -> void:
	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var skip_btn := Button.new()
	skip_btn.text = tr("ui.reward.btn_skip").to_upper()
	skip_btn.theme_type_variation = "VowButton"
	skip_btn.add_theme_font_override("font", mono_font)
	skip_btn.add_theme_font_size_override("font_size", 10)
	# 카드 하단(~872) ~ 화면 하단(1080) 중앙 = 976, 버튼 높이 40 → y=956
	skip_btn.position = Vector2(cx - 140.0, 940.0)
	skip_btn.size = Vector2(280.0, 40.0)
	skip_btn.pressed.connect(_on_skip)
	SacredTheme.animate_button(skip_btn)
	add_child(skip_btn)

func _process(_dt: float) -> void:
	if _cells.is_empty():
		return
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var found: int = -1
	for i in _cells.size():
		var cell: Panel = _cells[i]
		if not is_instance_valid(cell):
			continue
		if cell.modulate.r < 0.9:
			continue
		if _cell_base_rects[i].has_point(mouse_pos):
			found = i
			break
	if found == _hovered_idx:
		return
	if _hovered_idx >= 0 and _hovered_idx < _cell_apply_unhover.size():
		_cell_apply_unhover[_hovered_idx].call()
	if found >= 0:
		_cell_apply_hover[found].call()
	_hovered_idx = found

func _on_card_selected(card: Resource, cell: Panel, cta: Button, card_node: CardScene) -> void:
	if _picked_count >= _pick_max:
		return
	DeckManager.add_card_to_deck(card)
	cell.modulate = Color(0.45, 0.45, 0.45)
	cta.disabled = true
	card_node.tween_glow(0.0, 0.10)
	_picked_count += 1
	if _progress_lbl:
		_progress_lbl.text = tr("ui.reward.progress") % [_picked_count, _pick_max]
	if _picked_count >= _pick_max:
		GameManager.complete_card_pick()

func _on_skip() -> void:
	GameManager.complete_card_pick()
