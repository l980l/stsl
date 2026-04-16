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
	var pool: Array = []
	for hero in TeamManager.heroes:
		match hero.hero_id:
			"napoleon":   pool.append_array(_napoleon_card_pool())
			"cleopatra":  pool.append_array(_cleopatra_card_pool())
			"yi_sun_sin": pool.append_array(_yi_sun_sin_card_pool())
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func _recruit_hero_pool() -> Array:
	var existing := []
	for h in TeamManager.heroes:
		existing.append(h.hero_id)
	var pool := []
	if "cleopatra" not in existing:
		pool.append(_make_cleopatra_hero())
	if "yi_sun_sin" not in existing:
		pool.append(_make_yi_sun_sin_hero())
	return pool

func _make_cleopatra_hero() -> Resource:
	var HeroRes = load("res://resources/hero_resource.gd")
	var hero: Resource = HeroRes.new()
	hero.hero_id = "cleopatra"
	hero.hero_name = "클레오파트라"
	hero.max_hp = 60
	hero.character_scene = load("res://characters/heroes/cleopatra/cleopatra.tscn")
	return hero

func _make_yi_sun_sin_hero() -> Resource:
	var HeroRes = load("res://resources/hero_resource.gd")
	var hero: Resource = HeroRes.new()
	hero.hero_id = "yi_sun_sin"
	hero.hero_name = "이순신"
	hero.max_hp = 75
	hero.character_scene = load("res://characters/heroes/yi_sun_sin/yi_sun_sin.tscn")
	return hero

