# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const CardResource = preload("res://resources/card_resource.gd")
const SoldierScene = preload("res://characters/summons/soldier/soldier.tscn")
const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")

const WINDOW_W := 1920
const WINDOW_H := 1080
const HERO_X := 20
const ENEMY_X := 1440
const ENEMY_COL_GAP := 20
const SLOT_W := 240
const SLOT_H := 280
const BOTTOM_Y := 840
const CARD_W := 110
const CARD_H := 160
const SLOT_GAP := 20
const MAX_ENEMY_COUNT := 6
const TOKEN_COLS := 6
const TOKEN_ROWS := 2
const TOKEN_TILE_W := 111
const TOKEN_TILE_H := 138
const TOKEN_TILE_GAP := 4
const TOKEN_AREA_X := 270

# UI 참조 (Dictionary 배열)
# hero entry: {panel, name_lbl, hp_lbl, block_lbl, hero_id}
# enemy entry: {panel, intent_lbl, btn, name_lbl, hp_lbl, block_lbl}
var _hero_nodes: Array = []
var _enemy_nodes: Array = []
var _card_buttons: Array = []
var _hero_char_nodes: Dictionary = {}  # hero_id → Node2D
var _enemy_char_nodes: Array = []      # index → Node2D

var _energy_label: Label
var _end_turn_btn: Button
var _message_label: Label
var _relic_container: HBoxContainer
var _selected_card: Resource = null

var _drag_card: Resource = null
var _drag_preview: Label = null
var _card_tooltip: Control = null

var _hero_status_containers: Dictionary = {}
var _enemy_status_containers: Array = []
var _token_tile_nodes: Dictionary = {}
var _synergy_box: HBoxContainer = null
var _active_powers_box: VBoxContainer = null
var _debug_badge: Label = null
var _debug_hp_target_mode: bool = false
var _debug_grid_visible: bool = false
var _debug_grid_nodes: Array = []

var _deck_viewer: Control = null
var _deck_viewer_tab: String = "draw"

const STATUS_EMOJI := {
	"poison_dmg": "☠", "weak": "↓", "vulnerable": "⚡",
	"morale": "★", "charm": "♥", "strength": "↑",
	"taunt": "►", "counter_block": "🛡", "charm_resistance": "💜"
}

func _ready() -> void:
	_build_ui()
	if OS.is_debug_build():
		_build_debug_tooltip()
	BattleManager.team_mgr = TeamManager
	BattleManager.deck_mgr = DeckManager
	_connect_signals()
	_start_battle()
	if OS.is_debug_build():
		_debug_badge = Label.new()
		_debug_badge.position = Vector2(1500, 20)
		_debug_badge.add_theme_font_size_override("font_size", 14)
		_debug_badge.add_theme_color_override("font_color", Color.RED)
		_debug_badge.visible = false
		add_child(_debug_badge)

func _build_debug_tooltip() -> void:
	pass  # DebugManager autoload에서 전역 처리

# ─────────────────────────────────────────────
# UI 빌드
# ─────────────────────────────────────────────

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12)
	bg.position = Vector2.ZERO
	bg.size = Vector2(WINDOW_W, WINDOW_H)
	add_child(bg)

	# 상단 메시지 레이블
	_message_label = Label.new()
	_message_label.position = Vector2(WINDOW_W / 2.0 - 300, 16)
	_message_label.size = Vector2(600, 50)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 26)
	add_child(_message_label)

	# 에너지 레이블
	_energy_label = Label.new()
	_energy_label.position = Vector2(WINDOW_W - 220, BOTTOM_Y - 34)
	_energy_label.size = Vector2(200, 30)
	_energy_label.add_theme_font_size_override("font_size", 22)
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.text = "⚡ 0 / 3"
	add_child(_energy_label)

	# 턴 종료 버튼
	_end_turn_btn = Button.new()
	_end_turn_btn.position = Vector2(WINDOW_W - 220, BOTTOM_Y + 16)
	_end_turn_btn.size = Vector2(200, 60)
	_end_turn_btn.text = tr("battle.btn_end_turn")
	_end_turn_btn.add_theme_font_size_override("font_size", 22)
	_end_turn_btn.disabled = true
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	add_child(_end_turn_btn)

	# 덱 보기 버튼 (End Turn 왼쪽)
	var deck_btn := Button.new()
	deck_btn.position = Vector2(WINDOW_W - 350, BOTTOM_Y + 16)
	deck_btn.size = Vector2(120, 60)
	deck_btn.text = tr("ui.battle.btn_deck_view")
	deck_btn.add_theme_font_size_override("font_size", 18)
	deck_btn.pressed.connect(_show_deck_viewer_in_battle)
	add_child(deck_btn)

	# 상단 바 — 시너지 → 릴릭 순서, 넘치면 자동 줄바꿈
	var top_bar := FlowContainer.new()
	top_bar.position = Vector2(20, 4)
	top_bar.size = Vector2(WINDOW_W - 40, 72)
	add_child(top_bar)

	_synergy_box = HBoxContainer.new()
	_synergy_box.add_theme_constant_override("separation", 6)
	top_bar.add_child(_synergy_box)

	_relic_container = HBoxContainer.new()
	_relic_container.add_theme_constant_override("separation", 6)
	top_bar.add_child(_relic_container)
	_refresh_relics()

	_active_powers_box = VBoxContainer.new()
	_active_powers_box.position = Vector2(20, 800)
	_active_powers_box.custom_minimum_size = Vector2(300, 0)
	_active_powers_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_active_powers_box)

	# 영웅 슬롯 3개 고정 (초기 숨김)
	for i in range(3):
		_hero_nodes.append(_make_hero_slot(i))
	# 적 슬롯은 _setup_enemies()에서 동적 생성

