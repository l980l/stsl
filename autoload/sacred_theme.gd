# autoload/sacred_theme.gd
# Sacred UI Kit → Godot 전역 Theme 런타임 정의
# global_theme.tres를 로드하고 StyleBox·폰트·컬러를 프로그래밍으로 채운다.
extends Node

const _FONT_DIR  := "res://assets/fonts/"
const _NOTO_PATH := "res://resources/theme/fonts/NotoSans-Regular.ttf"
const _NOTO_CJK  := "res://resources/theme/fonts/NotoSansCJK-Regular.ttc"

const _HERO_COUNTRY := {
	"napoleon":     "france",
	"joan_of_arc":  "france",
	"cleopatra":    "egypt",
	"genghis_khan": "mongolia",
	"musashi":      "japan",
	"yi_sun_sin":   "korea",
}
const _COUNTRY_FONTS := {
	"france":   "CinzelDecorative-Regular.ttf",
	"egypt":    "CinzelDecorative-Regular.ttf",
	"mongolia": "Cinzel-Bold.ttf",
	# japan/korea: Cinzel-Regular로 fallback (CJK 글리프는 NotoSansCJK로 렌더)
}

var theme: Theme
var _cached_halo_shader: Shader = null
var _cached_line_shader: Shader = null
var _cached_btn_glow_shader: Shader = null
var _country_font_cache: Dictionary = {}
var _cursor_base_image: Image = null

const _CURSOR_DEFAULT := 32
const _SETTINGS_PATH  := "user://settings.cfg"

func _ready() -> void:
	theme = load("res://resources/theme/global_theme.tres")
	_setup_fonts()
	_setup_buttons()
	_setup_panels()
	_setup_labels()
	_setup_cursor()

func _setup_cursor() -> void:
	if _cursor_base_image == null:
		_cursor_base_image = (load("res://assets/art/ui/cursor.svg") as Texture2D).get_image()
	apply_cursor_size(load_cursor_size())

func apply_cursor_size(px: int) -> void:
	if _cursor_base_image == null:
		_cursor_base_image = (load("res://assets/art/ui/cursor.svg") as Texture2D).get_image()
	var img := _cursor_base_image.duplicate() as Image
	img.resize(px, px, Image.INTERPOLATE_LANCZOS)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(img), Input.CURSOR_ARROW, Vector2(px * 0.5, px * 0.5))

func load_cursor_size() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(_SETTINGS_PATH) == OK:
		return int(cfg.get_value("cursor", "size", _CURSOR_DEFAULT))
	return _CURSOR_DEFAULT

func save_cursor_size(px: int) -> void:
	var cfg := ConfigFile.new()
	cfg.load(_SETTINGS_PATH)
	cfg.set_value("cursor", "size", px)
	cfg.save(_SETTINGS_PATH)

# ── 폰트 ──────────────────────────────────────────────────────────────

func _load_font(filename: String) -> FontFile:
	var path := _FONT_DIR + filename
	if ResourceLoader.exists(path):
		return load(path) as FontFile
	return null

func _make_font(primary_file: String) -> Font:
	var primary := _load_font(primary_file)
	if primary == null:
		return load(_NOTO_PATH) as Font

	var noto: Font = load(_NOTO_PATH) if ResourceLoader.exists(_NOTO_PATH) else null
	var noto_cjk: Font = load(_NOTO_CJK) if ResourceLoader.exists(_NOTO_CJK) else null

	var v := FontVariation.new()
	v.base_font = primary
	var fallbacks: Array[Font] = []
	if noto:
		fallbacks.append(noto)
	if noto_cjk:
		fallbacks.append(noto_cjk)
	v.fallbacks = fallbacks
	return v

