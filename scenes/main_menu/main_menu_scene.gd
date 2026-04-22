# scenes/main_menu/main_menu_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "ui.main_menu.title"
	title.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_ALWAYS
	title.position = Vector2(660, 200)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)

	var btn_new := Button.new()
	btn_new.text = "ui.main_menu.new_game"
	btn_new.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_ALWAYS
	btn_new.position = Vector2(810, 420)
	btn_new.size = Vector2(300, 60)
	btn_new.add_theme_font_size_override("font_size", 24)
	btn_new.pressed.connect(_on_new_game)
	add_child(btn_new)

	if SaveManager.has_save():
		var btn_cont := Button.new()
		btn_cont.text = "ui.main_menu.continue"
		btn_cont.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_ALWAYS
		btn_cont.position = Vector2(810, 500)
		btn_cont.size = Vector2(300, 60)
		btn_cont.add_theme_font_size_override("font_size", 24)
		btn_cont.pressed.connect(_on_continue)
		add_child(btn_cont)

	var lang_lbl := Label.new()
	lang_lbl.text = "ui.main_menu.language_label"
	lang_lbl.auto_translate_mode = Control.AUTO_TRANSLATE_MODE_ALWAYS
	lang_lbl.position = Vector2(1600, 40)
	lang_lbl.size = Vector2(80, 40)
	lang_lbl.add_theme_font_size_override("font_size", 16)
	add_child(lang_lbl)

	var lang_opt := OptionButton.new()
	lang_opt.position = Vector2(1690, 40)
	lang_opt.size = Vector2(200, 40)
	lang_opt.add_theme_font_size_override("font_size", 16)
	for code in LocaleManager.LOCALES:
		lang_opt.add_item(LocaleManager.get_display_name(code))
	lang_opt.selected = LocaleManager.LOCALES.find(LocaleManager.current_locale)
	lang_opt.item_selected.connect(func(idx: int): LocaleManager.set_locale(LocaleManager.LOCALES[idx]))
	add_child(lang_opt)

func _on_new_game() -> void:
	SaveManager.clear_save()
	get_tree().change_scene_to_file("res://scenes/chapter_select/chapter_select_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
