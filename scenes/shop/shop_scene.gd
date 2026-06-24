# scenes/shop/shop_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const CARD_SCENE_MODERN := preload("res://scenes/card/card_scene_v2.tscn")
const CARD_REMOVAL_OVERLAY := preload("res://scenes/components/card_removal_overlay.gd")

func _make_card() -> Control:
	return CARD_SCENE_MODERN.instantiate() if GameSettings.card_frame_key == "modern" else CARD_SCENE.instantiate()
const CARD_W  := 140
const CARD_H  := 200
const CARD_GAP := 20

const RELIC_PANEL_W   := 400
const RELIC_PANEL_H   := 200
const RELIC_PANEL_GAP := 18

const SVC_PANEL_W   := 380
const SVC_PANEL_H   := 110
const SVC_PANEL_GAP := 20

var _inventory:           Dictionary  = {}
var _upgrade_layer:       CanvasLayer     = null
var _upgrade_group:       Control         = null
var _upgrade_overlay:     Control         = null
var _upgrade_scroll:      ScrollContainer = null
var _upgrade_card_parents:Dictionary      = {}
var _active_scroll:       ScrollContainer = null
var _card_tweens:         Dictionary  = {}
var _upgrade_card_tweens: Dictionary  = {}
var _card_removed:          bool      = false
var _upgrade_btn_ref:       Button    = null
var _upgrade_price:         int       = 0
var _selected_upgrade_card: Resource  = null
var _selected_upgrade_node: Control = null
var _confirm_upgrade_btn:   Button    = null
# 구매 가능 버튼 → 가격. 골드 변경 시 disabled 일괄 갱신용. 구매 완료된 버튼은 erase.
var _affordable_btns: Dictionary = {}

func _ready() -> void:
	_inventory = GameManager.generate_shop_inventory()
	_build_ui()
	AudioManager.play_bgm_dynamic("shop", "")
	# 언어/카드 프레임 변경 시 진열 라벨·카드 노드만 다시 그림 (_inventory 는 유지 → 진열 reroll 방지)
	LocaleManager.locale_changed.connect(_on_locale_or_frame_changed)
	GameSettings.card_frame_changed.connect(_on_locale_or_frame_changed)

func _on_locale_or_frame_changed(_v) -> void:
	_rebuild_ui()

func _rebuild_ui() -> void:
	_hide_upgrade_panel()
	for tw in _card_tweens.values():
		if tw.is_valid():
			tw.kill()
	_card_tweens.clear()
	_upgrade_btn_ref = null
	_affordable_btns.clear()
	# tscn 에 박혀있는 자식(SettingsButton/SettingsOverlay 등 owner 가 root 인 노드)은 보존,
	# _build_ui 가 add 한 동적 자식만 제거.
	for c in get_children():
		if c.owner == self:
			continue
		c.queue_free()
	_build_ui()

# 구매 버튼 등록 — 가격 + 부가 조건(못 살 결정적 조건. 예: 강화 가능 카드 없음). 골드 변경 시 일괄 평가.
func _register_buy_btn(btn: Button, price: int, extra_disabled: bool = false) -> void:
	_affordable_btns[btn] = {"price": price, "extra": extra_disabled}
	btn.disabled = extra_disabled or GameManager.gold < price

func _refresh_affordable_btns() -> void:
	for btn in _affordable_btns.keys():
		if not is_instance_valid(btn):
			_affordable_btns.erase(btn)
			continue
		var meta: Dictionary = _affordable_btns[btn]
		btn.disabled = meta["extra"] or GameManager.gold < meta["price"]