func _setup_fonts() -> void:
	var font_display := _make_font("Cinzel-Regular.ttf")
	var font_ui      := _make_font("Inter-Regular.ttf")
	var font_mono    := _make_font("SpaceMono-Regular.ttf")
	var font_italic  := _make_font("IMFellEnglish-Italic.ttf")

	# 전역 기본폰트
	theme.default_font = font_ui
	theme.default_font_size = 16

	# Label 폰트 변형 등록 — theme_type_variation 으로 사용
	for variant in ["TitleLabel", "EyebrowLabel", "SubLabel", "AccentLabel"]:
		theme.set_type_variation(variant, "Label")

	theme.set_font("font", "TitleLabel", font_display)
	theme.set_font_size("font_size", "TitleLabel", 28)
	theme.set_color("font_color", "TitleLabel", SacredPalette.BONE_100)

	theme.set_font("font", "EyebrowLabel", font_mono)
	theme.set_font_size("font_size", "EyebrowLabel", 10)
	theme.set_color("font_color", "EyebrowLabel", SacredPalette.BRASS_400)

	theme.set_font("font", "SubLabel", font_italic)
	theme.set_font_size("font_size", "SubLabel", 13)
	theme.set_color("font_color", "SubLabel", SacredPalette.FG_3)

	theme.set_font("font", "AccentLabel", font_display)
	theme.set_font_size("font_size", "AccentLabel", 16)
	theme.set_color("font_color", "AccentLabel", SacredPalette.BRASS_400)

	theme.set_type_variation("ToastLabel", "Label")
	theme.set_font("font", "ToastLabel", font_mono)
	theme.set_font_size("font_size", "ToastLabel", 12)
	theme.set_color("font_color", "ToastLabel", SacredPalette.BRASS_300)

# ── 영웅별 장식체 폰트 ────────────────────────────────────────────────

func get_hero_font(hero_id: String) -> Font:
	if _country_font_cache.has(hero_id):
		return _country_font_cache[hero_id]
	var country: String = _HERO_COUNTRY.get(hero_id, "")
	var filename: String = _COUNTRY_FONTS.get(country, "Cinzel-Regular.ttf")
	var font := _make_font(filename)
	_country_font_cache[hero_id] = font
	return font

# ── StyleBoxFlat 헬퍼 ─────────────────────────────────────────────────

