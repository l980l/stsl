# scenes/ui/settings_overlay.gd
extends CanvasLayer

@onready var _lang_opt:    OptionButton = $Panel/LangOpt
@onready var _title_lbl:   Label        = $Panel/Title
@onready var _lang_lbl:    Label        = $Panel/LangLbl
@onready var _btn_close:   Button       = $Panel/BtnClose
@onready var _btn_defaults: Button      = $Panel/Footer/BtnDefaults
@onready var _btn_cancel:  Button       = $Panel/Footer/BtnCancel
@onready var _btn_apply:   Button       = $Panel/Footer/BtnApply

const _CURSOR_SIZES: Dictionary = {"S": 24, "M": 32, "L": 48, "XL": 64}
const _DEFAULT_KEY := "M"

var _popup_tween: Tween = null
var _seg_buttons: Dictionary = {}
var _seg_base_styles: Dictionary = {}

var _initial_cursor_px: int = 32
var _initial_locale_idx: int = 0
var _pending_cursor_px: int = 32
var _pending_locale_idx: int = 0
var _applying: bool = false

func _ready() -> void:
	for code in LocaleManager.LOCALES:
		_lang_opt.add_item(LocaleManager.get_display_name(code))
	_lang_opt.item_selected.connect(_on_locale_selected)

	_btn_close.pressed.connect(close)
	_btn_cancel.pressed.connect(_on_cancel)
	_btn_apply.pressed.connect(_on_apply)
	_btn_defaults.pressed.connect(_on_defaults)

	_title_lbl.text = tr("ui.settings.title")
	_title_lbl.theme_type_variation = "TitleLabel"
	var panel_w := ($Panel as Panel).offset_right - ($Panel as Panel).offset_left
	LabelUtils.fit_text(_title_lbl, 28, 16, panel_w)
	_lang_lbl.text = tr("ui.settings.language")
	_lang_lbl.theme_type_variation = "SubLabel"
	LabelUtils.fit_text(_lang_lbl, 18, 12)

	_btn_close.theme_type_variation = "IconButton"
	_btn_close.text = "✕"
	_btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn_close.add_theme_font_size_override("font_size", 20)
	_btn_close.custom_minimum_size = Vector2(40, 40)

	var _mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	_btn_defaults.theme_type_variation = "VowButton"
	_btn_defaults.text = tr("ui.settings.btn_defaults").to_upper()
	_btn_defaults.add_theme_font_override("font", _mono_font)
	_btn_defaults.add_theme_font_size_override("font_size", 11)
	_btn_cancel.theme_type_variation = "VowButton"
	_btn_cancel.text = tr("ui.settings.btn_cancel").to_upper()
	_btn_cancel.add_theme_font_override("font", _mono_font)
	_btn_cancel.add_theme_font_size_override("font_size", 11)
	_btn_apply.text = tr("ui.settings.btn_apply").to_upper()
	_btn_apply.add_theme_font_override("font", _mono_font)
	_btn_apply.add_theme_font_size_override("font_size", 11)
	SacredTheme.animate_button(_btn_apply)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = SacredPalette.INK_900
	panel_style.border_color = SacredPalette.BRASS_500
	panel_style.set_border_width_all(2)
	($Panel as Panel).add_theme_stylebox_override("panel", panel_style)
	SacredTheme.add_corner_brackets($Panel)

	var panel_hl := TextureRect.new()
	panel_hl.texture = _make_top_gradient_tex(0.18)
	panel_hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel_hl.stretch_mode = TextureRect.STRETCH_SCALE
	panel_hl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel_hl.offset_bottom = 80.0
	panel_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	($Panel as Panel).add_child(panel_hl)

	# 타이틀 아래 금빛 구분선
	var panel := $Panel as Panel
	var div_y := 68.0
	var div_line := TextureRect.new()
	div_line.texture = _make_h_center_gradient(0.75)
	div_line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div_line.stretch_mode = TextureRect.STRETCH_SCALE
	div_line.offset_left   = 48.0
	div_line.offset_top    = div_y - 0.5
	div_line.offset_right  = panel_w - 48.0
	div_line.offset_bottom = div_y + 1.5
	div_line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	panel.add_child(div_line)

	_build_cursor_row()

func open() -> void:
	_initial_cursor_px = SacredTheme.load_cursor_size()
	_initial_locale_idx = LocaleManager.LOCALES.find(LocaleManager.current_locale)
	_pending_cursor_px = _initial_cursor_px
	_pending_locale_idx = _initial_locale_idx
	_lang_opt.selected = _initial_locale_idx
	_applying = false
	_refresh_seg()

	if _popup_tween:
		_popup_tween.kill()
	var p := $Panel as Panel
	p.pivot_offset = p.size / 2.0
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	visible = true
	_popup_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(p, "scale", Vector2.ONE, 0.15)
	_popup_tween.parallel().tween_property(p, "modulate:a", 1.0, 0.15)

func close() -> void:
	if not _applying:
		_revert_pending()
	if _popup_tween:
		_popup_tween.kill()
	var p := $Panel as Panel
	p.pivot_offset = p.size / 2.0
	_popup_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(p, "scale", Vector2(0.9, 0.9), 0.12)
	_popup_tween.parallel().tween_property(p, "modulate:a", 0.0, 0.12)
	_popup_tween.tween_callback(func(): visible = false)

