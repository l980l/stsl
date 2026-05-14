# scenes/event/event_scene.gd
extends Node2D


const ROMAN      := ["I", "II", "III", "IV", "V"]
const FRAME_L    := 80.0
const FRAME_T    := 80.0
const FRAME_W    := 1920.0 - FRAME_L * 2.0   # 1760
const FRAME_H    := 1080.0 - FRAME_T - 40.0  # 960
const ILLO_H     := 680.0
const NARR_H     := 270.0
const CHOICE_PAD := 24.0

const CARD_REMOVAL_OVERLAY := preload("res://scenes/components/card_removal_overlay.gd")

var _frame: Panel = null
var _popup_tween: Tween = null
var _pending_card_removal: bool = false

func _ready() -> void:
	var event: Resource = GameManager.pending_event
	if event == null:
		GameManager._request_scene("res://scenes/map/map_scene.tscn")
		return
	_build_ui(event)
	_play_open()
	AudioManager.play_bgm_dynamic("event", event.bgm_type)

func _build_ui(event: Resource) -> void:
	($BG as ColorRect).color = SacredPalette.INK_1000

	# 상단 블룸
	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920.0, 560.0)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

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

	# 이벤트 일러스트 (event_name 키 → ID 추출: "event.act1.golden_chest.name" → "golden_chest")
	var parts: PackedStringArray = event.event_name.split(".")
	if parts.size() >= 3:
		var illust_path := "res://assets/art/events/%s.png" % parts[2]
		if ResourceLoader.exists(illust_path):
			var illo_tex := TextureRect.new()
			illo_tex.texture = load(illust_path)
			illo_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			illo_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			illo_tex.size = Vector2(FRAME_W, ILLO_H)
			illo_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			illo.add_child(illo_tex)

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
	hdr.text = tr("ui.event.choose_header")
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
	var enabled: bool = _is_choice_available(choice)

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
	if not enabled:
		card.modulate = Color(0.55, 0.55, 0.55, 1.0)
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

	# 조건 미충족 hint
	if not enabled and choice.required_hero_id != "":
		var hint_lbl := Label.new()
		hint_lbl.text = tr("ui.event.requires_hero") % tr("hero." + choice.required_hero_id + ".name")
		hint_lbl.add_theme_color_override("font_color", SacredPalette.BLOOD_400)
		hint_lbl.add_theme_font_size_override("font_size", 12)
		content.add_child(hint_lbl)

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

	# 투명 버튼 오버레이 (호버 + 클릭) — 조건 미충족 시 비활성
	var btn := Button.new()
	btn.flat = true
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = not enabled
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(btn)

	if enabled:
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

func _is_choice_available(choice: Resource) -> bool:
	if choice.required_hero_id != "":
		var found: bool = false
		for h in TeamManager.heroes:
			if h.hero_id == choice.required_hero_id:
				found = true
				break
		if not found:
			return false
	if choice.cost_gold > 0 and GameManager.gold < choice.cost_gold:
		return false
	return true

# 번역 키에 %d가 없을 때(번역 미로드 등) % 연산자 크래시를 막는 가드
func _fmt(key: String, arg) -> String:
	var t := tr(key)
	return (t % arg) if "%" in t else t