func _make_hero_slot(index: int) -> Dictionary:
	var y := 80 + index * (SLOT_H + SLOT_GAP)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.12, 0.2)
	panel.position = Vector2(HERO_X, y)
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)

	# UI 상단 배치, 스프라이트는 그 뒤에 렌더 (z_index=1 for UI)
	var bar_w: float = 211.0
	var _bar_h: float = 12.0
	var bar_x: float = HERO_X + (SLOT_W - bar_w) / 2.0

	var name_lbl := _make_label(Vector2(bar_x, y + 4), Vector2(bar_w, 22), 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.z_index = 1
	name_lbl.visible = false

	var hp_bar := _make_hp_bar(Vector2(bar_x, y + 28), bar_w)
	hp_bar.z_index = 1
	hp_bar.visible = false

	var hp_lbl := _make_label(Vector2(bar_x, y + 22), Vector2(bar_w, 24), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.z_index = 1
	hp_lbl.visible = false

	var block_lbl := _make_label(Vector2(bar_x, y + 22), Vector2(bar_w, 24), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	block_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 2
	block_lbl.visible = false

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, y + 42)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	status_box.visible = false
	add_child(status_box)

	return { "panel": panel, "name_lbl": name_lbl, "hp_bar": hp_bar,
			 "hp_lbl": hp_lbl, "block_lbl": block_lbl,
			 "hero_id": "", "status_box": status_box }

func _enemy_slot_pos(index: int, total: int) -> Vector2:
	if total <= 3:
		return Vector2(ENEMY_X, 80 + index * (SLOT_H + SLOT_GAP))
	var row: int = int(index / 2.0)
	var col: int = index % 2
	return Vector2(ENEMY_X + col * (SLOT_W + ENEMY_COL_GAP), 80 + row * (SLOT_H + SLOT_GAP))

func _make_enemy_slot(index: int, total: int) -> Dictionary:
	var pos: Vector2 = _enemy_slot_pos(index, total)
	var panel := ColorRect.new()
	panel.color = Color(0.18, 0.10, 0.10)
	panel.position = pos
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)

	var bar_w: float = 211.0
	var _bar_h: float = 12.0
	var bar_x: float = pos.x + (SLOT_W - bar_w) / 2.0

	var intent_lbl := _make_label(Vector2(pos.x, pos.y + 4), Vector2(SLOT_W, 22), 18)
	intent_lbl.modulate = Color(1.0, 0.8, 0.2)
	intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_lbl.z_index = 1

	var btn := Button.new()
	btn.flat = true
	btn.position = pos
	btn.size = Vector2(SLOT_W, SLOT_H)
	btn.text = ""
	btn.visible = false
	var captured_index := index
	btn.pressed.connect(func(): _on_enemy_pressed(captured_index))
	add_child(btn)

	var name_lbl := _make_label(Vector2(bar_x, pos.y + 28), Vector2(bar_w, 18), 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.z_index = 1

	var hp_bar := _make_hp_bar(Vector2(bar_x, pos.y + 48), bar_w)
	hp_bar.z_index = 1

	var hp_lbl := _make_label(Vector2(bar_x, pos.y + 42), Vector2(bar_w, 24), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.z_index = 1

	var block_lbl := _make_label(Vector2(bar_x, pos.y + 42), Vector2(bar_w, 24), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	block_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 2

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, pos.y + 62)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	add_child(status_box)

	var counter_lbl := Label.new()
	counter_lbl.position = Vector2(pos.x + SLOT_W - 80, pos.y + 4)
	counter_lbl.size = Vector2(78, 22)
	counter_lbl.add_theme_font_size_override("font_size", 14)
	counter_lbl.modulate = Color(1.0, 0.7, 0.4)
	counter_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	counter_lbl.visible = false
	counter_lbl.z_index = 2
	add_child(counter_lbl)

	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
			 "block_lbl": block_lbl, "status_box": status_box,
			 "counter_lbl": counter_lbl }

func _refresh_relics() -> void:
	for child in _relic_container.get_children():
		child.queue_free()
	if not GameManager or not GameManager.is_inside_tree():
		return
	for relic in GameManager.relics:
		var lbl := Label.new()
		lbl.text = "[%s]" % relic.relic_name
		lbl.tooltip_text = relic.description
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(1.0, 0.85, 0.3)
		_relic_container.add_child(lbl)

func _make_label(pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	add_child(lbl)
	return lbl

func _make_hp_bar(pos: Vector2, width: float) -> Control:
	var wrapper := Control.new()
	wrapper.position = pos
	wrapper.size = Vector2(width, 12)
	wrapper.custom_minimum_size = Vector2.ZERO

	var bg := ColorRect.new()
	bg.position = Vector2.ZERO
	bg.size = Vector2(width, 12)
	bg.color = Color(0.15, 0.15, 0.15)
	wrapper.add_child(bg)

	var fill := ColorRect.new()
	fill.name = "Fill"
	fill.position = Vector2.ZERO
	fill.size = Vector2(width, 12)
	fill.color = Color(0.8, 0.15, 0.15)
	wrapper.add_child(fill)

	add_child(wrapper)
	return wrapper

# ─────────────────────────────────────────────
# 시그널 연결 (스텁 — Task 3~5에서 채움)
# ─────────────────────────────────────────────

func _connect_signals() -> void:
	DeckManager.hand_changed.connect(_refresh_hand)
	DeckManager.energy_changed.connect(_on_energy_changed)
	DeckManager.card_played.connect(_on_card_played)
	BattleManager.player_turn_started.connect(_on_player_turn_started)
	BattleManager.enemy_turn_started.connect(_on_enemy_turn_started)
	BattleManager.hero_damaged.connect(_on_hero_damaged)
	BattleManager.enemy_damaged.connect(_on_enemy_damaged)
	TeamManager.hero_healed.connect(_on_hero_healed)
	BattleManager.enemy_died.connect(_on_enemy_died)
	BattleManager.battle_won.connect(_on_battle_won)
	BattleManager.battle_lost.connect(_on_battle_lost)
	TeamManager.hero_died.connect(_on_hero_died)
	TeamManager.hero_revived.connect(_on_hero_revived)
	BattleManager.status_applied.connect(_on_status_applied)
	BattleManager.morale_changed.connect(_on_morale_changed)
	BattleManager.active_powers_changed.connect(_on_active_powers_changed)
	BattleManager.enemy_counter_changed.connect(_on_enemy_counter_changed)

# ─────────────────────────────────────────────
# 배틀 초기화
# ─────────────────────────────────────────────

func _start_battle() -> void:
	if not GameManager.pending_enemies.is_empty():
		BattleManager.turn_interval = 0.4
		BattleManager.setup_battle(GameManager.pending_enemies)
		_setup_heroes()
		_setup_enemies()
		BattleManager.start_player_turn()
	else:
		_start_test_battle()  # GameManager 없이 단독 실행 시 폴백

func _start_test_battle() -> void:
	var HeroRes = load("res://resources/hero_resource.gd")
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var CardRes = load("res://resources/card_resource.gd")

	# 영웅 설정
	TeamManager.clear()
	var napoleon = HeroRes.new()
	napoleon.hero_id = "napoleon"
	napoleon.hero_name = "나폴레옹"
	napoleon.max_hp = 70
	napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
	TeamManager.add_hero(napoleon)

	# 덱 설정 (스트라이크 3장 + 디펜드 2장)
	DeckManager.clear()
	for _i in range(3):
		var card = CardRes.new()
		card.card_name = "스트라이크"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "attack"
		var eff = EffectRes.new()
		eff.effect_type = EffectRes.EffectType.DAMAGE
		eff.value = 6
		eff.target = "SINGLE"
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)
	for _i in range(2):
		var card = CardRes.new()
		card.card_name = "디펜드"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "idle"
		var eff = EffectRes.new()
		eff.effect_type = EffectRes.EffectType.BLOCK
		eff.value = 5
		eff.target = "SELF"
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)

	# 적 설정
	var IntentResClass = load("res://resources/intent_resource.gd")
	var satyr = EnemyRes.new()
	satyr.enemy_name = "사티로스"
	satyr.max_hp = 30
	satyr.character_scene = load("res://characters/enemies/satyr/satyr.tscn")
	var intent = IntentResClass.new()
	intent.action_type = IntentResClass.ActionType.ATTACK
	intent.value = 6
	intent.target = IntentResClass.TargetType.RANDOM
	satyr.intent_pattern = [intent]

	BattleManager.turn_interval = 0.4
	BattleManager.setup_battle([satyr])
	_setup_heroes()
	_setup_enemies()
	BattleManager.start_player_turn()

# ─────────────────────────────────────────────
# 영웅/적 표시 (Task 2에서 구현)
# ─────────────────────────────────────────────

func _setup_heroes() -> void:
	# 기존 캐릭터 노드 정리
	for char_node in _hero_char_nodes.values():
		char_node.queue_free()
	_hero_char_nodes.clear()
	for entry in _hero_nodes:
		entry["panel"].visible = false
		entry["name_lbl"].visible = false
		entry["hp_bar"].visible = false
		entry["hp_lbl"].visible = false
		entry["block_lbl"].visible = false
		entry["status_box"].visible = false
		entry["hero_id"] = ""
	# 기존 병사 타일 정리
	for tiles in _token_tile_nodes.values():
		for tile in tiles:
			tile.queue_free()
	_token_tile_nodes.clear()

	var heroes := TeamManager.heroes
	for i in range(min(heroes.size(), 3)):
		var hero: Resource = heroes[i]
		var entry: Dictionary = _hero_nodes[i]
		entry["panel"].visible = true
		entry["name_lbl"].visible = true
		entry["hp_bar"].visible = true
		entry["hp_lbl"].visible = true
		entry["block_lbl"].visible = true
		entry["status_box"].visible = true
		entry["hero_id"] = hero.hero_id
		entry["name_lbl"].text = hero.get("hero_name") if hero.get("hero_name") != null else hero.hero_id

		if hero.character_scene != null:
			var char_node = hero.character_scene.instantiate()
			var slot_y: int = 80 + i * (SLOT_H + SLOT_GAP)
			char_node.position = Vector2(HERO_X + SLOT_W / 2.0 - 40.0 * 1.44, slot_y + 88)
			char_node.scale = Vector2(1.44, 2.4)
			add_child(char_node)
			_hero_char_nodes[hero.hero_id] = char_node

		_hero_status_containers[hero.hero_id] = entry["status_box"]
		_update_hero_ui(hero.hero_id)

func _setup_enemies() -> void:
	# 기존 노드 전부 파괴
	for char_node in _enemy_char_nodes:
		if char_node != null:
			char_node.queue_free()
	_enemy_char_nodes.clear()
	for entry in _enemy_nodes:
		entry["panel"].queue_free()
		entry["intent_lbl"].queue_free()
		entry["btn"].queue_free()
		entry["name_lbl"].queue_free()
		entry["hp_bar"].queue_free()
		entry["hp_lbl"].queue_free()
		entry["block_lbl"].queue_free()
		entry["status_box"].queue_free()
		entry["counter_lbl"].queue_free()
	_enemy_nodes.clear()
	_enemy_status_containers.clear()

	var total: int = 0
	while total < MAX_ENEMY_COUNT and BattleManager.get_enemy(total) != null:
		total += 1

	for i in range(total):
		var entry: Dictionary = _make_enemy_slot(i, total)
		_enemy_nodes.append(entry)
		_enemy_char_nodes.append(null)
		_enemy_status_containers.append(entry["status_box"])

		var enemy: Resource = BattleManager.get_enemy(i)
		entry["panel"].visible = true
		entry["btn"].visible = true
		entry["btn"].disabled = false
		entry["name_lbl"].text = enemy.get("enemy_name") if enemy.get("enemy_name") != null else "적"

		if enemy.character_scene != null:
			var char_node = enemy.character_scene.instantiate()
			var slot_pos: Vector2 = _enemy_slot_pos(i, total)
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0 + 40.0 * 1.44, slot_pos.y + 88)
			char_node.scale = Vector2(-1.44, 2.4)
			add_child(char_node)
			_enemy_char_nodes[i] = char_node

		_update_enemy_ui(i)
		_refresh_enemy_counter(i)

