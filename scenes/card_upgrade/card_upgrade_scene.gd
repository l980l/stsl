# scenes/card_upgrade/card_upgrade_scene.gd
extends Node2D

const CARD_SCENE := preload("res://scenes/card/card_scene_v2.tscn")
func _make_card() -> Control:
	return CARD_SCENE.instantiate()
const CARD_W := 140
const CARD_H := 200
const COLS := 4
# 왼쪽은 강화할 카드 목록, 오른쪽은 강화 전후 미리보기 패널
const LIST_CX := 530.0
const PREVIEW_RECT := Rect2(1020.0, 240.0, 820.0, 680.0)
const PREVIEW_SCALE := 1.5

var _preview_cards: Array = []  # [강화 전, 강화 후] 카드 노드
var _preview_hint: Label = null
var _preview_diff: VBoxContainer = null
var _preview_slots: Control = null
var _hovered_node: Control = null

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

	var scroll_w: int = COLS * (CARD_W + 20) - 20
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(LIST_CX - scroll_w / 2.0, 240)
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
		node.card_hovered.connect(func(_c): _on_card_hovered(node, card))
		node.card_unhovered.connect(func(_c): _on_card_unhovered(node))
		grid.add_child(node)
	# 카드 노드의 실제 레이아웃 크기는 CARD_W 가정보다 넓다(모던 프레임 196px).
	# 가정값으로 만든 영역은 오른쪽 열을 잘라 가로 스크롤을 만들므로,
	# 그리드가 실제로 필요한 너비에 맞춰 영역을 넓히고 다시 가운데 정렬한다.
	_fit_scroll_to_grid.call_deferred(scroll, grid)

	_build_preview_panel()

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
	scroll.position.x = LIST_CX - scroll.size.x / 2.0

# 오른쪽 미리보기: 마우스를 올린 카드의 강화 전·후 카드와 바뀌는 효과 문장
func _build_preview_panel() -> void:
	var P := SacredPalette
	var r := PREVIEW_RECT

	var panel := Panel.new()
	panel.position = r.position
	panel.size = r.size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.078, 0.063, 0.047, 0.4)
	sb.border_color = P.BRASS_700
	sb.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	SacredTheme.add_corner_brackets(panel, P.BRASS_500, 12, 6)

	var eyebrow := Label.new()
	eyebrow.text = tr("ui.card_upgrade.preview")
	eyebrow.theme_type_variation = "EyebrowLabel"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.position = Vector2(0.0, 22.0)
	eyebrow.size = Vector2(r.size.x, 18.0)
	panel.add_child(eyebrow)

	var card_w: float = CARD_W * PREVIEW_SCALE
	var card_h: float = CARD_H * PREVIEW_SCALE
	var gap: float = 120.0
	var left_x: float = (r.size.x - (card_w * 2.0 + gap)) * 0.5
	var card_y: float = 86.0

	_preview_slots = Control.new()
	_preview_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview_slots.size = r.size
	_preview_slots.visible = false
	panel.add_child(_preview_slots)

	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	for i in 2:
		var x: float = left_x + i * (card_w + gap)
		var tag := Label.new()
		tag.text = tr("ui.card_upgrade.before" if i == 0 else "ui.card_upgrade.after")
		tag.add_theme_font_override("font", mono_font)
		tag.add_theme_font_size_override("font_size", SacredTheme.FS_SMALL)
		tag.add_theme_color_override("font_color", P.BONE_400 if i == 0 else P.BRASS_300)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tag.position = Vector2(x, card_y - 30.0)
		tag.size = Vector2(card_w, 20.0)
		_preview_slots.add_child(tag)

		var wrapper := Control.new()
		wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.position = Vector2(x, card_y)
		wrapper.size = Vector2(card_w, card_h)
		_preview_slots.add_child(wrapper)
		_preview_cards.append(wrapper)

	var arrow := Label.new()
	arrow.text = "→"
	arrow.theme_type_variation = "AccentLabel"
	arrow.add_theme_color_override("font_color", P.BRASS_300)
	arrow.add_theme_font_size_override("font_size", 40)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	arrow.position = Vector2(left_x + card_w, card_y)
	arrow.size = Vector2(gap, card_h)
	_preview_slots.add_child(arrow)

	_preview_diff = VBoxContainer.new()
	_preview_diff.add_theme_constant_override("separation", 8)
	_preview_diff.position = Vector2(48.0, card_y + card_h + 28.0)
	_preview_diff.size = Vector2(r.size.x - 96.0, r.size.y - (card_y + card_h + 28.0) - 24.0)
	_preview_slots.add_child(_preview_diff)

	_preview_hint = Label.new()
	_preview_hint.text = tr("ui.card_upgrade.preview_hint")
	_preview_hint.theme_type_variation = "SubLabel"
	_preview_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_preview_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_preview_hint.position = Vector2(80.0, 0.0)
	_preview_hint.size = Vector2(r.size.x - 160.0, r.size.y)
	panel.add_child(_preview_hint)