func _add_initial_deck_for(hero: Resource) -> void:
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	match hero.hero_id:
		"cleopatra":
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "독침"
				c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "attack"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE
				e.value = 3; e.target = "SINGLE"
				var ep: Resource = EffRes.new(); ep.effect_type = EffRes.EffectType.APPLY_STATUS
				ep.status_type = "poison"; ep.value = 3; ep.target = "SINGLE"
				c.effects = [e, ep]; DeckManager.add_card_to_deck(c)
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "왕실 방어"
				c.owner_id = "cleopatra"; c.cost = 1; c.play_animation = "idle"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 6
				c.effects = [e]; DeckManager.add_card_to_deck(c)
		"yi_sun_sin":
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "방패"
				c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "idle"
				var e: Resource = EffRes.new(); e.effect_type = EffRes.EffectType.BLOCK; e.value = 7
				c.effects = [e]; DeckManager.add_card_to_deck(c)
			for _i in range(2):
				var c: Resource = CardRes.new(); c.card_name = "역공"
				c.owner_id = "yi_sun_sin"; c.cost = 1; c.play_animation = "attack"
				var eb: Resource = EffRes.new(); eb.effect_type = EffRes.EffectType.BLOCK; eb.value = 3
				var ed: Resource = EffRes.new(); ed.effect_type = EffRes.EffectType.DAMAGE
				ed.value = 3; ed.target = "SINGLE"
				c.effects = [eb, ed]; DeckManager.add_card_to_deck(c)

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
	e5a.value = 3; e5a.target = "SINGLE"
	var e5b: Resource = EffRes.new()
	e5b.effect_type = EffRes.EffectType.APPLY_STATUS
	e5b.status_type = "poison"; e5b.value = 2; e5b.target = "SINGLE"
	c5.effects = [e5a, e5b]
	cards.append(c5)

	# 6. 돌격 — DAMAGE 8 + 사기+1
	var c6: Resource = CardRes.new()
	c6.card_name = "돌격"; c6.owner_id = "napoleon"; c6.cost = 1; c6.play_animation = "attack"
	var e6a: Resource = EffRes.new(); e6a.effect_type = EffRes.EffectType.DAMAGE; e6a.value = 8; e6a.target = "SINGLE"
	var e6b: Resource = EffRes.new(); e6b.effect_type = EffRes.EffectType.GAIN_MORALE; e6b.value = 1
	c6.effects = [e6a, e6b]; cards.append(c6)

	# 7. 황제의 명령 — DAMAGE 5 ALL + 사기+2
	var c7: Resource = CardRes.new()
	c7.card_name = "황제의 명령"; c7.owner_id = "napoleon"; c7.cost = 2; c7.play_animation = "attack"
	var e7a: Resource = EffRes.new(); e7a.effect_type = EffRes.EffectType.DAMAGE; e7a.value = 5; e7a.target = "ALL"
	var e7b: Resource = EffRes.new(); e7b.effect_type = EffRes.EffectType.GAIN_MORALE; e7b.value = 2
	c7.effects = [e7a, e7b]; cards.append(c7)

	# 8. 사기 폭발 — 사기 3 소모 → DAMAGE 20
	var c8: Resource = CardRes.new()
	c8.card_name = "사기 폭발"; c8.owner_id = "napoleon"; c8.cost = 0; c8.play_animation = "attack"
	var e8: Resource = EffRes.new(); e8.effect_type = EffRes.EffectType.CONSUME_MORALE
	e8.value = 3; e8.bonus_value = 20; e8.target = "SINGLE"
	c8.effects = [e8]; cards.append(c8)

	# 9. 군기 확립 — DRAW 2 + 사기+1
	var c9: Resource = CardRes.new()
	c9.card_name = "군기 확립"; c9.owner_id = "napoleon"; c9.cost = 1; c9.play_animation = "idle"
	var e9a: Resource = EffRes.new(); e9a.effect_type = EffRes.EffectType.DRAW; e9a.value = 2
	var e9b: Resource = EffRes.new(); e9b.effect_type = EffRes.EffectType.GAIN_MORALE; e9b.value = 1
	c9.effects = [e9a, e9b]; cards.append(c9)

	# 10. 포격 — DAMAGE 14 (사기 2이상이면 DAMAGE 20 → CONDITIONAL_DMG 간략화)
	var c10: Resource = CardRes.new()
	c10.card_name = "포격"; c10.owner_id = "napoleon"; c10.cost = 2; c10.play_animation = "attack"
	var e10: Resource = EffRes.new(); e10.effect_type = EffRes.EffectType.CONDITIONAL_DMG
	e10.value = 14; e10.bonus_value = 20; e10.status_type = "morale"; e10.target = "SINGLE"
	c10.effects = [e10]; cards.append(c10)

	# 11. 연속 타격 — DAMAGE 4 + ENERGY +1
	var c11: Resource = CardRes.new()
	c11.card_name = "연속 타격"; c11.owner_id = "napoleon"; c11.cost = 1; c11.play_animation = "attack"
	var e11a: Resource = EffRes.new(); e11a.effect_type = EffRes.EffectType.DAMAGE; e11a.value = 4; e11a.target = "SINGLE"
	var e11b: Resource = EffRes.new(); e11b.effect_type = EffRes.EffectType.ENERGY; e11b.value = 1
	c11.effects = [e11a, e11b]; cards.append(c11)

	# 12. 돌격 명령 — 사기+2 + DRAW 1
	var c12: Resource = CardRes.new()
	c12.card_name = "돌격 명령"; c12.owner_id = "napoleon"; c12.cost = 1; c12.play_animation = "idle"
	var e12a: Resource = EffRes.new(); e12a.effect_type = EffRes.EffectType.GAIN_MORALE; e12a.value = 2
	var e12b: Resource = EffRes.new(); e12b.effect_type = EffRes.EffectType.DRAW; e12b.value = 1
	c12.effects = [e12a, e12b]; cards.append(c12)

	# 13. 전열 정비 — DRAW 1, cost 0
	var c13: Resource = CardRes.new()
	c13.card_name = "전열 정비"; c13.owner_id = "napoleon"; c13.cost = 0; c13.play_animation = "idle"
	var e13: Resource = EffRes.new(); e13.effect_type = EffRes.EffectType.DRAW; e13.value = 1
	c13.effects = [e13]; cards.append(c13)

	# 14. 쾌속 전진 — DAMAGE 3 (간략화: 사기 스케일 대신 고정)
	var c14: Resource = CardRes.new()
	c14.card_name = "쾌속 전진"; c14.owner_id = "napoleon"; c14.cost = 1; c14.play_animation = "attack"
	var e14: Resource = EffRes.new(); e14.effect_type = EffRes.EffectType.DAMAGE; e14.value = 3; e14.target = "SINGLE"
	c14.effects = [e14]; cards.append(c14)

	return cards

