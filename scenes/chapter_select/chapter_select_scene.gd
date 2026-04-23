# scenes/chapter_select/chapter_select_scene.gd
extends Node2D

const _CHAPTERS := [
	{"id": 1, "name_key": "ui.chapter_select.chapter1.name", "desc_key": "ui.chapter_select.chapter1.desc"},
	{"id": 2, "name_key": "ui.chapter_select.chapter2.name", "desc_key": "ui.chapter_select.chapter2.desc"},
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
	title.text = tr("ui.chapter_select.title")
	title.position = Vector2(660, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	title.modulate = Color(1.0, 0.9, 0.4)
	add_child(title)
	title.size = Vector2(600, 100)
	LabelUtils.fit_text(title, 64, 36)

	for i in range(_CHAPTERS.size()):
		_make_chapter_card(_CHAPTERS[i], i)

	var btn_back := Button.new()
	btn_back.text = tr("ui.chapter_select.back")
	btn_back.position = Vector2(60, 960)
	btn_back.add_theme_font_size_override("font_size", 24)
	btn_back.pressed.connect(_on_back)
	add_child(btn_back)
	btn_back.size = Vector2(200, 60)
	LabelUtils.fit_text(btn_back, 24, 14)

func _make_chapter_card(chapter: Dictionary, idx: int) -> void:
	var card_x := 300 + idx * 700
	var panel := ColorRect.new()
	panel.color = Color(0.15, 0.15, 0.25)
	panel.position = Vector2(card_x, 300)
	panel.size = Vector2(600, 520)
	add_child(panel)

	var name_label := Label.new()
	name_label.text = tr(chapter["name_key"])
	name_label.position = Vector2(card_x + 20, 330)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.clip_contents = true
	name_label.add_theme_font_size_override("font_size", 32)
	add_child(name_label)
	name_label.size = Vector2(560, 80)
	LabelUtils.fit_text(name_label, 32, 18)

	var desc_label := Label.new()
	desc_label.text = tr(chapter["desc_key"])
	desc_label.position = Vector2(card_x + 20, 430)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_contents = true
	desc_label.add_theme_font_size_override("font_size", 22)
	add_child(desc_label)
	desc_label.size = Vector2(560, 280)
	LabelUtils.fit_text(desc_label, 22, 12)

	var _pm = get_node_or_null("/root/ProgressManager")
	var unlocked: bool = _pm.is_chapter_unlocked(int(chapter["id"])) if _pm else true
	var btn := Button.new()
	btn.text = tr("ui.chapter_select.start") if unlocked else tr("ui.chapter_select.locked")
	btn.disabled = not unlocked
	btn.position = Vector2(card_x + 150, 740)
	btn.add_theme_font_size_override("font_size", 24)
	if unlocked:
		var chapter_id: int = chapter["id"]
		btn.pressed.connect(func(): _on_chapter_selected(chapter_id))
	add_child(btn)
	btn.size = Vector2(300, 60)
	LabelUtils.fit_text(btn, 24, 14)

	if not unlocked:
		var hint := Label.new()
		hint.text = tr("ui.chapter_select.unlock_hint")
		hint.position = Vector2(card_x + 20, 680)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 20)
		hint.modulate = Color(0.8, 0.5, 0.5)
		add_child(hint)
		hint.size = Vector2(560, 40)
		LabelUtils.fit_text(hint, 20, 12)

func _on_chapter_selected(chapter_id: int) -> void:
	GameManager.current_chapter = chapter_id
	get_tree().change_scene_to_file("res://scenes/hero_select/hero_select_scene.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu_scene.tscn")
