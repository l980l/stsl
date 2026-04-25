# scenes/shop/shop_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const CARD_W  := 140
const CARD_H  := 200
const CARD_GAP := 20

const RELIC_PANEL_W   := 400
const RELIC_PANEL_H   := 200
const RELIC_PANEL_GAP := 18

const SVC_PANEL_W   := 380
const SVC_PANEL_H   := 110
const SVC_PANEL_GAP := 20

var _inventory:          Dictionary  = {}
var _remove_layer:       CanvasLayer = null
var _card_tweens:        Dictionary  = {}
var _remove_card_tweens: Dictionary  = {}
var _card_removed:       bool        = false

func _ready() -> void:
	_inventory = GameManager.generate_shop_inventory()
	_build_ui()

func _unhandled_input(ev: InputEvent) -> void:
	if _remove_layer and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_hide_remove_panel()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color    = P.INK_1000
	bg.position = Vector2.ZERO
	bg.size     = Vector2(1920, 1080)
	add_child(bg)

	var eyebrow := Label.new()
	eyebrow.theme_type_variation   = "EyebrowLabel"
	eyebrow.text                   = "— MARKET —"
	eyebrow.horizontal_alignment   = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position               = Vector2(760, 14)
	eyebrow.size                   = Vector2(400, 24)
	add_child(eyebrow)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text                 = tr("ui.shop.title")
	title.position             = Vector2(760, 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	title.size = Vector2(400, 50)
	LabelUtils.fit_text(title, 32, 18)

	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLabel"
	gold_lbl.theme_type_variation = "EyebrowLabel"
	gold_lbl.add_theme_font_size_override("font_size", 42)
	gold_lbl.text     = tr("ui.shop.gold_label") % GameManager.gold
	gold_lbl.position = Vector2(30, 20)
	gold_lbl.size     = Vector2(380, 60)
	add_child(gold_lbl)

	_build_card_section()
	_build_relic_section()
	_build_service_section()

	var exit_btn := Button.new()
	exit_btn.theme_type_variation = "VowButton"
	exit_btn.text = tr("ui.shop.btn_exit")
	exit_btn.position = Vector2(860, 820)
	exit_btn.add_theme_font_size_override("font_size", 20)
	exit_btn.pressed.connect(_on_exit)
	add_child(exit_btn)
	exit_btn.size = Vector2(200, 50)
	LabelUtils.fit_text(exit_btn, 20, 12)
	SacredTheme.animate_button(exit_btn)

# ── 카드 섹션 ─────────────────────────────────────────────
func _build_card_section() -> void:
	var cards:  Array = _inventory.get("cards",       [])
	var prices: Array = _inventory.get("card_prices", [])

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text                 = "— Cards —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position             = Vector2(460, 100)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	var n := cards.size()
	if n == 0:
		return
	var total_w := n * CARD_W + (n - 1) * CARD_GAP
	var start_x := int((1920 - total_w) / 2)

	for i in range(n):
		var card: Resource = cards[i]
		var price: int     = prices[i] if i < prices.size() else 75
		var cx := start_x + i * (CARD_W + CARD_GAP)

		var node: CardScene = CARD_SCENE.instantiate()
		node.position     = Vector2(cx, 128)
		node.pivot_offset = Vector2(CARD_W / 2.0, CARD_H)
		node.setup(card, CardScene.Mode.REWARD)
		add_child(node)

		var captured_node: CardScene = node
		node.mouse_entered.connect(func(): _show_card_hover(captured_node))
		node.mouse_exited.connect(func():  _clear_card_hover(captured_node))

		var btn := Button.new()
		btn.text     = tr("ui.shop.btn_buy") % price
		btn.position = Vector2(cx, 346)
		btn.size     = Vector2(CARD_W, 36)
		btn.add_theme_font_size_override("font_size", 13)
		var captured_card := card
		var captured_btn  := btn
		btn.pressed.connect(func(): _on_buy_card(captured_card, captured_btn, price))
		add_child(btn)
		SacredTheme.animate_button(btn)

func _show_card_hover(node: CardScene) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(1.5, 1.5), 0.22)
	_card_tweens[node] = tw

func _clear_card_hover(node: CardScene) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.16)
	tw.tween_callback(func(): node.z_index = 0)
	_card_tweens[node] = tw

