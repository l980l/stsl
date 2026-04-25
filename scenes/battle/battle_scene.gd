# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const SoldierScene = preload("res://characters/summons/soldier/soldier.tscn")
const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const ARROW_CHEVRON_TEX := preload("res://assets/art/ui/arrow_chevron.png")
const ARROW_HEAD_TEX    := preload("res://assets/art/ui/arrow_head.png")

const WINDOW_W := 1920
const WINDOW_H := 1080
const SLOT_W := 240
const SLOT_H := 280
const BOTTOM_Y := 840
const CARD_W := 110
const CARD_H := 160
const BASE_CARD_SCALE := 1.4
const FAN_PIVOT_Y_OFFSET := 1200.0
const FAN_ANGLE_PER_CARD := 0.10
const FAN_MAX_TOTAL_ANGLE := 0.9
const HAND_BASE_Y := 960
const MAX_ENEMY_COUNT := 6
const TOKEN_COLS := 6
const TOKEN_ROWS := 1
const TOKEN_TILE_W := 111
const TOKEN_TILE_H := 138
const TOKEN_TILE_GAP := 4

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
var _relic_container: FlowContainer
var _selected_card: Resource = null

var _drag_card: Resource = null
var _drag_chevrons: Array = []
var _drag_arrow_head: Sprite2D = null
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_end_pos: Vector2 = Vector2.ZERO
var _drag_t_offset: float = 0.0

var _hero_status_containers: Dictionary = {}
var _enemy_status_containers: Array = []
var _token_tile_nodes: Dictionary = {}
var _synergy_box: FlowContainer = null
var _active_powers_box: VBoxContainer = null
var _debug_badge: Label = null
var _debug_hp_target_mode: bool = false
var _debug_grid_visible: bool = false
var _debug_grid_nodes: Array = []
var _debug_token_hero_idx: int = 0

var _deck_viewer: CanvasLayer = null
var _deck_viewer_tooltip: CardScene = null


const STATUS_EMOJI := {
	"poison_dmg": "☠", "weak": "↓", "vulnerable": "⚡",
	"morale": "★", "charm": "♥", "strength": "↑",
	"taunt": "►", "counter_block": "🛡", "charm_resistance": "💜"
}

func _trf(key: String, args) -> String:
	var s := tr(key)
	if "%d" in s or "%s" in s or "%f" in s:
		return s % args
	return s

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

func _process(delta: float) -> void:
	if _drag_card != null and not _drag_chevrons.is_empty():
		_drag_t_offset = fmod(_drag_t_offset + delta * 0.15, 1.0)
		_update_drag_chevrons()

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

	# 덱 보기 버튼 (End Turn 아래)
	var deck_btn := Button.new()
	deck_btn.position = Vector2(WINDOW_W - 220, BOTTOM_Y + 84)
	deck_btn.size = Vector2(200, 60)
	deck_btn.text = tr("ui.battle.btn_deck_view")
	deck_btn.add_theme_font_size_override("font_size", 18)
	deck_btn.pressed.connect(_show_deck_viewer_in_battle)
	add_child(deck_btn)

	# HUD 바 — 시너지 + 릴릭 아이콘, 메시지 레이블 아래
	_relic_container = FlowContainer.new()
	_relic_container.position = Vector2(20, 70)
	_relic_container.size = Vector2(WINDOW_W - 40, 72)
	_relic_container.add_theme_constant_override("h_separation", 6)
	_relic_container.add_theme_constant_override("v_separation", 4)
	add_child(_relic_container)
	_synergy_box = _relic_container
	_refresh_hud()

	_active_powers_box = VBoxContainer.new()
	_active_powers_box.position = Vector2(20, 800)
	_active_powers_box.custom_minimum_size = Vector2(300, 0)
	_active_powers_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_active_powers_box)

	# 영웅 슬롯 3개 고정 (초기 숨김)
	for i in range(3):
		_hero_nodes.append(_make_hero_slot(i))
	# 적 슬롯은 _setup_enemies()에서 동적 생성

