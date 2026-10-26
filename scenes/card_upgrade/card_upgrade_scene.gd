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
	# 카드 선택·상점과 같은 바탕: 잉크 배경 + 위쪽 빛 번짐 + 사선 무늬
	var bg := ColorRect.new()
	bg.color = SacredPalette.INK_1000
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.size = Vector2(1920.0, 560.0)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	_build_header(960.0)

	var scroll_w: int = COLS * (CARD_W + 20) - 20  # 940
	var scroll := ScrollContainer.new()
	scroll.position = Vector2((1920 - scroll_w) / 2.0, 240)
	scroll.size = Vector2(scroll_w, 680)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	SacredTheme.style_sacred_scrollbar(scroll)
	add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 20)
	grid.add_theme_constant_override("v_separation", 20)
	grid.custom_minimum_size = Vector2(scroll_w, 0)
	scroll.add_child(grid)

	for card: Resource in upgradeable:
		var node: Control = _make_card()
		GameSettings.apply_card_transform(node, Vector2.ZERO, Vector2(70.0, 100.0), 1.0)
		node.setup(card, node.Mode.UPGRADE)
		node.card_clicked.connect(func(c): _on_card_selected(c))
		grid.add_child(node)
	# 카드 노드의 실제 레이아웃 크기는 CARD_W 가정보다 넓다(모던 프레임 196px).
	# 가정값으로 만든 940px 영역은 오른쪽 열을 잘라 가로 스크롤을 만들므로,
	# 그리드가 실제로 필요한 너비에 맞춰 영역을 넓히고 다시 가운데 정렬한다.
	_fit_scroll_to_grid.call_deferred(scroll, grid)

	# 카드 선택 화면의 "지나친다" 버튼과 같은 모양·위치
	var skip_btn := Button.new()
	skip_btn.theme_type_variation = "VowButton"
	skip_btn.text = tr("ui.card_upgrade.btn_skip").to_upper()
	skip_btn.add_theme_font_override("font", load("res://assets/fonts/SpaceMono-Regular.ttf") as Font)
	skip_btn.add_theme_font_size_override("font_size", SacredTheme.FS_SMALL)
	skip_btn.position = Vector2(960.0 - 140.0, 940.0)
	skip_btn.size = Vector2(280.0, 40.0)
	skip_btn.pressed.connect(GameManager.complete_card_upgrade)
	SacredTheme.animate_button(skip_btn)
	add_child(skip_btn)

# 카드 선택 화면과 같은 머리말: 작은 표제 · 제목 · 부제 · ✦ 가로줄
func _build_header(cx: float) -> void:
	var P := SacredPalette
	var sx: float = 320.0
	var sw: float = 1280.0

	var eyebrow := Label.new()
	eyebrow.text = tr("ui.card_upgrade.eyebrow")
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(sx, 62.0)
	eyebrow.size = Vector2(sw, 18.0)
	add_child(eyebrow)

	var title := Label.new()
	title.text = tr("ui.card_upgrade.title")
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(sx, 86.0)
	title.size = Vector2(sw, 68.0)
	add_child(title)
	LabelUtils.fit_text(title, 52, 28)

	var sub := Label.new()
	sub.text = tr("ui.card_upgrade.subtitle")
	sub.theme_type_variation = "SubLabel"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(sx, 162.0)
	sub.size = Vector2(sw, 26.0)
	add_child(sub)
	LabelUtils.fit_text(sub, SacredTheme.FS_TEXT, SacredTheme.FS_SMALL)

	var rule_w: float = 280.0
	var rule_y: float = 200.0
	var rule := TextureRect.new()
	rule.texture = SacredTheme.make_center_bright_h_tex(P.BRASS_400, 0.9)
	rule.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rule.stretch_mode = TextureRect.STRETCH_SCALE
	rule.position = Vector2(cx - rule_w * 0.5, rule_y)
	rule.size = Vector2(rule_w, 1.0)
	add_child(rule)

	var orn_w: float = 32.0
	var orn_h: float = 20.0
	var orn_bg := ColorRect.new()
	orn_bg.color = P.INK_1000
	orn_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	orn_bg.position = Vector2(cx - orn_w * 0.5, rule_y - orn_h * 0.5)
	orn_bg.size = Vector2(orn_w, orn_h)
	add_child(orn_bg)

	var orn := Label.new()
	orn.text = "✦"
	orn.theme_type_variation = "AccentLabel"
	orn.add_theme_color_override("font_color", P.BRASS_300)
	orn.add_theme_font_size_override("font_size", 14)  # 장식 글리프 — 글자 크기 하한 예외
	orn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	orn.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	orn.position = Vector2(cx - orn_w * 0.5, rule_y - orn_h * 0.5)
	orn.size = Vector2(orn_w, orn_h)
	orn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(orn)

func _fit_scroll_to_grid(scroll: ScrollContainer, grid: GridContainer) -> void:
	# 가로 스크롤을 끄면 ScrollContainer가 스스로 그리드 폭만큼 커지므로 위치는 항상 다시 맞춘다.
	var need_w: float = minf(grid.get_combined_minimum_size().x, 1920.0 - 80.0)
	scroll.size.x = maxf(scroll.size.x, need_w)
	scroll.position.x = (1920.0 - scroll.size.x) / 2.0

func _on_card_selected(card: Resource) -> void:
	GameManager.upgrade_card(card)
	GameManager.complete_card_upgrade()
