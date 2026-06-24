# scenes/ui/credits_overlay.gd
# 메인 메뉴 전용 크레딧 오버레이 — 사용 애셋·AI 도구·영감받은 작품·고증 면책 표시.
# 코드로 직접 빌드 (settings_overlay 의 패널/팝업 패턴을 따름). 닫으면 queue_free.
extends CanvasLayer

const PANEL_W := 720.0
const PANEL_H := 824.0

# 고유 명사 — 번역하지 않고 그대로 노출 (사이트/도구/작품명/엔진/폰트)
const _SOUND_SOURCE := "Sound Effect Lab — soundeffect-lab.info"
const _AI_BGM       := "ACE-Step 1.5"
const _AI_ILLUST    := "Nano Banana"
const _AI_IMGEDIT   := "Qwen Image Edit"
const _AI_FRAME     := "Z-Image Turbo"
const _AI_VFXUI     := "Claude"
const _AI_TRANSLATE := "Claude & Gemini"
const _ENGINE       := "Godot Engine 4.6.2"
# 번들 폰트 — 모두 SIL Open Font License (Latin·KO·JA·ZH·EL, 변형 통합 표기)
const _FONTS := "Cinzel, Cinzel Decorative, IM Fell English, Inter, Space Mono, Pretendard, Hahmlet, Gowun Batang, D2Coding, Noto Sans JP, Hina Mincho, Zen Old Mincho, HackGen, Noto Sans SC, Noto Sans TC, Source Han Serif, LXGW WenKai, Sarasa Mono, Cormorant Garamond, EB Garamond, JetBrains Mono — SIL OFL"
# [작품명(고유명사·비번역), 영감받은 부분 i18n 키]
const _INSPIRED := [
	["Slay the Spire", "ui.credits.inspired.sts"],
	["Hades", "ui.credits.inspired.hades"],
	["Clair Obscur: Expedition 33", "ui.credits.inspired.expedition33"],
	["Persona", "ui.credits.inspired.persona"],
	["Metaphor: ReFantazio", "ui.credits.inspired.metaphor"],
	["Civilization", "ui.credits.inspired.civ"],
]

var _panel: Panel = null
var _popup_tween: Tween = null
var _content_w: float = PANEL_W - 96.0

func _ready() -> void:
	layer = 60
	_build()
	open()