func _hero_slot_pos(index: int) -> Vector2:
	return (get_node("HeroSlot%d" % (index + 1)) as Marker2D).position

func _summon_area_pos(index: int) -> Vector2:
	return (get_node("SummonArea%d" % (index + 1)) as Marker2D).position

func _make_hero_slot(index: int) -> Dictionary:
	var pos := _hero_slot_pos(index)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0)
	panel.position = pos
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)

	var bar_w: float = 211.0
	var _bar_h: float = 12.0
	var bar_x: float = pos.x + (SLOT_W - bar_w) / 2.0

	var name_lbl := _make_label(Vector2(bar_x, pos.y + 4), Vector2(bar_w, 22), 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.z_index = 1
	name_lbl.visible = false

	var hp_bar := _make_hp_bar(Vector2(bar_x, pos.y + 28), bar_w)
	hp_bar.z_index = 1
	hp_bar.visible = false

	var hp_lbl := _make_label(Vector2(bar_x, pos.y + 22), Vector2(bar_w, 24), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.z_index = 1
	hp_lbl.visible = false

	var block_lbl := _make_label(Vector2(bar_x, pos.y + 22), Vector2(bar_w, 24), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	block_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 2
	block_lbl.visible = false

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, pos.y + 42)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	status_box.visible = false
	add_child(status_box)

	return { "panel": panel, "name_lbl": name_lbl, "hp_bar": hp_bar,
			 "hp_lbl": hp_lbl, "block_lbl": block_lbl,
			 "hero_id": "", "status_box": status_box }

func _enemy_slot_pos(index: int, _total: int = 0) -> Vector2:
	return (get_node("EnemySlot%d" % (index + 1)) as Marker2D).position

func _make_enemy_slot(index: int, total: int) -> Dictionary:
	var pos: Vector2 = _enemy_slot_pos(index, total)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0)
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

	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
			 "block_lbl": block_lbl, "status_box": status_box }

func _refresh_hud() -> void:
	if _relic_container == null:
		return
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
			lbl.modulate = Color(1.0, 0.0, 1.0)
			_relic_container.add_child(lbl)
	if not GameManager or not GameManager.is_inside_tree():
		return
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
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.modulate = Color(1.0, 0.85, 0.3)
			_relic_container.add_child(lbl)

