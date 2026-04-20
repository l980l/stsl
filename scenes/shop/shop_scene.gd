# scenes/shop/shop_scene.gd
extends Node2D

var _inventory: Dictionary = {}
var _relic_btn: Button = null
var _remove_panel: Control = null

func _ready() -> void:
	_inventory = GameManager.generate_shop_inventory()
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.05, 0.02)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var title := Label.new()
	title.text = "상점"
	title.position = Vector2(860, 20)
	title.size = Vector2(200, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1.0, 0.85, 0.3)
	add_child(title)

	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLabel"
	gold_lbl.text = "보유 골드: %d" % GameManager.gold
	gold_lbl.position = Vector2(50, 30)
	gold_lbl.size = Vector2(300, 40)
	gold_lbl.add_theme_font_size_override("font_size", 20)
	add_child(gold_lbl)

	_build_card_section()
	_build_relic_section()
	_build_service_section()

	var exit_btn := Button.new()
	exit_btn.text = "나가기"
	exit_btn.position = Vector2(860, 980)
	exit_btn.size = Vector2(200, 50)
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(_on_exit)
	add_child(exit_btn)

func _build_card_section() -> void:
	var sec_lbl := Label.new()
	sec_lbl.text = "카드 구매 (%d 골드)" % _inventory.get("card_price", 75)
	sec_lbl.position = Vector2(100, 100)
	sec_lbl.size = Vector2(400, 40)
	sec_lbl.add_theme_font_size_override("font_size", 18)
	add_child(sec_lbl)

	var cards: Array = _inventory.get("cards", [])
	var price: int = _inventory.get("card_price", 75)
	for i in range(cards.size()):
		var card: Resource = cards[i]

		var panel := ColorRect.new()
		panel.color = Color(0.15, 0.12, 0.08)
		panel.position = Vector2(100 + i * 320, 150)
		panel.size = Vector2(280, 180)
		add_child(panel)

		var name_lbl := Label.new()
		name_lbl.text = card.card_name
		name_lbl.position = Vector2(110 + i * 320, 160)
		name_lbl.size = Vector2(260, 40)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		add_child(name_lbl)

		var owner_lbl := Label.new()
		owner_lbl.text = "[%s] 비용 %d" % [card.owner_id, card.cost]
		owner_lbl.position = Vector2(110 + i * 320, 205)
		owner_lbl.size = Vector2(260, 30)
		owner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		owner_lbl.add_theme_font_size_override("font_size", 13)
		owner_lbl.modulate = Color(0.8, 0.8, 0.8)
		add_child(owner_lbl)

		var btn := Button.new()
		btn.text = "구매 (%d 골드)" % price
		btn.position = Vector2(110 + i * 320, 280)
		btn.size = Vector2(260, 40)
		btn.add_theme_font_size_override("font_size", 14)
		var captured_card := card
		var captured_btn := btn
		btn.pressed.connect(func(): _on_buy_card(captured_card, captured_btn, price))
		add_child(btn)

func _build_relic_section() -> void:
	var sec_lbl := Label.new()
	sec_lbl.text = "릴릭 구매 (%d 골드)" % _inventory.get("relic_price", 150)
	sec_lbl.position = Vector2(1100, 100)
	sec_lbl.size = Vector2(400, 40)
	sec_lbl.add_theme_font_size_override("font_size", 18)
	add_child(sec_lbl)

	var relic = _inventory.get("relic", null)
	var price: int = _inventory.get("relic_price", 150)

	var panel := ColorRect.new()
	panel.color = Color(0.15, 0.12, 0.08)
	panel.position = Vector2(1100, 150)
	panel.size = Vector2(600, 180)
	add_child(panel)

	if relic:
		var name_lbl := Label.new()
		name_lbl.text = relic.relic_name
		name_lbl.position = Vector2(1110, 160)
		name_lbl.size = Vector2(580, 40)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.85, 0.3)
		add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = relic.description
		desc_lbl.position = Vector2(1110, 205)
		desc_lbl.size = Vector2(580, 60)
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_lbl.modulate = Color(0.8, 0.8, 0.8)
		add_child(desc_lbl)

		_relic_btn = Button.new()
		_relic_btn.text = "구매 (%d 골드)" % price
		_relic_btn.position = Vector2(1260, 285)
		_relic_btn.size = Vector2(280, 40)
		_relic_btn.add_theme_font_size_override("font_size", 14)
		_relic_btn.pressed.connect(func(): _on_buy_relic(relic, price))
		add_child(_relic_btn)
	else:
		var empty_lbl := Label.new()
		empty_lbl.text = "재고 없음"
		empty_lbl.position = Vector2(1110, 205)
		empty_lbl.size = Vector2(580, 40)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.modulate = Color(0.5, 0.5, 0.5)
		add_child(empty_lbl)

