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
	title.text = "STSL"
	title.position = Vector2(660, 200)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)

	var btn_new := Button.new()
	btn_new.text = "새 게임"
	btn_new.position = Vector2(810, 420)
	btn_new.size = Vector2(300, 60)
	btn_new.add_theme_font_size_override("font_size", 24)
	btn_new.pressed.connect(_on_new_game)
	add_child(btn_new)

	if SaveManager.has_save():
		var btn_cont := Button.new()
		btn_cont.text = "이어하기"
		btn_cont.position = Vector2(810, 500)
		btn_cont.size = Vector2(300, 60)
		btn_cont.add_theme_font_size_override("font_size", 24)
		btn_cont.pressed.connect(_on_continue)
		add_child(btn_cont)

func _on_new_game() -> void:
	SaveManager.clear_save()
	GameManager.start_run()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
