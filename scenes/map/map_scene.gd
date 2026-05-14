# scenes/map/map_scene.gd
extends Node2D

const MapNodeRes = preload("res://resources/map_node_resource.gd")
const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")

const NODE_SIZE      := 56
const COL_GAP        := 130   # MapGenerator.COLS=7 과 동기화: 7×130=910
const FLOOR_GAP      := 128
const MAP_PAD_TOP    := 48    # 보스 노드 위 여백
const MAP_PAD_BOT    := 64    # floor 0 노드 아래 여백
const MAP_SCROLL_TOP := 150   # 스크롤 영역 시작 Y (타이틀·렐릭 아래)
const _MAP_W         := 7 * COL_GAP
const COL_X_BASE     := int((1920 - _MAP_W) / 2.0) + int(COL_GAP / 2.0)

var _node_buttons: Dictionary = {}  # node_id → Button
var _floor_label: Label
var _relic_container: FlowContainer
var _map_scroll:        ScrollContainer = null
var _map_content:       Control         = null
var _deck_viewer:       CanvasLayer     = null
var _deck_group:        Control         = null
var _deck_overlay:      Control         = null
var _deck_scroll:       ScrollContainer = null
var _deck_card_tweens:  Dictionary      = {}
var _deck_card_parents: Dictionary      = {}
var _active_scroll:     ScrollContainer = null
var _confirm_popup:     CanvasLayer     = null

var _room_tooltip_panel: Panel = null
var _room_tooltip_label: Label = null
var _room_tooltip_timer: Timer = null
var _room_tooltip_pending: String = ""
const _ROOM_TOOLTIP_DELAY := 0.4

func _trf(key: String, args) -> String:
	var s := tr(key)
	if "%d" in s or "%s" in s or "%f" in s:
		return s % args
	return s

func _ready() -> void:
	_build_ui()
	_refresh_map()
	call_deferred("_init_map_scroll")