func _build_service_section() -> void:
	var sec_lbl := Label.new()
	sec_lbl.text = "서비스"
	sec_lbl.position = Vector2(100, 400)
	sec_lbl.size = Vector2(200, 40)
	sec_lbl.add_theme_font_size_override("font_size", 18)
	add_child(sec_lbl)

	var heal_btn := Button.new()
	var heal_price: int = _inventory.get("heal_price", 30)
	var heal_amount: int = _inventory.get("heal_amount", 20)
	heal_btn.text = "회복 %dHP (%d 골드)" % [heal_amount, heal_price]
	heal_btn.position = Vector2(100, 450)
	heal_btn.size = Vector2(320, 50)
	heal_btn.add_theme_font_size_override("font_size", 16)
	heal_btn.pressed.connect(func(): _on_heal(heal_amount, heal_price))
	add_child(heal_btn)

	var remove_btn := Button.new()
	var remove_price: int = _inventory.get("remove_price", 100)
	remove_btn.text = "카드 제거 (%d 골드)" % remove_price
	remove_btn.position = Vector2(460, 450)
	remove_btn.size = Vector2(320, 50)
	remove_btn.add_theme_font_size_override("font_size", 16)
	remove_btn.pressed.connect(func(): _on_open_remove_panel(remove_btn, remove_price))
	add_child(remove_btn)

func _on_buy_card(card: Resource, btn: Button, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	DeckManager.add_card_to_deck(card)
	btn.disabled = true
	btn.text = "구매 완료"
	_refresh_gold_label()

func _on_buy_relic(relic: Resource, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	GameManager.add_relic(relic)
	if _relic_btn:
		_relic_btn.disabled = true
		_relic_btn.text = "구매 완료"
	_refresh_gold_label()

func _on_heal(amount: int, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	for hero in TeamManager.heroes:
		TeamManager.heal(hero.hero_id, amount)
	_refresh_gold_label()

func _on_open_remove_panel(remove_btn: Button, price: int) -> void:
	if _remove_panel:
		_remove_panel.queue_free()
		_remove_panel = null
		return

	var full_deck: Array = DeckManager.get_full_deck()
	if full_deck.is_empty():
		return

	_remove_panel = Control.new()
	_remove_panel.position = Vector2(100, 520)
	_remove_panel.size = Vector2(1720, 400)
	add_child(_remove_panel)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.95)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1720, 400)
	_remove_panel.add_child(bg)

	var lbl := Label.new()
	lbl.text = "제거할 카드를 선택하세요 (%d 골드)" % price
	lbl.position = Vector2(10, 10)
	lbl.size = Vector2(700, 35)
	lbl.add_theme_font_size_override("font_size", 18)
	_remove_panel.add_child(lbl)

	for i in range(full_deck.size()):
		var card: Resource = full_deck[i]
		var card_btn := Button.new()
		card_btn.text = "%s (비용 %d)" % [card.card_name, card.cost]
		card_btn.position = Vector2(10 + (i % 8) * 210, 55 + (i / 8 as int) * 60)
		card_btn.size = Vector2(200, 50)
		card_btn.add_theme_font_size_override("font_size", 13)
		var captured_card := card
		card_btn.pressed.connect(func(): _on_remove_card(captured_card, remove_btn, price))
		_remove_panel.add_child(card_btn)

func _on_remove_card(card: Resource, remove_btn: Button, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	DeckManager.remove_from_deck(card)
	remove_btn.disabled = true
	remove_btn.text = "카드 제거 완료"
	if _remove_panel:
		_remove_panel.queue_free()
		_remove_panel = null
	_refresh_gold_label()

func _refresh_gold_label() -> void:
	var lbl := get_node_or_null("GoldLabel")
	if lbl:
		lbl.text = "보유 골드: %d" % GameManager.gold

func _on_exit() -> void:
	GameManager.complete_shop()
