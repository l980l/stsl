# scenes/card_upgrade/card_upgrade_scene.gd
extends Node2D

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
	var dm: Object = null
	if Engine.has_singleton("DeckManager"):
		dm = Engine.get_singleton("DeckManager")
	elif get_tree() and get_tree().root:
		dm = get_tree().root.get_node_or_null("DeckManager")
	if dm == null:
		return []
	var all: Array = dm.draw_pile.duplicate()
	all.append_array(dm.discard_pile)
	var result: Array = []
	for card in all:
		if not card.get("upgraded"):
			result.append(card)
	return result

func _build_ui(upgradeable: Array) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "강화할 카드를 선택하세요"
	title.position = Vector2(660, 30)
	title.size = Vector2(600, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	add_child(title)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(160, 110)
	scroll.size = Vector2(1600, 870)
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	scroll.add_child(grid)

	for card in upgradeable:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(CARD_W, CARD_H)
		var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
		var cost: int = card.get("cost") if card.get("cost") != null else 0
		var owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
		btn.text = "[%d]\n%s\n%s\n→ 강화" % [cost, card_name, owner]
		btn.add_theme_font_size_override("font_size", 14)
		var captured_card := card
		btn.pressed.connect(func(): _on_card_selected(captured_card))
		grid.add_child(btn)

	var skip_btn := Button.new()
	skip_btn.text = "건너뛰기"
	skip_btn.position = Vector2(880, 1010)
	skip_btn.size = Vector2(160, 50)
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(GameManager.complete_card_upgrade)
	add_child(skip_btn)

func _on_card_selected(card: Resource) -> void:
	GameManager.upgrade_card(card)
	GameManager.complete_card_upgrade()
