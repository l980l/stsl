# autoload/game_manager.gd
class_name GameManagerClass
extends Node

const _NapoleonCards  = preload("res://resources/cards/cards_napoleon.gd")
const _CleopatraCards = preload("res://resources/cards/cards_cleopatra.gd")
const _YiSunSinCards  = preload("res://resources/cards/cards_yi_sun_sin.gd")
const _EnemiesAct1    = preload("res://resources/enemies/enemies_act1.gd")
const _RelicData      = preload("res://resources/relics/relics.gd")
const _EventsAct1     = preload("res://resources/events/events_act1.gd")

enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST, GAME_OVER, CARD_UPGRADE, HERO_RECRUIT }

var current_state: GameState = GameState.MAP
var current_floor: int = 0
const MAX_ACTS: int = 2
var current_act: int = 1
var gold: int = 0
var relics: Array = []
var run_won: bool = false

# ── Plan 04: 런 스테이트 ──────────────────────────────
var run_map: Array = []             # Array[MapNodeResource]
var available_node_ids: Array = []  # 현재 클릭 가능한 노드 ID 목록
var current_node_id: int = -1
var pending_enemies: Array = []     # 다음 배틀 적 데이터
var card_rewards: Array = []        # 다음 카드 보상 목록
var pending_event: Resource = null  # 현재 이벤트 데이터 (EventResource)
var card_rewards_pick_count: int = 1  # 카드픽 화면에서 선택 가능한 카드 수
var pending_boss_upgrade: bool = false  # 보스 후 카드 강화 대기 여부
var pending_boss_recruit: bool = false  # 보스 후 영웅 영입 대기 여부
# ─────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal gold_changed(new_gold: int)
signal relic_added(relic: Resource)
signal run_started()
signal node_entered(node_id: int)
signal run_ended(won: bool)