func _update_hero_ui(hero_id: String) -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		var hero: Resource = TeamManager.get_hero(hero_id)
		if hero == null:
			return
		var cur_hp: int = TeamManager.get_current_hp(hero_id)
		var block: int = BattleManager.get_hero_block(hero_id)
		var status: Dictionary = BattleManager.get_hero_status(hero_id)
		var morale: int = status.get("morale", 0)
		var _bar: Control = entry["hp_bar"]
		var _ratio: float = float(cur_hp) / float(hero.max_hp) if hero.max_hp > 0 else 0.0
		_bar.get_node("Fill").size.x = _bar.size.x * _ratio
		entry["hp_lbl"].text = "%d / %d" % [cur_hp, hero.max_hp]
		var block_str: String = "🛡%d " % block if block > 0 else ""
		var morale_str: String = "★%d" % morale if morale > 0 else ""
		entry["block_lbl"].text = block_str + morale_str
		if not TeamManager.is_alive(hero_id):
			entry["panel"].modulate = Color(0.4, 0.4, 0.4)
		_refresh_status_icons_hero(hero_id)
		_refresh_token_tiles(hero_id)
		return

func _refresh_token_tiles(hero_id: String) -> void:
	if _token_tile_nodes.has(hero_id):
		for node in _token_tile_nodes[hero_id]:
			node.queue_free()
	_token_tile_nodes[hero_id] = []

	if not TeamManager.is_alive(hero_id):
		return

	var token_count: int = BattleManager.get_hero_status(hero_id).get("tokens", 0)
	if token_count <= 0:
		return

	var hero_idx: int = -1
	for i in range(_hero_nodes.size()):
		if _hero_nodes[i]["hero_id"] == hero_id:
			hero_idx = i
			break
	if hero_idx < 0:
		return

	var slot_y: int = 80 + hero_idx * (SLOT_H + SLOT_GAP)
	var grid_h: int = TOKEN_ROWS * TOKEN_TILE_H + (TOKEN_ROWS - 1) * TOKEN_TILE_GAP
	var base_y: int = slot_y + int((SLOT_H - grid_h) / 2.0)
	var max_tokens: int = TOKEN_COLS * TOKEN_ROWS

	for t in range(min(token_count, max_tokens)):
		var col: int = int(t / float(TOKEN_ROWS))
		var row: int = t % TOKEN_ROWS
		var tile_x: int = TOKEN_AREA_X + col * (TOKEN_TILE_W + TOKEN_TILE_GAP)
		var tile_y: int = base_y + row * (TOKEN_TILE_H + TOKEN_TILE_GAP)

		# 셀 배경
		var bg := ColorRect.new()
		bg.color = Color(0.18, 0.16, 0.10)
		bg.size = Vector2(TOKEN_TILE_W, TOKEN_TILE_H)
		bg.position = Vector2(tile_x, tile_y)
		bg.tooltip_text = tr("battle.token_tooltip")
		bg.mouse_filter = Control.MOUSE_FILTER_STOP
		add_child(bg)
		_token_tile_nodes[hero_id].append(bg)

		# 병사 캐릭터 씬 (idle 애니메이션 포함)
		var char_node = SoldierScene.instantiate()
		char_node.position = Vector2(tile_x + (TOKEN_TILE_W - 40) / 2.0, tile_y + TOKEN_TILE_H - 20 - 50)
		add_child(char_node)
		_token_tile_nodes[hero_id].append(char_node)

		# 이름 라벨 (하단)
		var lbl := Label.new()
		lbl.text = tr("battle.token_soldier")
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.position = Vector2(tile_x, tile_y + TOKEN_TILE_H - 18)
		lbl.size = Vector2(TOKEN_TILE_W, 16)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(lbl)
		_token_tile_nodes[hero_id].append(lbl)

