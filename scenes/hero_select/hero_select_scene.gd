# scenes/hero_select/hero_select_scene.gd
extends Node2D

const _HR = preload("res://resources/heroes/hero_registry.gd")

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var is_recruit: bool = GameManager.pending_boss_recruit
	var pm = get_node_or_null("/root/ProgressManager")

	var owned_ids: Array = []
	if is_recruit:
		var tm = get_node_or_null("/root/TeamManager")
		if tm:
			for h in tm.heroes:
				owned_ids.append(h.hero_id)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "동료를 영입하세요" if is_recruit else "시작 영웅을 선택하세요"
	title.position = Vector2(660, 60)
	title.size = Vector2(600, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	add_child(title)

	var hero_ids: Array = _HR.all_hero_ids()
	const CARD_W := 440
	const CARD_H := 480
	const GAP_X := 60
	const GAP_Y := 50
	const COLS := 3
	const ROW_START_Y := 130

	for i in range(hero_ids.size()):
		var hid: String = hero_ids[i]
		var info: Dictionary = _HR.get_display_info(hid)
		var col: int = i % COLS
		var row: int = i / COLS
		var row_count: int = (hero_ids.size() + COLS - 1) / COLS
		var cols_in_row: int = COLS if row < row_count - 1 else ((hero_ids.size() - 1) % COLS + 1)
		var row_w: float = cols_in_row * CARD_W + (cols_in_row - 1) * GAP_X
		var x: float = (1920.0 - row_w) / 2.0 + col * (CARD_W + GAP_X)
		var y: float = ROW_START_Y + row * (CARD_H + GAP_Y)

		var already_owned: bool = is_recruit and hid in owned_ids
		var is_locked: bool = (not is_recruit) and pm != null and not pm.is_hero_unlocked(hid)

		var panel_color := Color(0.05, 0.05, 0.08) if (already_owned or is_locked) else Color(0.1, 0.1, 0.2)
		var panel := ColorRect.new()
		panel.color = panel_color
		panel.position = Vector2(x, y)
		panel.size = Vector2(CARD_W, CARD_H)
		add_child(panel)

		var name_lbl := Label.new()
		name_lbl.text = "%s\nHP %d" % [info.get("name", hid), info.get("hp", 0)]
		name_lbl.position = Vector2(x + 10, y + 10)
		name_lbl.size = Vector2(CARD_W - 20, 70)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 24)
		add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = info.get("desc", "")
		desc_lbl.position = Vector2(x + 20, y + 90)
		desc_lbl.size = Vector2(CARD_W - 40, 280)
		desc_lbl.add_theme_font_size_override("font_size", 15)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(desc_lbl)

		if is_locked:
			var lock_lbl := Label.new()
			var unlock_desc: String = info.get("unlock_description", "")
			lock_lbl.text = "🔒 잠금\n" + (unlock_desc if unlock_desc != "" else "해금 조건 미달성")
			lock_lbl.position = Vector2(x + 20, y + 380)
			lock_lbl.size = Vector2(CARD_W - 40, 50)
			lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			lock_lbl.add_theme_font_size_override("font_size", 14)
			add_child(lock_lbl)

		var btn := Button.new()
		if already_owned:
			btn.text = "이미 보유 중"
			btn.disabled = true
		elif is_locked:
			btn.text = "잠금"
			btn.disabled = true
		elif is_recruit:
			btn.text = info.get("name", hid) + " 영입"
		else:
			btn.text = info.get("name", hid) + " 선택"
		btn.position = Vector2(x + 60, y + 410)
		btn.size = Vector2(CARD_W - 120, 55)
		btn.add_theme_font_size_override("font_size", 20)
		if not already_owned and not is_locked:
			var captured_id: String = hid
			btn.pressed.connect(func(): _on_hero_selected(captured_id))
		add_child(btn)

func _on_hero_selected(hero_id: String) -> void:
	if GameManager.pending_boss_recruit:
		GameManager.complete_hero_recruit(hero_id)
	else:
		GameManager.start_run(hero_id, GameManager.current_chapter)
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
