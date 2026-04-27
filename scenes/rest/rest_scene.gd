# scenes/rest/rest_scene.gd
extends Node2D

const ROMAN      := ["I", "II", "III"]
const FRAME_L    := 80.0
const FRAME_T    := 80.0
const FRAME_W    := 1920.0 - FRAME_L * 2.0
const FRAME_H    := 1080.0 - FRAME_T - 40.0
const ILLO_H     := 680.0
const NARR_H     := 270.0
const CHOICE_PAD := 24.0

var _frame: Panel = null
var _popup_tween: Tween = null

func _ready() -> void:
	_build_ui()
	_play_open()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = SacredPalette.INK_1000
	bg.size = Vector2(1920.0, 1080.0)
	add_child(bg)

	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920.0, 560.0)
	add_child(bloom)

	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.078, 0.059, 0.047, 0.92)
	frame_style.border_color = SacredPalette.BRASS_500
	frame_style.set_border_width_all(1)
	var frame := Panel.new()
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.position = Vector2(FRAME_L, FRAME_T)
	frame.size = Vector2(FRAME_W, FRAME_H)
	frame.pivot_offset = Vector2(FRAME_W * 0.5, FRAME_H * 0.5)
	add_child(frame)
	SacredTheme.add_corner_brackets(frame)
	_frame = frame

	_build_illo(frame)
	_build_choices(frame)

func _build_illo(frame: Panel) -> void:
	var illo := Control.new()
	illo.position = Vector2.ZERO
	illo.size = Vector2(FRAME_W, ILLO_H)
	illo.clip_contents = true
	frame.add_child(illo)

	# 중앙 금빛 환경광
	var cg := Gradient.new()
	var bc := SacredPalette.BRASS_300
	cg.set_color(0, Color(bc.r, bc.g, bc.b, 0.17))
	cg.set_color(1, Color(bc.r, bc.g, bc.b, 0.0))
	var cg_tex := GradientTexture2D.new()
	cg_tex.gradient = cg
	cg_tex.fill = GradientTexture2D.FILL_RADIAL
	cg_tex.fill_from = Vector2(0.5, 0.35)
	cg_tex.fill_to   = Vector2(1.0, 0.35)
	cg_tex.width = 64; cg_tex.height = 64
	var amb := TextureRect.new()
	amb.texture = cg_tex
	amb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	amb.stretch_mode = TextureRect.STRETCH_SCALE
	amb.size = Vector2(FRAME_W, ILLO_H)
	amb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illo.add_child(amb)

	# 플레이트 배지
	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var plate_lbl := Label.new()
	plate_lbl.text = "— Rest · " + tr("ui.rest.title") + " —"
	if mono_font:
		plate_lbl.add_theme_font_override("font", mono_font)
	plate_lbl.add_theme_font_size_override("font_size", 11)
	plate_lbl.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	plate_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plate_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var plate_style := StyleBoxFlat.new()
	plate_style.bg_color = Color(0.027, 0.020, 0.012, 0.80)
	plate_style.border_color = SacredPalette.BRASS_500
	plate_style.set_border_width_all(1)
	plate_style.content_margin_left = 24.0
	plate_style.content_margin_right = 24.0
	plate_style.content_margin_top = 7.0
	plate_style.content_margin_bottom = 7.0
	plate_lbl.add_theme_stylebox_override("normal", plate_style)
	plate_lbl.size = Vector2(480.0, 32.0)
	plate_lbl.position = Vector2((FRAME_W - 480.0) * 0.5, 24.0)
	illo.add_child(plate_lbl)

	# 하단 비네트
	var vg := Gradient.new()
	vg.set_color(0, Color(0.027, 0.020, 0.012, 0.0))
	vg.set_color(1, Color(0.027, 0.020, 0.012, 0.96))
	vg.add_point(0.52, Color(0.027, 0.020, 0.012, 0.0))
	vg.add_point(0.76, Color(0.027, 0.020, 0.012, 0.72))
	var vg_tex := GradientTexture2D.new()
	vg_tex.gradient = vg
	vg_tex.fill = GradientTexture2D.FILL_LINEAR
	vg_tex.fill_from = Vector2(0.5, 0.0)
	vg_tex.fill_to   = Vector2(0.5, 1.0)
	var vig := TextureRect.new()
	vig.texture = vg_tex
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.stretch_mode = TextureRect.STRETCH_SCALE
	vig.size = Vector2(FRAME_W, ILLO_H)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	illo.add_child(vig)

	# Narration 블록
	var pad_x := 120.0
	var narr := VBoxContainer.new()
	narr.add_theme_constant_override("separation", 12)
	narr.position = Vector2(pad_x, ILLO_H - NARR_H - 20.0)
	narr.size = Vector2(FRAME_W - pad_x * 2.0, NARR_H)
	illo.add_child(narr)

	# 타이틀
	var title_lbl := Label.new()
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.text = tr("ui.rest.title")
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narr.add_child(title_lbl)
	LabelUtils.fit_text(title_lbl, 60, 30)

	# 구분선 + ✦
	var div_row := HBoxContainer.new()
	div_row.alignment = BoxContainer.ALIGNMENT_CENTER
	div_row.add_theme_constant_override("separation", 12)
	div_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narr.add_child(div_row)

	var line_l := TextureRect.new()
	line_l.texture = SacredTheme.make_center_bright_h_tex()
	line_l.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line_l.stretch_mode = TextureRect.STRETCH_SCALE
	line_l.custom_minimum_size = Vector2(120.0, 1.0)
	line_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div_row.add_child(line_l)

	var gem := Label.new()
	gem.text = "✦"
	gem.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	gem.add_theme_font_size_override("font_size", 13)
	div_row.add_child(gem)

	var line_r := TextureRect.new()
	line_r.texture = SacredTheme.make_center_bright_h_tex()
	line_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line_r.stretch_mode = TextureRect.STRETCH_SCALE
	line_r.custom_minimum_size = Vector2(120.0, 1.0)
	line_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	div_row.add_child(line_r)

	# 영웅 HP 현황
	var tm := _get_tm()
	if tm and tm.heroes.size() > 0:
		var hp_box := HBoxContainer.new()
		hp_box.alignment = BoxContainer.ALIGNMENT_CENTER
		hp_box.add_theme_constant_override("separation", 48)
		hp_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		narr.add_child(hp_box)

		for hero in tm.heroes:
			var cur_hp: int = tm.get_current_hp(hero.hero_id) if tm.has_method("get_current_hp") else hero.max_hp
			var ratio: float = float(cur_hp) / float(hero.max_hp)
			var hp_color: Color = SacredPalette.BLOOD_300 if ratio <= 0.3 else SacredPalette.BONE_200

			var hero_col := VBoxContainer.new()
			hero_col.add_theme_constant_override("separation", 6)
			hp_box.add_child(hero_col)

			var name_lbl := Label.new()
			name_lbl.text = tr(hero.hero_name)
			name_lbl.add_theme_font_size_override("font_size", 16)
			name_lbl.add_theme_color_override("font_color", SacredPalette.BRASS_300)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hero_col.add_child(name_lbl)

			var hp_lbl := Label.new()
			hp_lbl.text = tr("ui.rest.hero_hp_format") % [tr(hero.hero_name), cur_hp, hero.max_hp]
			# hero_hp_format는 이름 포함이므로 이름만 따로 표시
			hp_lbl.text = "%d / %d" % [cur_hp, hero.max_hp]
			hp_lbl.add_theme_font_size_override("font_size", 22)
			hp_lbl.add_theme_color_override("font_color", hp_color)
			hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hero_col.add_child(hp_lbl)