func _input(ev: InputEvent) -> void:
	if _active_scroll == null:
		return
	if ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_active_scroll.scroll_vertical -= 40
			get_viewport().set_input_as_handled()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_active_scroll.scroll_vertical += 40
			get_viewport().set_input_as_handled()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		if _upgrade_layer:
			_hide_upgrade_panel()
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var P := SacredPalette

	var bg := ColorRect.new()
	bg.color    = P.INK_1000
	bg.position = Vector2.ZERO
	bg.size     = Vector2(1920, 1080)
	add_child(bg)

	var bloom := SacredTheme.make_top_ellipse_bloom()
	bloom.position = Vector2.ZERO
	bloom.size     = Vector2(1920, 400)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

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
	gold_lbl.add_theme_font_size_override("font_size", 21)
	gold_lbl.text     = "⛬ %dg" % GameManager.gold
	gold_lbl.position = Vector2(30, 22)
	gold_lbl.size     = Vector2(200, 32)
	add_child(gold_lbl)
	LabelUtils.fit_text(gold_lbl, 21, 13)

	var title_div := TextureRect.new()
	title_div.texture = SacredTheme.make_center_bright_h_tex()
	title_div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_div.stretch_mode = TextureRect.STRETCH_SCALE
	title_div.position = Vector2(360, 100)
	title_div.size = Vector2(1200, 2)
	title_div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title_div)

	_build_card_section()
	_build_relic_section()
	_build_service_section()

	var exit_btn := Button.new()
	exit_btn.theme_type_variation = "VowButton"
	exit_btn.text = tr("ui.shop.btn_exit")
	exit_btn.position = Vector2(860, 928)
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
	sec_lbl.position             = Vector2(460, 142)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	var n := cards.size()
	if n == 0:
		return
	var total_w := n * CARD_W + (n - 1) * CARD_GAP
	var start_x: int = int((1920 - total_w) / 2.0)

	# 도감 — 상점에 진열된 카드는 "관측(발견)" 처리 (구매 안 해도 발견 상태)
	var _pm = get_node_or_null("/root/ProgressManager")
	if _pm != null:
		for c in cards:
			if c != null and c.card_name != "":
				_pm.observe_card(c.owner_id + "|" + c.card_name)

	for i in range(n):
		var card: Resource = cards[i]
		var price: int     = prices[i] if i < prices.size() else 75
		var cx := start_x + i * (CARD_W + CARD_GAP)

		var node: Control = _make_card()
		GameSettings.apply_card_transform(node, Vector2(cx, 174), Vector2(CARD_W / 2.0, CARD_H), 1.0)
		node.setup(card, CardScene.Mode.REWARD)
		add_child(node)

		var captured_node: Control = node
		node.mouse_entered.connect(func(): _show_card_hover(captured_node))
		node.mouse_exited.connect(func():  _clear_card_hover(captured_node))

		var price_lbl := Label.new()
		price_lbl.text                 = "⛬ %dg" % price
		price_lbl.theme_type_variation = "EyebrowLabel"
		price_lbl.add_theme_font_size_override("font_size", 16)
		price_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price_lbl.position             = Vector2(cx, 382)
		price_lbl.size                 = Vector2(CARD_W, 20)
		add_child(price_lbl)

		var btn := Button.new()
		btn.text     = tr("ui.shop.btn_buy_simple")
		btn.position = Vector2(cx, 408)
		btn.size     = Vector2(CARD_W, 36)
		btn.add_theme_font_size_override("font_size", 13)
		var captured_card := card
		var captured_btn  := btn
		btn.pressed.connect(func(): _on_buy_card(captured_card, captured_btn, price))
		add_child(btn)
		SacredTheme.animate_button(btn)
		_register_buy_btn(btn, price)

func _show_card_hover(node: Control) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", GameSettings.get_card_scale(1.5), 0.22)
	_card_tweens[node] = tw

func _clear_card_hover(node: Control) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", GameSettings.get_card_scale(1.0), 0.16)
	tw.tween_callback(func():
		if is_instance_valid(node):
			node.z_index = 0
	)
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
	sec_lbl.position             = Vector2(460, 484)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	if relics.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.theme_type_variation = "SubLabel"
		empty_lbl.text                 = tr("ui.shop.relic_empty")
		empty_lbl.position             = Vector2(660, 480)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.size                 = Vector2(600, 40)
		add_child(empty_lbl)
		return

	var n := relics.size()
	var total_w := n * RELIC_PANEL_W + (n - 1) * RELIC_PANEL_GAP
	var start_x: int = int((1920 - total_w) / 2.0)

	for i in range(n):
		var relic: Resource = relics[i]
		var px := start_x + i * (RELIC_PANEL_W + RELIC_PANEL_GAP)
		var py := 510
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
			icon_rect.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
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
		LabelUtils.fit_text(name_lbl, 22, 13)

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
		var desc_box := Control.new()
		desc_box.position           = Vector2(100, 64)
		desc_box.size               = Vector2(288, 70)
		desc_box.custom_minimum_size= Vector2(288, 70)
		desc_box.clip_children      = Control.CLIP_CHILDREN_AND_DRAW
		desc_box.mouse_filter       = Control.MOUSE_FILTER_IGNORE
		panel.add_child(desc_box)

		var desc_lbl := Label.new()
		desc_lbl.theme_type_variation = "SubLabel"
		desc_lbl.text                 = tr(relic.description)
		desc_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_box.add_child(desc_lbl)
		desc_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		LabelUtils.fit_text(desc_lbl, 14, 9, -1.0, 70.0)

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
		btn.text     = tr("ui.shop.btn_buy_simple")
		btn.position = Vector2(260, 140)
		btn.size     = Vector2(124, 38)
		btn.add_theme_font_size_override("font_size", 14)
		var captured_relic := relic
		var captured_btn   := btn
		btn.pressed.connect(func(): _on_buy_relic(captured_relic, captured_btn, relic_price))
		panel.add_child(btn)
		SacredTheme.animate_button(btn)
		_register_buy_btn(btn, relic_price)

		# 코너 브라켓 (마지막에 추가해서 가장 위에 렌더)
		SacredTheme.add_corner_brackets(panel, P.BRASS_700)

