# scenes/ui/settings_overlay.gd
extends CanvasLayer

@onready var _lang_opt: OptionButton = $Panel/LangOpt
@onready var _title_lbl: Label = $Panel/Title
@onready var _lang_lbl: Label = $Panel/LangLbl
@onready var _btn_close: Button = $Panel/BtnClose

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

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _unhandled_input(ev: InputEvent) -> void:
	if visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _on_locale_selected(idx: int) -> void:
	LocaleManager.set_locale(LocaleManager.LOCALES[idx])
	get_tree().reload_current_scene()