func _refresh_relics() -> void:
	_refresh_hud()

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
	napoleon.hero_name = "hero.napoleon.name"
	napoleon.max_hp = 70
	napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
	TeamManager.add_hero(napoleon)

	# 덱 설정 (스트라이크 3장 + 디펜드 2장)
	DeckManager.clear()
	for _i in range(3):
		var card = CardRes.new()
		card.card_name = "card.napoleon.strike.name"
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
		card.card_name = "card.napoleon.defend.name"
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
	satyr.enemy_name = "enemy.greek.satyr"
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
		entry["name_lbl"].text = tr(hero.get("hero_name")) if hero.get("hero_name") != null else hero.hero_id

		if hero.character_scene != null:
			var char_node = hero.character_scene.instantiate()
			var slot_pos := _hero_slot_pos(i)
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 40.0 * 1.44, slot_pos.y + 88)
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
		entry["name_lbl"].text = tr(enemy.get("enemy_name")) if enemy.get("enemy_name") != null else "적"

		var slot_pos: Vector2 = _enemy_slot_pos(i, total)
		if enemy.character_scene != null:
			var char_node = enemy.character_scene.instantiate()
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0 + 40.0 * 1.44, slot_pos.y + 88)
			char_node.scale = Vector2(-1.44, 2.4)
			add_child(char_node)
			_enemy_char_nodes[i] = char_node
		else:
			var placeholder := ColorRect.new()
			placeholder.color = Color(0.45, 0.45, 0.5, 0.6)
			placeholder.size = Vector2(60, 120)
			placeholder.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 30, slot_pos.y + 40)
			add_child(placeholder)
			_enemy_char_nodes[i] = placeholder

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

	var area_pos := _summon_area_pos(hero_idx)
	var max_tokens: int = TOKEN_COLS * TOKEN_ROWS

	for t in range(min(token_count, max_tokens)):
		var col: int = int(t / float(TOKEN_ROWS))
		var row: int = t % TOKEN_ROWS
		var tile_x: int = int(area_pos.x) + col * (TOKEN_TILE_W + TOKEN_TILE_GAP)
		var tile_y: int = int(area_pos.y) + row * (TOKEN_TILE_H + TOKEN_TILE_GAP)

		# 병사 캐릭터 씬 (2배 스케일)
		var char_node = SoldierScene.instantiate()
		char_node.scale = Vector2(2.0, 2.0)
		char_node.position = Vector2(tile_x + TOKEN_TILE_W / 2.0 - 40.0, tile_y + TOKEN_TILE_H / 4.0)
		add_child(char_node)
		_token_tile_nodes[hero_id].append(char_node)

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
				entry["intent_lbl"].text = _trf("battle.intent.attack", intent.value)
			IntentRes.ActionType.BUFF:
				match intent.status_type:
					"strength": entry["intent_lbl"].text = _trf("battle.intent.buff.strength", intent.value)
					_:          entry["intent_lbl"].text = _trf("battle.intent.buff.block", intent.value)
			IntentRes.ActionType.DEBUFF:
				entry["intent_lbl"].text = tr("battle.intent.debuff")
			IntentRes.ActionType.PREPARE:
				entry["intent_lbl"].text = tr("battle.intent.prepare")
			_:
				entry["intent_lbl"].text = "?"

	if not BattleManager.is_enemy_alive(index):
		entry["panel"].modulate = Color(0.3, 0.3, 0.3)
		entry["btn"].disabled = true
		entry["intent_lbl"].text = tr("battle.intent.dead")

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

	var n_cards: int = hand.size()
	var step: float = FAN_ANGLE_PER_CARD if n_cards <= 1 else \
		minf(FAN_ANGLE_PER_CARD, FAN_MAX_TOTAL_ANGLE / float(n_cards - 1))
	var fan_pivot := Vector2(WINDOW_W / 2.0, HAND_BASE_Y + FAN_PIVOT_Y_OFFSET)
	var half_card := Vector2(70, 100) * BASE_CARD_SCALE

	for i in range(n_cards):
		var card: Resource = hand[i]
		var node: CardScene = CARD_SCENE.instantiate()
		var angle: float = (i - (n_cards - 1) / 2.0) * step
		var arc_pos: Vector2 = fan_pivot + Vector2(sin(angle), -cos(angle)) * FAN_PIVOT_Y_OFFSET
		node.position = arc_pos - half_card
		node.rotation = angle
		node.pivot_offset = Vector2(70, 100)
		node.scale = Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE)
		node.z_index = 10 + i
		node.set_meta("_fan_pos", node.position)
		node.set_meta("_fan_rot", node.rotation)
		node.set_meta("_fan_idx", i)
		node.set_meta("_fan_center", arc_pos)
		node.set_meta("_fan_title_pos", arc_pos + Vector2(0, -70.0 * BASE_CARD_SCALE).rotated(angle))
		node.set_meta("_card_res", card)
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
	_drag_start_pos = screen_pos
	for btn in _card_buttons:
		if is_instance_valid(btn) and btn.get_meta("_card_res", null) == card:
			_drag_start_pos = btn.get_meta("_fan_title_pos", screen_pos)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.4)
			break
	_start_drag(card)
	_create_drag_arrow(screen_pos)

func _on_card_drag_moved(_card: Resource, screen_pos: Vector2) -> void:
	_drag_end_pos = screen_pos
	_update_drag_arrow(screen_pos)

func _on_card_drag_released(_card: Resource, screen_pos: Vector2) -> void:
	if _drag_card != null:
		_finish_drag(screen_pos)