func _build() -> void:
	var P := SacredPalette

	# 딤 배경 — 클릭 시 닫기
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			close())
	add_child(dim)

	# 중앙 패널
	_panel = Panel.new()
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -PANEL_W / 2.0
	_panel.offset_right = PANEL_W / 2.0
	_panel.offset_top = -PANEL_H / 2.0
	_panel.offset_bottom = PANEL_H / 2.0
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var ps := StyleBoxFlat.new()
	ps.bg_color = P.INK_900
	ps.border_color = P.BRASS_500
	ps.set_border_width_all(2)
	_panel.add_theme_stylebox_override("panel", ps)
	add_child(_panel)
	SacredTheme.add_corner_brackets(_panel)

	# 상단 골든 페이드
	var fade_hl := TextureRect.new()
	fade_hl.texture = SacredTheme.make_top_fade_tex()
	fade_hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade_hl.stretch_mode = TextureRect.STRETCH_SCALE
	fade_hl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	fade_hl.offset_bottom = 80.0
	fade_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(fade_hl)

	# 타이틀
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.text = tr("ui.credits.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.offset_left = 0.0
	title.offset_top = 26.0
	title.offset_right = PANEL_W
	title.offset_bottom = 70.0
	_panel.add_child(title)

	# 닫기 ✕
	var btn_close := Button.new()
	btn_close.theme_type_variation = "IconButton"
	btn_close.text = "✕"
	btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_close.add_theme_font_size_override("font_size", 20)
	btn_close.custom_minimum_size = Vector2(40, 40)
	btn_close.offset_left = PANEL_W - 52.0
	btn_close.offset_top = 14.0
	btn_close.offset_right = PANEL_W - 12.0
	btn_close.offset_bottom = 54.0
	btn_close.pressed.connect(close)
	_panel.add_child(btn_close)

	# 타이틀 하단 구분선
	var line := TextureRect.new()
	line.texture = SacredTheme.make_center_bright_h_tex()
	line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.offset_left = 48.0
	line.offset_top = 84.0
	line.offset_right = PANEL_W - 48.0
	line.offset_bottom = 85.0
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(line)

	# 스크롤 컨텐츠
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.offset_left = 40.0
	scroll.offset_top = 102.0
	scroll.offset_right = PANEL_W - 24.0
	scroll.offset_bottom = PANEL_H - 78.0
	_panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(vbox)

	# 섹션들 — 고증 → 영감받은 작품 → 에셋(폰트·효과음) → AI 도구 → 게임 엔진
	_add_section(vbox, tr("ui.credits.section.disclaimer"), [tr("ui.credits.disclaimer.body")])
	_add_inspired(vbox, tr("ui.credits.section.inspired"))
	_add_section(vbox, tr("ui.credits.section.assets"), [
		"%s — %s" % [tr("ui.credits.assets.fonts"), _FONTS],
		"%s — %s" % [tr("ui.credits.section.sound"), _SOUND_SOURCE],
	])
	_add_section(vbox, tr("ui.credits.section.ai"), [
		"%s — %s" % [tr("ui.credits.ai.bgm"), _AI_BGM],
		"%s — %s" % [tr("ui.credits.ai.illust"), _AI_ILLUST],
		"%s — %s" % [tr("ui.credits.ai.imgedit"), _AI_IMGEDIT],
		"%s — %s" % [tr("ui.credits.ai.frame"), _AI_FRAME],
		"%s — %s" % [tr("ui.credits.ai.vfxui"), _AI_VFXUI],
		"%s — %s" % [tr("ui.credits.ai.translation"), _AI_TRANSLATE],
	])
	_add_section(vbox, tr("ui.credits.section.engine"), [_ENGINE])

	# 하단 뒤로 버튼
	var mono := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var btn_back := Button.new()
	btn_back.theme_type_variation = "VowButton"
	btn_back.text = tr("ui.credits.back").to_upper()
	btn_back.add_theme_font_override("font", mono)
	btn_back.add_theme_font_size_override("font_size", 12)
	btn_back.offset_left = PANEL_W / 2.0 - 110.0
	btn_back.offset_right = PANEL_W / 2.0 + 110.0
	btn_back.offset_top = PANEL_H - 62.0
	btn_back.offset_bottom = PANEL_H - 22.0
	btn_back.pressed.connect(close)
	_panel.add_child(btn_back)
	SacredTheme.animate_button(btn_back)

# 영감 섹션 — 작품명(BRASS) + 영감받은 부분(BONE, 들여쓰기) 블록 반복
func _add_inspired(parent: VBoxContainer, header: String) -> void:
	var P := SacredPalette
	var hd := Label.new()
	hd.theme_type_variation = "EyebrowLabel"
	hd.text = header
	hd.add_theme_color_override("font_color", P.BRASS_300)
	hd.add_theme_font_size_override("font_size", 14)
	hd.custom_minimum_size = Vector2(_content_w, 0)
	parent.add_child(hd)

	for g in _INSPIRED:
		var ttl := Label.new()
		ttl.theme_type_variation = "SubLabel"
		ttl.text = g[0]
		ttl.add_theme_color_override("font_color", P.BONE_100)
		ttl.custom_minimum_size = Vector2(_content_w, 0)
		parent.add_child(ttl)

		var desc := Label.new()
		desc.theme_type_variation = "SubLabel"
		desc.text = tr(g[1])
		desc.add_theme_color_override("font_color", P.BONE_400)
		desc.add_theme_font_size_override("font_size", 12)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(_content_w - 16.0, 0)
		desc.offset_left = 16.0  # 살짝 들여쓰기 효과 (VBox 내 무시되면 무해)
		parent.add_child(desc)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)

# 섹션 = 머리글(BRASS) + 본문 줄들(BONE, 자동 줄바꿈)
func _add_section(parent: VBoxContainer, header: String, lines: Array) -> void:
	var P := SacredPalette
	var hd := Label.new()
	hd.theme_type_variation = "EyebrowLabel"
	hd.text = header
	hd.add_theme_color_override("font_color", P.BRASS_300)
	hd.add_theme_font_size_override("font_size", 14)
	hd.custom_minimum_size = Vector2(_content_w, 0)
	parent.add_child(hd)

	for ln in lines:
		var body := Label.new()
		body.theme_type_variation = "SubLabel"
		body.text = ln
		body.add_theme_color_override("font_color", P.BONE_100)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(_content_w, 0)
		parent.add_child(body)

	# 섹션 간 여백 스페이서
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)

func open() -> void:
	if _popup_tween:
		_popup_tween.kill()
	_panel.pivot_offset = Vector2(PANEL_W, PANEL_H) / 2.0
	_panel.scale = Vector2(0.9, 0.9)
	_panel.modulate.a = 0.0
	visible = true
	_popup_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(_panel, "scale", Vector2.ONE, 0.15)
	_popup_tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.15)

func close() -> void:
	if _popup_tween:
		_popup_tween.kill()
	_panel.pivot_offset = Vector2(PANEL_W, PANEL_H) / 2.0
	_popup_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(_panel, "scale", Vector2(0.9, 0.9), 0.12)
	_popup_tween.parallel().tween_property(_panel, "modulate:a", 0.0, 0.12)
	_popup_tween.tween_callback(queue_free)

func _unhandled_input(ev: InputEvent) -> void:
	if visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
