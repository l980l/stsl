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
	_start_battle()

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
# 배틀 초기화
# ─────────────────────────────────────────────

func _start_battle() -> void:
	if not GameManager.pending_enemies.is_empty():
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
		entry["hero_id"] = ""

	var heroes := TeamManager.heroes
	for i in range(min(heroes.size(), 3)):
		var hero: Resource = heroes[i]
		var entry: Dictionary = _hero_nodes[i]
		entry["panel"].visible = true
		entry["hero_id"] = hero.hero_id
		entry["name_lbl"].text = hero.get("hero_name") if hero.get("hero_name") != null else hero.hero_id

		# 캐릭터 씬 인스턴스화
		if hero.character_scene != null:
			var char_node = hero.character_scene.instantiate()
			char_node.position = Vector2(HERO_X + 170, 80 + i * (SLOT_H + SLOT_GAP) + 120)
			add_child(char_node)
			_hero_char_nodes[hero.hero_id] = char_node

		_update_hero_ui(hero.hero_id)

func _setup_enemies() -> void:
	# 기존 캐릭터 노드 정리
	for i in range(_enemy_char_nodes.size()):
		if _enemy_char_nodes[i] != null:
			_enemy_char_nodes[i].queue_free()
			_enemy_char_nodes[i] = null
	for entry in _enemy_nodes:
		entry["panel"].visible = false

	var count := 0
	while count < 3 and BattleManager.get_enemy(count) != null:
		count += 1

	for i in range(count):
		var enemy: Resource = BattleManager.get_enemy(i)
		var entry: Dictionary = _enemy_nodes[i]
		entry["panel"].visible = true
		entry["btn"].disabled = false
		entry["name_lbl"].text = enemy.get("enemy_name") if enemy.get("enemy_name") != null else "적"

		# 캐릭터 씬 인스턴스화 (좌우 반전: scale.x = -1)
		if enemy.character_scene != null:
			var char_node = enemy.character_scene.instantiate()
			char_node.position = Vector2(ENEMY_X + 190, 80 + i * (SLOT_H + SLOT_GAP) + 120)
			char_node.scale = Vector2(-1, 1)  # 적은 왼쪽 향함
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
		entry["hp_lbl"].text = "HP  %d / %d" % [cur_hp, hero.max_hp]
		var block: int = BattleManager.get_hero_block(hero_id)
		entry["block_lbl"].text = "🛡 %d" % block if block > 0 else ""
		if not TeamManager.is_alive(hero_id):
			entry["panel"].modulate = Color(0.4, 0.4, 0.4)
		return

func _update_enemy_ui(index: int) -> void:
	var entry: Dictionary = _enemy_nodes[index]
	var enemy: Resource = BattleManager.get_enemy(index)
	if enemy == null:
		return
	var cur_hp: int = BattleManager.get_enemy_hp(index)
	entry["hp_lbl"].text = "HP  %d / %d" % [cur_hp, enemy.max_hp]
	var block: int = BattleManager.get_enemy_block(index)
	entry["block_lbl"].text = "🛡 %d" % block if block > 0 else ""

	# 의도 표시
	var intent: Resource = BattleManager.get_enemy_current_intent(index)
	if intent != null:
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				entry["intent_lbl"].text = "⚔ %d" % intent.value
			IntentRes.ActionType.BUFF:
				entry["intent_lbl"].text = "🛡 %d" % intent.value
			IntentRes.ActionType.DEBUFF:
				entry["intent_lbl"].text = "💀 약화"
			_:
				entry["intent_lbl"].text = "?"

	if not BattleManager.is_enemy_alive(index):
		entry["panel"].modulate = Color(0.3, 0.3, 0.3)
		entry["btn"].disabled = true
		entry["intent_lbl"].text = "✝"

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
		btn.text = "[%d]\n%s\n%s" % [card.cost, card_name, owner_id]
		btn.add_theme_font_size_override("font_size", 13)
		btn.disabled = not can_play

		var captured_card := card
		btn.pressed.connect(func(): _on_card_pressed(captured_card))
		add_child(btn)
		_card_buttons.append(btn)

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_pressed(card: Resource) -> void:
	if not BattleManager.is_player_turn or not DeckManager.can_play(card):
		return

	# 타겟 선택이 필요한지 확인 (SINGLE DAMAGE 효과)
	var needs_target := false
	for effect in card.effects:
		if effect.effect_type == EffectRes.EffectType.DAMAGE and effect.target == "SINGLE":
			needs_target = true
			break

	if needs_target:
		_selected_card = card
		_message_label.text = "공격 대상을 선택하세요 ▶"
	else:
		# 즉시 플레이 (블록, 전체 공격 등)
		BattleManager.play_card(card, -1)
		_selected_card = null
		_message_label.text = ""

func _on_enemy_pressed(index: int) -> void:
	if _selected_card == null or not BattleManager.is_player_turn:
		return
	if not BattleManager.is_enemy_alive(index):
		return
	BattleManager.play_card(_selected_card, index)
	_selected_card = null
	_message_label.text = ""

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

func _on_hero_damaged(hero_id: String, _amount: int) -> void:
	_update_hero_ui(hero_id)
	# hurt 애니메이션 트리거
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node and char_node.has_node("AnimationPlayer"):
		var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
		if ap.has_animation("hurt"):
			ap.play("hurt")

func _on_enemy_damaged(index: int, _amount: int) -> void:
	_update_enemy_ui(index)
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
	GameManager.complete_battle(false)