# ── 렐릭 섹션 ─────────────────────────────────────────────
func _build_relic_section() -> void:
	var P            := SacredPalette
	var relics: Array    = _inventory.get("relics",       [])
	var relic_price: int = _inventory.get("relic_price", 150)

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text                 = "— Relics —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position             = Vector2(460, 402)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	if relics.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.theme_type_variation = "SubLabel"
		empty_lbl.text                 = tr("ui.shop.relic_empty")
		empty_lbl.position             = Vector2(660, 440)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size                 = Vector2(600, 40)
		add_child(empty_lbl)
		return

	var n := relics.size()
	var total_w := n * RELIC_PANEL_W + (n - 1) * RELIC_PANEL_GAP
	var start_x := int((1920 - total_w) / 2)

	for i in range(n):
		var relic: Resource = relics[i]
		var px := start_x + i * (RELIC_PANEL_W + RELIC_PANEL_GAP)
		var py := 428
		var hero_col: Color = _hero_color(relic.owner_hero_id)

		# 패널 (INK_900 배경)
		var panel := Panel.new()
		panel.position = Vector2(px, py)
		panel.size     = Vector2(RELIC_PANEL_W, RELIC_PANEL_H)
		var sb_panel := StyleBoxFlat.new()
		sb_panel.bg_color = P.INK_900
		panel.add_theme_stylebox_override("panel", sb_panel)
		add_child(panel)

		# 원형 아이콘: 영웅 색상 링 + 어두운 내부
		var ring := Panel.new()
		ring.position = Vector2(12, 12)
		ring.size     = Vector2(76, 76)
		var sb_ring := StyleBoxFlat.new()
		sb_ring.bg_color = hero_col
		sb_ring.set_corner_radius_all(38)
		ring.add_theme_stylebox_override("panel", sb_ring)
		panel.add_child(ring)

		var inner_bg := Panel.new()
		inner_bg.position = Vector2(4, 4)
		inner_bg.size     = Vector2(68, 68)
		var sb_inner := StyleBoxFlat.new()
		sb_inner.bg_color = P.INK_900
		sb_inner.set_corner_radius_all(34)
		inner_bg.add_theme_stylebox_override("panel", sb_inner)
		ring.add_child(inner_bg)

		var tex: Texture2D = IconUtils.get_relic_icon(relic.relic_name)
		if tex:
			var icon_rect := TextureRect.new()
			icon_rect.texture      = tex
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.position     = Vector2(4, 4)
			icon_rect.size         = Vector2(60, 60)
			inner_bg.add_child(icon_rect)
		else:
			var fb := Label.new()
			fb.text                 = "⚙"
			fb.add_theme_font_size_override("font_size", 28)
			fb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			fb.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
			fb.position             = Vector2.ZERO
			fb.size                 = Vector2(68, 68)
			inner_bg.add_child(fb)

		# 이름
		var name_lbl := Label.new()
		name_lbl.theme_type_variation = "AccentLabel"
		name_lbl.text     = tr(relic.relic_name)
		name_lbl.position = Vector2(100, 12)
		name_lbl.size     = Vector2(288, 30)
		panel.add_child(name_lbl)

		# 영웅 전용 태그
		if relic.owner_hero_id != "":
			var bound_lbl := Label.new()
			bound_lbl.theme_type_variation = "EyebrowLabel"
			bound_lbl.text    = "— " + relic.owner_hero_id.to_upper() + " ONLY —"
			bound_lbl.modulate = Color(hero_col.r, hero_col.g, hero_col.b, 0.85)
			bound_lbl.add_theme_font_size_override("font_size", 11)
			bound_lbl.position = Vector2(100, 44)
			bound_lbl.size     = Vector2(288, 18)
			panel.add_child(bound_lbl)

		# 설명
		var desc_lbl := Label.new()
		desc_lbl.theme_type_variation = "SubLabel"
		desc_lbl.text          = tr(relic.description)
		desc_lbl.position      = Vector2(100, 64)
		desc_lbl.size          = Vector2(288, 70)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 14)
		panel.add_child(desc_lbl)

		# 가격
		var price_lbl := Label.new()
		price_lbl.theme_type_variation = "EyebrowLabel"
		price_lbl.text     = "⛬ %dg" % relic_price
		price_lbl.add_theme_font_size_override("font_size", 18)
		price_lbl.position = Vector2(100, 150)
		price_lbl.size     = Vector2(120, 34)
		panel.add_child(price_lbl)

		# 구매 버튼
		var btn := Button.new()
		btn.text     = "구매"
		btn.position = Vector2(264, 148)
		btn.size     = Vector2(124, 38)
		btn.add_theme_font_size_override("font_size", 14)
		var captured_relic := relic
		var captured_btn   := btn
		btn.pressed.connect(func(): _on_buy_relic(captured_relic, captured_btn, relic_price))
		panel.add_child(btn)
		SacredTheme.animate_button(btn)

		# 코너 브라켓 (마지막에 추가해서 가장 위에 렌더)
		SacredTheme.add_corner_brackets(panel, P.BRASS_700)