func _get_tm() -> Object:
	if Engine.has_singleton("TeamManager"):
		return Engine.get_singleton("TeamManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("TeamManager")
	return null

func _get_dm() -> Object:
	if Engine.has_singleton("DeckManager"):
		return Engine.get_singleton("DeckManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("DeckManager")
	return null

func _get_bm() -> Object:
	if Engine.has_singleton("BattleManager"):
		return Engine.get_singleton("BattleManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("BattleManager")
	return null

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
	current_act = 1
	gold = 0
	relics.clear()
	run_map.clear()
	available_node_ids.clear()
	current_node_id = -1
	pending_enemies.clear()
	card_rewards.clear()
	pending_event = null
	run_won = false
	card_rewards_pick_count = 1
	pending_boss_upgrade = false
	pending_boss_recruit = false

# ── Plan 04: 런 관리 ──────────────────────────────────

func start_run(initial_hero_id: String = "napoleon") -> void:
	reset()

	var tm := _get_tm()
	if tm:
		tm.clear()
	var dm := _get_dm()
	if dm:
		dm.clear()

	# 초기 영웅 생성 및 추가
	var hero := _make_hero_by_id(initial_hero_id)
	if tm:
		tm.add_hero(hero)

	# 초기 덱 생성
	_add_initial_deck_for(hero)

	# 맵 생성
	var MapGen = load("res://autoload/map_generator.gd")
	run_map = MapGen.generate(current_act)
	available_node_ids = [0, 1, 2]
	run_started.emit()

func _make_hero_by_id(hero_id: String) -> Resource:
	var HeroRes = load("res://resources/hero_resource.gd")
	var hero: Resource = HeroRes.new()
	hero.hero_id = hero_id
	match hero_id:
		"napoleon":
			hero.hero_name = "나폴레옹"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
		"cleopatra":
			hero.hero_name = "클레오파트라"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/cleopatra/cleopatra.tscn")
		"yi_sun_sin":
			hero.hero_name = "이순신"
			hero.max_hp = 1000
			hero.character_scene = load("res://characters/heroes/yi_sun_sin/yi_sun_sin.tscn")
	return hero

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
			change_state(GameState.SHOP)
			_request_scene("res://scenes/shop/shop_scene.tscn")

func complete_battle(won: bool) -> void:
	pending_enemies.clear()
	if won:
		var RelicRes = load("res://resources/relic_resource.gd")
		trigger_relics(RelicRes.TriggerType.BATTLE_WIN)
		card_rewards = _generate_card_rewards()
		# 룸 타입별 카드 보상 수량 및 보스 릴릭 처리
		if current_node_id >= 0 and current_node_id < run_map.size():
			var node: Resource = run_map[current_node_id]
			var MapNodeRes = load("res://resources/map_node_resource.gd")
			match node.room_type:
				MapNodeRes.RoomType.ELITE:
					card_rewards_pick_count = 2
					add_gold(randi_range(20, 25))
				MapNodeRes.RoomType.BOSS:
					card_rewards_pick_count = 2
					add_gold(40)
					var relic := get_random_relic()
					if relic:
						add_relic(relic)
				_:
					card_rewards_pick_count = 1
					add_gold(randi_range(10, 15))
		change_state(GameState.CARD_PICK)
		_request_scene("res://scenes/card_pick/card_pick_scene.tscn")
	else:
		run_won = false
		run_ended.emit(false)
		var _sm_fail = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
		if _sm_fail:
			_sm_fail.clear_save()
		change_state(GameState.GAME_OVER)
		_request_scene("res://scenes/game_over/game_over_scene.tscn")

func complete_card_pick() -> void:
	var node: Resource = run_map[current_node_id]
	_advance_nodes_from(current_node_id)
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	card_rewards.clear()
	if node.room_type == MapNodeRes.RoomType.BOSS:
		# 보스 승리: 카드 강화 1회 후 게임 오버(승)
		pending_boss_upgrade = true
		change_state(GameState.CARD_UPGRADE)
		_request_scene("res://scenes/card_upgrade/card_upgrade_scene.tscn")
		return
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func complete_shop() -> void:
	_advance_nodes_from(current_node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func recruit_random_hero() -> void:
	var pool := _recruit_hero_pool()
	if pool.is_empty():
		return
	var hero: Resource = pool[randi() % pool.size()]
	var tm := _get_tm()
	if tm:
		tm.add_hero(hero)
	_add_initial_deck_for(hero)

func complete_event() -> void:
	pending_event = null
	_advance_nodes_from(current_node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func complete_rest() -> void:
	_advance_nodes_from(current_node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func enter_card_upgrade() -> void:
	_advance_nodes_from(current_node_id)
	change_state(GameState.CARD_UPGRADE)
	_request_scene("res://scenes/card_upgrade/card_upgrade_scene.tscn")

func complete_card_upgrade() -> void:
	if pending_boss_upgrade:
		pending_boss_upgrade = false
		var pool := _recruit_hero_pool()
		if not pool.is_empty():
			pending_boss_recruit = true
			change_state(GameState.HERO_RECRUIT)
			_request_scene("res://scenes/hero_select/hero_select_scene.tscn")
			return
		if current_act < MAX_ACTS:
			_start_next_act()
		else:
			_end_run_won()
		return
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func complete_hero_recruit(hero_id: String) -> void:
	pending_boss_recruit = false
	var hero: Resource = _make_hero_by_id(hero_id)
	var tm := _get_tm()
	if tm:
		tm.add_hero(hero)
	_add_initial_deck_for(hero)
	if current_act < MAX_ACTS:
		_start_next_act()
	else:
		_end_run_won()

func _start_next_act() -> void:
	current_act += 1
	current_floor = 0
	current_node_id = -1
	pending_boss_upgrade = false
	pending_boss_recruit = false
	var MapGen = load("res://autoload/map_generator.gd")
	run_map = MapGen.generate(current_act)
	available_node_ids = [0, 1, 2]
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func _end_run_won() -> void:
	run_won = true
	run_ended.emit(true)
	var _sm = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
	if _sm:
		_sm.clear_save()
	change_state(GameState.GAME_OVER)
	_request_scene("res://scenes/game_over/game_over_scene.tscn")

func upgrade_card(card: Resource) -> void:
	if not card.can_upgrade():
		return
	card.upgrade_level += 1
	var level: int = card.upgrade_level
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")

	var rate: float = 0.0
	match card.rarity:
		CardRes.Rarity.UNCOMMON:   rate = 0.10
		CardRes.Rarity.RARE:       rate = 0.12
		CardRes.Rarity.LEGENDARY:  rate = 0.14
		CardRes.Rarity.DIVINE:     rate = 0.16

	var PERCENT_TYPES = [
		EffRes.EffectType.DAMAGE,
		EffRes.EffectType.BLOCK,
		EffRes.EffectType.HEAL,
		EffRes.EffectType.BLOCK_ALL,
		EffRes.EffectType.HEAL_ALL,
		EffRes.EffectType.FORMATION_BLOCK,
		EffRes.EffectType.COUNTER_BLOCK,
		EffRes.EffectType.POISON_BURST,
		EffRes.EffectType.CONSUME_MORALE,
		EffRes.EffectType.CONDITIONAL_DMG,
	]

	var INT_TYPES = [
		EffRes.EffectType.DRAW,
		EffRes.EffectType.ENERGY,
		EffRes.EffectType.GAIN_MORALE,
		EffRes.EffectType.APPLY_STATUS,
		EffRes.EffectType.CHARM,
		EffRes.EffectType.COST_NEXT,
		EffRes.EffectType.SUMMON_TOKEN,
	]

	for effect in card.effects:
		if effect.effect_type in PERCENT_TYPES:
			effect.value = int(effect.base_value * (1.0 + rate * level))
			effect.bonus_value = int(effect.base_bonus_value * (1.0 + rate * level))
		elif effect.effect_type in INT_TYPES:
			effect.value = effect.base_value + level
			effect.bonus_value = effect.base_bonus_value + level if effect.base_bonus_value > 0 else 0

func generate_shop_inventory() -> Dictionary:
	var tm := _get_tm()
	var card_pool: Array = []
	if tm:
		for hero in tm.heroes:
			match hero.hero_id:
				"napoleon":   card_pool.append_array(_napoleon_card_pool())
				"cleopatra":  card_pool.append_array(_cleopatra_card_pool())
				"yi_sun_sin": card_pool.append_array(_yi_sun_sin_card_pool())
	card_pool.shuffle()
	return {
		"cards": card_pool.slice(0, min(3, card_pool.size())),
		"card_price": 75,
		"relic": get_random_relic(),
		"relic_price": 150,
		"remove_price": 100,
		"heal_price": 30,
		"heal_amount": 20,
	}

func _advance_nodes_from(node_id: int) -> void:
	var node: Resource = run_map[node_id]
	available_node_ids = node.connections.duplicate()

func _heal_all_heroes(amount: int) -> void:
	if not is_inside_tree():
		return
	var tm := _get_tm()
	if tm == null:
		return
	for hero in tm.heroes:
		tm.heal(hero.hero_id, amount)

func _satyr_scene() -> PackedScene:
	return load("res://characters/enemies/satyr/satyr.tscn")

func _make_normal_enemies() -> Array:
	var scene := _satyr_scene()
	match randi() % 4:
		0: return [_EnemiesAct1.satyr(scene, 30, 6)]
		1: return [_EnemiesAct1.harpy(scene, 25)]
		2: return [_EnemiesAct1.cyclops(scene, 45)]
		_: return [_EnemiesAct1.snake(scene, 20)]

const _ACT_HP_MULT: Dictionary = {1: 1.0, 2: 1.3}
const _ACT_DMG_MULT: Dictionary = {1: 1.0, 2: 1.2}

func _apply_act_difficulty(enemies: Array, act: int) -> void:
	var hp_m: float = _ACT_HP_MULT.get(act, 1.0)
	var dmg_m: float = _ACT_DMG_MULT.get(act, 1.0)
	var IntentRes = load("res://resources/intent_resource.gd")
	for enemy in enemies:
		enemy.max_hp = int(enemy.max_hp * hp_m)
		for intent in enemy.intent_pattern:
			if intent.action_type == IntentRes.ActionType.ATTACK:
				intent.value = int(intent.value * dmg_m)
		for phase_pattern in enemy.phase_patterns:
			for intent in phase_pattern:
				if intent.action_type == IntentRes.ActionType.ATTACK:
					intent.value = int(intent.value * dmg_m)

func _make_enemies_for_node(node: Resource) -> Array:
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var enemies: Array
	match node.room_type:
		MapNodeRes.RoomType.BATTLE:
			enemies = _make_normal_enemies()
		MapNodeRes.RoomType.ELITE:
			enemies = _make_elite_enemies()
		MapNodeRes.RoomType.BOSS:
			enemies = _make_boss_enemies()
		_:
			enemies = []
	_apply_act_difficulty(enemies, current_act)
	return enemies

func _make_elite_enemies() -> Array:
	var scene := _satyr_scene()
	if randi() % 2 == 0:
		return [_EnemiesAct1.minotaur(scene)]
	return [_EnemiesAct1.medusa(scene)]

func _make_boss_enemies() -> Array:
	return [_EnemiesAct1.hydra(_satyr_scene())]

func _generate_card_rewards() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	var pool: Array = []
	for hero in tm.heroes:
		match hero.hero_id:
			"napoleon":   pool.append_array(_napoleon_card_pool())
			"cleopatra":  pool.append_array(_cleopatra_card_pool())
			"yi_sun_sin": pool.append_array(_yi_sun_sin_card_pool())
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func _recruit_hero_pool() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	var existing := []
	for h in tm.heroes:
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
	hero.max_hp = 1000
	hero.character_scene = load("res://characters/heroes/cleopatra/cleopatra.tscn")
	return hero

func _make_yi_sun_sin_hero() -> Resource:
	var HeroRes = load("res://resources/hero_resource.gd")
	var hero: Resource = HeroRes.new()
	hero.hero_id = "yi_sun_sin"
	hero.hero_name = "이순신"
	hero.max_hp = 1000
	hero.character_scene = load("res://characters/heroes/yi_sun_sin/yi_sun_sin.tscn")
	return hero

func _add_initial_deck_for(hero: Resource) -> void:
	var dm := _get_dm()
	if dm == null:
		return
	var cards: Array = []
	match hero.hero_id:
		"napoleon":   cards = _NapoleonCards.starter_deck()
		"cleopatra":  cards = _CleopatraCards.starter_deck()
		"yi_sun_sin": cards = _YiSunSinCards.starter_deck()
	for card in cards:
		dm.add_card_to_deck(card)

func _napoleon_card_pool() -> Array:
	return _NapoleonCards.pool()

func _cleopatra_card_pool() -> Array:
	return _CleopatraCards.pool()

func _yi_sun_sin_card_pool() -> Array:
	return _YiSunSinCards.pool()

func _get_random_event() -> Resource:
	var pool := _build_event_pool()
	return pool[randi() % pool.size()]

func _build_event_pool() -> Array:
	return _EventsAct1.build_pool()

func to_dict() -> Dictionary:
	var map_data := []
	for node in run_map:
		map_data.append({
			"node_id": node.node_id,
			"floor_num": node.floor_num,
			"column": node.column,
			"room_type": node.room_type,
			"connections": node.connections.duplicate(),
			"visited": node.visited,
		})
	return {
		"current_act": current_act,
		"current_floor": current_floor,
		"gold": gold,
		"current_node_id": current_node_id,
		"available_node_ids": available_node_ids.duplicate(),
		"run_map": map_data,
	}

func from_dict(data: Dictionary) -> void:
	current_act = data.get("current_act", 1)
	current_floor = data.get("current_floor", 0)
	gold = data.get("gold", 0)
	current_node_id = data.get("current_node_id", -1)
	available_node_ids = data.get("available_node_ids", [0, 1, 2])
	run_map.clear()
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	for nd in data.get("run_map", []):
		var node: Resource = MapNodeRes.new()
		node.node_id = nd["node_id"]
		node.floor_num = nd["floor_num"]
		node.column = nd["column"]
		node.room_type = nd["room_type"]
		node.connections = nd["connections"].duplicate()
		node.visited = nd["visited"]
		run_map.append(node)

func _request_scene(path: String) -> void:
	if is_inside_tree():
		# 맵으로 돌아갈 때 저장
		if path == "res://scenes/map/map_scene.tscn" and not run_map.is_empty():
			var _sm = Engine.get_singleton("SaveManager") if Engine.has_singleton("SaveManager") else null
			if _sm:
				_sm.save()
		get_tree().change_scene_to_file(path)

# ── 릴릭 시스템 ─────────────────────────────────

func get_random_relic() -> Resource:
	var tm := _get_tm()
	var pool := _build_relic_pool()
	var owned_names: Array = []
	for r in relics:
		owned_names.append(r.relic_name)
	var available: Array = []
	for r in pool:
		if r.relic_name in owned_names:
			continue
		if r.is_cursed:
			continue
		if r.owner_hero_id != "":
			if tm == null or not tm.has_hero(r.owner_hero_id):
				continue
		available.append(r)
	if available.is_empty():
		return null
	return available[randi() % available.size()]

func get_random_cursed_relic() -> Resource:
	var pool := _build_relic_pool()
	var owned_names: Array = []
	for r in relics:
		owned_names.append(r.relic_name)
	var available: Array = []
	for r in pool:
		if r.is_cursed and r.relic_name not in owned_names:
			available.append(r)
	if available.is_empty():
		return null
	return available[randi() % available.size()]

func trigger_relics(trigger: int, context: Dictionary = {}) -> void:
	for relic in relics:
		# 메인 효과
		if relic.trigger == trigger:
			var effective_value: int = relic.value
			if relic.owner_hero_id == "" or _is_hero_alive(relic.owner_hero_id):
				if relic.owner_hero_id != "":
					effective_value = relic.bonus_value
				_apply_relic_effect(relic, effective_value, context)
		# 패널티 효과 (저주 렐릭)
		if relic.is_cursed and relic.penalty_trigger == trigger and relic.penalty_value > 0:
			_apply_penalty_effect(relic)

func _apply_penalty_effect(relic: Resource) -> void:
	var RelicRes = load("res://resources/relic_resource.gd")
	var tm := _get_tm()
	if not is_inside_tree() or tm == null:
		return
	match relic.penalty_effect_type:
		RelicRes.EffectType.DAMAGE_HERO:
			var living: Array = tm.get_living_heroes()
			if not living.is_empty():
				var target = living[randi() % living.size()]
				tm.take_damage(target.hero_id, relic.penalty_value)
		_:
			push_warning("_apply_penalty_effect: 미처리 penalty_effect_type = %d" % relic.penalty_effect_type)

func _is_hero_alive(hero_id: String) -> bool:
	if not is_inside_tree():
		return false
	var tm := _get_tm()
	return tm != null and tm.is_alive(hero_id)

func _apply_relic_effect(relic: Resource, value: int, context: Dictionary) -> void:
	var RelicRes = load("res://resources/relic_resource.gd")
	var tm := _get_tm()
	var dm := _get_dm()
	match relic.effect_type:
		RelicRes.EffectType.HEAL:
			if is_inside_tree() and tm:
				for hero in tm.heroes:
					tm.heal(hero.hero_id, value)
		RelicRes.EffectType.ENERGY:
			if is_inside_tree() and dm:
				var dmg_amount: int = context.get("amount", 0)
				if relic.condition_value == 0 or dmg_amount >= relic.condition_value:
					dm.current_energy += value
					dm.energy_changed.emit(dm.current_energy)
		RelicRes.EffectType.DRAW:
			if is_inside_tree() and dm:
				dm.draw_cards(value)
		RelicRes.EffectType.BLOCK:
			var bm_block := _get_bm()
			if is_inside_tree() and bm_block and tm:
				for hero in tm.heroes:
					bm_block._hero_block[hero.hero_id] = \
						bm_block._hero_block.get(hero.hero_id, 0) + value
		RelicRes.EffectType.APPLY_STATUS_ENEMY:
			var bm_ase := _get_bm()
			if is_inside_tree() and bm_ase and bm_ase.is_battle_active:
				for i in range(bm_ase._enemies.size()):
					if bm_ase._enemy_alive[i]:
						bm_ase._apply_status_to_enemy(i, "poison", value)
		RelicRes.EffectType.GAIN_MORALE:
			var bm_gm := _get_bm()
			if is_inside_tree() and bm_gm:
				bm_gm._apply_status_to_hero(relic.owner_hero_id, "morale", value)
		RelicRes.EffectType.MAX_HP:
			if is_inside_tree() and tm:
				for hero in tm.heroes:
					tm.increase_max_hp(hero.hero_id, value)
		RelicRes.EffectType.COST_REDUCTION:
			pass  # PASSIVE 릴릭에서 별도 처리
		RelicRes.EffectType.DAMAGE_HERO:
			if is_inside_tree() and tm:
				var living: Array = tm.get_living_heroes()
				if not living.is_empty():
					var target = living[randi() % living.size()]
					tm.take_damage(target.hero_id, value)

func _build_relic_pool() -> Array:
	return _RelicData.build_pool()
