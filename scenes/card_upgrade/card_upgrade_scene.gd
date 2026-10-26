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
	title.theme_type_variation = "TitleLabel"  # 상점·카드 선택과 같은 제목 서체
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
		GameSettings.apply_card_transform(node, Vector2.ZERO, Vector2(70.0, 100.0), 1.0)
		node.setup(card, node.Mode.UPGRADE)
		node.card_clicked.connect(func(c): _on_card_selected(c))
		grid.add_child(node)
	# 카드 노드의 실제 레이아웃 크기는 CARD_W 가정보다 넓다(모던 프레임 196px).
	# 가정값으로 만든 940px 영역은 오른쪽 열을 잘라 가로 스크롤을 만들므로,
	# 그리드가 실제로 필요한 너비에 맞춰 영역을 넓히고 다시 가운데 정렬한다.
	_fit_scroll_to_grid.call_deferred(scroll, grid)

	var skip_btn := Button.new()
	skip_btn.theme_type_variation = "VowButton"  # 상점 나가기·카드 선택 건너뛰기와 같은 버튼
	skip_btn.position = Vector2(880, 1000)
	skip_btn.text = tr("ui.card_upgrade.btn_skip")
	skip_btn.add_theme_font_size_override("font_size", 18)
	skip_btn.pressed.connect(GameManager.complete_card_upgrade)
	add_child(skip_btn)
	skip_btn.size = Vector2(160, 50)
	LabelUtils.fit_text(skip_btn, 18, SacredTheme.FS_SMALL)

func _fit_scroll_to_grid(scroll: ScrollContainer, grid: GridContainer) -> void:
	var need_w: float = minf(grid.get_combined_minimum_size().x, 1920.0 - 80.0)
	if need_w <= scroll.size.x:
		return
	scroll.size.x = need_w
	scroll.position.x = (1920.0 - need_w) / 2.0

func _on_card_selected(card: Resource) -> void:
	GameManager.upgrade_card(card)
	GameManager.complete_card_upgrade()