func _update_enemy_ui(index: int) -> void:
	var entry: Dictionary = _enemy_nodes[index]
	var enemy: Resource = BattleManager.get_enemy(index)
	if enemy == null:
		return
	var cur_hp: int = BattleManager.get_enemy_hp(index)
	var block: int = BattleManager.get_enemy_block(index)
	var _bar: Control = entry["hp_bar"]
	var _ratio: float = float(cur_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0
	_bar.get_node("Fill").size.x = _bar.size.x * _ratio
	entry["hp_lbl"].text = "%d / %d" % [cur_hp, enemy.max_hp]
	entry["block_lbl"].text = "🛡%d" % block if block > 0 else ""

	# 의도 표시
	var intent: Resource = BattleManager.get_enemy_current_intent(index)
	if intent != null:
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				entry["intent_lbl"].text = "⚔ %d" % intent.value
			IntentRes.ActionType.BUFF:
				match intent.status_type:
					"strength": entry["intent_lbl"].text = "💪 강화 %d" % intent.value
					_:          entry["intent_lbl"].text = "🛡 %d" % intent.value
			IntentRes.ActionType.DEBUFF:
				entry["intent_lbl"].text = "💀 약화"
			IntentRes.ActionType.PREPARE:
				entry["intent_lbl"].text = "⏳ 준비"
			_:
				entry["intent_lbl"].text = "?"

	if not BattleManager.is_enemy_alive(index):
		entry["panel"].modulate = Color(0.3, 0.3, 0.3)
		entry["btn"].disabled = true
		entry["intent_lbl"].text = "✝"

	_refresh_status_icons_enemy(index)

# ─────────────────────────────────────────────
# 카드 핸드 (Task 3에서 구현)
# ─────────────────────────────────────────────

func _refresh_hand() -> void:
	for n in _card_buttons:
		if is_instance_valid(n):
			n.queue_free()
	_card_buttons.clear()

	var hand: Array = DeckManager.hand
	if hand.is_empty():
		return

	var card_w: int = 140
	var gap: int = 10
	var total_w: int = hand.size() * (card_w + gap) - gap
	var start_x: float = (WINDOW_W - total_w) / 2.0

	for i in range(hand.size()):
		var card: Resource = hand[i]
		var node: CardScene = CARD_SCENE.instantiate()
		node.position = Vector2(start_x + i * (card_w + gap), BOTTOM_Y)
		node.setup(card, node.Mode.HAND)
		node.set_disabled(not DeckManager.can_play(card))
		node.card_clicked.connect(_on_card_clicked)
		node.card_drag_started.connect(_on_card_drag_started)
		node.card_drag_moved.connect(_on_card_drag_moved)
		node.card_drag_released.connect(_on_card_drag_released)
		var captured_node := node
		node.card_hovered.connect(func(c: Resource): _on_card_hovered(c, captured_node))
		node.card_unhovered.connect(_on_card_unhovered)
		add_child(node)
		_card_buttons.append(node)

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_clicked(_card: Resource) -> void:
	pass  # 드래그 앤 드롭 방식으로만 카드 사용 가능

func _on_card_drag_started(card: Resource, screen_pos: Vector2) -> void:
	if not BattleManager.is_player_turn or not DeckManager.can_play(card):
		return
	_start_drag(card)
	if _drag_preview != null:
		_drag_preview.position = screen_pos + Vector2(8, 8)

func _on_card_drag_moved(_card: Resource, screen_pos: Vector2) -> void:
	if _drag_card != null and _drag_preview != null:
		_drag_preview.position = screen_pos + Vector2(8, 8)

func _on_card_drag_released(_card: Resource, screen_pos: Vector2) -> void:
	if _drag_card != null:
		_finish_drag(screen_pos)

func _on_card_hovered(card: Resource, card_node: CardScene) -> void:
	if _drag_card != null:
		return
	_free_card_tooltip()
	var tooltip: CardScene = CARD_SCENE.instantiate()
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.scale = Vector2(2.5, 2.5)
	tooltip.z_index = 100
	tooltip.setup(card, tooltip.Mode.HAND)
	add_child(tooltip)
	_card_tooltip = tooltip
	# 카드 정중앙 위쪽에 고정 (툴팁 350×500 기준)
	var base: Vector2 = card_node.global_position
	var x: float = clamp(base.x + 70.0 - 175.0, 0.0, 1570.0)
	var y: float = clamp(base.y - 510.0, 0.0, 580.0)
	tooltip.position = Vector2(x, y)

func _on_card_unhovered(_card: Resource) -> void:
	_free_card_tooltip()

func _free_card_tooltip() -> void:
	if _card_tooltip != null:
		_card_tooltip.queue_free()
		_card_tooltip = null

func _on_enemy_pressed(index: int) -> void:
	if _debug_hp_target_mode and OS.is_debug_build():
		_debug_hp_target_mode = false
		_open_enemy_hp_dialog(index)
		return

func _open_enemy_hp_dialog(index: int) -> void:
	var current_hp: int = BattleManager._enemy_hp[index] if index < BattleManager._enemy_hp.size() else 0
	var dlg := AcceptDialog.new()
	dlg.title = "적[%d] HP 설정 (현재: %d)" % [index, current_hp]
	dlg.add_cancel_button("취소")
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 2147483647
	spin.value = current_hp
	spin.step = 1
	dlg.add_child(spin)
	dlg.min_size = Vector2i(320, 100)
	dlg.confirmed.connect(func():
		BattleManager.debug_set_enemy_hp(index, int(spin.value))
		_message_label.text = "[DEBUG] 적[%d] HP → %d" % [index, int(spin.value)]
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
	spin.get_line_edit().grab_focus()
	spin.get_line_edit().select_all()

func _on_end_turn_pressed() -> void:
	_selected_card = null
	_message_label.text = ""
	_end_turn_btn.disabled = true
	BattleManager.end_player_turn()

func _on_player_turn_started() -> void:
	_end_turn_btn.disabled = false
	_message_label.text = tr("battle.msg_player_turn")
	_energy_label.text = "⚡ %d / %d" % [DeckManager.current_energy, DeckManager.MAX_ENERGY]
	# 영웅 블록 UI 갱신 (start_player_turn이 블록 초기화했으므로)
	for entry in _hero_nodes:
		var hid: String = entry["hero_id"]
		if hid != "":
			_update_hero_ui(hid)
	# 적 의도 갱신
	for i in range(_enemy_nodes.size()):
		if _enemy_nodes[i]["panel"].visible:
			_update_enemy_ui(i)
	# 살아있는 적 클릭 버튼 재활성
	for i in range(_enemy_nodes.size()):
		if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
			_enemy_nodes[i]["btn"].disabled = false
	_refresh_synergy_hud()

func _on_enemy_turn_started() -> void:
	_end_turn_btn.disabled = true
	_selected_card = null
	_message_label.text = tr("battle.msg_enemy_turn")
	# 적 클릭 버튼 비활성
	for entry in _enemy_nodes:
		if entry["panel"].visible and not entry["btn"].disabled:
			entry["btn"].disabled = true

func _on_energy_changed(new_energy: int) -> void:
	_energy_label.text = "⚡ %d / %d" % [new_energy, DeckManager.MAX_ENERGY]
	# 카드 노드 활성/비활성 갱신
	var hand: Array = DeckManager.hand
	for i in range(min(_card_buttons.size(), hand.size())):
		_card_buttons[i].set_disabled(not DeckManager.can_play(hand[i]))

func _on_card_played(card: Resource) -> void:
	call_deferred("_refresh_all_hero_ui")
	var anim_name: String = card.get("play_animation") if card.get("play_animation") != null else ""
	if anim_name == "":
		return
	var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
	var char_node = _hero_char_nodes.get(owner_id)
	if char_node == null or not char_node.has_node("AnimationPlayer"):
		return
	var anim_player: AnimationPlayer = char_node.get_node("AnimationPlayer")
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _refresh_all_hero_ui() -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != "":
			_update_hero_ui(entry["hero_id"])

func _spawn_damage_popup(world_pos: Vector2, amount: int, fully_blocked: bool) -> void:
	var lbl := Label.new()
	if fully_blocked:
		lbl.text = tr("battle.popup_block")
		lbl.modulate = Color(0.4, 0.8, 1.0)
	else:
		lbl.text = str(amount)
		lbl.modulate = Color(1.0, 0.2, 0.2)
	lbl.add_theme_font_size_override("font_size", 28)
	var offset := Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 20.0))
	lbl.position = world_pos + offset
	lbl.z_index = 20
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world_pos.y - 60.0, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(lbl.queue_free)

