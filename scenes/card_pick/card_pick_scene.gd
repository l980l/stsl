# scenes/card_pick/card_pick_scene.gd
extends Node2D

const CARD_W := 140
const CARD_H := 200
const COLS := 6

var _picked_count: int = 0
var _pick_max: int = 1
var _card_buttons: Array = []  # {card, btn}
var _title_label: Label = null

func _ready() -> void:
	if GameManager.card_rewards.is_empty():
		GameManager.complete_card_pick()
		return
	_pick_max = GameManager.card_rewards_pick_count
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	_title_label = Label.new()
	_title_label.text = "카드를 선택하세요 (%d/%d)" % [_picked_count, _pick_max]
	_title_label.position = Vector2(660, 30)
	_title_label.size = Vector2(600, 60)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	add_child(_title_label)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(160, 110)
	scroll.size = Vector2(1600, 870)
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)

	for card in GameManager.card_rewards:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
		var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
		var cost: int = card.get("cost") if card.get("cost") != null else 0
		btn.text = "[%d]\n%s\n%s" % [cost, card_name, card.get("owner_id") if card.get("owner_id") != null else ""]
		btn.add_theme_font_size_override("font_size", 15)
		var captured_card := card
		var captured_btn := btn
		btn.pressed.connect(func(): _on_card_selected(captured_card, captured_btn))
		grid.add_child(btn)
		_card_buttons.append({"card": card, "btn": btn})

	var skip_btn := Button.new()
	skip_btn.position = Vector2(880, 1010)
	skip_btn.size = Vector2(160, 50)
	skip_btn.text = "건너뛰기"
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)

func _on_card_selected(card: Resource, btn: Button) -> void:
	DeckManager.add_card_to_deck(card)
	btn.disabled = true
	_picked_count += 1
	_title_label.text = "카드를 선택하세요 (%d/%d)" % [_picked_count, _pick_max]
	if _picked_count >= _pick_max:
		GameManager.complete_card_pick()

func _on_skip() -> void:
	GameManager.complete_card_pick()
