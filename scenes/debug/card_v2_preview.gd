# scenes/debug/card_v2_preview.gd
# 카드 v2 디자인 prototype 미리보기 — F6 으로 실행. 인게임 영향 0.
# 6장 카드를 3×2 그리드로 표시: 영웅 6명 × 레어도 5종 중 대표 조합.
extends Node2D

const CardV2Scene = preload("res://scenes/card/card_scene_v2.tscn")

const SAMPLES := [
	{"name": "Charge of Glory",    "cost": 2, "card_type": 0, "rarity": "common",    "desc": "Strike one foe for 100 damage. If they fall, draw a card.",  "hero": "napoleon"},
	{"name": "Royal Venom",        "cost": 1, "card_type": 1, "rarity": "uncommon",  "desc": "Apply 4 poison to all enemies. Charm the weakest.",        "hero": "cleopatra"},
	{"name": "Turtle Ship Volley", "cost": 3, "card_type": 0, "rarity": "rare",      "desc": "Deal 60 damage per token. Tokens regroup after strike.",   "hero": "yi_sun_sin"},
	{"name": "Maid's Resolve",     "cost": 2, "card_type": 2, "rarity": "legendary", "desc": "Power: at turn start, lowest HP ally gains 6 block.",     "hero": "joan_of_arc"},
	{"name": "Khan's Decree",      "cost": 0, "card_type": 1, "rarity": "divine",    "desc": "All cards cost 0 this turn. Exhaust.",                     "hero": "genghis_khan"},
	{"name": "Twin Cutter",        "cost": 2, "card_type": 0, "rarity": "rare",      "desc": "Two strikes of 80 damage each. If hand is empty, draw 2.", "hero": "musashi"},
]

const COLS := 3
const COL_GAP := 60
const ROW_GAP := 80
const PAD_X := 200
const PAD_Y := 120

func _ready() -> void:
	# 배경 — 어둡게 (Sacred 톤)
	var bg := ColorRect.new()
	bg.color = Color("#070710")  # ink-1000
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.size = Vector2(1920, 1080)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_layer := CanvasLayer.new()
	bg_layer.layer = -1
	add_child(bg_layer)
	bg_layer.add_child(bg)

	# 타이틀
	var title := Label.new()
	title.text = "CARD V2 PREVIEW · F6"
	title.position = Vector2(PAD_X, 40)
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#c9a84c"))
	add_child(title)

	# 6장 표시 — 3×2, 카드 native 140×200 (인게임 size 동일), preview 에서 scale 2.0 으로 화면 표시
	const CARD_SCALE := 2.0
	const CARD_DISPLAY_W := 140 * CARD_SCALE  # 280
	const CARD_DISPLAY_H := 200 * CARD_SCALE  # 400
	for i in SAMPLES.size():
		var s: Dictionary = SAMPLES[i]
		var col := i % COLS
		var row := i / COLS
		var card := CardV2Scene.instantiate()
		card.scale = Vector2(CARD_SCALE, CARD_SCALE)
		card.position = Vector2(
			PAD_X + col * (CARD_DISPLAY_W + COL_GAP),
			PAD_Y + row * (CARD_DISPLAY_H + ROW_GAP)
		)
		add_child(card)
		card.set_demo_data(
			s["name"], s["cost"], s["card_type"], s["rarity"],
			s["desc"], s["hero"], null
		)
		var rl := Label.new()
		rl.text = "[%s · %s]" % [str(s["rarity"]).to_upper(), str(s["hero"]).to_upper()]
		rl.position = card.position - Vector2(0, 22)
		rl.add_theme_font_size_override("font_size", 11)
		rl.add_theme_color_override("font_color", Color("#7a6660"))
		add_child(rl)