func _input(ev: InputEvent) -> void:
	if _active_scroll != null and ev is InputEventMouseButton:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			_active_scroll.scroll_vertical -= 40
			get_viewport().set_input_as_handled()
			return
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_active_scroll.scroll_vertical += 40
			get_viewport().set_input_as_handled()
			return

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		if _confirm_popup:
			_close_confirm_popup()
			get_viewport().set_input_as_handled()
		elif _deck_viewer:
			_hide_deck_viewer()
			get_viewport().set_input_as_handled()

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = SacredPalette.INK_1000
	bg.position = Vector2.ZERO
	bg.size = Vector2(1920, 1080)
	add_child(bg)

	# 상단 블룸
	var bloom := SacredTheme.make_top_ellipse_bloom(0.0)
	bloom.position = Vector2.ZERO
	bloom.size = Vector2(1920, 560)
	add_child(bloom)

	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.position = Vector2.ZERO
	crosshatch.size = Vector2(1920, 1080)
	add_child(crosshatch)

	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.text = _trf("ui.map.act_title", GameManager.current_act)
	title.position = Vector2(760, 45)
	title.size = Vector2(400, 54)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	LabelUtils.fit_text(title, 40, 22)

	# 골드 소지량 (좌측 상단 — 상점씬과 동일)
	var gold_lbl := Label.new()
	gold_lbl.name = "GoldLabel"
	gold_lbl.theme_type_variation = "EyebrowLabel"
	gold_lbl.add_theme_font_size_override("font_size", 21)
	gold_lbl.text     = "⛬ %dg" % GameManager.gold
	gold_lbl.position = Vector2(30, 22)
	gold_lbl.size     = Vector2(200, 32)
	add_child(gold_lbl)
	LabelUtils.fit_text(gold_lbl, 21, 13)

	# 릴릭 표시
	_relic_container = FlowContainer.new()
	_relic_container.position = Vector2(20, 70)
	_relic_container.size = Vector2(1880, 72)
	_relic_container.add_theme_constant_override("h_separation", 6)
	_relic_container.add_theme_constant_override("v_separation", 4)
	add_child(_relic_container)
	_refresh_relics()

	# 타이틀~스크롤 구분선
	var div_line := TextureRect.new()
	div_line.texture = SacredTheme.make_center_bright_h_tex()
	div_line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div_line.stretch_mode = TextureRect.STRETCH_SCALE
	div_line.position = Vector2(64, 146)
	div_line.size = Vector2(1920 - 128, 2)
	div_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(div_line)

	# 맵 스크롤 영역
	var content_h := MAP_PAD_TOP + (MapGenerator.FLOORS - 1) * FLOOR_GAP + NODE_SIZE + MAP_PAD_BOT
	_map_scroll = ScrollContainer.new()
	_map_scroll.position               = Vector2(0, MAP_SCROLL_TOP)
	_map_scroll.size                   = Vector2(1920, 1080 - MAP_SCROLL_TOP)
	_map_scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_map_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_map_scroll)

	_map_content = Control.new()
	_map_content.custom_minimum_size = Vector2(1920, content_h)
	_map_scroll.add_child(_map_content)

	_build_room_tooltip()

	# 연결선 먼저 그리기 (버튼 뒤에)
	_draw_connections()

	# 노드 버튼 생성
	for node in GameManager.run_map:
		_create_node_button(node)

	# 오버레이 UI (스크롤 위에 렌더)
	_floor_label = Label.new()
	_floor_label.theme_type_variation = "SubLabel"
	_floor_label.position = Vector2(50, 520)
	_floor_label.size = Vector2(300, 40)
	add_child(_floor_label)

	var deck_btn := Button.new()
	deck_btn.text = tr("ui.map.btn_deck")
	deck_btn.position = Vector2(50, 570)
	deck_btn.add_theme_font_size_override("font_size", 16)
	deck_btn.pressed.connect(_show_deck_viewer)
	add_child(deck_btn)
	deck_btn.size = Vector2(160, 40)
	LabelUtils.fit_text(deck_btn, 16, 12)
	SacredTheme.animate_button(deck_btn)

	var btn_back := Button.new()
	btn_back.theme_type_variation = "VowButton"
	btn_back.text = tr("ui.chapter_select.back")
	btn_back.position = Vector2(60, 960)
	btn_back.size = Vector2(200, 52)
	btn_back.add_theme_font_size_override("font_size", 14)
	btn_back.pressed.connect(_on_back_pressed)
	add_child(btn_back)
	LabelUtils.fit_text(btn_back, 14, 11)
	SacredTheme.animate_button(btn_back)

	_build_party_panel()

func _build_room_tooltip() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 20
	add_child(cl)
	_room_tooltip_panel = Panel.new()
	_room_tooltip_panel.visible = false
	_room_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_room_tooltip_panel)
	_room_tooltip_label = Label.new()
	_room_tooltip_label.position = Vector2(10, 6)
	_room_tooltip_label.add_theme_font_size_override("font_size", 15)
	_room_tooltip_panel.add_child(_room_tooltip_label)
	_room_tooltip_timer = Timer.new()
	_room_tooltip_timer.one_shot = true
	_room_tooltip_timer.wait_time = _ROOM_TOOLTIP_DELAY
	_room_tooltip_timer.timeout.connect(_on_room_tooltip_timer)
	add_child(_room_tooltip_timer)

func _on_room_hover(text: String) -> void:
	_room_tooltip_pending = text
	_room_tooltip_timer.start()

func _on_room_exit() -> void:
	_room_tooltip_timer.stop()
	_room_tooltip_pending = ""
	_room_tooltip_panel.visible = false

func _on_room_tooltip_timer() -> void:
	if _room_tooltip_pending.is_empty():
		return
	_room_tooltip_label.text = _room_tooltip_pending
	_room_tooltip_label.reset_size()
	var sz := _room_tooltip_label.get_combined_minimum_size()
	_room_tooltip_panel.size = sz + Vector2(20, 12)
	var mpos := get_viewport().get_mouse_position()
	_room_tooltip_panel.position = mpos + Vector2(16, 24)
	_room_tooltip_panel.position.x = minf(_room_tooltip_panel.position.x, 1916.0 - _room_tooltip_panel.size.x)
	_room_tooltip_panel.position.y = minf(_room_tooltip_panel.position.y, 1076.0 - _room_tooltip_panel.size.y)
	_room_tooltip_panel.visible = true

