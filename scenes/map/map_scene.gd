# scenes/map/map_scene.gd
extends Node2D

const MapNodeRes = preload("res://resources/map_node_resource.gd")

const COL_X := [760, 960, 1160]
const FLOOR_Y_BOTTOM := 900
const FLOOR_GAP := 88
const NODE_W := 120
const NODE_H := 50

var _node_buttons: Dictionary = {}  # node_id → Button
var _floor_label: Label
var _relic_container: HBoxContainer
var _deck_overlay: Control = null

func _ready() -> void:
	_build_ui()
	_refresh_map()

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 제목 (동적 포맷 — 번역 스코프 아웃)
	var title := Label.new()
	title.text = "Act %d" % GameManager.current_act
	title.position = Vector2(860, 20)
	title.size = Vector2(200, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)

	# 층 정보 (동적 포맷 — 번역 스코프 아웃)
	_floor_label = Label.new()
	_floor_label.position = Vector2(50, 520)
	_floor_label.size = Vector2(300, 40)
	_floor_label.add_theme_font_size_override("font_size", 18)
	add_child(_floor_label)

	# 릴릭 표시
	_relic_container = HBoxContainer.new()
	_relic_container.position = Vector2(50, 60)
	_relic_container.size = Vector2(1820, 40)
	add_child(_relic_container)
	_refresh_relics()

	# 덱 보기 버튼
	var deck_btn := Button.new()
	deck_btn.text = tr("ui.map.btn_deck")
	deck_btn.position = Vector2(50, 570)
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.pressed.connect(_show_deck_viewer)
	add_child(deck_btn)
	deck_btn.size = Vector2(160, 40)
	LabelUtils.fit_text(deck_btn, 16, 12)

	# 연결선 먼저 그리기 (버튼 뒤에)
	_draw_connections()

	# 노드 버튼 생성
	for node in GameManager.run_map:
		_create_node_button(node)

func _draw_connections() -> void:
	for node in GameManager.run_map:
		var from := _node_center(node)
		for conn_id in node.connections:
			var to := _node_center(GameManager.run_map[conn_id])
			var line := Line2D.new()
			line.add_point(from)
			line.add_point(to)
			line.width = 3.0
			line.default_color = Color(0.4, 0.4, 0.5, 0.6)
			add_child(line)

func _create_node_button(node: Resource) -> void:
	var btn := Button.new()
	btn.position = _node_top_left(node)
	btn.size = Vector2(NODE_W, NODE_H)
	btn.text = _room_type_text(node.room_type)
	btn.add_theme_font_size_override("font_size", 13)
	var captured_id: int = node.node_id
	btn.pressed.connect(func(): GameManager.enter_node(captured_id))
	add_child(btn)
	_node_buttons[node.node_id] = btn
	LabelUtils.fit_text(btn, 13, 10)

func _refresh_map() -> void:
	for node_id in _node_buttons:
		var btn: Button = _node_buttons[node_id]
		var node: Resource = GameManager.run_map[node_id]

		if node.visited:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
		elif node_id in GameManager.available_node_ids:
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0)
		else:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.7, 0.5)

		if node_id == GameManager.current_node_id:
			btn.modulate = Color(1.0, 1.0, 0.3)

	_floor_label.text = "현재 층: %d / 9" % GameManager.current_floor

func _node_center(node: Resource) -> Vector2:
	return Vector2(
		COL_X[node.column],
		FLOOR_Y_BOTTOM - node.floor_num * FLOOR_GAP
	)

func _node_top_left(node: Resource) -> Vector2:
	return _node_center(node) - Vector2(NODE_W / 2.0, NODE_H / 2.0)

func _refresh_relics() -> void:
	for child in _relic_container.get_children():
		child.queue_free()
	for relic in GameManager.relics:
		var lbl := Label.new()
		lbl.text = "[%s]" % relic.relic_name
		lbl.tooltip_text = relic.description
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(1.0, 0.85, 0.3)
		_relic_container.add_child(lbl)

func _room_type_text(room_type: int) -> String:
	match room_type:
		MapNodeRes.RoomType.BATTLE: return tr("ui.map.room_battle")
		MapNodeRes.RoomType.ELITE: return tr("ui.map.room_elite")
		MapNodeRes.RoomType.REST: return tr("ui.map.room_rest")
		MapNodeRes.RoomType.SHOP: return tr("ui.map.room_shop")
		MapNodeRes.RoomType.BOSS: return tr("ui.map.room_boss")
		_: return "?"

func _show_deck_viewer() -> void:
	if _deck_overlay:
		return

	var dm: Object = null
	if Engine.has_singleton("DeckManager"):
		dm = Engine.get_singleton("DeckManager")
	elif get_tree() and get_tree().root:
		dm = get_tree().root.get_node_or_null("DeckManager")

	var all_cards: Array = []
	if dm:
		all_cards = dm.draw_pile.duplicate()
		all_cards.append_array(dm.discard_pile)
		all_cards.append_array(dm.hand)

	_deck_overlay = Control.new()
	_deck_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_deck_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_deck_overlay.add_child(dim)

	var panel := ColorRect.new()
	panel.color = Color(0.1, 0.1, 0.2)
	panel.position = Vector2(460, 100)
	panel.size = Vector2(1000, 850)
	_deck_overlay.add_child(panel)

	var header := Label.new()
	header.text = "덱 목록  (%d장)" % all_cards.size()
	header.position = Vector2(460, 110)
	header.size = Vector2(1000, 50)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 26)
	_deck_overlay.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(470, 170)
	scroll.size = Vector2(980, 700)
	_deck_overlay.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(960, 0)
	scroll.add_child(vbox)

	for card in all_cards:
		var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
		var cost: int = card.get("cost") if card.get("cost") != null else 0
		var card_owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
		var lbl := Label.new()
		lbl.text = "[%d코스트]  %s  (%s)" % [cost, card_name, card_owner]
		lbl.add_theme_font_size_override("font_size", 16)
		vbox.add_child(lbl)

	var close_btn := Button.new()
	close_btn.text = tr("ui.map.btn_close")
	close_btn.position = Vector2(880, 960)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_hide_deck_viewer)
	_deck_overlay.add_child(close_btn)
	close_btn.size = Vector2(160, 45)
	LabelUtils.fit_text(close_btn, 18, 12)

func _hide_deck_viewer() -> void:
	if _deck_overlay:
		_deck_overlay.queue_free()
		_deck_overlay = null
