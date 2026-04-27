# scenes/event/event_scene.gd
extends Node2D

const EventChoiceResource = preload("res://resources/event_choice_resource.gd")

const ROMAN      := ["I", "II", "III", "IV", "V"]
const FRAME_L    := 80.0
const FRAME_T    := 80.0
const FRAME_W    := 1920.0 - FRAME_L * 2.0   # 1760
const FRAME_H    := 1080.0 - FRAME_T - 40.0  # 960
const ILLO_H     := 680.0
const NARR_H     := 270.0
const CHOICE_PAD := 24.0

var _frame: Panel = null
var _popup_tween: Tween = null

func _ready() -> void:
	var event: Resource = GameManager.pending_event
	if event == null:
		GameManager._request_scene("res://scenes/map/map_scene.tscn")
		return
	_build_ui(event)
	_play_open()

func _build_ui(event: Resource) -> void:
	($BG as ColorRect).color = SacredPalette.INK_1000

	# 상단 블룸
	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920.0, 560.0)
	add_child(bloom)

	# 이벤트 프레임
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

	_build_illo(frame, event)
	_build_choices(frame, event)

func _build_illo(frame: Panel, event: Resource) -> void:
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

	# 이벤트 플레이트 배지 (상단 중앙)
	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var plate_lbl := Label.new()
	plate_lbl.text = "— Event · " + tr(event.event_name) + " —"
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

	# 하단 비네트 — narration 영역 고정 배경
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

	# Narration 블록 (illo 하단 절대 위치)
	var pad_x := 120.0
	var narr := VBoxContainer.new()
	narr.add_theme_constant_override("separation", 12)
	narr.position = Vector2(pad_x, ILLO_H - NARR_H - 20.0)
	narr.size = Vector2(FRAME_W - pad_x * 2.0, NARR_H)
	illo.add_child(narr)

	# 이벤트 타이틀
	var title_lbl := Label.new()
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.text = tr(event.event_name)
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

	# 설명 텍스트
	var desc_lbl := Label.new()
	desc_lbl.text = tr(event.description)
	desc_lbl.add_theme_color_override("font_color", SacredPalette.BONE_200)
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	narr.add_child(desc_lbl)
	LabelUtils.fit_text(desc_lbl, 20, 13)

func _build_choices(frame: Panel, event: Resource) -> void:
	# illo 하단 구분선
	var sep := TextureRect.new()
	sep.texture = SacredTheme.make_center_bright_h_tex()
	sep.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sep.stretch_mode = TextureRect.STRETCH_SCALE
	sep.position = Vector2(0.0, ILLO_H)
	sep.size = Vector2(FRAME_W, 1.0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(sep)

	# 선택 영역 전체 VBox
	var area := VBoxContainer.new()
	area.position = Vector2(56.0, ILLO_H + CHOICE_PAD)
	area.size = Vector2(FRAME_W - 112.0, FRAME_H - ILLO_H - CHOICE_PAD - 34.0)
	area.add_theme_constant_override("separation", 12)
	frame.add_child(area)

	# "— 선택하라 —" 헤더
	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var hdr := Label.new()
	hdr.text = "— 선택하라 —"
	if mono_font:
		hdr.add_theme_font_override("font", mono_font)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", SacredPalette.BRASS_400)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	area.add_child(hdr)

	# 선택지 카드 행
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.add_child(row)

	for i in event.choices.size():
		_build_choice_card(row, i, event.choices[i])

func _build_choice_card(row: HBoxContainer, idx: int, choice: Resource) -> void:
	var base_style := StyleBoxFlat.new()
	base_style.bg_color = Color(0.027, 0.020, 0.012, 0.55)
	base_style.border_color = SacredPalette.BRASS_700
	base_style.set_border_width_all(1)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.09, 0.068, 0.040, 0.60)
	hover_style.border_color = SacredPalette.BRASS_400
	hover_style.set_border_width_all(1)

	var card := Panel.new()
	card.add_theme_stylebox_override("panel", base_style)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, 100.0)
	row.add_child(card)

	# 좌측 액센트 바 (3px, 호버 시 페이드인)
	var accent := ColorRect.new()
	accent.color = SacredPalette.BRASS_400
	accent.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	accent.offset_right = 3.0
	accent.modulate.a = 0.0
	card.add_child(accent)

	# Inner: [번호 | 세로선 | 내용 with margin]
	var inner := HBoxContainer.new()
	inner.add_theme_constant_override("separation", 0)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(inner)

	# 로마 숫자 영역
	var num_box := CenterContainer.new()
	num_box.custom_minimum_size = Vector2(70.0, 0.0)
	num_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(num_box)

	var italic_font := load("res://assets/fonts/IMFellEnglish-Italic.ttf") as Font
	var num_lbl := Label.new()
	num_lbl.text = ROMAN[idx] if idx < ROMAN.size() else str(idx + 1)
	if italic_font:
		num_lbl.add_theme_font_override("font", italic_font)
	num_lbl.add_theme_font_size_override("font_size", 30)
	num_lbl.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	num_box.add_child(num_lbl)

	# 세로 구분선
	var vdiv := ColorRect.new()
	vdiv.color = SacredPalette.BRASS_700
	vdiv.custom_minimum_size = Vector2(1.0, 0.0)
	vdiv.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.add_child(vdiv)

	# 내용 영역 (MarginContainer → VBox)
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

	# 선택지 텍스트
	var reg_font := load("res://assets/fonts/IMFellEnglish-Regular.ttf") as Font
	var verb_lbl := Label.new()
	verb_lbl.text = tr(choice.label)
	if reg_font:
		verb_lbl.add_theme_font_override("font", reg_font)
	verb_lbl.add_theme_font_size_override("font_size", 20)
	verb_lbl.add_theme_color_override("font_color", SacredPalette.BONE_100)
	verb_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	verb_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(verb_lbl)
	LabelUtils.fit_text(verb_lbl, 20, 13)

	# 비용 태그
	var tags := _cost_tags(choice)
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
			ts.content_margin_left = 8.0
			ts.content_margin_right = 8.0
			ts.content_margin_top = 3.0
			ts.content_margin_bottom = 3.0
			t.add_theme_stylebox_override("normal", ts)
			tag_row.add_child(t)

	var sp_bot := Control.new()
	sp_bot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(sp_bot)

	# 투명 버튼 오버레이 (호버 + 클릭)
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

	var cap_card  := card
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
	btn.pressed.connect(_on_choice_selected.bind(choice))