func _on_apply() -> void:
	_applying = true
	SacredTheme.save_cursor_size(_pending_cursor_px)
	var locale_changed := _pending_locale_idx != _initial_locale_idx
	if locale_changed:
		LocaleManager.set_locale(LocaleManager.LOCALES[_pending_locale_idx])
	close()
	if locale_changed:
		get_tree().reload_current_scene.call_deferred()

func _on_cancel() -> void:
	close()

func _on_defaults() -> void:
	_set_pending_cursor(_CURSOR_SIZES[_DEFAULT_KEY])
	_pending_locale_idx = _initial_locale_idx
	_lang_opt.selected = _initial_locale_idx

func _set_pending_cursor(px: int) -> void:
	_pending_cursor_px = px
	SacredTheme.apply_cursor_size(px)
	_refresh_seg()

func _revert_pending() -> void:
	SacredTheme.apply_cursor_size(_initial_cursor_px)

func _on_locale_selected(idx: int) -> void:
	_pending_locale_idx = idx

func _refresh_seg() -> void:
	var nearest_key := _DEFAULT_KEY
	var best_dist := INF
	for k in _CURSOR_SIZES:
		var d := absf(_pending_cursor_px - _CURSOR_SIZES[k])
		if d < best_dist:
			best_dist = d
			nearest_key = k
	for k in _seg_buttons:
		var btn: Button = _seg_buttons[k]
		_apply_seg_style(btn, k == nearest_key)

func _make_top_gradient_tex(top_alpha: float) -> GradientTexture2D:
	var g := Gradient.new()
	var c := SacredPalette.BRASS_300
	g.set_color(0, Color(c.r, c.g, c.b, top_alpha))
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to   = Vector2(0.5, 1.0)
	return tex

func _make_h_center_gradient(alpha: float) -> GradientTexture2D:
	var g := Gradient.new()
	var c := SacredPalette.BRASS_300
	g.set_color(0, Color(c.r, c.g, c.b, 0.0))
	g.set_color(1, Color(c.r, c.g, c.b, 0.0))
	g.add_point(0.5, Color(c.r, c.g, c.b, alpha))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.0, 0.5)
	tex.fill_to   = Vector2(1.0, 0.5)
	return tex

func _apply_seg_style(btn: Button, is_active: bool) -> void:
	var hl: Node = btn.get_node_or_null("_hl")
	if hl:
		hl.visible = is_active

	if is_active:
		var s := StyleBoxFlat.new()
		s.bg_color = Color(SacredPalette.BRASS_700.r, SacredPalette.BRASS_700.g, SacredPalette.BRASS_700.b, 0.35)
		s.border_color = SacredPalette.BRASS_400
		s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("hover", s)
		btn.add_theme_color_override("font_color", SacredPalette.BONE_100)
	else:
		var base: StyleBox = _seg_base_styles.get(btn) as StyleBox
		if base:
			btn.add_theme_stylebox_override("normal", base)
		else:
			btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_color_override("font_color")

func _build_cursor_row() -> void:
	var panel := $Panel as Panel

	var lbl := Label.new()
	lbl.text = tr("ui.settings.cursor_size")
	lbl.theme_type_variation = "SubLabel"
	lbl.offset_left   = 40.0
	lbl.offset_top    = 175.0
	lbl.offset_right  = 200.0
	lbl.offset_bottom = 210.0
	panel.add_child(lbl)
	LabelUtils.fit_text(lbl, 18, 12)

	var seg_box := HBoxContainer.new()
	seg_box.offset_left   = 210.0
	seg_box.offset_top    = 175.0
	seg_box.offset_right  = 560.0
	seg_box.offset_bottom = 218.0
	seg_box.add_theme_constant_override("separation", 0)
	panel.add_child(seg_box)

	var keys: Array = _CURSOR_SIZES.keys()
	for i in keys.size():
		var key: String = keys[i]
		var btn := Button.new()
		btn.text = key
		btn.custom_minimum_size = Vector2(0, 43)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", load("res://assets/fonts/SpaceMono-Regular.ttf"))
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_set_pending_cursor.bind(_CURSOR_SIZES[key]))

		# 세그먼트처럼 붙여 보이게 — 좌우 테두리 공유
		var base_style := StyleBoxFlat.new()
		base_style.bg_color = Color(SacredPalette.INK_900.r, SacredPalette.INK_900.g, SacredPalette.INK_900.b, 0.8)
		base_style.border_color = SacredPalette.BRASS_700
		base_style.border_width_top = 1
		base_style.border_width_bottom = 1
		base_style.border_width_left = 1 if i == 0 else 0
		base_style.border_width_right = 1
		btn.add_theme_stylebox_override("normal", base_style)
		btn.add_theme_stylebox_override("focus", base_style)
		_seg_base_styles[btn] = base_style

		seg_box.add_child(btn)
		_seg_buttons[key] = btn

		# _hl은 미리 생성해 두고 visibility로 토글
		var hl := TextureRect.new()
		hl.name = "_hl"
		hl.texture = _make_top_gradient_tex(0.30)
		hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hl.stretch_mode = TextureRect.STRETCH_SCALE
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hl.visible = false
		btn.add_child(hl)
		hl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_refresh_seg()

func _unhandled_input(ev: InputEvent) -> void:
	if visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
