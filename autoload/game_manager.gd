# autoload/game_manager.gd
class_name GameManagerClass
extends Node

enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST }

var current_state: GameState = GameState.MAP
var current_floor: int = 0
var current_chapter: int = 1
var gold: int = 0
var relics: Array = []

# ── Plan 04: 런 스테이트 ──────────────────────────────
var run_map: Array = []             # Array[MapNodeResource]
var available_node_ids: Array = []  # 현재 클릭 가능한 노드 ID 목록
var current_node_id: int = -1
var pending_enemies: Array = []     # 다음 배틀 적 데이터
var card_rewards: Array = []        # 다음 카드 보상 목록
var pending_event: Resource = null  # 현재 이벤트 데이터 (EventResource)
# ─────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal gold_changed(new_gold: int)
signal relic_added(relic: Resource)
signal run_started()
signal node_entered(node_id: int)
signal run_ended(won: bool)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_relic(relic: Resource) -> void:
	relics.append(relic)
	relic_added.emit(relic)

func has_relic(relic_name: String) -> bool:
	for r in relics:
		if r.relic_name == relic_name:
			return true
	return false

func reset() -> void:
	current_state = GameState.MAP
	current_floor = 0
	current_chapter = 1
	gold = 0
	relics.clear()
	run_map.clear()
	available_node_ids.clear()
	current_node_id = -1
	pending_enemies.clear()
	card_rewards.clear()
	pending_event = null

# ── Plan 04: 런 관리 ──────────────────────────────────

func start_run() -> void:
	reset()

	# TeamManager 초기화 (나폴레옹 1명)
	TeamManager.clear()
	var HeroRes = load("res://resources/hero_resource.gd")
	var napoleon: Resource = HeroRes.new()
	napoleon.hero_id = "napoleon"
	napoleon.hero_name = "나폴레옹"
	napoleon.max_hp = 70
	napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
	TeamManager.add_hero(napoleon)

	# DeckManager 초기화 (스트라이크 3 + 디펜드 2)
	DeckManager.clear()
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	for _i in range(3):
		var card: Resource = CardRes.new()
		card.card_name = "스트라이크"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "attack"
		var eff: Resource = EffRes.new()
		eff.effect_type = EffRes.EffectType.DAMAGE
		eff.value = 6
		eff.target = "SINGLE"
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)
	for _i in range(2):
		var card: Resource = CardRes.new()
		card.card_name = "디펜드"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "idle"
		var eff: Resource = EffRes.new()
		eff.effect_type = EffRes.EffectType.BLOCK
		eff.value = 5
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)

	# 맵 생성
	var MapGen = load("res://autoload/map_generator.gd")
	run_map = MapGen.generate()
	available_node_ids = [0, 1, 2]  # floor 0 전체 접근 가능
	run_started.emit()
	# 씬 전환 없음 — MapScene._ready()에서 호출되므로 이미 MapScene에 있음

func enter_node(node_id: int) -> void:
	if node_id not in available_node_ids:
		return
	var node: Resource = run_map[node_id]
	node.visited = true
	current_node_id = node_id
	current_floor = node.floor_num
	node_entered.emit(node_id)

	var MapNodeRes = load("res://resources/map_node_resource.gd")
	match node.room_type:
		MapNodeRes.RoomType.BATTLE, \
		MapNodeRes.RoomType.ELITE, \
		MapNodeRes.RoomType.BOSS:
			pending_enemies = _make_enemies_for_node(node)
			change_state(GameState.BATTLE)
			_request_scene("res://scenes/battle/battle_scene.tscn")
		MapNodeRes.RoomType.REST:
			change_state(GameState.REST)
			_request_scene("res://scenes/rest/rest_scene.tscn")
		MapNodeRes.RoomType.EVENT:
			pending_event = _get_random_event()
			change_state(GameState.EVENT)
			_request_scene("res://scenes/event/event_scene.tscn")
		MapNodeRes.RoomType.SHOP:
			# Plan 05에서 구현 — 지금은 건너뜀
			_advance_nodes_from(node_id)
			change_state(GameState.MAP)
			_request_scene("res://scenes/map/map_scene.tscn")

func complete_battle(won: bool) -> void:
	pending_enemies.clear()  # 전투 종료 후 이전 적 데이터 정리
	if won:
		card_rewards = _generate_card_rewards()
		change_state(GameState.CARD_PICK)
		_request_scene("res://scenes/card_pick/card_pick_scene.tscn")
	else:
		run_ended.emit(false)
		change_state(GameState.MAP)
		_request_scene("res://scenes/map/map_scene.tscn")