func _cleopatra_card_pool() -> Array:
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var cards: Array = []

	# 1. 독안개 — 독 3 (ALL), cost 2
	var c1: Resource = CardRes.new(); c1.card_name = "독안개"; c1.owner_id = "cleopatra"; c1.cost = 2; c1.play_animation = "attack"
	var e1: Resource = EffRes.new(); e1.effect_type = EffRes.EffectType.APPLY_STATUS; e1.status_type = "poison"; e1.value = 3; e1.target = "ALL"
	c1.effects = [e1]; cards.append(c1)

	# 2. 독구름 — DAMAGE 2 ALL + 독 2 ALL, cost 1
	var c2: Resource = CardRes.new(); c2.card_name = "독구름"; c2.owner_id = "cleopatra"; c2.cost = 1; c2.play_animation = "attack"
	var e2a: Resource = EffRes.new(); e2a.effect_type = EffRes.EffectType.DAMAGE; e2a.value = 2; e2a.target = "ALL"
	var e2b: Resource = EffRes.new(); e2b.effect_type = EffRes.EffectType.APPLY_STATUS; e2b.status_type = "poison"; e2b.value = 2; e2b.target = "ALL"
	c2.effects = [e2a, e2b]; cards.append(c2)

	# 3. 뱀의 독 — 독 8 SINGLE, cost 1
	var c3: Resource = CardRes.new(); c3.card_name = "뱀의 독"; c3.owner_id = "cleopatra"; c3.cost = 1; c3.play_animation = "attack"
	var e3: Resource = EffRes.new(); e3.effect_type = EffRes.EffectType.APPLY_STATUS; e3.status_type = "poison"; e3.value = 8; e3.target = "SINGLE"
	c3.effects = [e3]; cards.append(c3)

	# 4. 독 폭발 — POISON_BURST, cost 1
	var c4: Resource = CardRes.new(); c4.card_name = "독 폭발"; c4.owner_id = "cleopatra"; c4.cost = 1; c4.play_animation = "attack"
	var e4: Resource = EffRes.new(); e4.effect_type = EffRes.EffectType.POISON_BURST; e4.target = "SINGLE"
	c4.effects = [e4]; cards.append(c4)

	# 5. 이중 독 — CONDITIONAL_DMG(value=2, bonus=8, cond=poison), cost 1
	var c5: Resource = CardRes.new(); c5.card_name = "이중 독"; c5.owner_id = "cleopatra"; c5.cost = 1; c5.play_animation = "attack"
	var e5: Resource = EffRes.new(); e5.effect_type = EffRes.EffectType.CONDITIONAL_DMG; e5.value = 2; e5.bonus_value = 8; e5.status_type = "poison"; e5.target = "SINGLE"
	c5.effects = [e5]; cards.append(c5)

	# 6. 치명독 — DAMAGE 4 + 독 5 + vulnerable 1, cost 2
	var c6: Resource = CardRes.new(); c6.card_name = "치명독"; c6.owner_id = "cleopatra"; c6.cost = 2; c6.play_animation = "attack"
	var e6a: Resource = EffRes.new(); e6a.effect_type = EffRes.EffectType.DAMAGE; e6a.value = 4; e6a.target = "SINGLE"
	var e6b: Resource = EffRes.new(); e6b.effect_type = EffRes.EffectType.APPLY_STATUS; e6b.status_type = "poison"; e6b.value = 5; e6b.target = "SINGLE"
	var e6c: Resource = EffRes.new(); e6c.effect_type = EffRes.EffectType.APPLY_STATUS; e6c.status_type = "vulnerable"; e6c.value = 1; e6c.target = "SINGLE"
	c6.effects = [e6a, e6b, e6c]; cards.append(c6)

	# 7. 독 강화 — DRAW 1 + ENERGY 1, cost 0 (간략화)
	var c7: Resource = CardRes.new(); c7.card_name = "독 강화"; c7.owner_id = "cleopatra"; c7.cost = 0; c7.play_animation = "idle"
	var e7a: Resource = EffRes.new(); e7a.effect_type = EffRes.EffectType.DRAW; e7a.value = 1
	var e7b: Resource = EffRes.new(); e7b.effect_type = EffRes.EffectType.ENERGY; e7b.value = 1
	c7.effects = [e7a, e7b]; cards.append(c7)

	# 8. 독 회복 — HEAL 6 (독 합계 기반 간략화), cost 1
	var c8: Resource = CardRes.new(); c8.card_name = "독 회복"; c8.owner_id = "cleopatra"; c8.cost = 1; c8.play_animation = "idle"
	var e8: Resource = EffRes.new(); e8.effect_type = EffRes.EffectType.HEAL; e8.value = 6
	c8.effects = [e8]; cards.append(c8)

	# 9. 유혹 — APPLY_STATUS(charm 2), cost 1
	var c9: Resource = CardRes.new(); c9.card_name = "유혹"; c9.owner_id = "cleopatra"; c9.cost = 1; c9.play_animation = "idle"
	var e9: Resource = EffRes.new(); e9.effect_type = EffRes.EffectType.APPLY_STATUS; e9.status_type = "charm"; e9.value = 2; e9.target = "SINGLE"
	c9.effects = [e9]; cards.append(c9)

	# 10. 저주의 시선 — weak 2 + vulnerable 2, cost 1
	var c10: Resource = CardRes.new(); c10.card_name = "저주의 시선"; c10.owner_id = "cleopatra"; c10.cost = 1; c10.play_animation = "idle"
	var e10a: Resource = EffRes.new(); e10a.effect_type = EffRes.EffectType.APPLY_STATUS; e10a.status_type = "weak"; e10a.value = 2; e10a.target = "SINGLE"
	var e10b: Resource = EffRes.new(); e10b.effect_type = EffRes.EffectType.APPLY_STATUS; e10b.status_type = "vulnerable"; e10b.value = 2; e10b.target = "SINGLE"
	c10.effects = [e10a, e10b]; cards.append(c10)

	# 11. 파라오의 명 — BLOCK 8 + DRAW 2, cost 1
	var c11: Resource = CardRes.new(); c11.card_name = "파라오의 명"; c11.owner_id = "cleopatra"; c11.cost = 1; c11.play_animation = "idle"
	var e11a: Resource = EffRes.new(); e11a.effect_type = EffRes.EffectType.BLOCK; e11a.value = 8
	var e11b: Resource = EffRes.new(); e11b.effect_type = EffRes.EffectType.DRAW; e11b.value = 2
	c11.effects = [e11a, e11b]; cards.append(c11)

	# 12. 독 방패 — BLOCK 10 (독 조건 간략화), cost 1
	var c12: Resource = CardRes.new(); c12.card_name = "독 방패"; c12.owner_id = "cleopatra"; c12.cost = 1; c12.play_animation = "idle"
	var e12: Resource = EffRes.new(); e12.effect_type = EffRes.EffectType.BLOCK; e12.value = 10
	c12.effects = [e12]; cards.append(c12)

	# 13. 왕실 칙령 — DRAW 2 (서치 간략화), cost 2
	var c13: Resource = CardRes.new(); c13.card_name = "왕실 칙령"; c13.owner_id = "cleopatra"; c13.cost = 2; c13.play_animation = "idle"
	var e13: Resource = EffRes.new(); e13.effect_type = EffRes.EffectType.DRAW; e13.value = 2
	c13.effects = [e13]; cards.append(c13)

	# 14. 재생독 — DAMAGE 3 + 독 1 ALL, cost 1
	var c14: Resource = CardRes.new(); c14.card_name = "재생독"; c14.owner_id = "cleopatra"; c14.cost = 1; c14.play_animation = "attack"
	var e14a: Resource = EffRes.new(); e14a.effect_type = EffRes.EffectType.DAMAGE; e14a.value = 3; e14a.target = "SINGLE"
	var e14b: Resource = EffRes.new(); e14b.effect_type = EffRes.EffectType.APPLY_STATUS; e14b.status_type = "poison"; e14b.value = 1; e14b.target = "ALL"
	c14.effects = [e14a, e14b]; cards.append(c14)

	return cards