func _spawn_heal_popup(world_pos: Vector2, amount: int) -> void:
	var lbl := Label.new()
	lbl.text = "+" + str(amount)
	lbl.modulate = Color(0.2, 1.0, 0.4)
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.position = world_pos
	lbl.z_index = 20
	add_child(lbl)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "position:y", world_pos.y - 60.0, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8)
	tw.chain().tween_callback(lbl.queue_free)

func _on_hero_healed(hero_id: String, amount: int) -> void:
	_update_hero_ui(hero_id)
	for entry in _hero_nodes:
		if entry["hero_id"] == hero_id and entry["panel"].visible:
			var panel: ColorRect = entry["panel"]
			var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
			_spawn_heal_popup(popup_pos, amount)
			break

func _on_hero_damaged(hero_id: String, amount: int) -> void:
	_update_hero_ui(hero_id)
	for entry in _hero_nodes:
		if entry["hero_id"] == hero_id and entry["panel"].visible:
			var panel: ColorRect = entry["panel"]
			var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
			_spawn_damage_popup(popup_pos, amount, amount == 0)
			break
	# hurt 애니메이션 트리거
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node and char_node.has_node("AnimationPlayer"):
		var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
		if ap.has_animation("hurt"):
			ap.play("hurt")

func _on_enemy_damaged(index: int, amount: int) -> void:
	_update_enemy_ui(index)
	if index < _enemy_nodes.size() and _enemy_nodes[index]["panel"].visible:
		var panel: ColorRect = _enemy_nodes[index]["panel"]
		var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
		_spawn_damage_popup(popup_pos, amount, amount == 0)
	var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
	if char_node and char_node.has_node("AnimationPlayer"):
		var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
		if ap.has_animation("hurt"):
			ap.play("hurt")

