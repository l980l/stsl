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
	bg.color = SacredPalette.INK_1000
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = tr("ui.game_over.victory") if is_win else tr("ui.game_over.defeat")
	title.position = Vector2(660, 200)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 72)
	title.modulate = SacredPalette.BRASS_300 if is_win else SacredPalette.BLOOD_400
	add_child(title)
	title.size = Vector2(600, 120)
	LabelUtils.fit_text(title, 72, 40)

	# 스토리 라인 (패배=재안치 / 승리=순환 암시) — 풀 하이브리드 (포화 없음, 랜덤·직전 반복 회피)
	var _story_key: String = GameManager.pick_story_key("cyclewin" if is_win else "reanchor")
	var _story_txt: String = tr(_story_key)
	if _story_txt != "" and _story_txt != _story_key:
		var story_lbl := Label.new()
		story_lbl.text = _story_txt
		story_lbl.position = Vector2(460, 300)
		story_lbl.size = Vector2(1000, 70)
		story_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		story_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		story_lbl.theme_type_variation = "SubLabel"
		story_lbl.add_theme_font_size_override("font_size", 22)
		story_lbl.modulate = Color(0.74, 0.71, 0.64)
		add_child(story_lbl)

	var info := Label.new()
	info.text = tr("ui.game_over.stats") % [GameManager.current_floor, GameManager.gold]
	info.position = Vector2(660, 380)
	info.size = Vector2(600, 80)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.theme_type_variation = "SubLabel"
	info.add_theme_font_size_override("font_size", 28)
	add_child(info)

	var btn := Button.new()
	btn.text = tr("ui.game_over.btn_main_menu")
	btn.position = Vector2(810, 520)
	btn.theme_type_variation = "PrimaryButton"
	btn.add_theme_font_size_override("font_size", 24)
	btn.pressed.connect(_on_main_menu)
	add_child(btn)
	btn.size = Vector2(300, 60)
	LabelUtils.fit_text(btn, 24, 14)
	SacredTheme.animate_button(btn)

func _on_main_menu() -> void:
	SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn")