func _cost_tags(choice: Resource) -> Array:
	var tags: Array = []
	if choice.cost_gold > 0:
		tags.append({"text": "−%d 코인" % choice.cost_gold, "color": SacredPalette.BONE_300})
	if choice.cost_hp > 0:
		tags.append({"text": "−%d HP" % choice.cost_hp, "color": SacredPalette.BLOOD_400})
	match choice.effect_type:
		EventChoiceResource.EffectType.GOLD:
			tags.append({"text": "+%d 코인" % choice.value, "color": SacredPalette.BRASS_300})
		EventChoiceResource.EffectType.HEAL:
			tags.append({"text": "+%d HP" % choice.value, "color": SacredPalette.BRASS_300})
		EventChoiceResource.EffectType.DRAW_UP:
			tags.append({"text": "드로우 +%d" % choice.value, "color": SacredPalette.BRASS_300})
		EventChoiceResource.EffectType.REMOVE_CARD:
			tags.append({"text": "카드 제거", "color": SacredPalette.BONE_300})
		EventChoiceResource.EffectType.ADD_RELIC:
			tags.append({"text": "렐릭 획득", "color": SacredPalette.BRASS_300})
		EventChoiceResource.EffectType.ADD_RELIC_GAMBLE:
			tags.append({"text": "렐릭 도박", "color": SacredPalette.BONE_300})
		EventChoiceResource.EffectType.ADD_HERO:
			tags.append({"text": "영웅 합류", "color": SacredPalette.BRASS_300})
	return tags

func _play_open() -> void:
	if _popup_tween:
		_popup_tween.kill()
	_frame.modulate.a = 0.0
	_frame.scale = Vector2(0.97, 0.97)
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_frame, "modulate:a", 1.0, 0.30)
	_popup_tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.28)

func _play_close(callback: Callable) -> void:
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween().set_parallel(true)
	_popup_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(_frame, "modulate:a", 0.0, 0.20)
	_popup_tween.tween_property(_frame, "scale", Vector2(0.97, 0.97), 0.20)
	_popup_tween.chain().tween_callback(callback)

func _on_choice_selected(choice: Resource) -> void:
	_play_close(func():
		_apply_choice(choice)
		GameManager.complete_event()
	)

func _apply_choice(choice: Resource) -> void:
	match choice.effect_type:
		EventChoiceResource.EffectType.GOLD:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			GameManager.add_gold(choice.value)
		EventChoiceResource.EffectType.HEAL:
			if GameManager.spend_gold(choice.cost_gold):
				for hero in TeamManager.heroes:
					TeamManager.heal(hero.hero_id, choice.value)
		EventChoiceResource.EffectType.DRAW_UP:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			DeckManager.base_draw_count += choice.value
		EventChoiceResource.EffectType.REMOVE_CARD:
			if not DeckManager.draw_pile.is_empty():
				DeckManager.draw_pile.remove_at(
					randi() % DeckManager.draw_pile.size())
		EventChoiceResource.EffectType.ADD_RELIC:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			var relic: Resource = GameManager.get_random_relic()
			if relic:
				GameManager.add_relic(relic)
		EventChoiceResource.EffectType.ADD_RELIC_GAMBLE:
			var relic: Resource
			if randf() < 0.5:
				relic = GameManager.get_random_relic()
			else:
				relic = GameManager.get_random_cursed_relic()
			if relic:
				GameManager.add_relic(relic)
		EventChoiceResource.EffectType.ADD_HERO:
			GameManager.recruit_random_hero()
		EventChoiceResource.EffectType.NONE:
			pass
