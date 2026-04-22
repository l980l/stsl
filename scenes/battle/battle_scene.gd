# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const SoldierScene = preload("res://characters/summons/soldier/soldier.tscn")

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
var _potential_drag_card: Resource = null
var _drag_start_pos: Vector2 = Vector2.ZERO
const DRAG_THRESHOLD := 10.0

var _hero_status_containers: Dictionary = {}
var _enemy_status_containers: Array = []
var _token_tile_nodes: Dictionary = {}
var _synergy_box: HBoxContainer = null
var _ppt_label: Label = null
var _debug_badge: Label = null
var _debug_hp_target_mode: bool = false
var _debug_grid_visible: bool = false
var _debug_grid_nodes: Array = []

const STATUS_EMOJI := {
	"poison_dmg": "☠", "weak": "↓", "vulnerable": "⚡",
	"morale": "★", "charm": "♥", "strength": "↑",
	"taunt": "►", "counter_block": "🛡", "charm_resistance": "💜"
}
const STATUS_TOOLTIP := {
	"poison_dmg": "독: 매 턴 N×10 피해. 지속 3턴, 중첩 시 데미지 누적+지속 갱신",
	"weak": "약화: 공격 피해 25% 감소. 매 턴 1 감소",
	"vulnerable": "취약: 받는 피해 50% 증가. 매 턴 1 감소",
	"morale": "사기: CONSUME_MORALE 카드로 추가 피해 제공",
	"charm": "매혹: 다음 행동 아군에게 적용",
	"strength": "강화: 피해 +N",
	"taunt": "도발: 이 대상이 우선 공격 받음",
	"counter_block": "반격 방어: 피해 = 현재 방어도 기반",
	"charm_resistance": "매혹 저항 N: 매혹 (3+N)스택이 되어야 반함"
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
	_end_turn_btn.text = "턴 종료"
	_end_turn_btn.add_theme_font_size_override("font_size", 22)
	_end_turn_btn.disabled = true
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	add_child(_end_turn_btn)

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

	_ppt_label = Label.new()
	_ppt_label.position = Vector2(20, 840)
	_ppt_label.size = Vector2(300, 30)
	_ppt_label.add_theme_font_size_override("font_size", 14)
	_ppt_label.modulate = Color(0.4, 1.0, 0.4)
	_ppt_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_ppt_label.visible = false
	add_child(_ppt_label)

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
	var bar_h: float = 13.0
	var bar_x: float = HERO_X + (SLOT_W - bar_w) / 2.0

	var name_lbl := _make_label(Vector2(bar_x, y + 4), Vector2(bar_w, 22), 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.z_index = 1
	name_lbl.visible = false

	var hp_bar := _make_hp_bar(Vector2(bar_x, y + 28), bar_w)
	hp_bar.z_index = 1
	hp_bar.visible = false

	var hp_lbl := _make_label(Vector2(bar_x, y + 28), Vector2(bar_w, bar_h), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.z_index = 1
	hp_lbl.visible = false

	var block_lbl := _make_label(Vector2(bar_x, y + 50), Vector2(bar_w, 18), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 1
	block_lbl.visible = false

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, y + 70)
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
	var bar_h: float = 18.0
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

	var hp_lbl := _make_label(Vector2(bar_x, pos.y + 48), Vector2(bar_w, bar_h), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.z_index = 1

	var block_lbl := _make_label(Vector2(bar_x, pos.y + 70), Vector2(bar_w, 16), 11)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 1

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, pos.y + 88)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	add_child(status_box)

	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
			 "block_lbl": block_lbl, "status_box": status_box }

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

func _make_hp_bar(pos: Vector2, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = Vector2(width, 13)
	bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.8, 0.15, 0.15)
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.15)
	bar.add_theme_stylebox_override("background", bg)
	add_child(bar)
	return bar

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
	BattleManager.status_applied.connect(_on_status_applied)
	BattleManager.morale_changed.connect(_on_morale_changed)
	BattleManager.active_powers_changed.connect(_on_active_powers_changed)

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
		entry["hp_bar"].max_value = hero.max_hp
		entry["hp_bar"].value = cur_hp
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
		bg.tooltip_text = "다음 턴 시작 시 상대를 공격합니다"
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
		lbl.text = "병사"
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
	entry["hp_bar"].max_value = enemy.max_hp
	entry["hp_bar"].value = cur_hp
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
	for btn in _card_buttons:
		if is_instance_valid(btn):
			btn.queue_free()
	_card_buttons.clear()

	var hand: Array = DeckManager.hand
	if hand.is_empty():
		return

	var total_w: float = hand.size() * (CARD_W + 10) - 10
	var start_x: float = (WINDOW_W - total_w) / 2.0

	for i in range(hand.size()):
		var card: Resource = hand[i]
		var can_play: bool = DeckManager.can_play(card)

		var btn := Button.new()
		btn.position = Vector2(start_x + i * (CARD_W + 10), BOTTOM_Y)
		btn.size = Vector2(CARD_W, CARD_H)

		var card_name: String = card.get("card_name") if card.get("card_name") != null else "?"
		var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
		var upgraded_mark: String = " ★" if card.get("upgraded") else ""
		var effect_desc: String = _card_effect_text(card)
		btn.text = "[%d] %s%s\n%s\n%s" % [card.cost, card_name, upgraded_mark, owner_id, effect_desc]
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = not can_play
		if BattleManager.has_synergy_bonus(card):
			btn.add_theme_color_override("font_color", Color(1.0, 0.2, 1.0))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 1.0))

		var captured_card := card
		var captured_card2 := card
		btn.button_down.connect(func(): _on_card_button_down(captured_card2))
		btn.pressed.connect(func(): _on_card_pressed(captured_card))
		add_child(btn)
		_card_buttons.append(btn)

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_pressed(_card: Resource) -> void:
	pass  # 드래그 앤 드롭 방식으로만 카드 사용 가능

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
	_message_label.text = "플레이어 턴"
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
	_message_label.text = "적 턴..."
	# 적 클릭 버튼 비활성
	for entry in _enemy_nodes:
		if entry["panel"].visible and not entry["btn"].disabled:
			entry["btn"].disabled = true