# ── 서비스 섹션 ───────────────────────────────────────────
func _build_service_section() -> void:
	var P := SacredPalette

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text                 = "— " + tr("ui.shop.sec_service") + " —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position             = Vector2(460, 648)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	var heal_price:    int = _inventory.get("heal_price",    30)
	var heal_amount:   int = _inventory.get("heal_amount",   20)
	var remove_price:  int = _inventory.get("remove_price",  100)
	var upgrade_price: int = _inventory.get("upgrade_price", 150)

	var services := [
		{
			"glyph":    "♥",
			"name":     "체력 회복",
			"desc":     "파티 전원 HP +%d" % heal_amount,
			"price":    heal_price,
			"accent":   P.EMERALD_400,
			"callback": func(): _on_heal(heal_amount, heal_price),
			"enabled":  true,
		},
		{
			"glyph":    "✕",
			"name":     "카드 제거",
			"desc":     "덱에서 카드 1장 제거",
			"price":    remove_price,
			"accent":   P.BLOOD_400,
			"callback": func(): _show_remove_panel(remove_price),
			"enabled":  not _card_removed and not DeckManager.get_full_deck().is_empty(),
		},
		{
			"glyph":    "✦",
			"name":     "카드 강화",
			"desc":     "덱의 카드 1장 강화",
			"price":    upgrade_price,
			"accent":   P.AMETHYST_400,
			"callback": func(): _on_upgrade_card(upgrade_price),
			"enabled":  _has_upgradeable_cards(),
		},
	]

	var n := services.size()
	var total_w := n * SVC_PANEL_W + (n - 1) * SVC_PANEL_GAP
	var start_x := int((1920 - total_w) / 2)
	var sy      := 676

	for i in range(n):
		var svc:    Dictionary = services[i]
		var sx:     int        = start_x + i * (SVC_PANEL_W + SVC_PANEL_GAP)
		var accent: Color      = svc["accent"]

		var panel := Panel.new()
		panel.position = Vector2(sx, sy)
		panel.size     = Vector2(SVC_PANEL_W, SVC_PANEL_H)
		var sb := StyleBoxFlat.new()
		sb.bg_color     = P.INK_900
		sb.border_color = Color(accent.r, accent.g, accent.b, 0.35)
		sb.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", sb)
		add_child(panel)

		# 왼쪽 강조 줄
		var stripe := ColorRect.new()
		stripe.color    = Color(accent.r, accent.g, accent.b, 0.7)
		stripe.position = Vector2.ZERO
		stripe.size     = Vector2(4, SVC_PANEL_H)
		panel.add_child(stripe)

		# 글리프 아이콘
		var glyph_lbl := Label.new()
		glyph_lbl.text = svc["glyph"]
		glyph_lbl.add_theme_font_size_override("font_size", 30)
		glyph_lbl.modulate             = accent
		glyph_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		glyph_lbl.position = Vector2(12, int((SVC_PANEL_H - 40) / 2))
		glyph_lbl.size     = Vector2(48, 40)
		panel.add_child(glyph_lbl)

		# 이름
		var name_lbl := Label.new()
		name_lbl.theme_type_variation = "AccentLabel"
		name_lbl.text = svc["name"]
		name_lbl.add_theme_font_size_override("font_size", 15)
		name_lbl.position = Vector2(68, 14)
		name_lbl.size     = Vector2(184, 26)
		panel.add_child(name_lbl)

		# 설명
		var desc_lbl := Label.new()
		desc_lbl.theme_type_variation = "SubLabel"
		desc_lbl.text          = svc["desc"]
		desc_lbl.position      = Vector2(68, 42)
		desc_lbl.size          = Vector2(184, 54)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		panel.add_child(desc_lbl)

		# 가격
		var price_lbl := Label.new()
		price_lbl.theme_type_variation = "EyebrowLabel"
		price_lbl.text                 = "⛬ %dg" % svc["price"]
		price_lbl.add_theme_font_size_override("font_size", 16)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_lbl.position             = Vector2(260, 14)
		price_lbl.size                 = Vector2(108, 26)
		panel.add_child(price_lbl)

		# 구매 버튼
		var btn := Button.new()
		btn.text     = "구매"
		btn.position = Vector2(260, 46)
		btn.size     = Vector2(108, 50)
		btn.add_theme_font_size_override("font_size", 14)
		btn.disabled = not svc["enabled"]
		var captured_cb: Callable = svc["callback"]
		btn.pressed.connect(captured_cb)
		panel.add_child(btn)
		if svc["enabled"]:
			SacredTheme.animate_button(btn)