# 선택지의 효과를 태그 배열로 변환. 모든 선택지가 일관된 태그를 갖는다.
# - 비용은 확률과 무관하게 항상 표시
# - 확률 분기는 "N% → 효과" 형태. 같은 분기에서 함께 일어나는 효과는 한 태그로 묶는다
#   (예: 스핑크스 70% → 카드 제거 / +30코인 — "70%"가 두 번 반복되지 않도록)
# - 효과·비용이 전혀 없으면 "효과 없음" 태그
func _cost_tags(choice: Resource) -> Array:
	var tags: Array = []
	# 비용 — 확률과 무관하게 항상 발생
	if choice.cost_gold > 0:
		tags.append({"text": _fmt("ui.event.tag.cost_gold", choice.cost_gold), "color": SacredPalette.BONE_300})
	if choice.cost_hp > 0:
		tags.append({"text": _fmt("ui.event.tag.cost_hp", choice.cost_hp), "color": SacredPalette.BLOOD_400})

	if choice.success_chance > 0 and choice.success_chance < 100:
		# 확률 분기 — 성공 효과들은 한 태그로 묶고, 실패(alt) 분기는 별도 태그
		var p_succ: String = "%d%% → " % choice.success_chance
		var p_fail: String = "%d%% → " % (100 - choice.success_chance)
		_append_success_tag(tags, choice, p_succ)
		# 확률 실패(alt) 분기 — 여기서 일어나는 카드 제거는 강제된 손해(페널티)
		_append_effect_tag(tags, choice.alt_effect_type, choice.alt_value, "", choice, p_fail, true)
	else:
		# 확률 없음 — 효과를 그대로
		_append_effect_tag(tags, choice.effect_type, choice.value, choice.card_id, choice, "")
		if choice.secondary_effect_type != EventChoiceResource.EffectType.NONE:
			_append_effect_tag(tags, choice.secondary_effect_type, choice.secondary_value, "", choice, "")
		# 효과도 비용도 없는 선택지 — "효과 없음"으로 명시
		if choice.effect_type == EventChoiceResource.EffectType.NONE \
				and choice.secondary_effect_type == EventChoiceResource.EffectType.NONE \
				and choice.cost_gold == 0 and choice.cost_hp == 0:
			tags.append({"text": tr("ui.event.tag.none"), "color": SacredPalette.BONE_300})
	return tags

# 확률 성공 분기 — effect (+secondary)를 한 태그로 묶는다.
# 성공 분기 효과는 모두 보상(플레이어가 선택지로 의도한 결과)이므로 보상색.
func _append_success_tag(tags: Array, choice: Resource, prefix: String) -> void:
	var parts: Array = [_effect_text(choice.effect_type, choice.value, choice.card_id, choice)]
	if choice.secondary_effect_type != EventChoiceResource.EffectType.NONE:
		parts.append(_effect_text(choice.secondary_effect_type, choice.secondary_value, "", choice))
	tags.append({"text": prefix + " / ".join(parts), "color": SacredPalette.BRASS_300})

# 효과 1개의 태그 텍스트(번역 적용)만 반환. 색상·prefix는 호출자가 결정.
# is_penalty: 페널티 맥락이면 REMOVE_CARD를 "무작위 카드 1장 제거"로 표시 (보상은 "카드 제거").
func _effect_text(etype: int, value: int, card_id: String, choice: Resource, is_penalty: bool = false) -> String:
	match etype:
		EventChoiceResource.EffectType.NONE:
			return tr("ui.event.tag.none")
		EventChoiceResource.EffectType.GOLD:
			return _fmt("ui.event.tag.gain_gold", value)
		EventChoiceResource.EffectType.HEAL:
			return _fmt("ui.event.tag.gain_hp", value)
		EventChoiceResource.EffectType.DRAW_UP:
			return tr("ui.event.tag.draw_up")
		EventChoiceResource.EffectType.REMOVE_CARD:
			return tr("ui.event.tag.remove_card_random") if is_penalty else tr("ui.event.tag.remove_card")
		EventChoiceResource.EffectType.ADD_RELIC:
			return tr("ui.event.tag.add_relic")
		EventChoiceResource.EffectType.ADD_RELIC_GAMBLE:
			return tr("ui.event.tag.relic_gamble")
		EventChoiceResource.EffectType.ADD_HERO:
			return tr("ui.event.tag.add_hero")
		EventChoiceResource.EffectType.ADD_CARD:
			if card_id != "" and ResourceLoader.exists(card_id):
				var card_res: Resource = load(card_id)
				if card_res and "card_name" in card_res:
					return _fmt("ui.event.tag.add_card_named", tr(card_res.card_name))
			return tr("ui.event.tag.add_card")
		EventChoiceResource.EffectType.TRIGGER_BATTLE:
			return tr("ui.event.tag.battle_elite" if choice.encounter_tier >= 1 else "ui.event.tag.battle")
	return ""