func _make_box(bg: Color, border: Color, bw: int = 1,
		pad_h: int = 28, pad_v: int = 13,
		shadow_c: Color = Color.TRANSPARENT, shadow_sz: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_content_margin(SIDE_LEFT,   pad_h)
	s.set_content_margin(SIDE_RIGHT,  pad_h)
	s.set_content_margin(SIDE_TOP,    pad_v)
	s.set_content_margin(SIDE_BOTTOM, pad_v)
	s.shadow_color = shadow_c
	s.shadow_size   = shadow_sz
	return s

# ── 버튼 ──────────────────────────────────────────────────────────────

func _apply_button_styles(type: String, normal: StyleBoxFlat, hover: StyleBoxFlat,
		pressed: StyleBoxFlat, font_col: Color, font_sz: int = 12) -> void:
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = SacredPalette.BRASS_500
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.bg_color.a = 0.4

	theme.set_stylebox("normal",   type, normal)
	theme.set_stylebox("hover",    type, hover)
	theme.set_stylebox("pressed",  type, pressed)
	theme.set_stylebox("focus",    type, focus)
	theme.set_stylebox("disabled", type, disabled)
	theme.set_color("font_color",          type, font_col)
	theme.set_color("font_hover_color",    type, font_col.lightened(0.25))
	theme.set_color("font_pressed_color",  type, font_col)
	theme.set_color("font_disabled_color", type, font_col.darkened(0.5))
	theme.set_font_size("font_size", type, font_sz)

func _setup_buttons() -> void:
	var P := SacredPalette

	# ── 기본 Button (.sbtn) ──
	var btn_normal  := _make_box(P.INK_1000, P.BRASS_700, 1, 16, 8)
	var btn_hover   := _make_box(P.INK_1000, P.BRASS_500, 1, 16, 8)
	var btn_pressed := _make_box(P.INK_900, P.BRASS_600, 1, 16, 9)
	_apply_button_styles("Button", btn_normal, btn_hover, btn_pressed, P.BONE_100)
	# CSS: .sbtn:hover { color: var(--brass-300) }
	theme.set_color("font_hover_color", "Button", P.BRASS_300)

	# ── PrimaryButton (.sbtn--primary) ──
	theme.set_type_variation("PrimaryButton", "Button")
	var pri_bg     := Color(P.INK_900.r + 0.04, P.INK_900.g + 0.02, P.INK_900.b + 0.06)
	var pri_normal  := _make_box(pri_bg, P.BRASS_500, 1, 28, 13)
	var pri_hover   := _make_box(pri_bg, P.BRASS_400, 1, 28, 13)
	var pri_pressed := _make_box(P.INK_900, P.BRASS_500, 1, 28, 14)
	_apply_button_styles("PrimaryButton", pri_normal, pri_hover, pri_pressed, P.BRASS_300)
	# CSS: .sbtn--primary:hover { color: var(--bone-100) } — 호버 시 텍스트 흰색
	theme.set_color("font_hover_color", "PrimaryButton", P.BONE_100)

	# ── SacramentButton (.sbtn--sacrament) ──
	theme.set_type_variation("SacramentButton", "Button")
	var sac_normal  := _make_box(P.BLOOD_700, P.BLOOD_500)
	var sac_hover   := _make_box(P.BLOOD_600, P.BLOOD_400, 1, 28, 13,
			Color(P.BLOOD_500.r, P.BLOOD_500.g, P.BLOOD_500.b, 0.4), 6)
	var sac_pressed := _make_box(P.BLOOD_700, P.BLOOD_500, 1, 28, 14)
	_apply_button_styles("SacramentButton", sac_normal, sac_hover, sac_pressed, P.BONE_100)

	# ── VowButton (.sbtn--vow, ghost/cancel) ──
	theme.set_type_variation("VowButton", "Button")
	var vow_normal  := _make_box(Color(0, 0, 0, 0), P.LINE_2, 1, 16, 8)
	var vow_hover   := _make_box(Color(0, 0, 0, 0), P.BONE_400, 1, 16, 8)
	var vow_pressed := _make_box(Color(0, 0, 0, 0.08), P.BONE_400, 1, 16, 9)
	_apply_button_styles("VowButton", vow_normal, vow_hover, vow_pressed, P.FG_2)

	# ── IconButton (.sbtn--icon, 정사각) ──
	theme.set_type_variation("IconButton", "Button")
	var ico_normal  := _make_box(P.INK_1000, P.BRASS_700, 1, 0, 0)
	var ico_hover   := _make_box(P.INK_1000, P.BRASS_500, 1, 0, 0,
			Color(P.BRASS_400.r, P.BRASS_400.g, P.BRASS_400.b, 0.18), 4)
	var ico_pressed := _make_box(P.INK_900, P.BRASS_600, 1, 0, 1)
	_apply_button_styles("IconButton", ico_normal, ico_hover, ico_pressed, P.BRASS_400)
	theme.set_constant("icon_max_width", "IconButton", 18)

	# ── ChapterButton (챕터 선택 카드 전체가 버튼) ──
	theme.set_type_variation("ChapterButton", "Button")
	var ch_normal  := _make_box(P.INK_800, P.BRASS_700, 1, 0, 0)
	var ch_hover   := _make_box(P.INK_700, P.BRASS_400, 1, 0, 0)
	var ch_pressed := _make_box(P.INK_800, P.BRASS_500, 1, 0, 0)
	_apply_button_styles("ChapterButton", ch_normal, ch_hover, ch_pressed, P.BONE_100, 16)

	var ch_locked_normal := _make_box(P.INK_1000, P.LINE_1, 1, 0, 0)
	var ch_locked_hover  := _make_box(P.INK_1000, P.LINE_2, 1, 0, 0)
	theme.set_type_variation("ChapterButtonLocked", "Button")
	_apply_button_styles("ChapterButtonLocked",
			ch_locked_normal, ch_locked_hover, ch_locked_normal, P.FG_4, 16)

	# ── RoomButton (맵 노드 기본) ──
	theme.set_type_variation("RoomButton", "Button")
	var room_normal  := _make_box(P.INK_1000, P.BRASS_700, 1, 10, 6)
	var room_hover   := _make_box(P.INK_1000, P.BRASS_500, 1, 10, 6)
	var room_pressed := _make_box(P.INK_900, P.BRASS_600, 1, 10, 7)
	_apply_button_styles("RoomButton", room_normal, room_hover, room_pressed, P.BONE_100, 12)
	theme.set_color("font_hover_color", "RoomButton", P.BRASS_300)

	# ── EliteRoomButton (엘리트 방 — AMETHYST 톤) ──
	theme.set_type_variation("EliteRoomButton", "Button")
	var elite_bg := Color(P.INK_1000.r + 0.03, P.INK_1000.g, P.INK_1000.b + 0.06)
	var elite_normal  := _make_box(elite_bg, P.AMETHYST_500, 1, 10, 6)
	var elite_hover   := _make_box(elite_bg, P.AMETHYST_400, 1, 10, 6)
	var elite_pressed := _make_box(P.INK_1000, P.AMETHYST_500, 1, 10, 7)
	_apply_button_styles("EliteRoomButton", elite_normal, elite_hover, elite_pressed, P.AMETHYST_300, 12)

	# ── BossRoomButton (보스 방 — BLOOD 톤) ──
	theme.set_type_variation("BossRoomButton", "Button")
	var boss_bg := Color(P.INK_1000.r + 0.06, P.INK_1000.g, P.INK_1000.b)
	var boss_normal  := _make_box(boss_bg, P.BLOOD_500, 1, 10, 6)
	var boss_hover   := _make_box(boss_bg, P.BLOOD_400, 1, 10, 6)
	var boss_pressed := _make_box(P.INK_1000, P.BLOOD_500, 1, 10, 7)
	_apply_button_styles("BossRoomButton", boss_normal, boss_hover, boss_pressed, P.BLOOD_300, 12)

	# ── DangerButton (이벤트 도박/저주 — 투명 배경 + BLOOD 테두리) ──
	theme.set_type_variation("DangerButton", "Button")
	var danger_normal  := _make_box(Color(0, 0, 0, 0), P.BLOOD_500)
	var danger_hover   := _make_box(Color(0, 0, 0, 0), P.BLOOD_400)
	var danger_pressed := _make_box(Color(0, 0, 0, 0.08), P.BLOOD_400)
	_apply_button_styles("DangerButton", danger_normal, danger_hover, danger_pressed, P.BLOOD_300)

# ── 패널 ──────────────────────────────────────────────────────────────

func _setup_panels() -> void:
	var P := SacredPalette
	var panel_style := _make_box(P.INK_900, P.BRASS_700, 1, 16, 16)
	theme.set_stylebox("panel", "Panel", panel_style)
	theme.set_stylebox("panel", "PanelContainer", panel_style)

# ── 라벨 기본색 ───────────────────────────────────────────────────────

func _setup_labels() -> void:
	theme.set_color("font_color", "Label", SacredPalette.BONE_100)

# ── 모서리 L자 브라켓 장식 ───────────────────────────────────────────
# CSS .sacred-window__corner / .sacred-popup__corner 대응
# node 의 4모서리에 L자 ColorRect 8개를 자식으로 추가한다.
# node.size 가 확정된 후 호출할 것.

func add_corner_brackets(node: Control,
		color: Color = SacredPalette.BRASS_500,
		bracket_len: int = 14,
		inset: int = 6,
		thickness: int = 1) -> void:
	_place_brackets(node, color, bracket_len, inset, thickness)
	node.resized.connect(func():
		for child in node.get_children():
			if child.get_meta("_corner_bracket", false):
				child.queue_free()
		_place_brackets(node, color, bracket_len, inset, thickness)
	)

func _place_brackets(node: Control, color: Color,
		bl: int, inset: int, t: int) -> void:
	var w := node.size.x
	var h := node.size.y
	if w <= 0 or h <= 0:
		return
	var specs: Array[Array] = [
		# TL
		[Vector2(inset,         inset        ), Vector2(bl, t )],
		[Vector2(inset,         inset        ), Vector2(t,  bl)],
		# TR
		[Vector2(w - inset - bl, inset        ), Vector2(bl, t )],
		[Vector2(w - inset - t,  inset        ), Vector2(t,  bl)],
		# BL
		[Vector2(inset,          h - inset - t), Vector2(bl, t )],
		[Vector2(inset,          h - inset - bl), Vector2(t,  bl)],
		# BR
		[Vector2(w - inset - bl, h - inset - t ), Vector2(bl, t )],
		[Vector2(w - inset - t,  h - inset - bl), Vector2(t,  bl)],
	]
	for spec in specs:
		var rect := ColorRect.new()
		rect.color = color
		rect.position = spec[0]
		rect.size     = spec[1]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_meta("_corner_bracket", true)
		node.add_child(rect)

# ── 팝업 브라켓 (틱 마크 포함) ──────────────────────────────────────
# CSS .sacred-popup__corner 대응 — L자 + 양 끝 틱 마크

func attach_popup_brackets_to_dialog(dlg: AcceptDialog) -> void:
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 10
	dlg.add_child(overlay)
	add_popup_brackets(overlay)

func add_popup_brackets(node: Control,
		color: Color = SacredPalette.BRASS_500,
		bracket_len: int = 14,
		inset: int = 6,
		thickness: int = 1,
		tick_gap: int = 3,
		tick_len: int = 4) -> void:
	_place_popup_brackets(node, color, bracket_len, inset, thickness, tick_gap, tick_len)
	node.resized.connect(func():
		for child in node.get_children():
			if child.get_meta("_popup_bracket", false):
				child.queue_free()
		_place_popup_brackets(node, color, bracket_len, inset, thickness, tick_gap, tick_len)
	)

func _place_popup_brackets(node: Control, color: Color,
		bl: int, inset: int, t: int, tg: int, tl: int) -> void:
	var w := node.size.x
	var h := node.size.y
	if w <= 0 or h <= 0:
		return
	var specs: Array[Array] = [
		# TL — H바, V바, H틱, V틱
		[Vector2(inset,                   inset                  ), Vector2(bl, t )],
		[Vector2(inset,                   inset                  ), Vector2(t,  bl)],
		[Vector2(inset + bl + tg,         inset                  ), Vector2(tl, t )],
		[Vector2(inset,                   inset + bl + tg        ), Vector2(t,  tl)],
		# TR
		[Vector2(w - inset - bl,          inset                  ), Vector2(bl, t )],
		[Vector2(w - inset - t,           inset                  ), Vector2(t,  bl)],
		[Vector2(w - inset - bl - tg - tl, inset                 ), Vector2(tl, t )],
		[Vector2(w - inset - t,           inset + bl + tg        ), Vector2(t,  tl)],
		# BL
		[Vector2(inset,                   h - inset - t          ), Vector2(bl, t )],
		[Vector2(inset,                   h - inset - bl         ), Vector2(t,  bl)],
		[Vector2(inset + bl + tg,         h - inset - t          ), Vector2(tl, t )],
		[Vector2(inset,                   h - inset - bl - tg - tl), Vector2(t, tl)],
		# BR
		[Vector2(w - inset - bl,          h - inset - t          ), Vector2(bl, t )],
		[Vector2(w - inset - t,           h - inset - bl         ), Vector2(t,  bl)],
		[Vector2(w - inset - bl - tg - tl, h - inset - t         ), Vector2(tl, t )],
		[Vector2(w - inset - t,           h - inset - bl - tg - tl), Vector2(t, tl)],
	]
	for spec in specs:
		var rect := ColorRect.new()
		rect.color = color
		rect.position = spec[0]
		rect.size     = spec[1]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.set_meta("_popup_bracket", true)
		node.add_child(rect)

# ── 버튼 ::before/::after 장식선 + 호버 트랜지션 ────────────────────

func _get_line_shader() -> Shader:
	if _cached_line_shader == null:
		_cached_line_shader = Shader.new()
		# CSS: linear-gradient(90deg, transparent, brass-700, transparent)
		_cached_line_shader.code = "shader_type canvas_item;\nvoid fragment() {\n\tfloat fade = smoothstep(0.0, 0.5, UV.x) * smoothstep(1.0, 0.5, UV.x);\n\tCOLOR = vec4(0.478, 0.361, 0.118, fade);\n}\n"
	return _cached_line_shader

func _get_btn_glow_shader() -> Shader:
	if _cached_btn_glow_shader == null:
		_cached_btn_glow_shader = Shader.new()
		# CSS box-shadow 방식 — 버튼 직사각형 SDF, 버튼 내부는 0 (투명 배경 버튼 대응)
		_cached_btn_glow_shader.code = "shader_type canvas_item;\nuniform float opacity : hint_range(0.0, 1.0) = 0.0;\nuniform vec2 edge_uv = vec2(0.1, 0.25);\nvoid fragment() {\n\tvec2 d2 = abs(UV - vec2(0.5)) - (vec2(0.5) - edge_uv);\n\tfloat outside = step(0.0, max(d2.x, d2.y));\n\tvec2 dn = max(d2, vec2(0.0)) / edge_uv;\n\tfloat t = length(dn);\n\tfloat alpha = smoothstep(1.0, 0.0, t) * opacity * 0.65 * outside;\n\tCOLOR = vec4(0.788, 0.659, 0.298, alpha);\n}\n"
	return _cached_btn_glow_shader

func animate_button(btn: Button) -> void:
	var P := SacredPalette
	var line_shader := _get_line_shader()
	var variation := btn.theme_type_variation
	var is_vow := variation == "VowButton" or variation == "DangerButton"

	if variation == "BossRoomButton":
		add_corner_brackets(btn, P.BLOOD_500, 8, 4)

	# ::before — CSS: left:8px right:8px top:3px height:1px gradient
	var top_line := ColorRect.new()
	top_line.anchor_left   = 0.0
	top_line.anchor_right  = 1.0
	top_line.anchor_top    = 0.0
	top_line.anchor_bottom = 0.0
	top_line.offset_left   = 8.0
	top_line.offset_right  = -8.0
	top_line.offset_top    = 3.0
	top_line.offset_bottom = 4.0
	top_line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var top_mat := ShaderMaterial.new()
	top_mat.shader = line_shader
	top_line.material = top_mat
	btn.add_child(top_line)

	# ::after — CSS: left:8px right:8px bottom:3px height:1px gradient
	var bot_line := ColorRect.new()
	bot_line.anchor_left   = 0.0
	bot_line.anchor_right  = 1.0
	bot_line.anchor_top    = 1.0
	bot_line.anchor_bottom = 1.0
	bot_line.offset_left   = 8.0
	bot_line.offset_right  = -8.0
	bot_line.offset_top    = -4.0
	bot_line.offset_bottom = -3.0
	bot_line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var bot_mat := ShaderMaterial.new()
	bot_mat.shader = line_shader
	bot_line.material = bot_mat
	btn.add_child(bot_line)

	# 외부 후광 — VowButton 제외 (CSS: vow hover { box-shadow: none })
	# CSS Primary: 기본 희미한 후광 → 호버 시 강해짐
	if not is_vow:
		var is_primary := variation == "PrimaryButton"
		attach_outer_glow(btn, 24.0, 0.1 if is_primary else 0.0, 0.3 if is_primary else 0.2)

	# 장식선 hover 색상 — CSS: ::before/::after brass-700 → brass-400 on hover
	var line_mod_hover := Color(
		P.BRASS_400.r / max(P.BRASS_700.r, 0.001),
		P.BRASS_400.g / max(P.BRASS_700.g, 0.001),
		P.BRASS_400.b / max(P.BRASS_700.b, 0.001)
	)

	var tw := [null]
	btn.mouse_entered.connect(func():
		if tw[0]: tw[0].kill()
		tw[0] = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw[0].tween_property(top_line, "modulate", line_mod_hover, 0.16)
		tw[0].parallel().tween_property(bot_line, "modulate", line_mod_hover, 0.16)
	)
	btn.mouse_exited.connect(func():
		if tw[0]: tw[0].kill()
		tw[0] = btn.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw[0].tween_property(top_line, "modulate", Color.WHITE, 0.16)
		tw[0].parallel().tween_property(bot_line, "modulate", Color.WHITE, 0.16)
	)

# ── 버튼 외곽 후광 (box-shadow 방식) — animate_button 및 챕터 카드에서 재사용 ──
# CSS: 0 0 24px rgba(212,169,72,0.18). VowButton은 호출하지 않을 것.

func attach_outer_glow(btn: Button, pad: float = 24.0, default_opacity: float = 0.0, hover_opacity: float = 1.0) -> void:
	var og_mat := ShaderMaterial.new()
	og_mat.shader = _get_btn_glow_shader()
	og_mat.set_shader_parameter("opacity", default_opacity)
	var glow_size := btn.size + Vector2(pad * 2.0, pad * 2.0)
	og_mat.set_shader_parameter("edge_uv", Vector2(pad / glow_size.x, pad / glow_size.y))
	var outer_glow := ColorRect.new()
	outer_glow.show_behind_parent = true
	outer_glow.position = Vector2(-pad, -pad)
	outer_glow.size = glow_size
	outer_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer_glow.material = og_mat
	btn.add_child(outer_glow)
	btn.resized.connect(func():
		var new_gs := btn.size + Vector2(pad * 2.0, pad * 2.0)
		outer_glow.position = Vector2(-pad, -pad)
		outer_glow.size = new_gs
		og_mat.set_shader_parameter("edge_uv", Vector2(pad / new_gs.x, pad / new_gs.y))
	)
	var ogtw := [null]
	btn.mouse_entered.connect(func():
		if ogtw[0]: ogtw[0].kill()
		var cur: float = og_mat.get_shader_parameter("opacity")
		ogtw[0] = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		ogtw[0].tween_method(func(v: float): og_mat.set_shader_parameter("opacity", v), cur, hover_opacity, 0.20)
	)
	btn.mouse_exited.connect(func():
		if ogtw[0]: ogtw[0].kill()
		var cur: float = og_mat.get_shader_parameter("opacity")
		ogtw[0] = btn.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		ogtw[0].tween_method(func(v: float): og_mat.set_shader_parameter("opacity", v), cur, default_opacity, 0.20)
	)

# ── 챕터 카드 halo (방사형 금빛 후광) ────────────────────────────────

func _get_halo_shader() -> Shader:
	if _cached_halo_shader == null:
		_cached_halo_shader = Shader.new()
		_cached_halo_shader.code = "shader_type canvas_item;\nuniform float opacity : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec2 focus = vec2(0.5, 0.35);\n\tfloat d = length((UV - focus) * vec2(1.0, 1.5));\n\tfloat alpha = smoothstep(0.55, 0.0, d);\n\tCOLOR = vec4(0.788, 0.659, 0.298, alpha * 0.4 * opacity);\n}\n"
	return _cached_halo_shader

func make_halo() -> ColorRect:
	var halo := ColorRect.new()
	halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.set_meta("_halo", true)
	var mat := ShaderMaterial.new()
	mat.shader = _get_halo_shader()
	mat.set_shader_parameter("opacity", 0.0)
	halo.material = mat
	return halo

# ── 그라데이션 텍스처 헬퍼 ────────────────────────────────────────────────
# 팝업 헤더 하이라이트·구분선·컬럼 구분선에 공통 사용

func make_top_fade_tex(color: Color = SacredPalette.BRASS_300, top_alpha: float = 0.18) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, top_alpha))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to   = Vector2(0.5, 1.0)
	return tex