# ── 헬퍼 ──────────────────────────────────────────────────
func _hero_color(hero_id: String) -> Color:
	match hero_id:
		"napoleon":     return Color("#c9a84c")
		"cleopatra":    return Color("#f0d870")
		"yi_sun_sin":   return Color("#4cb870")
		"joan_of_arc":  return Color("#ebe3d2")
		"genghis_khan": return Color("#d94a50")
		"musashi":      return Color("#d8cfb9")
	return SacredPalette.BRASS_700

func _has_upgradeable_cards() -> bool:
	var all: Array = DeckManager.draw_pile.duplicate()
	all.append_array(DeckManager.discard_pile)
	all.append_array(DeckManager.hand)
	for card in all:
		if card.upgrade_level < card.max_upgrade_level():
			return true
	return false

# ── 구매 콜백 ─────────────────────────────────────────────
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

func _on_upgrade_card(price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	GameManager.enter_card_upgrade()

# ── 카드 제거 패널 ────────────────────────────────────────
func _show_remove_panel(price: int) -> void:
	if _remove_layer:
		_hide_remove_panel()
		return
	var full_deck: Array = DeckManager.get_full_deck()
	if full_deck.is_empty():
		return

	_remove_layer = CanvasLayer.new()
	_remove_layer.layer = 10
	add_child(_remove_layer)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_remove_layer.add_child(overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_remove_panel()
	)
	overlay.add_child(dim)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1200, 500)
	panel.position = Vector2((1920 - 1200) / 2.0, (1080 - 500) / 2.0)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.theme_type_variation  = "TitleLabel"
	title_lbl.text                  = tr("ui.shop.remove_prompt") % price
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.theme_type_variation = "VowButton"
	close_btn.text = "✕  닫기"
	close_btn.custom_minimum_size = Vector2(80, 36)
	close_btn.pressed.connect(_hide_remove_panel)
	title_row.add_child(close_btn)
	SacredTheme.animate_button(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.clip_contents = false
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for card in full_deck:
		var captured_card: Resource = card

		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(91, 130)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.position     = Vector2(-24.5, -70.0)
		card_node.pivot_offset = Vector2(70.0, 200.0)
		card_node.scale        = Vector2(0.65, 0.65)
		card_node.setup(card, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var captured_node: CardScene = card_node
		card_node.card_hovered.connect(func(_c): _show_remove_card_hover(captured_node))
		card_node.card_unhovered.connect(func(_c): _clear_remove_card_hover(captured_node))
		card_node.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_remove_card(captured_card, price)
		)

func _show_remove_card_hover(node: CardScene) -> void:
	if node in _remove_card_tweens:
		_remove_card_tweens[node].kill()
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(1.0, 1.0), 0.22)
	_remove_card_tweens[node] = tw

func _clear_remove_card_hover(node: CardScene) -> void:
	if node in _remove_card_tweens:
		_remove_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(0.65, 0.65), 0.16)
	tw.tween_callback(func(): node.z_index = 0)
	_remove_card_tweens[node] = tw

func _hide_remove_panel() -> void:
	if _remove_layer:
		_remove_card_tweens.clear()
		_remove_layer.queue_free()
		_remove_layer = null

func _on_remove_card(card: Resource, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	_card_removed = true
	DeckManager.remove_from_deck(card)
	_hide_remove_panel()
	_refresh_gold_label()

func _refresh_gold_label() -> void:
	var lbl := get_node_or_null("GoldLabel")
	if lbl:
		lbl.text = tr("ui.shop.gold_label") % GameManager.gold

func _on_exit() -> void:
	GameManager.complete_shop()