func _build_party_panel() -> void:
	var tm := get_node_or_null("/root/TeamManager")
	if tm == null or (tm as Object).get("heroes") == null or tm.heroes.is_empty():
		return

	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var hdr := Label.new()
	hdr.text = "— PARTY —"
	if mono_font:
		hdr.add_theme_font_override("font", mono_font)
	hdr.add_theme_font_size_override("font_size", 11)
	hdr.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.position = Vector2(1610, 492)
	hdr.size = Vector2(260, 20)
	add_child(hdr)

	var panel_x := 1600.0
	var panel_y := 518.0
	var bar_w   := 260.0

	var party_vbox := VBoxContainer.new()
	party_vbox.add_theme_constant_override("separation", 18)
	party_vbox.position = Vector2(panel_x, panel_y)
	party_vbox.size = Vector2(bar_w, 400)
	add_child(party_vbox)

	for hero in tm.heroes:
		var cur_hp: int = tm.get_current_hp(hero.hero_id) if tm.has_method("get_current_hp") else hero.max_hp
		var ratio: float = float(cur_hp) / float(hero.max_hp)

		var hero_col := VBoxContainer.new()
		hero_col.add_theme_constant_override("separation", 4)
		party_vbox.add_child(hero_col)

		var name_lbl := Label.new()
		name_lbl.text = tr(hero.hero_name)
		name_lbl.add_theme_font_size_override("font_size", 14)
		name_lbl.add_theme_color_override("font_color", SacredPalette.BRASS_300)
		hero_col.add_child(name_lbl)

		var bar := _make_map_hp_bar(bar_w, ratio)
		hero_col.add_child(bar)

		var hp_lbl := Label.new()
		hp_lbl.text = "%d / %d" % [cur_hp, hero.max_hp]
		hp_lbl.add_theme_font_size_override("font_size", 12)
		var hp_color: Color
		if ratio <= 0.15:
			hp_color = SacredPalette.BLOOD_300
		elif ratio <= 0.5:
			hp_color = SacredPalette.BLOOD_400
		else:
			hp_color = SacredPalette.BONE_300
		hp_lbl.add_theme_color_override("font_color", hp_color)
		hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hero_col.add_child(hp_lbl)

func _make_map_hp_bar(bar_w: float, ratio: float) -> Control:
	var height := 12.0
	var P := SacredPalette

	var outer := Panel.new()
	outer.custom_minimum_size = Vector2(bar_w, height)
	var sb := StyleBoxFlat.new()
	sb.bg_color = P.INK_1000
	sb.border_color = P.BRASS_700
	sb.set_border_width_all(1)
	outer.add_theme_stylebox_override("panel", sb)

	var inner_w := bar_w - 2.0
	var inner_h := height - 2.0

	var g := Gradient.new()
	if ratio <= 0.15:
		g.set_color(0, P.BLOOD_500); g.set_offset(0, 0.0)
		g.set_color(1, P.BLOOD_300); g.set_offset(1, 1.0)
	elif ratio <= 0.5:
		g.set_color(0, P.BLOOD_600); g.set_offset(0, 0.0)
		g.set_color(1, P.BLOOD_400); g.set_offset(1, 1.0)
	else:
		g.set_color(0, P.BLOOD_700); g.set_offset(0, 0.0)
		g.set_color(1, P.BLOOD_400); g.set_offset(1, 1.0)
		g.add_point(0.6, P.BLOOD_500)
	var tex := GradientTexture1D.new()
	tex.gradient = g

	var fill_w := maxf(ratio * inner_w, 1.0 if ratio > 0.0 else 0.0)
	var fill := TextureRect.new()
	fill.position     = Vector2(1.0, 1.0)
	fill.texture      = tex
	fill.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.size         = Vector2(fill_w, inner_h)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	outer.add_child(fill)

	var hg := Gradient.new()
	hg.set_color(0, Color(1.0, 0.92, 0.82, 0.18))
	hg.set_color(1, Color(1.0, 0.92, 0.82, 0.0))
	var hg_tex := GradientTexture2D.new()
	hg_tex.gradient  = hg
	hg_tex.fill      = GradientTexture2D.FILL_LINEAR
	hg_tex.fill_from = Vector2(0.5, 0.0)
	hg_tex.fill_to   = Vector2(0.5, 0.5)
	hg_tex.width = 4; hg_tex.height = 16
	var highlight := TextureRect.new()
	highlight.texture      = hg_tex
	highlight.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	highlight.stretch_mode = TextureRect.STRETCH_SCALE
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_child(highlight)

	return outer

