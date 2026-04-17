# scenes/hero_select/hero_select_scene.gd
extends Node2D

const HEROES := [
	{
		"id": "napoleon",
		"name": "나폴레옹",
		"hp": 70,
		"desc": "포지션: 공격형 지휘관\n고유 메카닉: 사기(Morale)\n아키타입: 돌격(Blitz)\n\n스타터: 스트라이크×3 + 디펜드×2",
	},
	{
		"id": "cleopatra",
		"name": "클레오파트라",
		"hp": 60,
		"desc": "포지션: 디버프/조종형\n고유 메카닉: 매혹(Charm)\n아키타입: 독살(Venom)\n\n스타터: 독침×2 + 왕실 방어×2",
	},
	{
		"id": "yi_sun_sin",
		"name": "이순신",
		"hp": 75,
		"desc": "포지션: 방어형 역공\n고유 메카닉: 진형(Formation)\n아키타입: 거북선(Turtle)\n\n스타터: 방패×2 + 역공×2",
	},
]

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var is_recruit: bool = GameManager.pending_boss_recruit

	var owned_ids: Array = []
	if is_recruit:
		var tm = Engine.get_singleton("TeamManager") if Engine.has_singleton("TeamManager") else null
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

	const CARD_W := 440
	const CARD_H := 500
	const GAP := 60
	var total_w: float = HEROES.size() * CARD_W + (HEROES.size() - 1) * GAP
	var start_x: float = (1920.0 - total_w) / 2.0

	for i in range(HEROES.size()):
		var data: Dictionary = HEROES[i]
		var x: float = start_x + i * (CARD_W + GAP)
		var already_owned: bool = is_recruit and data["id"] in owned_ids

		var panel := ColorRect.new()
		panel.color = Color(0.05, 0.05, 0.08) if already_owned else Color(0.1, 0.1, 0.2)
		panel.position = Vector2(x, 160)
		panel.size = Vector2(CARD_W, CARD_H)
		add_child(panel)

		var name_lbl := Label.new()
		name_lbl.text = "%s\nHP %d" % [data["name"], data["hp"]]
		name_lbl.position = Vector2(x + 10, 170)
		name_lbl.size = Vector2(CARD_W - 20, 70)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 24)
		add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.position = Vector2(x + 20, 260)
		desc_lbl.size = Vector2(CARD_W - 40, 360)
		desc_lbl.add_theme_font_size_override("font_size", 16)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(desc_lbl)

		var btn := Button.new()
		if already_owned:
			btn.text = "이미 보유 중"
			btn.disabled = true
		elif is_recruit:
			btn.text = data["name"] + " 영입"
		else:
			btn.text = data["name"] + " 선택"
		btn.position = Vector2(x + 60, 690)
		btn.size = Vector2(CARD_W - 120, 60)
		btn.add_theme_font_size_override("font_size", 20)
		if not already_owned:
			var captured_id: String = data["id"]
			btn.pressed.connect(func(): _on_hero_selected(captured_id))
		add_child(btn)

func _on_hero_selected(hero_id: String) -> void:
	if GameManager.pending_boss_recruit:
		GameManager.complete_hero_recruit(hero_id)
	else:
		GameManager.start_run(hero_id)
		get_tree().change_scene_to_file("res://scenes/map/map_scene.tscn")