func _on_card_hovered(_card: Resource, card_node: CardScene) -> void:
	if _drag_card != null:
		return
	var hover_idx: int = card_node.get_meta("_fan_idx", -1)
	if hover_idx < 0:
		return
	for btn in _card_buttons:
		if not is_instance_valid(btn):
			continue
		var idx: int = btn.get_meta("_fan_idx", 0)
		var base_pos: Vector2 = btn.get_meta("_fan_pos")
		var base_rot: float = btn.get_meta("_fan_rot")
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		if idx == hover_idx:
			var hover_scale := BASE_CARD_SCALE * 1.4
			# 호버 후 카드 하단 y = base_pos.y + hover_scale * 100 + 100
			var card_bottom := base_pos.y + hover_scale * 100.0 + 100.0
			var lift := maxf(60.0, card_bottom - (WINDOW_H - 20.0))
			tw.tween_property(btn, "scale", Vector2(hover_scale, hover_scale), 0.12)
			tw.tween_property(btn, "position", base_pos + Vector2(0, -lift), 0.12)
			tw.tween_property(btn, "rotation", 0.0, 0.12)
			btn.z_index = 200
		else:
			var dist: int = idx - hover_idx
			var sign_x: float = 1.0 if dist > 0 else -1.0
			var falloff: float = maxf(0.0, 1.0 - abs(dist) / 4.0)
			tw.tween_property(btn, "position", base_pos + Vector2(sign_x * 35.0 * falloff, 0), 0.12)
			tw.tween_property(btn, "rotation", base_rot, 0.12)
			tw.tween_property(btn, "scale", Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE), 0.12)
			btn.z_index = 10 + idx

func _on_card_unhovered(_card: Resource) -> void:
	_reset_hand_fan()

func _reset_hand_fan() -> void:
	for btn in _card_buttons:
		if not is_instance_valid(btn):
			continue
		var idx: int = btn.get_meta("_fan_idx", 0)
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(btn, "position", btn.get_meta("_fan_pos"), 0.12)
		tw.tween_property(btn, "rotation", btn.get_meta("_fan_rot"), 0.12)
		tw.tween_property(btn, "scale", Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE), 0.12)
		btn.z_index = idx

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
	# 스프라이트 복원 (death 애니메이션 트랙 리셋 후 idle 재생)
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node != null:
		char_node.visible = true
		if char_node.has_node("AnimationPlayer"):
			var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
			ap.stop()
			if ap.has_animation("idle"):
				ap.play("idle")

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

func _make_status_label(key: String, val: int, status: Dictionary) -> Control:
	var tex: Texture2D = IconUtils.get_status_icon(key)
	var tooltip: String = _trf("status.%s.desc" % key, val)

	if tex != null:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 1)
		hbox.custom_minimum_size = Vector2(0, 20)
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.mouse_filter = Control.MOUSE_FILTER_STOP
		hbox.tooltip_text = tooltip

		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon)

		var lbl := Label.new()
		if key == "poison_dmg":
			var dur: int = status.get("poison_dur", 0)
			lbl.text = "%d/%d" % [val * 10, dur]
		else:
			lbl.text = "%d" % val
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lbl)

		return hbox

	# 아이콘 없으면 이모지 fallback
	var lbl := Label.new()
	if key == "poison_dmg":
		var dur: int = status.get("poison_dur", 0)
		lbl.text = "☠%d/%d" % [val * 10, dur]
	else:
		lbl.text = "%s%d" % [STATUS_EMOJI.get(key, key), val]
	lbl.tooltip_text = tooltip
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
	# 카드 카운터가 있으면 상태 아이콘 영역에 버프처럼 표시
	var cinfo: Dictionary = BattleManager.get_enemy_counter(index)
	if not cinfo.is_empty():
		var ct: int = int(cinfo.get("card_type", -1))
		var label_key: String = ""
		match ct:
			CardResource.CardType.ATTACK: label_key = "enemy.counter.attack.label"
			CardResource.CardType.SKILL:  label_key = "enemy.counter.skill.label"
			CardResource.CardType.POWER:  label_key = "enemy.counter.power.label"
		if label_key != "":
			var lbl := Label.new()
			lbl.text = _trf(label_key, [cinfo["count"], cinfo["threshold"]])
			lbl.tooltip_text = _counter_tooltip_text(cinfo)
			lbl.add_theme_font_size_override("font_size", 12)
			lbl.custom_minimum_size = Vector2(0, 18)
			lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.modulate = Color(1.0, 0.75, 0.3)
			box.add_child(lbl)

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
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		var desc_fmt: String = tr(base_key + ".desc")
		if desc_fmt != base_key + ".desc":
			lbl.tooltip_text = desc_fmt % v if desc_fmt.contains("%d") else desc_fmt
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
	_refresh_hud()