func _draw_connections() -> void:
	for node in GameManager.run_map:
		var from := _node_center(node)
		for conn_id in node.connections:
			var to := _node_center(GameManager.run_map[conn_id])
			var line := Line2D.new()
			line.add_point(from)
			line.add_point(to)
			line.width = 2.0
			line.default_color = Color(SacredPalette.BRASS_700.r, SacredPalette.BRASS_700.g, SacredPalette.BRASS_700.b, 0.4)
			_map_content.add_child(line)

func _create_node_button(node: Resource) -> void:
	var btn := Button.new()
	btn.position = _node_top_left(node)
	btn.size = Vector2(NODE_SIZE, NODE_SIZE)
	var tip_text := _room_type_text(node.room_type)
	btn.mouse_entered.connect(func(): _on_room_hover(tip_text))
	btn.mouse_exited.connect(_on_room_exit)
	var icon: Texture2D = IconUtils.get_room_icon(node.room_type)
	if icon != null:
		btn.icon = icon
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		btn.text = _room_type_text(node.room_type)
		btn.add_theme_font_size_override("font_size", 13)
		LabelUtils.fit_text(btn, 13, 10)
	match node.room_type:
		MapNodeRes.RoomType.ELITE:
			btn.theme_type_variation = "EliteRoomButton"
		MapNodeRes.RoomType.BOSS:
			btn.theme_type_variation = "BossRoomButton"
		_:
			btn.theme_type_variation = "RoomButton"
	var captured_id: int = node.node_id
	btn.pressed.connect(func(): GameManager.enter_node(captured_id))
	_map_content.add_child(btn)
	_node_buttons[node.node_id] = btn
	SacredTheme.animate_button(btn)

func _init_map_scroll() -> void:
	if _map_scroll == null:
		return
	# 현재 층 노드가 화면 중앙에 오도록 초기 스크롤 설정
	var cur_floor: int = GameManager.current_floor if GameManager.current_floor >= 0 else 0
	var node_y := MAP_PAD_TOP + (MapGenerator.FLOORS - 1 - cur_floor) * FLOOR_GAP + int(NODE_SIZE / 2.0)
	var visible_h := 1080 - MAP_SCROLL_TOP
	_map_scroll.scroll_vertical = max(0, int(node_y - visible_h * 0.5))

func _refresh_map() -> void:
	for node_id in _node_buttons:
		var btn: Button = _node_buttons[node_id]
		var node: Resource = GameManager.run_map[node_id]

		if node.visited:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
		elif node_id in GameManager.available_node_ids:
			btn.disabled = false
			btn.modulate = SacredPalette.BRASS_300
		else:
			btn.disabled = true
			btn.modulate = Color(0.6, 0.6, 0.7, 0.5)

		if node_id == GameManager.current_node_id:
			btn.modulate = Color(1.0, 1.0, 0.3)

	_floor_label.text = _trf("ui.map.floor_label", GameManager.current_floor)
	LabelUtils.fit_text(_floor_label, 18, 12)

func _node_jitter(node: Resource) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = node.node_id * 7919 + 31337
	return Vector2(rng.randf_range(-35.0, 35.0), rng.randf_range(-28.0, 28.0))

func _node_center(node: Resource) -> Vector2:
	var base := Vector2(
		COL_X_BASE + node.column * COL_GAP,
		MAP_PAD_TOP + (MapGenerator.FLOORS - 1 - node.floor_num) * FLOOR_GAP + int(NODE_SIZE / 2.0)
	)
	return base + _node_jitter(node)

func _node_top_left(node: Resource) -> Vector2:
	return _node_center(node) - Vector2(NODE_SIZE / 2.0, NODE_SIZE / 2.0)