# ── 서비스 섹션 ───────────────────────────────────────────
func _build_service_section() -> void:
	var P := SacredPalette

	var sec_lbl := Label.new()
	sec_lbl.theme_type_variation = "EyebrowLabel"
	sec_lbl.text                 = "— " + tr("ui.shop.sec_service") + " —"
	sec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_lbl.position             = Vector2(460, 750)
	sec_lbl.size                 = Vector2(1000, 26)
	add_child(sec_lbl)

	var heal_price:    int = _inventory.get("heal_price",    30)
	var heal_amount:   int = _inventory.get("heal_amount",   20)
	var remove_price:  int = _inventory.get("remove_price",  100)
	var upgrade_price: int = _inventory.get("upgrade_price", 150)

	var services := [
		{
			"glyph":    "♥",
			"name":     tr("ui.shop.svc_heal_name"),
			"desc":     tr("ui.shop.svc_heal_desc") % heal_amount,
			"price":    heal_price,
			"accent":   P.EMERALD_400,
			"callback": func(): _on_heal(heal_amount, heal_price),
			"enabled":  true,
		},
		{
			"glyph":    "✕",
			"name":     tr("ui.shop.svc_remove_name"),
			"desc":     tr("ui.shop.svc_remove_desc"),
			"price":    remove_price,
			"accent":   P.BLOOD_400,
			"callback": func(): _open_removal(remove_price),
			"enabled":  not _card_removed and not DeckManager.get_full_deck().is_empty(),
		},
		{
			"glyph":    "✦",
			"name":     tr("ui.shop.svc_upgrade_name"),
			"desc":     tr("ui.shop.svc_upgrade_desc"),
			"price":    upgrade_price,
			"accent":   P.AMETHYST_400,
			"callback": func(): _on_upgrade_card(upgrade_price),
			"enabled":  _has_upgradeable_cards(),
		},
	]

	var n := services.size()
	var total_w := n * SVC_PANEL_W + (n - 1) * SVC_PANEL_GAP
	var start_x: int = int((1920 - total_w) / 2.0)
	var sy      := 778

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
		glyph_lbl.position = Vector2(12, int((SVC_PANEL_H - 40) / 2.0))
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
		LabelUtils.fit_text(name_lbl, 15, 11)

		# 설명
		var desc_box := Control.new()
		desc_box.position           = Vector2(68, 42)
		desc_box.size               = Vector2(184, 54)
		desc_box.custom_minimum_size= Vector2(184, 54)
		desc_box.clip_children      = Control.CLIP_CHILDREN_AND_DRAW
		desc_box.mouse_filter       = Control.MOUSE_FILTER_IGNORE
		panel.add_child(desc_box)

		var desc_lbl := Label.new()
		desc_lbl.theme_type_variation = "SubLabel"
		desc_lbl.text                 = svc["desc"]
		desc_lbl.autowrap_mode        = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 13)
		desc_box.add_child(desc_lbl)
		desc_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		LabelUtils.fit_text(desc_lbl, 13, 9, -1.0, 54.0)

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
		btn.text     = tr("ui.shop.btn_buy_simple")
		btn.position = Vector2(260, 60)
		btn.size     = Vector2(108, 35)
		btn.add_theme_font_size_override("font_size", 14)
		var captured_cb: Callable = svc["callback"]
		btn.pressed.connect(captured_cb)
		panel.add_child(btn)
		_register_buy_btn(btn, svc["price"], not svc["enabled"])
		if not btn.disabled:
			SacredTheme.animate_button(btn)
		if i == 2:
			_upgrade_btn_ref  = btn
			_upgrade_price    = upgrade_price

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
	_affordable_btns.erase(btn)
	_refresh_gold_label()
	_refresh_upgrade_btn()

