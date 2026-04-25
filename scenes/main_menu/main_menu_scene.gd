# scenes/main_menu/main_menu_scene.gd
extends Node2D

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color = P.INK_900
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 상단 금빛 수평선 장식
	var top_line := ColorRect.new()
	top_line.color = P.BRASS_700
	top_line.position = Vector2(0, 180)
	top_line.size = Vector2(1920, 1)
	add_child(top_line)

	# 소제목 eyebrow
	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— THE CARD GAME —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(660, 200)
	eyebrow.size = Vector2(600, 30)
	add_child(eyebrow)

	# 메인 타이틀
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", P.BRASS_300)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = tr("ui.main_menu.title")
	title.position = Vector2(660, 235)
	title.size = Vector2(600, 110)
	add_child(title)
	LabelUtils.fit_text(title, 72, 36)

	# 구분선
	var divider := ColorRect.new()
	divider.color = P.BRASS_700
	divider.position = Vector2(760, 360)
	divider.size = Vector2(400, 1)
	add_child(divider)

	# 새 게임 버튼 (Primary)
	var btn_new := Button.new()
	btn_new.theme_type_variation = "PrimaryButton"
	btn_new.position = Vector2(810, 420)
	btn_new.size = Vector2(300, 60)
	btn_new.add_theme_font_size_override("font_size", 16)
	btn_new.text = tr("ui.main_menu.new_game")
	btn_new.pressed.connect(_on_new_game)
	add_child(btn_new)
	LabelUtils.fit_text(btn_new, 16, 12)
	SacredTheme.animate_button(btn_new)

	# 이어하기 버튼 (Primary — 있을 때만)
	if SaveManager.has_save():
		var btn_cont := Button.new()
		btn_cont.theme_type_variation = "PrimaryButton"
		btn_cont.position = Vector2(810, 500)
		btn_cont.size = Vector2(300, 60)
		btn_cont.add_theme_font_size_override("font_size", 16)
		btn_cont.text = tr("ui.main_menu.continue")
		btn_cont.pressed.connect(_on_continue)
		add_child(btn_cont)
		LabelUtils.fit_text(btn_cont, 16, 12)
		SacredTheme.animate_button(btn_cont)

	# 하단 금빛 수평선 장식
	var bot_line := ColorRect.new()
	bot_line.color = P.BRASS_700
	bot_line.position = Vector2(0, 900)
	bot_line.size = Vector2(1920, 1)
	add_child(bot_line)

func _on_new_game() -> void:
	SaveManager.clear_save()
	get_tree().change_scene_to_file("res://scenes/chapter_select/chapter_select_scene.tscn")

func _on_continue() -> void:
	SaveManager.load_save()
	get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
