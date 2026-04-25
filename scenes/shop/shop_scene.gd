# scenes/shop/shop_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const CARD_W := 140
const CARD_H := 200
const CARD_GAP := 20
const RELIC_PANEL_W := 420
const RELIC_PANEL_GAP := 20
const RELIC_PANEL_H := 150

var _inventory: Dictionary = {}
var _remove_panel: Control = null
var _hover_preview: CardScene = null

func _ready() -> void:
	_inventory = GameManager.generate_shop_inventory()
	_build_ui()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color = P.INK_1000
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.text = "— MARKET —"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(760, 14)
	eyebrow.size = Vector2(400, 24)
	add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = tr("ui.shop.title")
	title.position = Vector2(760, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	title.size = Vector2(400, 50)
	LabelUtils.fit_text(title, 32, 18)

	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLabel"
	gold_lbl.theme_type_variation = "EyebrowLabel"
	gold_lbl.add_theme_font_size_override("font_size", 42)
	gold_lbl.text = tr("ui.shop.gold_label") % GameManager.gold
	gold_lbl.position = Vector2(30, 20)
	gold_lbl.size = Vector2(380, 60)
	add_child(gold_lbl)

	_build_card_section()
	_build_relic_section()
	_build_service_section()

	var exit_btn := Button.new()
	exit_btn.theme_type_variation = "VowButton"
	exit_btn.text = tr("ui.shop.btn_exit")
	exit_btn.position = Vector2(860, 790)
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(_on_exit)
	add_child(exit_btn)
	exit_btn.size = Vector2(200, 50)
	LabelUtils.fit_text(exit_btn, 20, 12)
	SacredTheme.animate_button(exit_btn)

func _build_card_section() -> void:
	var cards: Array = _inventory.get("cards", [])
	var prices: Array = _inventory.get("card_prices", [])

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text = "— Cards —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position = Vector2(460, 100)
	sec_lbl.size = Vector2(1000, 26)
	add_child(sec_lbl)

	var n := cards.size()
	if n == 0:
		return
	var total_w := n * CARD_W + (n - 1) * CARD_GAP
	var start_x := int((1920 - total_w) / 2)

	for i in range(n):
		var card: Resource = cards[i]
		var price: int = prices[i] if i < prices.size() else 75
		var cx := start_x + i * (CARD_W + CARD_GAP)

		var node: CardScene = CARD_SCENE.instantiate()
		node.position = Vector2(cx, 128)
		node.setup(card, CardScene.Mode.REWARD)
		var captured_card := card
		node.mouse_entered.connect(func(): _show_hover_preview(captured_card))
		node.mouse_exited.connect(func(): _hide_hover_preview())
		add_child(node)

		var rarity_lbl := Label.new()
		rarity_lbl.theme_type_variation = "SubLabel"
		rarity_lbl.text = _rarity_label(card.rarity)
		rarity_lbl.position = Vector2(cx, 332)
		rarity_lbl.size = Vector2(CARD_W, 22)
		rarity_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rarity_lbl.modulate = _rarity_color(card.rarity)
		add_child(rarity_lbl)

		var price_lbl := Label.new()
		price_lbl.theme_type_variation = "SubLabel"
		price_lbl.text = "%dg" % price
		price_lbl.position = Vector2(cx, 354)
		price_lbl.size = Vector2(CARD_W, 20)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.modulate = SacredPalette.BRASS_400
		add_child(price_lbl)

		var btn := Button.new()
		btn.theme_type_variation = "PrimaryButton"
		btn.text = tr("ui.shop.btn_buy") % price
		btn.position = Vector2(cx, 378)
		btn.size = Vector2(CARD_W, 36)
		btn.add_theme_font_size_override("font_size", 13)
		var captured_btn := btn
		btn.pressed.connect(func(): _on_buy_card(captured_card, captured_btn, price))
		add_child(btn)
		SacredTheme.animate_button(btn)

func _build_relic_section() -> void:
	var P := SacredPalette
	var relics: Array = _inventory.get("relics", [])
	var relic_price: int = _inventory.get("relic_price", 150)

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text = "— Relics (%dg) —" % relic_price
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position = Vector2(460, 432)
	sec_lbl.size = Vector2(1000, 26)
	add_child(sec_lbl)

	if relics.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.theme_type_variation = "SubLabel"
		empty_lbl.text = tr("ui.shop.relic_empty")
		empty_lbl.position = Vector2(660, 480)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size = Vector2(600, 40)
		add_child(empty_lbl)
		return

	var n := relics.size()
	var total_w := n * RELIC_PANEL_W + (n - 1) * RELIC_PANEL_GAP
	var start_x := int((1920 - total_w) / 2)

	for i in range(n):
		var relic: Resource = relics[i]
		var px := start_x + i * (RELIC_PANEL_W + RELIC_PANEL_GAP)
		var py := 462

		var panel := ColorRect.new()
		panel.color = P.INK_800
		panel.position = Vector2(px, py)
		panel.size = Vector2(RELIC_PANEL_W, RELIC_PANEL_H)
		add_child(panel)

		var tex: Texture2D = IconUtils.get_relic_icon(relic.relic_name)
		if tex:
			var icon := TextureRect.new()
			icon.texture = tex
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.position = Vector2(px + 8, py + int((RELIC_PANEL_H - 48) / 2))
			icon.size = Vector2(48, 48)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(icon)

		var name_lbl := Label.new()
		name_lbl.theme_type_variation = "AccentLabel"
		name_lbl.text = tr(relic.relic_name)
		name_lbl.position = Vector2(px + 64, py + 8)
		name_lbl.size = Vector2(RELIC_PANEL_W - 72, 34)
		add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.theme_type_variation = "SubLabel"
		desc_lbl.text = tr(relic.description)
		desc_lbl.position = Vector2(px + 64, py + 46)
		desc_lbl.size = Vector2(RELIC_PANEL_W - 72, 56)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		add_child(desc_lbl)

		var btn := Button.new()
		btn.theme_type_variation = "PrimaryButton"
		btn.text = tr("ui.shop.btn_buy") % relic_price
		btn.position = Vector2(px + 64, py + 106)
		btn.size = Vector2(200, 36)
		btn.add_theme_font_size_override("font_size", 13)
		var captured_relic := relic
		var captured_btn := btn
		btn.pressed.connect(func(): _on_buy_relic(captured_relic, captured_btn, relic_price))
		add_child(btn)
		SacredTheme.animate_button(btn)

func _build_service_section() -> void:
	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text = "— " + tr("ui.shop.sec_service") + " —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position = Vector2(460, 638)
	sec_lbl.size = Vector2(1000, 26)
	add_child(sec_lbl)

	var heal_price: int = _inventory.get("heal_price", 30)
	var heal_amount: int = _inventory.get("heal_amount", 20)
	var heal_btn := Button.new()
	heal_btn.text = tr("ui.shop.btn_heal") % [heal_amount, heal_price]
	heal_btn.position = Vector2(480, 676)
	heal_btn.size = Vector2(380, 50)
	heal_btn.add_theme_font_size_override("font_size", 16)
	heal_btn.pressed.connect(func(): _on_heal(heal_amount, heal_price))
	add_child(heal_btn)
	SacredTheme.animate_button(heal_btn)

	var remove_price: int = _inventory.get("remove_price", 100)
	var remove_btn := Button.new()
	remove_btn.text = tr("ui.shop.btn_remove_card") % remove_price
	remove_btn.position = Vector2(900, 676)
	remove_btn.size = Vector2(380, 50)
	remove_btn.add_theme_font_size_override("font_size", 16)
	remove_btn.pressed.connect(func(): _on_open_remove_panel(remove_btn, remove_price))
	add_child(remove_btn)
	SacredTheme.animate_button(remove_btn)

func _rarity_label(rarity: int) -> String:
	match rarity:
		CardResource.Rarity.COMMON:    return "COMMON"
		CardResource.Rarity.UNCOMMON:  return "UNCOMMON"
		CardResource.Rarity.RARE:      return "RARE"
		CardResource.Rarity.LEGENDARY: return "LEGENDARY"
		CardResource.Rarity.DIVINE:    return "DIVINE"
	return ""

func _rarity_color(rarity: int) -> Color:
	var P := SacredPalette
	match rarity:
		CardResource.Rarity.COMMON:    return Color(0.85, 0.85, 0.85)
		CardResource.Rarity.UNCOMMON:  return P.EMERALD_400
		CardResource.Rarity.RARE:      return P.LAPIS_400
		CardResource.Rarity.LEGENDARY: return P.BRASS_400
		CardResource.Rarity.DIVINE:    return P.AMETHYST_400
	return Color.WHITE

func _show_hover_preview(card: Resource) -> void:
	_hide_hover_preview()
	_hover_preview = CARD_SCENE.instantiate()
	_hover_preview.position = Vector2(1530, 80)
	_hover_preview.z_index = 100
	_hover_preview.setup(card, CardScene.Mode.REWARD)
	add_child(_hover_preview)
	_hover_preview.scale = Vector2(2.0, 2.0)
	_hover_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _hide_hover_preview() -> void:
	if _hover_preview:
		_hover_preview.queue_free()
		_hover_preview = null

func _on_buy_card(card: Resource, btn: Button, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	DeckManager.add_card_to_deck(card)
	btn.disabled = true
	btn.text = tr("ui.shop.btn_purchased")
	_refresh_gold_label()

func _on_buy_relic(relic: Resource, btn: Button, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	GameManager.add_relic(relic)
	btn.disabled = true
	btn.text = tr("ui.shop.btn_purchased")
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
	_remove_panel.position = Vector2(100, 736)
	_remove_panel.size = Vector2(1720, 320)
	add_child(_remove_panel)
	SacredTheme.add_corner_brackets(_remove_panel)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.96)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1720, 320)
	_remove_panel.add_child(bg)

	var lbl := Label.new()
	lbl.text = tr("ui.shop.remove_prompt") % price
	lbl.position = Vector2(10, 10)
	lbl.size = Vector2(700, 35)
	lbl.add_theme_font_size_override("font_size", 18)
	_remove_panel.add_child(lbl)

	for i in range(full_deck.size()):
		var card: Resource = full_deck[i]
		var card_btn := Button.new()
		card_btn.text = tr("ui.shop.card_name_cost") % [tr(card.card_name), card.cost]
		card_btn.position = Vector2(10 + (i % 8) * 210, 55 + int(i / 8.0) * 60)
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
	remove_btn.text = tr("ui.shop.btn_removed")
	if _remove_panel:
		_remove_panel.queue_free()
		_remove_panel = null
	_refresh_gold_label()

func _refresh_gold_label() -> void:
	var lbl := get_node_or_null("GoldLabel")
	if lbl:
		lbl.text = tr("ui.shop.gold_label") % GameManager.gold

func _on_exit() -> void:
	GameManager.complete_shop()
