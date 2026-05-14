# scenes/components/card_removal_overlay.gd
# 덱에서 카드 1장을 선택해 제거하는 공용 오버레이.
# 상점(취소 가능)·이벤트(취소 불가) 양쪽에서 재사용.
# 컴포넌트는 카드 선택 UI만 담당 — 실제 제거/후처리는 confirmed 시그널 수신자가 한다.
extends CanvasLayer

const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")

## 카드 선택 확정 시 발신. 인자는 선택된 카드 Resource.
signal confirmed(card: Resource)

var _cancelable: bool = true
var _overlay: Control = null
var _group: Control = null
var _scroll: ScrollContainer = null
var _card_parents: Dictionary = {}
var _card_tweens: Dictionary = {}
var _selected_card: Resource = null
var _selected_node: CardScene = null
var _confirm_btn: Button = null
var _closing: bool = false

# deck: 표시할 카드 배열. opts: {cancelable: bool, title_text: String, confirm_text: String}
func open(deck: Array, opts: Dictionary = {}) -> void:
	_cancelable = opts.get("cancelable", true)
	var title_text: String = opts.get("title_text", "")
	var confirm_text: String = opts.get("confirm_text", "")
	layer = 10

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_overlay)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	if _cancelable:
		dim.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_close())
	_overlay.add_child(dim)

	_group = Control.new()
	_group.set_anchors_preset(Control.PRESET_FULL_RECT)
	_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.pivot_offset = Vector2(960, 540)
	_group.scale = Vector2(0.9, 0.9)
	_group.modulate.a = 0.0
	_overlay.add_child(_group)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 600)
	panel.position = Vector2((1920 - 1300) / 2.0, (1080 - 600) / 2.0)
	_group.add_child(panel)

	var hl := TextureRect.new()
	hl.texture = SacredTheme.make_top_fade_tex()
	hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hl.stretch_mode = TextureRect.STRETCH_SCALE
	hl.position = panel.position
	hl.size = Vector2(1300, 80)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(hl)

	var hdiv := TextureRect.new()
	hdiv.texture = SacredTheme.make_center_bright_h_tex()
	hdiv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hdiv.stretch_mode = TextureRect.STRETCH_SCALE
	hdiv.position = Vector2(panel.position.x + 20, panel.position.y + 60)
	hdiv.size = Vector2(1260, 2)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_group.add_child(hdiv)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.clip_children = Control.CLIP_CHILDREN_ONLY
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.text = title_text
	title_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title_lbl)
	LabelUtils.fit_text(title_lbl, 20, 14)

	if _cancelable:
		var close_btn := Button.new()
		close_btn.theme_type_variation = "IconButton"
		close_btn.text = "✕"
		close_btn.add_theme_font_size_override("font_size", 20)
		close_btn.custom_minimum_size = Vector2(40, 40)
		close_btn.pressed.connect(_close)
		_group.add_child(close_btn)
		close_btn.position = Vector2((1920.0 - 1300) / 2.0 + 1300 - 56, (1080.0 - 600) / 2.0 + 12)
		close_btn.size = Vector2(40, 40)
		SacredTheme.animate_button(close_btn)

	var clip_box := Control.new()
	clip_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(clip_box)

	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.clip_contents = true
	clip_box.add_child(_scroll)
	SacredTheme.style_sacred_scrollbar(_scroll)

	var margin_c := MarginContainer.new()
	margin_c.add_theme_constant_override("margin_left", 12)
	margin_c.add_theme_constant_override("margin_top", 12)
	margin_c.add_theme_constant_override("margin_right", 12)
	margin_c.add_theme_constant_override("margin_bottom", 12)
	_scroll.add_child(margin_c)

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	margin_c.add_child(grid)

	for card in deck:
		var captured_card: Resource = card
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(137, 195)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.position = Vector2(-1.75, -5.0)
		card_node.pivot_offset = Vector2(70.0, 200.0)
		card_node.scale = Vector2(0.975, 0.975)
		card_node.setup(card, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var captured_node: CardScene = card_node
		card_node.card_hovered.connect(func(_c): _show_card_hover(captured_node))
		card_node.card_unhovered.connect(func(_c): _clear_card_hover(captured_node))
		card_node.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_select_card(captured_card, captured_node))

	var confirm_row := HBoxContainer.new()
	vbox.add_child(confirm_row)
	var spc_l := Control.new()
	spc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(spc_l)
	_confirm_btn = Button.new()
	_confirm_btn.text = confirm_text
	_confirm_btn.custom_minimum_size = Vector2(200, 44)
	_confirm_btn.add_theme_font_size_override("font_size", 16)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm)
	confirm_row.add_child(_confirm_btn)
	SacredTheme.animate_button(_confirm_btn)
	var spc_r := Control.new()
	spc_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_row.add_child(spc_r)

	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_group, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(_group, "modulate:a", 1.0, 0.15)

func _input(ev: InputEvent) -> void:
	if _closing:
		return
	# 휠 스크롤
	if _scroll and ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_scroll.scroll_vertical -= 40
			get_viewport().set_input_as_handled()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_scroll.scroll_vertical += 40
			get_viewport().set_input_as_handled()
	# ESC — 취소 가능할 때만
	if _cancelable and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_close()
		get_viewport().set_input_as_handled()

func _show_card_hover(node: CardScene) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	if _overlay and node.get_parent() != _overlay:
		_card_parents[node] = node.get_parent()
		node.reparent(_overlay, true)
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(1.5, 1.5), 0.22)
	_card_tweens[node] = tw

func _clear_card_hover(node: CardScene) -> void:
	if node in _card_tweens:
		_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(0.975, 0.975), 0.16)
	tw.tween_callback(func():
		if not is_instance_valid(node):
			return
		node.z_index = 0
		if node in _card_parents:
			var orig: Node = _card_parents[node]
			_card_parents.erase(node)
			if is_instance_valid(orig):
				node.reparent(orig, false)
				node.position = Vector2(-1.75, -5.0)
				node.scale = Vector2(0.975, 0.975))
	_card_tweens[node] = tw

func _on_select_card(card: Resource, node: CardScene) -> void:
	if is_instance_valid(_selected_node):
		_selected_node.tween_glow(0.0, 0.12)
	_selected_card = card
	_selected_node = node
	node.tween_glow(1.0, 0.15)
	if is_instance_valid(_confirm_btn):
		_confirm_btn.disabled = false

func _on_confirm() -> void:
	if _selected_card == null or _closing:
		return
	confirmed.emit(_selected_card)
	_close()

func _close() -> void:
	if _closing:
		return
	_closing = true
	for tw in _card_tweens.values():
		if tw.is_valid():
			tw.kill()
	_card_tweens.clear()
	if is_instance_valid(_group):
		var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(_group, "scale", Vector2(0.9, 0.9), 0.12)
		tw.parallel().tween_property(_group, "modulate:a", 0.0, 0.12)
		tw.tween_callback(queue_free)
	else:
		queue_free()
