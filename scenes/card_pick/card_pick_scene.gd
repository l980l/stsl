# scenes/card_pick/card_pick_scene.gd
extends Node2D

const CARD_W := 140
const CARD_H := 200

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 제목
	var title := Label.new()
	title.text = "카드를 선택하세요 (1장)"
	title.position = Vector2(660, 100)
	title.size = Vector2(600, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var rewards := GameManager.card_rewards
	if rewards.is_empty():
		# 보상 없음 — 바로 맵으로
		GameManager.complete_card_pick()
		return

	var total_w: float = rewards.size() * (CARD_W + 20) - 20
	var start_x: float = (1920.0 - total_w) / 2.0

	for i in range(rewards.size()):
		var card: Resource = rewards[i]
		var btn := Button.new()
		btn.position = Vector2(start_x + i * (CARD_W + 20), 400)
		btn.size = Vector2(CARD_W, CARD_H)
		var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
		btn.text = "[%d]\n%s\n%s" % [card.cost, card_name, card.get("owner_id") if card.get("owner_id") != null else ""]
		btn.add_theme_font_size_override("font_size", 15)
		var captured_card := card
		btn.pressed.connect(func(): _on_card_selected(captured_card))
		add_child(btn)

	# 건너뛰기 버튼
	var skip_btn := Button.new()
	skip_btn.position = Vector2(880, 680)
	skip_btn.size = Vector2(160, 50)
	skip_btn.text = "건너뛰기"
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

func _on_card_selected(card: Resource) -> void:
	DeckManager.add_card_to_deck(card)
	GameManager.complete_card_pick()

func _on_skip() -> void:
	GameManager.complete_card_pick()
