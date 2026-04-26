# scenes/ui/settings_overlay.gd
extends CanvasLayer

@onready var _lang_opt: OptionButton = $Panel/LangOpt
@onready var _title_lbl: Label = $Panel/Title
@onready var _lang_lbl: Label = $Panel/LangLbl
@onready var _btn_close: Button = $Panel/BtnClose

var _popup_tween: Tween = null

func _ready() -> void:
	for code in LocaleManager.LOCALES:
		_lang_opt.add_item(LocaleManager.get_display_name(code))
	_lang_opt.selected = LocaleManager.LOCALES.find(LocaleManager.current_locale)
	_lang_opt.item_selected.connect(_on_locale_selected)
	_btn_close.pressed.connect(close)
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
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = SacredPalette.INK_900
	panel_style.border_color = SacredPalette.BRASS_500
	panel_style.set_border_width_all(2)
	($Panel as Panel).add_theme_stylebox_override("panel", panel_style)
	SacredTheme.add_corner_brackets($Panel)
	_build_cursor_row()

func open() -> void:
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
	if _popup_tween:
		_popup_tween.kill()
	var p := $Panel as Panel
	p.pivot_offset = p.size / 2.0
	_popup_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(p, "scale", Vector2(0.9, 0.9), 0.12)
	_popup_tween.parallel().tween_property(p, "modulate:a", 0.0, 0.12)
	_popup_tween.tween_callback(func(): visible = false)

func _unhandled_input(ev: InputEvent) -> void:
	if visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _build_cursor_row() -> void:
	var panel := $Panel as Panel

	var lbl := Label.new()
	lbl.text = tr("ui.settings.cursor_size")
	lbl.theme_type_variation = "SubLabel"
	lbl.offset_left   = 40.0
	lbl.offset_top    = 175.0
	lbl.offset_right  = 200.0
	lbl.offset_bottom = 210.0
	LabelUtils.fit_text(lbl, 18, 12)
	panel.add_child(lbl)

	var current_px := SacredTheme.load_cursor_size()

	var slider := HSlider.new()
	slider.min_value   = 16
	slider.max_value   = 64
	slider.step        = 8
	slider.value       = current_px
	slider.offset_left   = 210.0
	slider.offset_top    = 185.0
	slider.offset_right  = 490.0
	slider.offset_bottom = 210.0
	panel.add_child(slider)

	var size_lbl := Label.new()
	size_lbl.text = str(current_px)
	size_lbl.theme_type_variation = "SubLabel"
	size_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_lbl.offset_left   = 495.0
	size_lbl.offset_top    = 175.0
	size_lbl.offset_right  = 560.0
	size_lbl.offset_bottom = 210.0
	panel.add_child(size_lbl)

	slider.value_changed.connect(func(v: float) -> void:
		var px := int(v)
		size_lbl.text = str(px)
		SacredTheme.apply_cursor_size(px)
		SacredTheme.save_cursor_size(px)
	)

func _on_locale_selected(idx: int) -> void:
	LocaleManager.set_locale(LocaleManager.LOCALES[idx])
	get_tree().reload_current_scene()