# 효과별 태그 색상. REMOVE_CARD만 맥락(보상/페널티)에 따라 달라진다.
func _effect_color(etype: int, is_penalty: bool) -> Color:
	match etype:
		EventChoiceResource.EffectType.NONE:
			return SacredPalette.BONE_300
		EventChoiceResource.EffectType.ADD_RELIC_GAMBLE:
			return SacredPalette.BONE_300
		EventChoiceResource.EffectType.TRIGGER_BATTLE:
			return SacredPalette.BLOOD_400
		EventChoiceResource.EffectType.REMOVE_CARD:
			# 의도한 덱 압축이면 보상색, 확률 실패로 강제된 카드 분실이면 페널티색
			return SacredPalette.BLOOD_400 if is_penalty else SacredPalette.BRASS_300
		_:
			return SacredPalette.BRASS_300

# 효과 1개를 태그로 추가. prefix: 확률 "N% → " 또는 보상 화살표 "→ ".
# is_penalty: 확률 실패(alt) 분기처럼 강제된 손해인지 (REMOVE_CARD 색상에만 영향).
func _append_effect_tag(tags: Array, etype: int, value: int, card_id: String, choice: Resource, prefix: String, is_penalty: bool = false) -> void:
	# NONE은 prefix(확률 실패 분기 등)가 있을 때만 "효과 없음"을 표시
	if etype == EventChoiceResource.EffectType.NONE:
		if prefix != "":
			tags.append({"text": prefix + tr("ui.event.tag.none"), "color": SacredPalette.BONE_300})
		return
	tags.append({
		"text": prefix + _effect_text(etype, value, card_id, choice, is_penalty),
		"color": _effect_color(etype, is_penalty),
	})
	# 전투 보상은 "→ 효과"로 이어 붙임
	if etype == EventChoiceResource.EffectType.TRIGGER_BATTLE \
			and choice.reward_effect_type != EventChoiceResource.EffectType.NONE:
		_append_effect_tag(tags, choice.reward_effect_type, choice.reward_value, "", choice, "→ ")

func _play_open() -> void:
	if _popup_tween:
		_popup_tween.kill()
	_frame.scale = Vector2(0.97, 0.97)
	_popup_tween = create_tween()
	_popup_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_popup_tween.tween_property(_frame, "scale", Vector2(1.0, 1.0), 0.28)

func _play_close(callback: Callable) -> void:
	if _popup_tween:
		_popup_tween.kill()
	_popup_tween = create_tween()
	_popup_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_popup_tween.tween_property(_frame, "scale", Vector2(0.97, 0.97), 0.20)
	callback.call()

# _apply_choice 반환: 0=완료(complete_event 호출), 1=전투 진입, 2=카드 제거 패널 대기
const _CHOICE_DONE := 0
const _CHOICE_BATTLE := 1
const _CHOICE_CARD_REMOVAL := 2

func _on_choice_selected(choice: Resource) -> void:
	_play_close(func():
		var result := _apply_choice(choice)
		if result == _CHOICE_BATTLE:
			pass  # 전투 진입 — complete_event는 전투 종료 후
		elif result == _CHOICE_CARD_REMOVAL:
			_open_card_removal()  # 패널 confirmed 콜백이 complete_event 책임
		else:
			GameManager.complete_event()
	)