func _on_enemy_died(index: int) -> void:
	_update_enemy_ui(index)
	var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
	if char_node and char_node.has_node("AnimationPlayer"):
		var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
		if ap.has_animation("death"):
			ap.play("death")

func _on_hero_died(hero_id: String) -> void:
	_update_hero_ui(hero_id)
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node and char_node.has_node("AnimationPlayer"):
		var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
		if ap.has_animation("death"):
			ap.play("death")

func _on_hero_revived(hero_id: String) -> void:
	# 해당 영웅 슬롯을 다시 표시하고 HP/상태 갱신
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		entry["panel"].visible = true
		entry["panel"].modulate = Color(1.0, 1.0, 1.0)  # 사망 시 회색화 복원
		entry["name_lbl"].visible = true
		entry["hp_bar"].visible = true
		entry["hp_lbl"].visible = true
		entry["block_lbl"].visible = true
		entry["status_box"].visible = true
		_update_hero_ui(hero_id)
		break

func _on_battle_won() -> void:
	_message_label.text = tr("battle.msg_victory")
	_end_turn_btn.disabled = true
	_selected_card = null
	for entry in _enemy_nodes:
		entry["btn"].disabled = true
	GameManager.complete_battle(true)

func _on_battle_lost() -> void:
	_message_label.text = tr("battle.msg_defeat")
	_end_turn_btn.disabled = true
	_selected_card = null
	for entry in _enemy_nodes:
		entry["btn"].disabled = true
	GameManager.complete_battle(false)

# ─────────────────────────────────────────────
# 카드 효과 텍스트 헬퍼
# ─────────────────────────────────────────────

func _make_status_label(key: String, val: int, status: Dictionary) -> Label:
	var lbl := Label.new()
	if key == "poison_dmg":
		var dur: int = status.get("poison_dur", 0)
		lbl.text = "☠%d/%d" % [val * 10, dur]
		lbl.tooltip_text = tr("status.%s.desc" % key) % val
	else:
		lbl.text = "%s%d" % [STATUS_EMOJI.get(key, key), val]
		lbl.tooltip_text = tr("status.%s.desc" % key) % val
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.custom_minimum_size = Vector2(0, 18)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	return lbl

func _refresh_status_icons_hero(hero_id: String) -> void:
	var box: HBoxContainer = _hero_status_containers.get(hero_id)
	if box == null:
		return
	for child in box.get_children():
		child.queue_free()
	var status: Dictionary = BattleManager.get_hero_status(hero_id)
	for key in status:
		if key == "poison_dur" or key == "tokens":
			continue
		var val: int = status[key]
		if val <= 0:
			continue
		box.add_child(_make_status_label(key, val, status))

func _refresh_status_icons_enemy(index: int) -> void:
	if index >= _enemy_status_containers.size():
		return
	var box: HBoxContainer = _enemy_status_containers[index]
	if box == null:
		return
	for child in box.get_children():
		child.queue_free()
	var status: Dictionary = BattleManager.get_enemy_status(index)
	for key in status:
		if key == "poison_dur":
			continue
		var val: int = status[key]
		if val <= 0:
			continue
		box.add_child(_make_status_label(key, val, status))

func _on_morale_changed(hero_id: String, _new_value: int) -> void:
	_update_hero_ui(hero_id)

func _on_active_powers_changed() -> void:
	if _active_powers_box == null:
		return
	for child in _active_powers_box.get_children():
		child.queue_free()
	var powers: Dictionary = BattleManager.get_all_active_powers()
	for power_key in powers:
		var power: Dictionary = powers[power_key]
		var base_key: String = power_key.split(":")[0] if ":" in power_key else power_key
		var label_key: String = base_key + ".label"
		var v: int = power.get("value", 0)
		var lbl := Label.new()
		var fmt: String = tr(label_key)
		lbl.text = fmt % v if fmt.contains("%") else fmt
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.modulate = Color(0.7, 0.4, 0.9)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_active_powers_box.add_child(lbl)

func _on_status_applied(target: String, _status_type: String, _stacks: int) -> void:
	if target.begins_with("enemy_"):
		var idx := target.substr(6).to_int()
		_refresh_status_icons_enemy(idx)
	else:
		_refresh_status_icons_hero(target)

func _refresh_debug_badge() -> void:
	if _debug_badge == null:
		return
	var parts: Array[String] = []
	if BattleManager.debug_hero_invincible:
		parts.append("INV")
	if DeckManager.debug_unlimited_energy:
		parts.append("E∞")
	if _debug_grid_visible:
		parts.append("GRID")
	if parts.is_empty():
		_debug_badge.visible = false
	else:
		_debug_badge.text = "[DEBUG: " + ", ".join(parts) + "]"
		_debug_badge.visible = true