func make_center_bright_h_tex(color: Color = SacredPalette.BRASS_300, mid_alpha: float = 0.75) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.0))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	g.add_point(0.5, Color(color.r, color.g, color.b, mid_alpha))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	return tex

func make_center_bright_v_tex(color: Color = SacredPalette.BRASS_300, mid_alpha: float = 0.5) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(color.r, color.g, color.b, 0.0))
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	g.add_point(0.5, Color(color.r, color.g, color.b, mid_alpha))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to   = Vector2(0.5, 1.0)
	return tex

func make_top_ellipse_bloom(focus_y: float = 0.0) -> ColorRect:
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float opacity : hint_range(0.0, 1.0) = 1.0;\nuniform float focus_y : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() {\n\tvec2 focus = vec2(0.5, focus_y);\n\tfloat d = length((UV - focus) * vec2(1.0, 2.5));\n\tfloat a = smoothstep(0.7, 0.0, d) * 0.18 * opacity;\n\tCOLOR = vec4(0.722, 0.565, 0.165, a);\n}\n"
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("opacity", 1.0)
	mat.set_shader_parameter("focus_y", focus_y)
	rect.material = mat
	return rect

# ── 모달 dim 배경 (CanvasLayer에 반투명 차폐막 추가) ────────────────────
# 클릭 차단 포함. CanvasLayer.add_child 전에 호출해야 z 순서가 맞다.

func attach_modal_dim(layer: CanvasLayer) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.07, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)
	return dim