func _build_choices(frame: Panel) -> void:
	# 구분선
	var sep := TextureRect.new()
	sep.texture = SacredTheme.make_center_bright_h_tex()
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_SCALE
	sep.position = Vector2(0.0, ILLO_H)
	sep.size = Vector2(FRAME_W, 1.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(sep)

	var area := VBoxContainer.new()
	area.position = Vector2(56.0, ILLO_H + CHOICE_PAD)
	area.size = Vector2(FRAME_W - 112.0, FRAME_H - ILLO_H - CHOICE_PAD - 34.0)
	area.add_theme_constant_override("separation", 12)
	frame.add_child(area)

	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var hdr := Label.new()
	hdr.text = "— 선택하라 —"
	if mono_font:
		hdr.add_theme_font_override("font", mono_font)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", SacredPalette.BRASS_400)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area.add_child(hdr)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.add_child(row)

	var can_upgrade := _has_upgradeable_cards()

	var choices := [
		{
			"roman": "I",
			"label": tr("ui.rest.btn_heal"),
			"tags": [{"text": "+30% HP", "color": SacredPalette.BRASS_300}],
			"disabled": false,
			"leave": false,
			"action": _on_heal_pressed,
		},
		{
			"roman": "II",
			"label": tr("ui.rest.btn_upgrade"),
			"tags": [{"text": "카드 강화", "color": SacredPalette.BRASS_300 if can_upgrade else SacredPalette.BONE_400}],
			"disabled": not can_upgrade,
			"leave": false,
			"action": _on_upgrade_pressed,
		},
		{
			"roman": "III",
			"label": tr("ui.rest.btn_leave"),
			"tags": [],
			"disabled": false,
			"leave": true,
			"action": _on_leave_pressed,
		},
	]

	for ch in choices:
		_build_choice_card(row, ch)

func _build_choice_card(row: HBoxContainer, ch: Dictionary) -> void:
	var is_leave:    bool = ch["leave"]
	var is_disabled: bool = ch["disabled"]

	var border_col: Color = SacredPalette.BRASS_700 if not is_leave else SacredPalette.INK_600
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.027, 0.020, 0.012, 0.55) if not is_leave else Color(0.078, 0.078, 0.11, 0.40)
	base_style.border_color = border_col
	base_style.set_border_width_all(1)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.09, 0.068, 0.040, 0.60) if not is_leave else Color(0.10, 0.10, 0.16, 0.55)
	hover_style.border_color = SacredPalette.BRASS_400 if not is_leave else SacredPalette.BONE_400
	hover_style.set_border_width_all(1)

	var accent_col: Color = SacredPalette.BRASS_400 if not is_leave else SacredPalette.BONE_400

	var card := Panel.new()
	card.add_theme_stylebox_override("panel", base_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 100.0)
	if is_disabled:
		card.modulate.a = 0.45
	row.add_child(card)

	var accent := ColorRect.new()
	accent.color = accent_col
	accent.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	accent.offset_right = 3.0
	accent.modulate.a = 0.0
	card.add_child(accent)

	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(inner)

	var num_box := CenterContainer.new()
	num_box.custom_minimum_size = Vector2(70.0, 0.0)
	num_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(num_box)

	var italic_font := load("res://assets/fonts/IMFellEnglish-Italic.ttf") as Font
	var num_lbl := Label.new()
	num_lbl.text = ch["roman"]
	if italic_font:
		num_lbl.add_theme_font_override("font", italic_font)
	num_lbl.add_theme_font_size_override("font_size", 30)
	num_lbl.add_theme_color_override("font_color",
		SacredPalette.BRASS_300 if not is_leave else SacredPalette.BONE_400)
	num_box.add_child(num_lbl)

	var vdiv := ColorRect.new()
	vdiv.color = border_col
	vdiv.custom_minimum_size = Vector2(1.0, 0.0)
	vdiv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(vdiv)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(content)

	var sp_top := Control.new()
	sp_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sp_top)

	var reg_font := load("res://assets/fonts/IMFellEnglish-Regular.ttf") as Font
	var verb_lbl := Label.new()
	verb_lbl.text = ch["label"]
	if reg_font:
		verb_lbl.add_theme_font_override("font", reg_font)
	verb_lbl.add_theme_font_size_override("font_size", 20)
	verb_lbl.add_theme_color_override("font_color",
		SacredPalette.BONE_100 if not is_leave else SacredPalette.BONE_300)
	verb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verb_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(verb_lbl)
	LabelUtils.fit_text(verb_lbl, 20, 13)

	var tags: Array = ch["tags"]
	if not tags.is_empty():
		var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
		var tag_row := HBoxContainer.new()
		tag_row.add_theme_constant_override("separation", 6)
		content.add_child(tag_row)
		for tag in tags:
			var t := Label.new()
			t.text = tag["text"]
			if mono_font:
				t.add_theme_font_override("font", mono_font)
			t.add_theme_font_size_override("font_size", 10)
			t.add_theme_color_override("font_color", tag["color"] as Color)
			var ts := StyleBoxFlat.new()
			ts.bg_color = Color(0.027, 0.020, 0.012, 0.70)
			ts.border_color = tag["color"] as Color
			ts.set_border_width_all(1)
			ts.content_margin_left = 8.0; ts.content_margin_right = 8.0
			ts.content_margin_top = 3.0;  ts.content_margin_bottom = 3.0
			t.add_theme_stylebox_override("normal", ts)
			tag_row.add_child(t)

	var sp_bot := Control.new()
	sp_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sp_bot)

	if is_disabled:
		return

	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(btn)

	var cap_card   := card
	var cap_accent := accent
	btn.mouse_entered.connect(func():
		cap_card.add_theme_stylebox_override("panel", hover_style)
		var tw := cap_card.create_tween()
		tw.tween_property(cap_accent, "modulate:a", 1.0, 0.18)
	)
	btn.mouse_exited.connect(func():
		cap_card.add_theme_stylebox_override("panel", base_style)
		var tw := cap_card.create_tween()
		tw.tween_property(cap_accent, "modulate:a", 0.0, 0.18)
	)
	btn.pressed.connect(func():
		_play_close(ch["action"])
	)