func complete_card_pick() -> void:
	var node: Resource = run_map[current_node_id]
	_advance_nodes_from(current_node_id)
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	if node.room_type == MapNodeRes.RoomType.BOSS:
		run_ended.emit(true)
	card_rewards.clear()
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func _advance_nodes_from(node_id: int) -> void:
	var node: Resource = run_map[node_id]
	available_node_ids = node.connections.duplicate()

func _heal_all_heroes(amount: int) -> void:
	if not is_inside_tree():
		return
	for hero in TeamManager.heroes:
		TeamManager.heal(hero.hero_id, amount)

func _satyr_scene() -> PackedScene:
	return load("res://characters/enemies/satyr/satyr.tscn")

func _make_normal_enemies() -> Array:
	var scene := _satyr_scene()
	match randi() % 4:
		0: return [_make_satyr(scene, 30, 6)]
		1: return [_make_harpy(scene, 25)]
		2: return [_make_cyclops(scene, 45)]
		_: return [_make_snake(scene, 20)]

func _make_enemies_for_node(node: Resource) -> Array:
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	match node.room_type:
		MapNodeRes.RoomType.BATTLE:
			return _make_normal_enemies()
		MapNodeRes.RoomType.ELITE:
			return _make_elite_enemies()
		MapNodeRes.RoomType.BOSS:
			return _make_boss_enemies()
		_:
			return []

func _make_elite_enemies() -> Array:
	var scene := _satyr_scene()
	if randi() % 2 == 0:
		return [_make_minotaur(scene)]
	else:
		return [_make_medusa(scene)]

func _make_minotaur(scene: PackedScene) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "미노타우로스"
	enemy.max_hp = 90
	enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK
	i1.value = 12
	i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK
	i2.value = 12
	i2.target = IntentRes.TargetType.RANDOM
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK
	i3.value = 20
	i3.target = IntentRes.TargetType.ALL
	enemy.intent_pattern = [i1, i2, i3]
	return enemy

func _make_medusa(scene: PackedScene) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "메두사"
	enemy.max_hp = 75
	enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK
	i1.value = 10
	i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF
	i2.value = 2
	i2.status_type = "weak"
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF
	i3.value = 2
	i3.status_type = "vulnerable"
	var i4: Resource = IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK
	i4.value = 15
	i4.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2, i3, i4]
	return enemy

func _make_satyr(scene: PackedScene, hp: int, dmg: int) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "사티로스"
	enemy.max_hp = hp
	enemy.character_scene = scene
	var intent: Resource = IntentRes.new()
	intent.action_type = IntentRes.ActionType.ATTACK
	intent.value = dmg
	intent.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [intent]
	return enemy

func _make_harpy(scene: PackedScene, hp: int) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "하르피아"
	enemy.max_hp = hp
	enemy.character_scene = scene
	# 패턴: ATTACK(4) → ATTACK(4) → SPECIAL(discard 1, value=1)
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK
	i1.value = 4
	i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK
	i2.value = 4
	i2.target = IntentRes.TargetType.RANDOM
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.SPECIAL
	i3.value = 1
	enemy.intent_pattern = [i1, i2, i3]
	return enemy

func _make_cyclops(scene: PackedScene, hp: int) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "사이클롭스"
	enemy.max_hp = hp
	enemy.character_scene = scene
	# 패턴: BUFF(value=0, 준비) → ATTACK(value=18, target=RANDOM)
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF
	i1.value = 0
	i1.condition = "준비"
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK
	i2.value = 18
	i2.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2]
	return enemy

func _make_snake(scene: PackedScene, hp: int) -> Resource:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "메두사의 뱀"
	enemy.max_hp = hp
	enemy.character_scene = scene
	# 패턴: ATTACK(value=5, target=RANDOM) → DEBUFF(value=1, "vulnerable")
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK
	i1.value = 5
	i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF
	i2.value = 1
	i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2]
	return enemy

