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
	_lang_lbl.text = tr("ui.settings.language")
	_btn_close.text = tr("ui.map.btn_close")

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