func _input(event: InputEvent) -> void:
	# 드래그 처리는 card_scene 시그널(_on_card_drag_*)로 위임됨
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if _deck_viewer != null:
			_close_deck_viewer()

# ─────────────────────────────────────────────
# 덱뷰어 (전투 중)
# ─────────────────────────────────────────────

func _show_deck_viewer_in_battle() -> void:
	if _deck_viewer != null:
		return

	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.0, 0.0, 0.0, 0.72)
	bg_rect.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_deck_viewer()
	)
	overlay.add_child(bg_rect)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(1200, 680)
	panel.size = Vector2(1200, 680)
	panel.position = Vector2((WINDOW_W - 1200) / 2.0, (WINDOW_H - 680) / 2.0)
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
	title_lbl.text = tr("ui.battle.btn_deck_view")
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 18)
	close_btn.pressed.connect(_close_deck_viewer)
	title_row.add_child(close_btn)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	var draw_cards := DeckManager.draw_pile.duplicate()
	draw_cards.shuffle()
	var discard_cards := DeckManager.discard_pile.duplicate()

	_add_deck_column(columns, tr("ui.battle.deck_viewer.draw") + " (%d)" % draw_cards.size(), draw_cards)
	_add_deck_column(columns, tr("ui.battle.deck_viewer.discard") + " (%d)" % discard_cards.size(), discard_cards)

	var tip: CardScene = CARD_SCENE.instantiate()
	tip.scale = Vector2(2.5, 2.5)
	tip.z_index = 200
	tip.visible = false
	overlay.add_child(tip)
	_set_mouse_ignore_recursive(tip)
	_deck_viewer_tooltip = tip

	_deck_viewer = canvas


func _add_deck_column(parent: HBoxContainer, header: String, cards: Array) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	var lbl := Label.new()
	lbl.text = header
	lbl.add_theme_font_size_override("font_size", 18)
	col.add_child(lbl)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(scroll)

	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	if cards.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("ui.battle.deck_viewer.empty")
		empty_lbl.add_theme_font_size_override("font_size", 16)
		grid.add_child(empty_lbl)
		return

	for card_res in cards:
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

func _show_deck_tooltip(card: Resource, node: Control) -> void:
	if _deck_viewer_tooltip == null:
		return
	_deck_viewer_tooltip.setup(card, CardScene.Mode.HAND)
	var base := node.global_position
	var x: float = clamp(base.x + 45.0 - 175.0, 0.0, float(WINDOW_W - 350))
	var y: float = clamp(base.y - 510.0, 20.0, float(WINDOW_H - 500))
	_deck_viewer_tooltip.position = Vector2(x, y)
	_deck_viewer_tooltip.visible = true

func _hide_deck_tooltip() -> void:
	if _deck_viewer_tooltip != null:
		_deck_viewer_tooltip.visible = false

func _close_deck_viewer() -> void:
	if _deck_viewer != null:
		_deck_viewer_tooltip = null
		_deck_viewer.queue_free()
		_deck_viewer = null

func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in node.get_children():
		_set_mouse_ignore_recursive(c)


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
		elif event.keycode == KEY_O and event.shift_pressed:
			if BattleManager.debug_add_dummy_enemy(MAX_ENEMY_COUNT):
				_setup_enemies()
		elif event.keycode == KEY_S and event.shift_pressed:
			var living := TeamManager.get_living_heroes()
			if not living.is_empty():
				_debug_token_hero_idx = _debug_token_hero_idx % living.size()
				var hero_id: String = living[_debug_token_hero_idx].hero_id
				BattleManager.debug_add_dummy_token(hero_id)
				_refresh_token_tiles(hero_id)
				_debug_token_hero_idx += 1

