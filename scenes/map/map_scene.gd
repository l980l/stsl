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

	# 제목
	var title := Label.new()
	title.text = "탐험 맵"
	title.position = Vector2(860, 20)
	title.size = Vector2(200, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	add_child(title)

	# 층 정보
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
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(1.0, 0.85, 0.3)
		_relic_container.add_child(lbl)

func _room_type_text(room_type: int) -> String:
	match room_type:
		MapNodeRes.RoomType.BATTLE: return "⚔ 전투"
		MapNodeRes.RoomType.ELITE: return "💀 엘리트"
		MapNodeRes.RoomType.REST: return "🔥 휴식"
		MapNodeRes.RoomType.SHOP: return "🏪 상점"
		MapNodeRes.RoomType.BOSS: return "👑 보스"
		_: return "?"
