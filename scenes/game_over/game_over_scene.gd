# scenes/game_over/game_over_scene.gd
extends Node2D

const _ToastScene = preload("res://scenes/ui/hero_unlock_toast.tscn")

func _ready() -> void:
	_build_ui()
	if GameManager.run_won:
		var toast = _ToastScene.instantiate()
		add_child(toast)

func _build_ui() -> void:
	var is_win: bool = GameManager.run_won

	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.05, 0.02) if is_win else Color(0.05, 0.02, 0.02)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = tr("ui.game_over.victory") if is_win else tr("ui.game_over.defeat")
	title.position = Vector2(660, 200)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = Color(1.0, 0.9, 0.3) if is_win else Color(0.9, 0.3, 0.3)
	add_child(title)
	title.size = Vector2(600, 120)
	LabelUtils.fit_text(title, 72, 40)

	var info := Label.new()
	info.text = "도달 층: %d / 9\n보유 골드: %d" % [GameManager.current_floor, GameManager.gold]
	info.position = Vector2(660, 380)
	info.size = Vector2(600, 80)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_font_size_override("font_size", 28)
	add_child(info)

	var btn := Button.new()
	btn.text = tr("ui.game_over.btn_main_menu")
	btn.position = Vector2(810, 520)
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_main_menu)
	add_child(btn)
	btn.size = Vector2(300, 60)
	LabelUtils.fit_text(btn, 24, 14)

func _on_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
