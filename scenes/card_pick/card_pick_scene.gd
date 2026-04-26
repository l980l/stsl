# scenes/card_pick/card_pick_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const CARD_W := 140
const CARD_H := 200

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
	bg.color = SacredPalette.INK_1000
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	_title_label = Label.new()
	_title_label.text = tr("ui.card_pick.title") % [_picked_count, _pick_max]
	_title_label.position = Vector2(660, 100)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.theme_type_variation = "TitleLabel"
	_title_label.add_theme_font_size_override("font_size", 32)
	add_child(_title_label)
	_title_label.size = Vector2(600, 60)
	LabelUtils.fit_text(_title_label, 32, 18)

	var start_x: float = (1920.0 - GameManager.card_rewards.size() * 160) / 2.0  # 카드 폭 140 + 간격 20

	for i in range(GameManager.card_rewards.size()):
		var card: Resource = GameManager.card_rewards[i]
		var node: CardScene = CARD_SCENE.instantiate()
		node.position = Vector2(start_x + i * 160, 400)
		node.setup(card, node.Mode.REWARD)
		node.card_clicked.connect(func(c): _on_card_selected(c, node))
		add_child(node)
		_card_buttons.append({"card": card, "node": node})

	var skip_btn := Button.new()
	skip_btn.position = Vector2(880, 680)
	skip_btn.text = tr("ui.card_pick.btn_skip")
	skip_btn.theme_type_variation = "VowButton"
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(_on_skip)
	add_child(skip_btn)
	skip_btn.size = Vector2(160, 50)
	LabelUtils.fit_text(skip_btn, 18, 12)
	SacredTheme.animate_button(skip_btn)

func _on_card_selected(card: Resource, node) -> void:
	DeckManager.add_card_to_deck(card)
	node.set_disabled(true)
	_picked_count += 1
	_title_label.text = tr("ui.card_pick.title") % [_picked_count, _pick_max]
	if _picked_count >= _pick_max:
		GameManager.complete_card_pick()

func _on_skip() -> void:
	GameManager.complete_card_pick()