func _on_card_hovered(node: Control, card: Resource) -> void:
	if _hovered_node != null and is_instance_valid(_hovered_node) and _hovered_node != node:
		_hovered_node.tween_glow(0.0, 0.15)
	_hovered_node = node
	node.set_glow_color(SacredPalette.BRASS_300)
	node.tween_glow(1.0, 0.20)
	_show_preview(card)

func _on_card_unhovered(node: Control) -> void:
	node.tween_glow(0.0, 0.20)
	if _hovered_node == node:
		_hovered_node = null
		_preview_slots.visible = false
		_preview_hint.visible = true

func _show_preview(card: Resource) -> void:
	var upgraded := upgraded_copy(card)
	var pair := [card, upgraded]
	for i in 2:
		var wrapper: Control = _preview_cards[i]
		for child in wrapper.get_children():
			child.queue_free()
		var node: Control = _make_card()
		GameSettings.apply_card_transform(node, Vector2(70.0 * (PREVIEW_SCALE - 1.0), 200.0 * (PREVIEW_SCALE - 1.0)), Vector2(70.0, 200.0), PREVIEW_SCALE)
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		node.setup(pair[i], node.Mode.UPGRADE)
		wrapper.add_child(node)
		if i == 1:
			node.set_glow_color(SacredPalette.BRASS_300)
			node.tween_glow(0.6, 0.20)

	for child in _preview_diff.get_children():
		child.queue_free()
	var lines := upgrade_diff_lines(card, upgraded)
	if lines.is_empty():
		lines.append(tr("ui.card_upgrade.diff_none"))
	for line in lines:
		var lbl := Label.new()
		lbl.text = line
		lbl.add_theme_font_size_override("font_size", SacredTheme.FS_TEXT)
		lbl.add_theme_color_override("font_color", SacredPalette.BONE_100)
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(_preview_diff.size.x, 0.0)
		_preview_diff.add_child(lbl)

	_preview_hint.visible = false
	_preview_slots.visible = true

# 실제 강화와 같은 규칙(GameManager.upgrade_card)을 복사본에 적용한 결과.
static func upgraded_copy(card: Resource) -> Resource:
	var copy: Resource = card.duplicate(true)
	for key in card.get_meta_list():
		copy.set_meta(key, card.get_meta(key))
	GameManager.upgrade_card(copy)
	return copy

# 비용과 효과 문장 중 강화로 바뀌는 것만 "전 → 후"로 나열한다.
static func upgrade_diff_lines(before: Resource, after: Resource) -> Array:
	var lines: Array = []
	if before.cost != after.cost:
		lines.append("%s %d → %d" % [TranslationServer.translate("ui.card_upgrade.diff_cost"), before.cost, after.cost])
	for i in mini(before.effects.size(), after.effects.size()):
		var a: String = before.effects[i].display_text()
		var b: String = after.effects[i].display_text()
		if a != b:
			lines.append("%s → %s" % [a, b])
	return lines

func _on_card_selected(card: Resource) -> void:
	GameManager.upgrade_card(card)
	GameManager.complete_card_upgrade()