func _yi_sun_sin_card_pool() -> Array:
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var cards: Array = []

	# 1. 거북선 돌격 — DAMAGE 6 + COUNTER_BLOCK(60%), cost 2
	var c1: Resource = CardRes.new(); c1.card_name = "거북선 돌격"; c1.owner_id = "yi_sun_sin"; c1.cost = 2; c1.play_animation = "attack"
	var e1a: Resource = EffRes.new(); e1a.effect_type = EffRes.EffectType.DAMAGE; e1a.value = 6; e1a.target = "SINGLE"
	var e1b: Resource = EffRes.new(); e1b.effect_type = EffRes.EffectType.COUNTER_BLOCK; e1b.value = 60; e1b.target = "SINGLE"
	c1.effects = [e1a, e1b]; cards.append(c1)

	# 2. 반격 — COUNTER_BLOCK(100%), cost 1
	var c2: Resource = CardRes.new(); c2.card_name = "반격"; c2.owner_id = "yi_sun_sin"; c2.cost = 1; c2.play_animation = "attack"
	var e2: Resource = EffRes.new(); e2.effect_type = EffRes.EffectType.COUNTER_BLOCK; e2.value = 100; e2.target = "SINGLE"
	c2.effects = [e2]; cards.append(c2)

	# 3. 철갑 — BLOCK 14, cost 1
	var c3: Resource = CardRes.new(); c3.card_name = "철갑"; c3.owner_id = "yi_sun_sin"; c3.cost = 1; c3.play_animation = "idle"
	var e3: Resource = EffRes.new(); e3.effect_type = EffRes.EffectType.BLOCK; e3.value = 14
	c3.effects = [e3]; cards.append(c3)

	# 4. 학익진 — BLOCK_ALL 5, cost 2
	var c4: Resource = CardRes.new(); c4.card_name = "학익진"; c4.owner_id = "yi_sun_sin"; c4.cost = 2; c4.play_animation = "idle"
	var e4: Resource = EffRes.new(); e4.effect_type = EffRes.EffectType.BLOCK_ALL; e4.value = 5
	c4.effects = [e4]; cards.append(c4)

	# 5. 배수진 — HEAL -8 + BLOCK 18, cost 1
	var c5: Resource = CardRes.new(); c5.card_name = "배수진"; c5.owner_id = "yi_sun_sin"; c5.cost = 1; c5.play_animation = "idle"
	var e5a: Resource = EffRes.new(); e5a.effect_type = EffRes.EffectType.HEAL; e5a.value = -8
	var e5b: Resource = EffRes.new(); e5b.effect_type = EffRes.EffectType.BLOCK; e5b.value = 18
	c5.effects = [e5a, e5b]; cards.append(c5)

	# 6. 노량 해전 — DAMAGE 24 (조건 간략화: 항상 사용 가능), cost 2
	var c6: Resource = CardRes.new(); c6.card_name = "노량 해전"; c6.owner_id = "yi_sun_sin"; c6.cost = 2; c6.play_animation = "attack"
	var e6: Resource = EffRes.new(); e6.effect_type = EffRes.EffectType.DAMAGE; e6.value = 24; e6.target = "SINGLE"
	c6.effects = [e6]; cards.append(c6)

	# 7. 진형 강화 — FORMATION_BLOCK 5, cost 1
	var c7: Resource = CardRes.new(); c7.card_name = "진형 강화"; c7.owner_id = "yi_sun_sin"; c7.cost = 1; c7.play_animation = "idle"
	var e7: Resource = EffRes.new(); e7.effect_type = EffRes.EffectType.FORMATION_BLOCK; e7.value = 5
	c7.effects = [e7]; cards.append(c7)

	# 8. 수군 훈련 — BLOCK 5 + DRAW 1, cost 1
	var c8: Resource = CardRes.new(); c8.card_name = "수군 훈련"; c8.owner_id = "yi_sun_sin"; c8.cost = 1; c8.play_animation = "idle"
	var e8a: Resource = EffRes.new(); e8a.effect_type = EffRes.EffectType.BLOCK; e8a.value = 5
	var e8b: Resource = EffRes.new(); e8b.effect_type = EffRes.EffectType.DRAW; e8b.value = 1
	c8.effects = [e8a, e8b]; cards.append(c8)

	# 9. 한산대첩 — DAMAGE 8 ALL + BLOCK_ALL 8, cost 3
	var c9: Resource = CardRes.new(); c9.card_name = "한산대첩"; c9.owner_id = "yi_sun_sin"; c9.cost = 3; c9.play_animation = "attack"
	var e9a: Resource = EffRes.new(); e9a.effect_type = EffRes.EffectType.DAMAGE; e9a.value = 8; e9a.target = "ALL"
	var e9b: Resource = EffRes.new(); e9b.effect_type = EffRes.EffectType.BLOCK_ALL; e9b.value = 8
	c9.effects = [e9a, e9b]; cards.append(c9)

	# 10. 불굴 — HEAL_ALL 12, cost 2
	var c10: Resource = CardRes.new(); c10.card_name = "불굴"; c10.owner_id = "yi_sun_sin"; c10.cost = 2; c10.play_animation = "idle"
	var e10: Resource = EffRes.new(); e10.effect_type = EffRes.EffectType.HEAL_ALL; e10.value = 12
	c10.effects = [e10]; cards.append(c10)

	# 11. 엄정한 훈련 — DRAW 2 + BLOCK 4, cost 1
	var c11: Resource = CardRes.new(); c11.card_name = "엄정한 훈련"; c11.owner_id = "yi_sun_sin"; c11.cost = 1; c11.play_animation = "idle"
	var e11a: Resource = EffRes.new(); e11a.effect_type = EffRes.EffectType.DRAW; e11a.value = 2
	var e11b: Resource = EffRes.new(); e11b.effect_type = EffRes.EffectType.BLOCK; e11b.value = 4
	c11.effects = [e11a, e11b]; cards.append(c11)

	# 12. 거북선 방패 — BLOCK 8, cost 1
	var c12: Resource = CardRes.new(); c12.card_name = "거북선 방패"; c12.owner_id = "yi_sun_sin"; c12.cost = 1; c12.play_animation = "idle"
	var e12: Resource = EffRes.new(); e12.effect_type = EffRes.EffectType.BLOCK; e12.value = 8
	c12.effects = [e12]; cards.append(c12)

	# 13. 필사즉생 — DAMAGE 10 (HP 기반 간략화), cost 1
	var c13: Resource = CardRes.new(); c13.card_name = "필사즉생"; c13.owner_id = "yi_sun_sin"; c13.cost = 1; c13.play_animation = "attack"
	var e13: Resource = EffRes.new(); e13.effect_type = EffRes.EffectType.DAMAGE; e13.value = 10; e13.target = "SINGLE"
	c13.effects = [e13]; cards.append(c13)

	# 14. 해군 기동 — BLOCK 3, cost 0
	var c14: Resource = CardRes.new(); c14.card_name = "해군 기동"; c14.owner_id = "yi_sun_sin"; c14.cost = 0; c14.play_animation = "idle"
	var e14: Resource = EffRes.new(); e14.effect_type = EffRes.EffectType.BLOCK; e14.value = 3
	c14.effects = [e14]; cards.append(c14)

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