func _refresh_debug_grid() -> void:
	for node in _debug_grid_nodes:
		node.queue_free()
	_debug_grid_nodes.clear()
	if not _debug_grid_visible:
		return

	# 영웅 슬롯 외곽선 (파란색)
	for i in range(_hero_nodes.size()):
		var sp := _hero_slot_pos(i)
		for border in _make_border_rects(int(sp.x), int(sp.y), SLOT_W, SLOT_H, Color(0.3, 0.6, 1.0, 0.8)):
			add_child(border)
			_debug_grid_nodes.append(border)

	# 소환물 그리드 (노란색)
	for i in range(3):
		var ap := _summon_area_pos(i)
		for r in range(TOKEN_ROWS):
			for c in range(TOKEN_COLS):
				var cx: int = int(ap.x) + c * (TOKEN_TILE_W + TOKEN_TILE_GAP)
				var cy: int = int(ap.y) + r * (TOKEN_TILE_H + TOKEN_TILE_GAP)
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
	_refresh_status_icons_enemy(enemy_index)

func _counter_tooltip_text(info: Dictionary) -> String:
	var tkey: String = info.get("tooltip_key", "")
	if tkey != "":
		return tr(tkey)
	# tooltip_key 없는 경우 동적 생성 (fallback)
	var card_type: int = info.get("card_type", -1)
	var threshold: int = info.get("threshold", 0)
	var intent: Resource = info.get("intent")
	var card_name: String
	match card_type:
		CardResource.CardType.ATTACK: card_name = tr("card_type.attack.name")
		CardResource.CardType.SKILL:  card_name = tr("card_type.skill.name")
		CardResource.CardType.POWER:  card_name = tr("card_type.power.name")
		_: card_name = "?"
	var effect_desc: String = "?"
	if intent != null:
		var target_str: String
		match int(intent.target):
			IntentRes.TargetType.ALL:       target_str = tr("battle.target.all_ally")
			IntentRes.TargetType.LOWEST_HP: target_str = tr("battle.target.lowest_hp_ally")
			IntentRes.TargetType.RANDOM:    target_str = tr("battle.target.random_ally")
			_:                              target_str = tr("battle.target.ally")
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				effect_desc = _trf("battle.counter.effect.attack", [target_str, intent.value])
			IntentRes.ActionType.DEBUFF:
				var sname: String = tr("status.%s.name" % intent.status_type)
				effect_desc = _trf("battle.counter.effect.debuff", [target_str, sname, intent.value])
			IntentRes.ActionType.BUFF:
				var sname: String = tr("status.%s.name" % intent.status_type)
				effect_desc = _trf("battle.counter.effect.buff", [sname, intent.value])
	return _trf("battle.counter.tooltip.format", [card_name, threshold, effect_desc])

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
			EffectRes.EffectType.REVIVE:
				return "dead_ally"
	return "none"

func _start_drag(card: Resource) -> void:
	_reset_hand_fan()
	_drag_card = card
	_selected_card = null
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
		"dead_ally":
			_message_label.text = tr("battle.drag_dead_ally")
			for entry in _hero_nodes:
				if entry["panel"].visible and not TeamManager.is_alive(entry["hero_id"]):
					entry["panel"].color = Color(0.25, 0.12, 0.35)
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
		"dead_ally":
			for entry in _hero_nodes:
				if not entry["panel"].visible:
					continue
				var hero_id: String = entry["hero_id"]
				if TeamManager.is_alive(hero_id):
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
	for spr in _drag_chevrons:
		if is_instance_valid(spr):
			spr.queue_free()
	_drag_chevrons.clear()
	if _drag_arrow_head != null:
		_drag_arrow_head.queue_free()
		_drag_arrow_head = null
	_drag_t_offset = 0.0
	for btn in _card_buttons:
		if is_instance_valid(btn):
			btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
			var card_res: Resource = btn.get_meta("_card_res", null)
			if card_res != null:
				btn.set_disabled(not DeckManager.can_play(card_res))
	_drag_card = null
	_selected_card = null
	_message_label.text = ""
	for entry in _enemy_nodes:
		if entry["panel"].visible:
			entry["panel"].color = Color(0, 0, 0, 0)
	for entry in _hero_nodes:
		if entry["panel"].visible:
			entry["panel"].color = Color(0, 0, 0, 0)