func _refresh_relics() -> void:
	for child in _relic_container.get_children():
		child.queue_free()
	for s in BattleManager.get_active_synergies():
		var tip: String = "%s\n%s" % [tr(s["name_key"]), tr(s["desc_key"])]
		var tex: Texture2D = IconUtils.get_synergy_icon(s["name_key"])
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
			lbl.text = "[%s]" % tr(s["name_key"])
			lbl.tooltip_text = tip
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.modulate = SacredPalette.AMETHYST_300
			_relic_container.add_child(lbl)
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
			lbl.modulate = SacredPalette.BRASS_300
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
	_deck_overlay = overlay

	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(SacredPalette.INK_1000.r, SacredPalette.INK_1000.g, SacredPalette.INK_1000.b, 0.85)
	bg_rect.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_hide_deck_viewer()
	)
	overlay.add_child(bg_rect)

	var group := Control.new()
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.pivot_offset = Vector2(960, 540)
	group.scale = Vector2(0.9, 0.9)
	group.modulate.a = 0.0
	overlay.add_child(group)
	_deck_group = group

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1300, 700)
	panel.position = Vector2((1920 - 1300) / 2.0, (1080 - 700) / 2.0)
	group.add_child(panel)

	# PanelContainer는 자식 레이아웃을 강제하므로 브라켓을 sibling Control에 배치
	var panel_brackets := Control.new()
	panel_brackets.position = panel.position
	panel_brackets.size = Vector2(1300, 700)
	panel_brackets.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(panel_brackets)
	SacredTheme.add_corner_brackets(panel_brackets)

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
	hdiv.position = Vector2(panel.position.x + 20, panel.position.y + 62)
	hdiv.size = Vector2(1300 - 40, 2)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hdiv)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.clip_children = Control.CLIP_CHILDREN_ONLY
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.text = _trf("ui.map.deck_list_title", all_cards.size())
	title_lbl.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title_lbl)
	LabelUtils.fit_text(title_lbl, 22, 14)

	var close_btn := Button.new()
	close_btn.theme_type_variation = "IconButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_hide_deck_viewer)
	group.add_child(close_btn)
	close_btn.position = Vector2((1920.0 - 1300) / 2.0 + 1300 - 56, (1080.0 - 700) / 2.0 + 12)
	close_btn.size     = Vector2(40, 40)
	SacredTheme.animate_button(close_btn)

	var clip_box := Control.new()
	clip_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(clip_box)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_box.add_child(scroll)
	_deck_scroll = scroll
	SacredTheme.style_sacred_scrollbar(scroll)

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	for card_res in all_cards:
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(137, 195)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.position     = Vector2(-1.75, -5.0)
		card_node.pivot_offset = Vector2(70.0, 200.0)
		card_node.scale        = Vector2(0.975, 0.975)
		card_node.setup(card_res, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

		var captured_node: CardScene = card_node
		card_node.card_hovered.connect(func(_c): _show_deck_card_hover(captured_node))
		card_node.card_unhovered.connect(func(_c): _clear_deck_card_hover(captured_node))

	_deck_viewer = canvas
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(group, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(group, "modulate:a", 1.0, 0.15)

func _show_deck_card_hover(node: CardScene) -> void:
	if node in _deck_card_tweens:
		_deck_card_tweens[node].kill()
	_active_scroll = _deck_scroll
	if _deck_overlay and node.get_parent() != _deck_overlay:
		_deck_card_parents[node] = node.get_parent()
		node.reparent(_deck_overlay, true)
	node.z_index = 50
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(1.5, 1.5), 0.22)
	_deck_card_tweens[node] = tw

func _clear_deck_card_hover(node: CardScene) -> void:
	if node in _deck_card_tweens:
		_deck_card_tweens[node].kill()
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(node, "scale", Vector2(0.975, 0.975), 0.16)
	tw.tween_callback(func():
		if not is_instance_valid(node):
			return
		node.z_index = 0
		if node in _deck_card_parents:
			var orig: Node = _deck_card_parents[node]
			_deck_card_parents.erase(node)
			if is_instance_valid(orig):
				node.reparent(orig, false)
				node.position = Vector2(-1.75, -5.0)
				node.scale    = Vector2(0.975, 0.975)
	)
	_deck_card_tweens[node] = tw

func _hide_deck_viewer() -> void:
	if _deck_viewer:
		_deck_card_tweens.clear()
		_deck_card_parents.clear()
		_active_scroll = null
		_deck_scroll   = null
		_deck_overlay  = null
		var viewer := _deck_viewer
		var group  := _deck_group
		_deck_viewer = null
		_deck_group  = null
		if is_instance_valid(group):
			var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(group, "scale", Vector2(0.9, 0.9), 0.12)
			tw.parallel().tween_property(group, "modulate:a", 0.0, 0.12)
			tw.tween_callback(func(): if is_instance_valid(viewer): viewer.queue_free())
		else:
			if is_instance_valid(viewer): viewer.queue_free()

func _on_back_pressed() -> void:
	_show_confirm_popup()

func _show_confirm_popup() -> void:
	if _confirm_popup:
		return
	_confirm_popup = CanvasLayer.new()
	_confirm_popup.layer = 50
	add_child(_confirm_popup)

	# 반투명 오버레이
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_popup.add_child(overlay)

	# 팝업 패널
	var PW := 580.0
	var PH := 220.0
	var panel := Panel.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = SacredPalette.INK_900
	ps.border_color = SacredPalette.BRASS_500
	ps.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", ps)
	panel.position = Vector2((1920.0 - PW) * 0.5, (1080.0 - PH) * 0.5)
	panel.size = Vector2(PW, PH)
	panel.pivot_offset = Vector2(PW * 0.5, PH * 0.5)
	_confirm_popup.add_child(panel)
	SacredTheme.add_corner_brackets(panel)

	# 메시지
	var msg := Label.new()
	msg.text = tr("ui.map.confirm_back.message")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg.position = Vector2(40.0, 36.0)
	msg.size = Vector2(PW - 80.0, 96.0)
	msg.add_theme_font_size_override("font_size", 20)
	msg.add_theme_color_override("font_color", SacredPalette.BONE_100)
	panel.add_child(msg)
	LabelUtils.fit_text(msg, 20, 14)

	# 버튼 행
	var mono_font := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font
	var BTN_Y := PH - 72.0
	var BTN_W := 200.0
	var BTN_H := 46.0
	var GAP   := 24.0
	var total := BTN_W * 2.0 + GAP
	var bx    := (PW - total) * 0.5

	var btn_ok := Button.new()
	btn_ok.text = tr("ui.map.confirm_back.ok")
	btn_ok.theme_type_variation = "VowButton"
	if mono_font:
		btn_ok.add_theme_font_override("font", mono_font)
	btn_ok.add_theme_font_size_override("font_size", 13)
	btn_ok.position = Vector2(bx, BTN_Y)
	btn_ok.size = Vector2(BTN_W, BTN_H)
	btn_ok.pressed.connect(_on_confirm_back)
	panel.add_child(btn_ok)
	SacredTheme.animate_button(btn_ok)

	var btn_cancel := Button.new()
	btn_cancel.text = tr("ui.map.confirm_back.cancel")
	btn_cancel.theme_type_variation = "PrimaryButton"
	if mono_font:
		btn_cancel.add_theme_font_override("font", mono_font)
	btn_cancel.add_theme_font_size_override("font_size", 13)
	btn_cancel.position = Vector2(bx + BTN_W + GAP, BTN_Y)
	btn_cancel.size = Vector2(BTN_W, BTN_H)
	btn_cancel.pressed.connect(_close_confirm_popup)
	panel.add_child(btn_cancel)
	SacredTheme.animate_button(btn_cancel)

	# 팝업 열기 트윈
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	var tw := create_tween().set_parallel(true)
	tw.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "modulate:a", 1.0, 0.20)
	tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.18)

func _close_confirm_popup() -> void:
	if not _confirm_popup:
		return
	var popup := _confirm_popup
	_confirm_popup = null
	var panel: Panel = popup.get_child(1) as Panel
	if is_instance_valid(panel):
		var tw := create_tween().set_parallel(true)
		tw.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_property(panel, "modulate:a", 0.0, 0.15)
		tw.tween_property(panel, "scale", Vector2(0.95, 0.95), 0.15)
		tw.chain().tween_callback(func(): if is_instance_valid(popup): popup.queue_free())
	else:
		popup.queue_free()

func _on_confirm_back() -> void:
	GameManager.reset()
	SceneTransition.go("res://scenes/chapter_select/chapter_select_scene.tscn")