func _on_energy_changed(new_energy: int) -> void:
	_energy_label.text = "⚡ %d / %d" % [new_energy, DeckManager.MAX_ENERGY]
	# 카드 버튼 활성/비활성 갱신
	var hand: Array = DeckManager.hand
	for i in range(min(_card_buttons.size(), hand.size())):
		_card_buttons[i].disabled = not DeckManager.can_play(hand[i])

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
		lbl.text = "BLOCK"
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

func _on_battle_won() -> void:
	_message_label.text = "🏆 승리!"
	_end_turn_btn.disabled = true
	_selected_card = null
	for entry in _enemy_nodes:
		entry["btn"].disabled = true
	GameManager.complete_battle(true)

func _on_battle_lost() -> void:
	_message_label.text = "💀 패배..."
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
		lbl.tooltip_text = STATUS_TOOLTIP.get("poison_dmg", "독").replace("N", str(val))
	else:
		lbl.text = "%s%d" % [STATUS_EMOJI.get(key, key), val]
		lbl.tooltip_text = STATUS_TOOLTIP.get(key, key).replace("N", str(val))
	lbl.add_theme_font_size_override("font_size", 12)
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
	if _ppt_label == null:
		return
	var ppt: Dictionary = BattleManager.get_active_power("poison_per_turn")
	if ppt.is_empty():
		_ppt_label.visible = false
	else:
		_ppt_label.text = "🧪 독의 왕좌: +%d/턴 (%d턴)" % [ppt["value"], ppt["turns_remaining"]]
		_ppt_label.tooltip_text = "매 플레이어 턴 시작 시 모든 적에게 독 +%d 적용.\n독의 왕좌를 다시 사용하지 않으면 %d턴 후 사라집니다." % [ppt["value"], ppt["turns_remaining"]]
		_ppt_label.visible = true

func _on_status_applied(target: String, _status_type: String, _stacks: int) -> void:
	if target.begins_with("enemy_"):
		var idx := target.substr(6).to_int()
		_refresh_status_icons_enemy(idx)
	else:
		_refresh_status_icons_hero(target)

func _card_effect_text(card: Resource) -> String:
	var lines: Array = []
	for eff in card.effects:
		lines.append(eff.display_text())
	return "\n".join(lines)

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
		lbl.text = "[%s]" % s["name"]
		lbl.tooltip_text = s["desc"]
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.modulate = Color(1.0, 0.0, 1.0)
		_synergy_box.add_child(lbl)

func _on_card_button_down(card: Resource) -> void:
	if not BattleManager.is_player_turn or not DeckManager.can_play(card):
		return
	_potential_drag_card = card
	_drag_start_pos = get_viewport().get_mouse_position()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if _potential_drag_card != null and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var dist := get_viewport().get_mouse_position().distance_to(_drag_start_pos)
			if dist > DRAG_THRESHOLD and _drag_card == null:
				_start_drag(_potential_drag_card)
			if _drag_card != null:
				_drag_preview.position = get_viewport().get_mouse_position() + Vector2(8, 8)
	elif event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		if _drag_card != null:
			_finish_drag(get_viewport().get_mouse_position())
		_potential_drag_card = null

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
			_message_label.text = "적을 선택하세요 ▶"
			for i in range(_enemy_nodes.size()):
				if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
					_enemy_nodes[i]["panel"].color = Color(0.35, 0.12, 0.12)
		"ally":
			_message_label.text = "아군을 선택하세요 ▶"
			for entry in _hero_nodes:
				if entry["panel"].visible:
					entry["panel"].color = Color(0.12, 0.25, 0.12)
		"none":
			_message_label.text = "놓아서 사용 ▶"

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