func _create_drag_arrow(start_pos: Vector2) -> void:
	_drag_end_pos = start_pos
	_drag_t_offset = 0.0

	for i in range(8):
		var chev := Sprite2D.new()
		chev.texture = ARROW_CHEVRON_TEX
		chev.scale = Vector2(0.15, 0.15)
		chev.modulate = Color(1.0, 1.0, 1.0, 0.0)
		chev.z_index = 5
		add_child(chev)
		_drag_chevrons.append(chev)

	_drag_arrow_head = Sprite2D.new()
	_drag_arrow_head.texture = ARROW_HEAD_TEX
	_drag_arrow_head.scale = Vector2(0.2, 0.2)
	_drag_arrow_head.modulate = Color.WHITE
	_drag_arrow_head.z_index = 6
	add_child(_drag_arrow_head)

	_update_drag_arrow(start_pos)

func _drag_arrow_color(pos: Vector2) -> Color:
	if _drag_card == null:
		return Color.WHITE
	if pos.y >= BOTTOM_Y:
		return Color(1.0, 0.25, 0.25)
	match _card_target_type(_drag_card):
		"enemy":
			for i in range(_enemy_nodes.size()):
				var panel: ColorRect = _enemy_nodes[i]["panel"]
				if panel.visible and BattleManager.is_enemy_alive(i) \
						and panel.get_global_rect().has_point(pos):
					return Color(0.3, 1.0, 0.4)
			return Color(1.0, 0.25, 0.25)
		"ally":
			for entry in _hero_nodes:
				if entry["panel"].visible and TeamManager.is_alive(entry["hero_id"]) \
						and entry["panel"].get_global_rect().has_point(pos):
					return Color(0.3, 1.0, 0.4)
			return Color(1.0, 0.25, 0.25)
		"dead_ally":
			for entry in _hero_nodes:
				if entry["panel"].visible and not TeamManager.is_alive(entry["hero_id"]) \
						and entry["panel"].get_global_rect().has_point(pos):
					return Color(0.3, 1.0, 0.4)
			return Color(1.0, 0.25, 0.25)
		"none":
			return Color(0.3, 1.0, 0.4)
	return Color.WHITE

func _update_drag_arrow(end_pos: Vector2) -> void:
	if _drag_arrow_head == null:
		return
	var start := _drag_start_pos
	var ctrl := (start + end_pos) * 0.5 + Vector2(0, -200.0)
	var base := _drag_arrow_color(end_pos)
	var tangent_end := (end_pos - ctrl).normalized()
	_drag_arrow_head.position = end_pos
	_drag_arrow_head.rotation = tangent_end.angle()
	_drag_arrow_head.modulate = base

func _update_drag_chevrons() -> void:
	if _drag_chevrons.is_empty():
		return
	var start := _drag_start_pos
	var end_pos := _drag_end_pos
	var ctrl := (start + end_pos) * 0.5 + Vector2(0, -200.0)
	var base := _drag_arrow_color(end_pos)
	var n := _drag_chevrons.size()
	for i in range(n):
		var t_raw := fmod(_drag_t_offset + float(i) / float(n), 1.0)
		var t := t_raw * 0.88
		var p := (1-t)*(1-t)*start + 2*(1-t)*t*ctrl + t*t*end_pos
		var tangent := (2.0*(1-t)*(ctrl - start) + 2.0*t*(end_pos - ctrl)).normalized()
		var alpha := sin(PI * t_raw)
		var chev: Sprite2D = _drag_chevrons[i]
		chev.position = p
		chev.rotation = tangent.angle()
		chev.modulate = Color(base.r, base.g, base.b, alpha)