func _make_boss_enemies() -> Array:
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var IntentRes = load("res://resources/intent_resource.gd")
	var scene := _satyr_scene()
	var hydra: Resource = EnemyRes.new()
	hydra.enemy_name = "히드라"
	hydra.max_hp = 200
	hydra.character_scene = scene
	hydra.phase_thresholds = [0.6, 0.3]

	# Phase 0 (100%~60%): ATTACK(10) x2
	var p0a1: Resource = IntentRes.new()
	p0a1.action_type = IntentRes.ActionType.ATTACK
	p0a1.value = 10; p0a1.target = IntentRes.TargetType.RANDOM
	var p0a2: Resource = IntentRes.new()
	p0a2.action_type = IntentRes.ActionType.ATTACK
	p0a2.value = 10; p0a2.target = IntentRes.TargetType.RANDOM

	# Phase 1 (60%~30%): ATTACK(12) x3
	var p1a1: Resource = IntentRes.new()
	p1a1.action_type = IntentRes.ActionType.ATTACK
	p1a1.value = 12; p1a1.target = IntentRes.TargetType.RANDOM
	var p1a2: Resource = IntentRes.new()
	p1a2.action_type = IntentRes.ActionType.ATTACK
	p1a2.value = 12; p1a2.target = IntentRes.TargetType.RANDOM
	var p1a3: Resource = IntentRes.new()
	p1a3.action_type = IntentRes.ActionType.ATTACK
	p1a3.value = 12; p1a3.target = IntentRes.TargetType.LOWEST_HP

	# Phase 2 (30%~0%): ATTACK(12) x3 + BUFF(10)
	var p2a1: Resource = IntentRes.new()
	p2a1.action_type = IntentRes.ActionType.ATTACK
	p2a1.value = 12; p2a1.target = IntentRes.TargetType.RANDOM
	var p2a2: Resource = IntentRes.new()
	p2a2.action_type = IntentRes.ActionType.ATTACK
	p2a2.value = 12; p2a2.target = IntentRes.TargetType.RANDOM
	var p2a3: Resource = IntentRes.new()
	p2a3.action_type = IntentRes.ActionType.ATTACK
	p2a3.value = 12; p2a3.target = IntentRes.TargetType.LOWEST_HP
	var p2b: Resource = IntentRes.new()
	p2b.action_type = IntentRes.ActionType.BUFF
	p2b.value = 10

	hydra.phase_patterns = [[p0a1, p0a2], [p1a1, p1a2, p1a3], [p2a1, p2a2, p2a3, p2b]]
	return [hydra]

func _generate_card_rewards() -> Array:
	var pool: Array = _napoleon_card_pool()
	pool.shuffle()
	return pool.slice(0, 3)

func _napoleon_card_pool() -> Array:
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var cards: Array = []

	# 1. 헤비 스트라이크 — DAMAGE 9, cost 2
	var c1: Resource = CardRes.new()
	c1.card_name = "헤비 스트라이크"
	c1.owner_id = "napoleon"
	c1.cost = 2
	c1.play_animation = "attack"
	var e1: Resource = EffRes.new()
	e1.effect_type = EffRes.EffectType.DAMAGE
	e1.value = 9
	e1.target = "SINGLE"
	c1.effects = [e1]
	cards.append(c1)

	# 2. 클리브 — ALL DAMAGE 4, cost 1
	var c2: Resource = CardRes.new()
	c2.card_name = "클리브"
	c2.owner_id = "napoleon"
	c2.cost = 1
	c2.play_animation = "attack"
	var e2: Resource = EffRes.new()
	e2.effect_type = EffRes.EffectType.DAMAGE
	e2.value = 4
	e2.target = "ALL"
	c2.effects = [e2]
	cards.append(c2)

	# 3. 아이언 웨이브 — DAMAGE 5 + BLOCK 5, cost 1
	var c3: Resource = CardRes.new()
	c3.card_name = "아이언 웨이브"
	c3.owner_id = "napoleon"
	c3.cost = 1
	c3.play_animation = "attack"
	var e3a: Resource = EffRes.new()
	e3a.effect_type = EffRes.EffectType.DAMAGE
	e3a.value = 5
	e3a.target = "SINGLE"
	var e3b: Resource = EffRes.new()
	e3b.effect_type = EffRes.EffectType.BLOCK
	e3b.value = 5
	c3.effects = [e3a, e3b]
	cards.append(c3)

	# 4. 아이언 디펜스 — BLOCK 8, cost 1
	var c4: Resource = CardRes.new()
	c4.card_name = "아이언 디펜스"
	c4.owner_id = "napoleon"
	c4.cost = 1
	c4.play_animation = "idle"
	var e4: Resource = EffRes.new()
	e4.effect_type = EffRes.EffectType.BLOCK
	e4.value = 8
	c4.effects = [e4]
	cards.append(c4)

	# 5. 포이즌 스트라이크 — DAMAGE 3 + poison 2, cost 1
	var c5: Resource = CardRes.new()
	c5.card_name = "포이즌 스트라이크"
	c5.owner_id = "napoleon"
	c5.cost = 1
	c5.play_animation = "attack"
	var e5a: Resource = EffRes.new()
	e5a.effect_type = EffRes.EffectType.DAMAGE
	e5a.value = 3
	e5a.target = "SINGLE"
	var e5b: Resource = EffRes.new()
	e5b.effect_type = EffRes.EffectType.APPLY_STATUS
	e5b.status_type = "poison"
	e5b.value = 2
	e5b.target = "SINGLE"
	c5.effects = [e5a, e5b]
	cards.append(c5)

	return cards