func _on_buy_relic(relic: Resource, btn: Button, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	GameManager.add_relic(relic)
	btn.disabled = true
	btn.text = tr("ui.shop.btn_purchased")
	_affordable_btns.erase(btn)
	_refresh_gold_label()

func _on_heal(amount: int, price: int) -> void:
	if not GameManager.spend_gold(price):
		return
	for hero in TeamManager.heroes:
		TeamManager.heal(hero.hero_id, amount)
	_refresh_gold_label()

func _on_upgrade_card(price: int) -> void:
	_show_upgrade_panel(price)

# ── 카드 제거 패널 ────────────────────────────────────────
func _open_removal(price: int) -> void:
	var deck: Array = DeckManager.get_full_deck()
	if deck.is_empty():
		return
	var overlay = CARD_REMOVAL_OVERLAY.new()
	add_child(overlay)
	overlay.confirmed.connect(func(card: Resource) -> void:
		if not GameManager.spend_gold(price):
			return
		_card_removed = true
		DeckManager.remove_from_deck(card)
		_refresh_gold_label()
		_refresh_upgrade_btn()
	)
	overlay.open(deck, {
		"cancelable":   true,
		"title_text":   tr("ui.shop.remove_prompt") % price,
		"confirm_text": tr("ui.shop.btn_confirm_remove"),
	})

func _refresh_gold_label() -> void:
	var lbl := get_node_or_null("GoldLabel")
	if lbl:
		lbl.text = "⛬ %dg" % GameManager.gold
	_refresh_affordable_btns()

func _refresh_upgrade_btn() -> void:
	if not is_instance_valid(_upgrade_btn_ref):
		return
	var can := _has_upgradeable_cards()
	if _affordable_btns.has(_upgrade_btn_ref):
		_affordable_btns[_upgrade_btn_ref]["extra"] = not can
	var was_disabled: bool = _upgrade_btn_ref.disabled
	_refresh_affordable_btns()
	if was_disabled and not _upgrade_btn_ref.disabled:
		SacredTheme.animate_button(_upgrade_btn_ref)

# ── 카드 강화 패널 ────────────────────────────────────────
func _show_upgrade_panel(price: int) -> void:
	if _upgrade_layer:
		_hide_upgrade_panel()
		return
	var full_deck: Array = DeckManager.get_full_deck()
	var upgradeable: Array = full_deck.filter(func(c): return c.can_upgrade())
	if upgradeable.is_empty():
		return

	_upgrade_layer = CanvasLayer.new()
	_upgrade_layer.layer = 10
	add_child(_upgrade_layer)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_upgrade_layer.add_child(overlay)
	_upgrade_overlay = overlay

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_upgrade_panel()
	)
	overlay.add_child(dim)

	var group := Control.new()
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.pivot_offset = Vector2(960, 540)
	group.scale = Vector2(0.9, 0.9)
	group.modulate.a = 0.0
	overlay.add_child(group)
	_upgrade_group = group

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 600)
	panel.position = Vector2((1920 - 1300) / 2.0, (1080 - 600) / 2.0)
	group.add_child(panel)

	var hl := TextureRect.new()
	hl.texture = SacredTheme.make_top_fade_tex()
	hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hl.stretch_mode = TextureRect.STRETCH_SCALE
	hl.position = panel.position
	hl.size = Vector2(1300, 80)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hl)

	var hdiv := TextureRect.new()
	hdiv.texture = SacredTheme.make_center_bright_h_tex()
	hdiv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hdiv.stretch_mode = TextureRect.STRETCH_SCALE
	hdiv.position = Vector2(panel.position.x + 20, panel.position.y + 60)
	hdiv.size = Vector2(1260, 2)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hdiv)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left",   20)
	margin.add_theme_constant_override("margin_right",  20)
	margin.add_theme_constant_override("margin_top",    14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.clip_children = Control.CLIP_CHILDREN_ONLY
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.text                 = tr("ui.shop.upgrade_prompt") % price
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)
	LabelUtils.fit_text(title_lbl, 20, 14)

	var close_btn := Button.new()
	close_btn.theme_type_variation = "IconButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_hide_upgrade_panel)
	group.add_child(close_btn)
	close_btn.position = Vector2((1920.0 - 1300) / 2.0 + 1300 - 56, (1080.0 - 600) / 2.0 + 12)
	close_btn.size     = Vector2(40, 40)
	SacredTheme.animate_button(close_btn)

	var clip_box := Control.new()
	clip_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(clip_box)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.clip_contents = true
	clip_box.add_child(scroll)
	_upgrade_scroll = scroll
	SacredTheme.style_sacred_scrollbar(scroll)

	var margin_c := MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	scroll.add_child(margin_c)

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	margin_c.add_child(grid)

	for card in upgradeable:
		var captured_card: Resource = card

		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(137, 195)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: Control = _make_card()
		GameSettings.apply_card_transform(card_node, Vector2(-1.75, -5.0), Vector2(70.0, 200.0), 0.975)
		card_node.setup(card, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var captured_node: Control = card_node
		card_node.card_hovered.connect(func(_c): _show_upgrade_card_hover(captured_node))
		card_node.card_unhovered.connect(func(_c): _clear_upgrade_card_hover(captured_node))
		card_node.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_select_upgrade_card(captured_card, captured_node)
		)

	var confirm_row := HBoxContainer.new()
	vbox.add_child(confirm_row)
	var spc_l := Control.new()
	spc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(spc_l)
	var confirm_btn := Button.new()
	confirm_btn.text = tr("ui.shop.btn_confirm_upgrade")
	confirm_btn.custom_minimum_size = Vector2(200, 44)
	confirm_btn.add_theme_font_size_override("font_size", 16)
	confirm_btn.disabled = true
	confirm_btn.pressed.connect(_on_confirm_upgrade)
	confirm_row.add_child(confirm_btn)
	_confirm_upgrade_btn = confirm_btn
	SacredTheme.animate_button(confirm_btn)
	var spc_r := Control.new()
	spc_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(spc_r)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(group, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(group, "modulate:a", 1.0, 0.15)

func _show_upgrade_card_hover(node: Control) -> void:
	if node in _upgrade_card_tweens:
		_upgrade_card_tweens[node].kill()
	_active_scroll = _upgrade_scroll
	if _upgrade_overlay and node.get_parent() != _upgrade_overlay:
		_upgrade_card_parents[node] = node.get_parent()
		node.reparent(_upgrade_overlay, true)
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", GameSettings.get_card_scale(1.5), 0.22)
	_upgrade_card_tweens[node] = tw

func _clear_upgrade_card_hover(node: Control) -> void:
	if node in _upgrade_card_tweens:
		_upgrade_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", GameSettings.get_card_scale(0.975), 0.16)
	tw.tween_callback(func():
		if not is_instance_valid(node):
			return
		node.z_index = 0
		if node in _upgrade_card_parents:
			var orig: Node = _upgrade_card_parents[node]
			_upgrade_card_parents.erase(node)
			if is_instance_valid(orig):
				node.reparent(orig, false)
				GameSettings.apply_card_transform(node, Vector2(-1.75, -5.0), Vector2(70.0, 200.0), 0.975)
	)
	_upgrade_card_tweens[node] = tw

func _hide_upgrade_panel() -> void:
	if _upgrade_layer:
		for tw in _upgrade_card_tweens.values():
			if tw.is_valid():
				tw.kill()
		_upgrade_card_tweens.clear()
		_upgrade_card_parents.clear()
		_upgrade_overlay = null
		_upgrade_scroll  = null
		_active_scroll   = null
		_selected_upgrade_card = null
		_selected_upgrade_node = null
		_confirm_upgrade_btn   = null
		var layer := _upgrade_layer
		var group := _upgrade_group
		_upgrade_layer = null
		_upgrade_group = null
		if is_instance_valid(group):
			var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(group, "scale", Vector2(0.9, 0.9), 0.12)
			tw.parallel().tween_property(group, "modulate:a", 0.0, 0.12)
			tw.tween_callback(func(): if is_instance_valid(layer): layer.queue_free())
		else:
			if is_instance_valid(layer): layer.queue_free()

func _on_select_upgrade_card(card: Resource, node: Control) -> void:
	if is_instance_valid(_selected_upgrade_node):
		_selected_upgrade_node.tween_glow(0.0, 0.12)
	_selected_upgrade_card = card
	_selected_upgrade_node = node
	node.tween_glow(1.0, 0.15)
	if is_instance_valid(_confirm_upgrade_btn):
		_confirm_upgrade_btn.disabled = false

func _on_confirm_upgrade() -> void:
	if _selected_upgrade_card == null:
		return
	if not GameManager.spend_gold(_upgrade_price):
		return
	GameManager.upgrade_card(_selected_upgrade_card)
	_hide_upgrade_panel()
	_refresh_gold_label()
	if is_instance_valid(_upgrade_btn_ref):
		_upgrade_btn_ref.disabled = not _has_upgradeable_cards()

func _on_exit() -> void:
	GameManager.complete_shop()
