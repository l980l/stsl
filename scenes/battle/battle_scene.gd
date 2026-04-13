# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

const WINDOW_W := 1920
const WINDOW_H := 1080
const HERO_X := 20
const ENEMY_X := 1520
const SLOT_W := 360
const SLOT_H := 280
const BOTTOM_Y := 840
const CARD_W := 110
const CARD_H := 160
const SLOT_GAP := 20

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
var _selected_card: Resource = null

func _ready() -> void:
	_build_ui()
	BattleManager.team_mgr = TeamManager
	BattleManager.deck_mgr = DeckManager
	_connect_signals()
	_start_test_battle()

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
	_energy_label.position = Vector2(30, BOTTOM_Y + 16)
	_energy_label.size = Vector2(160, 50)
	_energy_label.add_theme_font_size_override("font_size", 26)
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

	# 영웅 슬롯 3개 (초기 숨김)
	for i in range(3):
		_hero_nodes.append(_make_hero_slot(i))
		_enemy_char_nodes.append(null)  # 적 캐릭터 노드 예약

	# 적 슬롯 3개 (초기 숨김)
	for i in range(3):
		_enemy_nodes.append(_make_enemy_slot(i))

func _make_hero_slot(index: int) -> Dictionary:
	var y := 80 + index * (SLOT_H + SLOT_GAP)
	var panel := ColorRect.new()
	panel.color = Color(0.12, 0.12, 0.2)
	panel.position = Vector2(HERO_X, y)
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)

	var name_lbl := _make_label(Vector2(HERO_X + 10, y + 196), Vector2(SLOT_W - 20, 28), 18)
	var hp_lbl   := _make_label(Vector2(HERO_X + 10, y + 226), Vector2(SLOT_W - 20, 24), 15)
	var block_lbl := _make_label(Vector2(HERO_X + 10, y + 250), Vector2(SLOT_W - 20, 22), 14)
	block_lbl.modulate = Color(0.5, 0.8, 1.0)

	return { "panel": panel, "name_lbl": name_lbl,
			 "hp_lbl": hp_lbl, "block_lbl": block_lbl, "hero_id": "" }

func _make_enemy_slot(index: int) -> Dictionary:
	var y := 80 + index * (SLOT_H + SLOT_GAP)
	var panel := ColorRect.new()
	panel.color = Color(0.18, 0.10, 0.10)
	panel.position = Vector2(ENEMY_X, y)
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)

	var intent_lbl := _make_label(Vector2(ENEMY_X + 10, y + 8), Vector2(SLOT_W - 20, 30), 20)
	intent_lbl.modulate = Color(1.0, 0.8, 0.2)
	intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 클릭 버튼 (투명, 캐릭터 영역 위에 올림)
	var btn := Button.new()
	btn.flat = true
	btn.position = Vector2(ENEMY_X + 20, y + 40)
	btn.size = Vector2(SLOT_W - 40, 160)
	btn.add_theme_font_size_override("font_size", 14)
	btn.text = "▶ 공격"
	var captured_index := index
	btn.pressed.connect(func(): _on_enemy_pressed(captured_index))
	add_child(btn)

	var name_lbl  := _make_label(Vector2(ENEMY_X + 10, y + 204), Vector2(SLOT_W - 20, 26), 16)
	var hp_lbl    := _make_label(Vector2(ENEMY_X + 10, y + 230), Vector2(SLOT_W - 20, 24), 14)
	var block_lbl := _make_label(Vector2(ENEMY_X + 10, y + 254), Vector2(SLOT_W - 20, 22), 13)
	block_lbl.modulate = Color(0.5, 0.8, 1.0)

	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_lbl": hp_lbl, "block_lbl": block_lbl }

func _make_label(pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	add_child(lbl)
	return lbl

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
	BattleManager.enemy_died.connect(_on_enemy_died)
	BattleManager.battle_won.connect(_on_battle_won)
	BattleManager.battle_lost.connect(_on_battle_lost)
	TeamManager.hero_died.connect(_on_hero_died)

# ─────────────────────────────────────────────
# 테스트 배틀 초기화 (Task 2에서 완성)
# ─────────────────────────────────────────────

func _start_test_battle() -> void:
	pass  # Task 2에서 구현

# ─────────────────────────────────────────────
# 영웅/적 표시 (Task 2에서 구현)
# ─────────────────────────────────────────────

func _setup_heroes() -> void:
	pass

func _setup_enemies() -> void:
	pass

func _update_hero_ui(_hero_id: String) -> void:
	pass

func _update_enemy_ui(_index: int) -> void:
	pass

# ─────────────────────────────────────────────
# 카드 핸드 (Task 3에서 구현)
# ─────────────────────────────────────────────

func _refresh_hand() -> void:
	pass

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_pressed(_card: Resource) -> void:
	pass

func _on_enemy_pressed(_index: int) -> void:
	pass

func _on_end_turn_pressed() -> void:
	pass

func _on_player_turn_started() -> void:
	pass

func _on_enemy_turn_started() -> void:
	pass

func _on_energy_changed(_new_energy: int) -> void:
	pass

func _on_card_played(_card: Resource) -> void:
	pass

func _on_hero_damaged(_hero_id: String, _amount: int) -> void:
	pass

func _on_enemy_damaged(_index: int, _amount: int) -> void:
	pass

func _on_enemy_died(_index: int) -> void:
	pass

func _on_hero_died(_hero_id: String) -> void:
	pass

func _on_battle_won() -> void:
	pass

func _on_battle_lost() -> void:
	pass