func _get_random_event() -> Resource:
	var pool := _build_event_pool()
	return pool[randi() % pool.size()]

func _build_event_pool() -> Array:
	var EventRes = load("res://resources/event_resource.gd")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var events := []

	# 1. 황금 상자
	var e1: Resource = EventRes.new()
	e1.event_name = "황금 상자"
	e1.description = "낡은 황금 상자가 놓여 있다."
	var c1a: Resource = ChoiceRes.new(); c1a.label = "열기"
	c1a.effect_type = ChoiceRes.EffectType.GOLD; c1a.value = 30
	var c1b: Resource = ChoiceRes.new(); c1b.label = "무시"
	c1b.effect_type = ChoiceRes.EffectType.NONE
	e1.choices = [c1a, c1b]; events.append(e1)

	# 2. 상처 입은 전사
	var e2: Resource = EventRes.new()
	e2.event_name = "상처 입은 전사"
	e2.description = "부상당한 병사가 치료를 요청한다."
	var c2a: Resource = ChoiceRes.new(); c2a.label = "치료 (골드 -20)"
	c2a.effect_type = ChoiceRes.EffectType.HEAL; c2a.value = 15; c2a.cost_gold = 20
	var c2b: Resource = ChoiceRes.new(); c2b.label = "무시"
	c2b.effect_type = ChoiceRes.EffectType.NONE
	e2.choices = [c2a, c2b]; events.append(e2)

	# 3. 고대 도서관
	var e3: Resource = EventRes.new()
	e3.event_name = "고대 도서관"
	e3.description = "신비로운 지식이 담긴 도서관. 공부하면 지식을 얻지만 기력을 소모한다."
	var c3a: Resource = ChoiceRes.new(); c3a.label = "공부 (HP -5)"
	c3a.effect_type = ChoiceRes.EffectType.DRAW_UP; c3a.value = 1; c3a.cost_hp = 5
	var c3b: Resource = ChoiceRes.new(); c3b.label = "무시"
	c3b.effect_type = ChoiceRes.EffectType.NONE
	e3.choices = [c3a, c3b]; events.append(e3)

	# 4. 저주받은 제단
	var e4: Resource = EventRes.new()
	e4.event_name = "저주받은 제단"
	e4.description = "제단에 무언가를 바치면 강력한 유물을 얻을 수 있다."
	var c4a: Resource = ChoiceRes.new(); c4a.label = "카드 바치기 (덱에서 1장 제거)"
	c4a.effect_type = ChoiceRes.EffectType.REMOVE_CARD; c4a.value = 1
	var c4b: Resource = ChoiceRes.new(); c4b.label = "무시"
	c4b.effect_type = ChoiceRes.EffectType.NONE
	e4.choices = [c4a, c4b]; events.append(e4)

	# 5. 동료 만남
	var e5: Resource = EventRes.new()
	e5.event_name = "동료 만남"
	e5.description = "역사 속 영웅이 합류를 요청한다."
	var c5a: Resource = ChoiceRes.new(); c5a.label = "합류시키기"
	c5a.effect_type = ChoiceRes.EffectType.ADD_HERO
	var c5b: Resource = ChoiceRes.new(); c5b.label = "거절"
	c5b.effect_type = ChoiceRes.EffectType.NONE
	e5.choices = [c5a, c5b]; events.append(e5)

	return events

func _request_scene(path: String) -> void:
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.change_scene_to_file(path)