func _refresh_synergy_hud() -> void:
	if _synergy_box == null:
		return
	for child in _synergy_box.get_children():
		child.queue_free()
	for s in BattleManager.get_active_synergies():
		var lbl := Label.new()
		lbl.text = "[%s]" % tr(s["name_key"])
		lbl.tooltip_text = tr(s["desc_key"])
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(1.0, 0.0, 1.0)
		_synergy_box.add_child(lbl)

func _input(event: InputEvent) -> void:
	# 드래그 처리는 card_scene 시그널(_on_card_drag_*)로 위임됨
	if _deck_viewer != null and event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_close_deck_viewer()

# ─────────────────────────────────────────────
# 덱뷰어 (전투 중)
# ─────────────────────────────────────────────

func _show_deck_viewer_in_battle() -> void:
	# 이미 열려있으면 무시
	if _deck_viewer != null:
		return

	# 반투명 풀스크린 배경 (CanvasLayer로 최상단 렌더)
	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	# 반투명 배경 — 바깥 클릭으로 닫기
	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.0, 0.0, 0.0, 0.72)
	bg_rect.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_deck_viewer()
	)
	overlay.add_child(bg_rect)

	# 메인 패널
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(1400, 820)
	panel.position = Vector2(260, 130)
	overlay.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# 제목 + X 버튼 행
	var title_row := HBoxContainer.new()
	vbox.add_child(title_row)

	var title_lbl := Label.new()
	title_lbl.text = tr("ui.battle.btn_deck_view")
	title_lbl.add_theme_font_size_override("font_size", 24)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_close_deck_viewer)
	title_row.add_child(close_btn)

	# 탭 버튼 행
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	vbox.add_child(tab_row)

	var tabs := ["draw", "hand", "discard", "exhaust"]
	var tab_keys := {
		"draw": "ui.battle.deck_viewer.draw",
		"hand": "ui.battle.deck_viewer.hand",
		"discard": "ui.battle.deck_viewer.discard",
		"exhaust": "ui.battle.deck_viewer.exhaust",
	}
	for tab_id in tabs:
		var tb := Button.new()
		tb.text = tr(tab_keys[tab_id])
		tb.add_theme_font_size_override("font_size", 18)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.pressed.connect(_switch_deck_tab.bind(tab_id))
		tab_row.add_child(tb)

	# 카드 그리드 스크롤
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 600)
	vbox.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.name = "CardGrid"
	scroll.add_child(grid)

	_deck_viewer = canvas
	_deck_viewer_tab = "draw"
	_switch_deck_tab("draw")

func _switch_deck_tab(tab: String) -> void:
	if _deck_viewer == null:
		return
	_deck_viewer_tab = tab

	# CardGrid 노드 찾기
	var grid: GridContainer = null
	for child in _deck_viewer.get_children():
		grid = _find_node_by_name(child, "CardGrid")
		if grid != null:
			break
	if grid == null:
		return

	# 기존 카드 제거
	for c in grid.get_children():
		c.queue_free()

	# 탭별 카드 목록 결정
	var card_list: Array = []
	match tab:
		"draw":
			card_list = DeckManager.draw_pile.duplicate()
			card_list.shuffle()  # 실제 순서 노출 금지
		"hand":
			card_list = DeckManager.hand.duplicate()
		"discard":
			card_list = DeckManager.discard_pile.duplicate()
		"exhaust":
			card_list = DeckManager.exhaust_pile.duplicate()

	if card_list.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("ui.battle.deck_viewer.empty")
		empty_lbl.add_theme_font_size_override("font_size", 18)
		grid.add_child(empty_lbl)
		return

	# CardScene 인스턴스화
	for card_res in card_list:
		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_node.scale = Vector2(2.5, 2.5)
		# 카드 씬이 클릭/드래그 시그널 방출 억제 — REWARD 모드로 표시
		card_node.setup(card_res, CardScene.Mode.REWARD)
		grid.add_child(card_node)

func _close_deck_viewer() -> void:
	if _deck_viewer != null:
		_deck_viewer.queue_free()
		_deck_viewer = null

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var result := _find_node_by_name(child, target_name)
		if result != null:
			return result
	return null

func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.pressed and not event.echo:
		if event.keycode == KEY_Q and event.shift_pressed:
			BattleManager.debug_instant_win()
		elif event.keycode == KEY_I and event.shift_pressed:
			BattleManager.debug_hero_invincible = not BattleManager.debug_hero_invincible
			_refresh_debug_badge()
		elif event.keycode == KEY_E and event.shift_pressed:
			DeckManager.debug_unlimited_energy = not DeckManager.debug_unlimited_energy
			_refresh_debug_badge()
		elif event.keycode == KEY_D and event.shift_pressed:
			DeckManager.draw_cards(1)
		elif event.keycode == KEY_H and event.shift_pressed:
			_debug_hp_target_mode = not _debug_hp_target_mode
			if _debug_hp_target_mode:
				_message_label.text = "[DEBUG] 적을 클릭해 HP를 설정하세요 (다시 Shift+H 취소)"
			else:
				_message_label.text = ""
		elif event.keycode == KEY_G and event.shift_pressed:
			_debug_grid_visible = not _debug_grid_visible
			_refresh_debug_grid()
			_refresh_debug_badge()

