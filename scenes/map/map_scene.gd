# scenes/map/map_scene.gd
extends Node2D

const MapNodeRes = preload("res://resources/map_node_resource.gd")
const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")

const COL_X := [760, 960, 1160]
const FLOOR_Y_BOTTOM := 900
const FLOOR_GAP := 88
const NODE_W := 120
const NODE_H := 50

var _node_buttons: Dictionary = {}  # node_id → Button
var _floor_label: Label
var _relic_container: HBoxContainer
var _deck_viewer: CanvasLayer = null
var _deck_viewer_tooltip: CardScene = null

func _trf(key: String, args) -> String:
	var s := tr(key)
	if "%d" in s or "%s" in s or "%f" in s:
		return s % args
	return s

func _ready() -> void:
	_build_ui()
	_refresh_map()

func _unhandled_input(ev: InputEvent) -> void:
	if _deck_viewer and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_hide_deck_viewer()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1)
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 제목 (동적 포맷 — 번역 스코프 아웃)
	var title := Label.new()
	title.text = _trf("ui.map.act_title", GameManager.current_act)
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

	_floor_label.text = _trf("ui.map.floor_label", GameManager.current_floor)

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
		var tip: String = "%s\n%s" % [tr(relic.relic_name), tr(relic.description)]
		var tex: Texture2D = IconUtils.get_relic_icon(relic.relic_name)
		if tex != null:
			var rect := TextureRect.new()
			rect.texture = tex
			rect.custom_minimum_size = Vector2(28, 28)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.tooltip_text = tip
			rect.mouse_filter = Control.MOUSE_FILTER_STOP
			_relic_container.add_child(rect)
		else:
			var lbl := Label.new()
			lbl.text = "[%s]" % tr(relic.relic_name)
			lbl.tooltip_text = tip
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
		MapNodeRes.RoomType.EVENT: return tr("ui.map.room_event")
		MapNodeRes.RoomType.SECRET: return tr("ui.map.room_type.secret")
		_: return "?"

func _show_deck_viewer() -> void:
	if _deck_viewer:
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

	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.0, 0.0, 0.0, 0.75)
	bg_rect.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_deck_viewer()
	)
	overlay.add_child(bg_rect)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1200, 700)
	panel.position = Vector2((1920 - 1200) / 2.0, (1080 - 700) / 2.0)
	overlay.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.text = _trf("ui.map.deck_list_title", all_cards.size())
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_hide_deck_viewer)
	title_row.add_child(close_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 9
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for card_res in all_cards:
		var captured_res: Resource = card_res
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(91, 130)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.scale = Vector2(0.65, 0.65)
		card_node.setup(card_res, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var captured_wrapper: Control = wrapper
		card_node.card_hovered.connect(func(_c): _show_deck_tooltip(captured_res, captured_wrapper))
		card_node.card_unhovered.connect(func(_c): _hide_deck_tooltip())

	var tip: CardScene = CARD_SCENE.instantiate()
	tip.scale = Vector2(2.5, 2.5)
	tip.z_index = 200
	tip.visible = false
	overlay.add_child(tip)
	_set_mouse_ignore_recursive(tip)
	_deck_viewer_tooltip = tip

	_deck_viewer = canvas

func _show_deck_tooltip(card: Resource, node: Control) -> void:
	if _deck_viewer_tooltip == null:
		return
	_deck_viewer_tooltip.setup(card, CardScene.Mode.HAND)
	var base := node.global_position
	var x: float = clamp(base.x + 45.0 - 175.0, 0.0, 1920.0 - 350.0)
	var y: float = clamp(base.y - 510.0, 20.0, 1080.0 - 500.0)
	_deck_viewer_tooltip.position = Vector2(x, y)
	_deck_viewer_tooltip.visible = true

func _hide_deck_tooltip() -> void:
	if _deck_viewer_tooltip != null:
		_deck_viewer_tooltip.visible = false

func _hide_deck_viewer() -> void:
	if _deck_viewer:
		_deck_viewer_tooltip = null
		_deck_viewer.queue_free()
		_deck_viewer = null

func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore_recursive(child)