func _apply_choice(choice: Resource) -> int:
	_pending_card_removal = false

	# 1) 비용 선처리 — gold 부족 시 효과 자체가 무효
	if choice.cost_gold > 0 and not GameManager.spend_gold(choice.cost_gold):
		return _CHOICE_DONE
	if choice.cost_hp > 0:
		for hero in TeamManager.heroes:
			TeamManager.take_damage(hero.hero_id, choice.cost_hp)

	# 2) TRIGGER_BATTLE은 별도 — pending_event를 유지한 채 전투 진입
	if choice.effect_type == EventChoiceResource.EffectType.TRIGGER_BATTLE:
		var reward: Dictionary = {
			"effect_type": choice.reward_effect_type,
			"value": choice.reward_value,
			"card_id": choice.card_id,
		}
		GameManager.start_event_battle(choice.encounter_tier, reward)
		return _CHOICE_BATTLE

	# 3) 확률 효과 — success_chance 0/100 외에는 dice 굴림
	if choice.success_chance > 0 and choice.success_chance < 100:
		if randi() % 100 < choice.success_chance:
			_apply_single_effect(choice.effect_type, choice.value, choice.card_id)
			# 성공 시 보조 효과도 적용 (예: 스핑크스 — REMOVE_CARD + GOLD)
			if choice.secondary_effect_type != EventChoiceResource.EffectType.NONE:
				_apply_single_effect(choice.secondary_effect_type, choice.secondary_value, "")
		else:
			# 실패 분기의 alt가 TRIGGER_BATTLE이면 전투 진입
			if choice.alt_effect_type == EventChoiceResource.EffectType.TRIGGER_BATTLE:
				var reward_alt: Dictionary = {
					"effect_type": choice.reward_effect_type,
					"value": choice.reward_value,
					"card_id": choice.card_id,
				}
				GameManager.start_event_battle(choice.encounter_tier, reward_alt)
				return _CHOICE_BATTLE
			# 확률 실패(alt) 분기 — 강제된 페널티
			_apply_single_effect(choice.alt_effect_type, choice.alt_value, "", true)
		return _CHOICE_CARD_REMOVAL if _pending_card_removal else _CHOICE_DONE

	# 4) 일반 + MULTI
	_apply_single_effect(choice.effect_type, choice.value, choice.card_id)
	if choice.secondary_effect_type != EventChoiceResource.EffectType.NONE:
		_apply_single_effect(choice.secondary_effect_type, choice.secondary_value, "")
	return _CHOICE_CARD_REMOVAL if _pending_card_removal else _CHOICE_DONE

# 카드 제거 패널 — 플레이어가 제거할 카드를 직접 선택 (취소 불가).
# 패널의 confirmed 콜백이 실제 제거 + complete_event를 책임진다.
func _open_card_removal() -> void:
	var deck: Array = DeckManager.get_full_deck()
	if deck.is_empty():
		GameManager.complete_event()
		return
	var overlay = CARD_REMOVAL_OVERLAY.new()
	add_child(overlay)
	overlay.confirmed.connect(func(card: Resource) -> void:
		DeckManager.remove_from_deck(card)
		GameManager.complete_event()
	)
	overlay.open(deck, {
		"cancelable":   false,
		"title_text":   tr("ui.event.remove_prompt"),
		"confirm_text": tr("ui.shop.btn_confirm_remove"),
	})

# is_penalty: 확률 실패(alt) 분기처럼 강제된 효과인지.
#   REMOVE_CARD가 페널티면 무작위 즉시 제거, 보상이면 플레이어가 카드 선택 패널에서 고른다.
func _apply_single_effect(etype: int, value: int, card_id: String, is_penalty: bool = false) -> void:
	match etype:
		EventChoiceResource.EffectType.GOLD:
			GameManager.add_gold(value)
		EventChoiceResource.EffectType.HEAL:
			for hero in TeamManager.heroes:
				TeamManager.heal(hero.hero_id, value)
		EventChoiceResource.EffectType.DRAW_UP:
			var _RelicData := load("res://resources/relics/relics.gd")
			for _i in range(value):
				GameManager.add_relic(_RelicData.sacred_scroll())
		EventChoiceResource.EffectType.REMOVE_CARD:
			if is_penalty:
				# 페널티 — 무작위 카드 1장 즉시 제거 (플레이어 선택권 없음)
				DeckManager.remove_random_card()
			else:
				# 보상 — _open_card_removal의 카드 선택 패널에서 처리, 여기선 대기 표시만
				_pending_card_removal = true
		EventChoiceResource.EffectType.ADD_RELIC:
			var relic: Resource = GameManager.get_random_relic()
			if relic:
				GameManager.add_relic(relic)
		EventChoiceResource.EffectType.ADD_RELIC_GAMBLE:
			var rg: Resource
			if randf() < 0.5:
				rg = GameManager.get_random_relic()
			else:
				rg = GameManager.get_random_cursed_relic()
			if rg:
				GameManager.add_relic(rg)
		EventChoiceResource.EffectType.ADD_HERO:
			GameManager.recruit_random_hero()
		EventChoiceResource.EffectType.ADD_CARD:
			if card_id != "" and ResourceLoader.exists(card_id):
				var card_res: Resource = load(card_id)
				if card_res:
					DeckManager.add_card_to_deck(card_res)
		EventChoiceResource.EffectType.NONE:
			pass