func _play_open() -> void:
	if _popup_tween:
		_popup_tween.kill()
	modulate.a = 0.0
	_frame.scale = Vector2(0.97, 0.97)
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(self, "modulate:a", 1.0, 0.30)
	_popup_tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.28)

func _play_close(callback: Callable) -> void:
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(self, "modulate:a", 0.0, 0.22)
	_popup_tween.tween_property(_frame, "scale", Vector2(0.97, 0.97), 0.20)
	_popup_tween.chain().tween_callback(callback)

func _has_upgradeable_cards() -> bool:
	var all: Array = DeckManager.draw_pile.duplicate()
	all.append_array(DeckManager.discard_pile)
	all.append_array(DeckManager.hand)
	for card in all:
		if card.upgrade_level < card.max_upgrade_level():
			return true
	return false

func _get_tm() -> Object:
	if Engine.has_singleton("TeamManager"):
		return Engine.get_singleton("TeamManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("TeamManager")
	return null

func _on_heal_pressed() -> void:
	var tm := _get_tm()
	if tm:
		for hero in tm.heroes:
			tm.heal(hero.hero_id, int(hero.max_hp * 0.3))
	GameManager.complete_rest()

func _on_upgrade_pressed() -> void:
	GameManager.enter_card_upgrade()

func _on_leave_pressed() -> void:
	GameManager.complete_rest()