func _refresh_debug_grid() -> void:
	for node in _debug_grid_nodes:
		node.queue_free()
	_debug_grid_nodes.clear()
	if not _debug_grid_visible:
		return

	# 영웅 슬롯 외곽선 (파란색)
	for i in range(_hero_nodes.size()):
		var slot_y: int = 80 + i * (SLOT_H + SLOT_GAP)
		for border in _make_border_rects(HERO_X, slot_y, SLOT_W, SLOT_H, Color(0.3, 0.6, 1.0, 0.8)):
			add_child(border)
			_debug_grid_nodes.append(border)

	# 소환물 그리드 (노란색)
	for i in range(3):
		var slot_y: int = 80 + i * (SLOT_H + SLOT_GAP)
		var grid_h: int = TOKEN_ROWS * TOKEN_TILE_H + (TOKEN_ROWS - 1) * TOKEN_TILE_GAP
		var base_y: int = slot_y + int((SLOT_H - grid_h) / 2.0)
		for r in range(TOKEN_ROWS):
			for c in range(TOKEN_COLS):
				var cx: int = TOKEN_AREA_X + c * (TOKEN_TILE_W + TOKEN_TILE_GAP)
				var cy: int = base_y + r * (TOKEN_TILE_H + TOKEN_TILE_GAP)
				var cell := ColorRect.new()
				cell.color = Color(0.8, 0.8, 0.2, 0.12)
				cell.size = Vector2(TOKEN_TILE_W, TOKEN_TILE_H)
				cell.position = Vector2(cx, cy)
				cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(cell)
				_debug_grid_nodes.append(cell)
				for border in _make_border_rects(cx, cy, TOKEN_TILE_W, TOKEN_TILE_H, Color(0.9, 0.9, 0.3, 0.6)):
					add_child(border)
					_debug_grid_nodes.append(border)

	# 적 슬롯 외곽선 (빨간색)
	var total: int = _enemy_nodes.size()
	for i in range(total):
		var pos: Vector2 = _enemy_slot_pos(i, total)
		for border in _make_border_rects(int(pos.x), int(pos.y), SLOT_W, SLOT_H, Color(1.0, 0.3, 0.3, 0.8)):
			add_child(border)
			_debug_grid_nodes.append(border)

func _on_enemy_counter_changed(enemy_index: int) -> void:
	_refresh_enemy_counter(enemy_index)

func _refresh_enemy_counter(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_nodes.size():
		return
	var slot: Dictionary = _enemy_nodes[enemy_index]
	var lbl: Label = slot.get("counter_lbl")
	if lbl == null:
		return
	var info: Dictionary = BattleManager.get_enemy_counter(enemy_index)
	if info.is_empty():
		lbl.visible = false
		return
	var ct: int = int(info.get("card_type", -1))
	var key: String = ""
	match ct:
		CardResource.CardType.ATTACK: key = "enemy.counter.attack.label"
		CardResource.CardType.SKILL:  key = "enemy.counter.skill.label"
		CardResource.CardType.POWER:  key = "enemy.counter.power.label"
		_:
			lbl.visible = false
			return
	lbl.text = tr(key) % [info["count"], info["threshold"]]
	lbl.visible = true

func _make_border_rects(x: int, y: int, w: int, h: int, color: Color) -> Array:
	var rects: Array = []
	var thickness: int = 1
	for data in [[x, y, w, thickness], [x, y+h-thickness, w, thickness],
				  [x, y, thickness, h], [x+w-thickness, y, thickness, h]]:
		var r := ColorRect.new()
		r.color = color
		r.position = Vector2(data[0], data[1])
		r.size = Vector2(data[2], data[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rects.append(r)
	return rects

func _card_target_type(card: Resource) -> String:
	# "enemy" / "ally" / "none"
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.APPLY_STATUS:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.CHARM:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.COUNTER_BLOCK, \
			EffectRes.EffectType.CONSUME_MORALE, \
			EffectRes.EffectType.POISON_BURST, \
			EffectRes.EffectType.CONDITIONAL_DMG:
				return "enemy"
			EffectRes.EffectType.HEAL:
				if effect.target == "SINGLE":
					return "ally"
	return "none"

func _start_drag(card: Resource) -> void:
	_free_card_tooltip()
	_drag_card = card
	_selected_card = null
	_drag_preview = Label.new()
	_drag_preview.text = "[%d] %s" % [card.cost, card.get("card_name") if card.get("card_name") else "?"]
	_drag_preview.add_theme_font_size_override("font_size", 14)
	_drag_preview.size = Vector2(120, 30)
	_drag_preview.modulate = Color(1.0, 1.0, 0.6, 0.85)
	_drag_preview.z_index = 10
	add_child(_drag_preview)
	match _card_target_type(card):
		"enemy":
			_message_label.text = tr("battle.drag_enemy")
			for i in range(_enemy_nodes.size()):
				if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
					_enemy_nodes[i]["panel"].color = Color(0.35, 0.12, 0.12)
		"ally":
			_message_label.text = tr("battle.drag_ally")
			for entry in _hero_nodes:
				if entry["panel"].visible:
					entry["panel"].color = Color(0.12, 0.25, 0.12)
		"none":
			_message_label.text = tr("battle.drag_release")

func _finish_drag(drop_pos: Vector2) -> void:
	if drop_pos.y >= BOTTOM_Y:
		_cleanup_drag()
		return
	match _card_target_type(_drag_card):
		"enemy":
			for i in range(_enemy_nodes.size()):
				var panel: ColorRect = _enemy_nodes[i]["panel"]
				if not panel.visible or not BattleManager.is_enemy_alive(i):
					continue
				if panel.get_global_rect().has_point(drop_pos):
					BattleManager.play_card(_drag_card, i)
					_cleanup_drag()
					return
			_cleanup_drag()
		"ally":
			for entry in _hero_nodes:
				if not entry["panel"].visible:
					continue
				var hero_id: String = entry["hero_id"]
				if not TeamManager.is_alive(hero_id):
					continue
				if entry["panel"].get_global_rect().has_point(drop_pos):
					BattleManager.play_card(_drag_card, -1, hero_id)
					_cleanup_drag()
					return
			_cleanup_drag()
		"none":
			BattleManager.play_card(_drag_card, -1)
			_cleanup_drag()

func _cleanup_drag() -> void:
	if _drag_preview != null:
		_drag_preview.queue_free()
		_drag_preview = null
	_drag_card = null
	_selected_card = null
	_message_label.text = ""
	for entry in _enemy_nodes:
		if entry["panel"].visible:
			entry["panel"].color = Color(0.18, 0.10, 0.10)
	for entry in _hero_nodes:
		if entry["panel"].visible:
			entry["panel"].color = Color(0.12, 0.12, 0.2)
