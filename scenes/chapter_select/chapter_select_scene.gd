# scenes/chapter_select/chapter_select_scene.gd
extends Node2D

const _CHAPTERS := [
	{"id": 1, "name": "챕터 1 — 지중해·북방 신화", "desc": "그리스·이집트·북유럽 신화의 적이 각 Act에 랜덤 배정됩니다."},
	{"id": 2, "name": "챕터 2 — 동아시아 신화", "desc": "한국·중국·일본 신화의 적이 각 Act에 랜덤 배정됩니다."},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "챕터 선택"
	title.position = Vector2(660, 120)
	title.size = Vector2(600, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)

	for i in range(_CHAPTERS.size()):
		_make_chapter_card(_CHAPTERS[i], i)

	var btn_back := Button.new()
	btn_back.text = "뒤로"
	btn_back.position = Vector2(60, 960)
	btn_back.size = Vector2(200, 60)
	btn_back.add_theme_font_size_override("font_size", 24)
	btn_back.pressed.connect(_on_back)
	add_child(btn_back)

func _make_chapter_card(chapter: Dictionary, idx: int) -> void:
	var card_x := 300 + idx * 700
	var panel := ColorRect.new()
	panel.color = Color(0.15, 0.15, 0.25)
	panel.position = Vector2(card_x, 300)
	panel.size = Vector2(600, 520)
	add_child(panel)

	var name_label := Label.new()
	name_label.text = chapter["name"]
	name_label.position = Vector2(card_x + 20, 330)
	name_label.size = Vector2(560, 60)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = chapter["desc"]
	desc_label.position = Vector2(card_x + 20, 420)
	desc_label.size = Vector2(560, 300)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 22)
	add_child(desc_label)

	var unlocked := ProgressManager.is_chapter_unlocked(chapter["id"])
	var btn := Button.new()
	btn.text = ("챕터 시작" if unlocked else "잠금")
	btn.disabled = not unlocked
	btn.position = Vector2(card_x + 150, 740)
	btn.size = Vector2(300, 60)
	btn.add_theme_font_size_override("font_size", 24)
	if unlocked:
		var chapter_id: int = chapter["id"]
		btn.pressed.connect(func(): _on_chapter_selected(chapter_id))
	add_child(btn)

	if not unlocked:
		var hint := Label.new()
		hint.text = "이전 챕터를 클리어하면 해금됩니다."
		hint.position = Vector2(card_x + 20, 680)
		hint.size = Vector2(560, 40)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 20)
		hint.modulate = Color(0.8, 0.5, 0.5)
		add_child(hint)

func _on_chapter_selected(chapter_id: int) -> void:
	GameManager.current_chapter = chapter_id
	get_tree().change_scene_to_file("res://scenes/hero_select/hero_select_scene.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
