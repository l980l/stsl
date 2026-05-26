# scenes/card_upgrade/card_upgrade_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const CARD_SCENE_MODERN := preload("res://scenes/card/card_scene_v2.tscn")
func _make_card() -> Control:
	return CARD_SCENE_MODERN.instantiate() if GameSettings.card_frame_key == "modern" else CARD_SCENE.instantiate()
const CARD_W := 140
const CARD_H := 200
const COLS := 6

func _ready() -> void:
	var upgradeable := _get_upgradeable_cards()
	if upgradeable.is_empty():
		GameManager.complete_card_upgrade()
		return
	_build_ui(upgradeable)

func _get_upgradeable_cards() -> Array:
	# hand도 포함 — 전투 중 손패 카드는 discard_pile에 없을 수 있음
	var all: Array = DeckManager.draw_pile.duplicate()
	all.append_array(DeckManager.discard_pile)
	all.append_array(DeckManager.hand)
	var result: Array = []
	for card in all:
		if card.upgrade_level < card.max_upgrade_level():
			result.append(card)
	return result

func _build_ui(upgradeable: Array) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = tr("ui.card_upgrade.title")
	title.position = Vector2(560, 30)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)
	title.size = Vector2(800, 60)
	LabelUtils.fit_text(title, 32, 18)

	var scroll_w: int = COLS * (CARD_W + 20) - 20  # 940
	var scroll := ScrollContainer.new()
	scroll.position = Vector2((1920 - scroll_w) / 2.0, 110)
	scroll.size = Vector2(scroll_w, 870)
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.custom_minimum_size = Vector2(scroll_w, 0)
	scroll.add_child(grid)

	for card: Resource in upgradeable:
		var node: Control = _make_card()
		node.scale = Vector2.ONE * GameSettings.get_card_native_scale()
		node.pivot_offset = Vector2(70.0, 100.0) * GameSettings.get_card_native_pivot_mul()
		node.setup(card, node.Mode.UPGRADE)
		node.card_clicked.connect(func(c): _on_card_selected(c))
		grid.add_child(node)

	var skip_btn := Button.new()
	skip_btn.position = Vector2(880, 1000)
	skip_btn.text = tr("ui.card_upgrade.btn_skip")
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(GameManager.complete_card_upgrade)
	add_child(skip_btn)
	skip_btn.size = Vector2(160, 50)
	LabelUtils.fit_text(skip_btn, 18, 12)

func _on_card_selected(card: Resource) -> void:
	GameManager.upgrade_card(card)
	GameManager.complete_card_upgrade()
