# autoload/game_manager.gd
class_name GameManagerClass
extends Node

const _HeroRegistry   = preload("res://resources/heroes/hero_registry.gd")
const _NapoleonCards  = preload("res://resources/cards/cards_napoleon.gd")
const _CleopatraCards = preload("res://resources/cards/cards_cleopatra.gd")
const _YiSunSinCards  = preload("res://resources/cards/cards_yi_sun_sin.gd")
const _JoanCards        = preload("res://resources/cards/cards_joan_of_arc.gd")
const _GenghisKhanCards = preload("res://resources/cards/cards_genghis_khan.gd")
const _MusashiCards     = preload("res://resources/cards/cards_musashi.gd")
const _GreekNormals    = preload("res://resources/enemies/greek/greek_normals.gd")
const _GreekAct1       = preload("res://resources/enemies/greek/greek_act1.gd")
const _GreekAct2       = preload("res://resources/enemies/greek/greek_act2.gd")
const _GreekAct3       = preload("res://resources/enemies/greek/greek_act3.gd")
const _EgyptianNormals = preload("res://resources/enemies/egyptian/egyptian_normals.gd")
const _EgyptianAct1    = preload("res://resources/enemies/egyptian/egyptian_act1.gd")
const _EgyptianAct2    = preload("res://resources/enemies/egyptian/egyptian_act2.gd")
const _EgyptianAct3    = preload("res://resources/enemies/egyptian/egyptian_act3.gd")
const _NorseNormals    = preload("res://resources/enemies/norse/norse_normals.gd")
const _NorseAct1       = preload("res://resources/enemies/norse/norse_act1.gd")
const _NorseAct2       = preload("res://resources/enemies/norse/norse_act2.gd")
const _NorseAct3       = preload("res://resources/enemies/norse/norse_act3.gd")
const _RelicData      = preload("res://resources/relics/relics.gd")
const _EventsAct1     = preload("res://resources/events/events_act1.gd")
const _EventsAct2     = preload("res://resources/events/events_act2.gd")
const _EventsAct3     = preload("res://resources/events/events_act3.gd")
const _EventsBuddhist  = preload("res://resources/events/events_buddhist.gd")
const _EventsDaoist    = preload("res://resources/events/events_daoist.gd")
const _EventsJapanese = preload("res://resources/events/events_japanese.gd")
const _MapNodeRes       = preload("res://resources/map_node_resource.gd")
const _BuddhistNormals  = preload("res://resources/enemies/buddhist/buddhist_normals.gd")
const _BuddhistAct1     = preload("res://resources/enemies/buddhist/buddhist_act1.gd")
const _BuddhistAct2     = preload("res://resources/enemies/buddhist/buddhist_act2.gd")
const _BuddhistAct3     = preload("res://resources/enemies/buddhist/buddhist_act3.gd")
const _DaoistNormals    = preload("res://resources/enemies/daoist/daoist_normals.gd")
const _DaoistAct1       = preload("res://resources/enemies/daoist/daoist_act1.gd")
const _DaoistAct2       = preload("res://resources/enemies/daoist/daoist_act2.gd")
const _DaoistAct3       = preload("res://resources/enemies/daoist/daoist_act3.gd")
const _JapaneseNormals = preload("res://resources/enemies/japanese/japanese_normals.gd")
const _JapaneseAct1    = preload("res://resources/enemies/japanese/japanese_act1.gd")
const _JapaneseAct2    = preload("res://resources/enemies/japanese/japanese_act2.gd")
const _JapaneseAct3    = preload("res://resources/enemies/japanese/japanese_act3.gd")

enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST, GAME_OVER, CARD_UPGRADE, HERO_RECRUIT }

var current_state: GameState = GameState.MAP
var current_floor: int = 0
const MAX_CHAPTERS: int = 2
var current_chapter: int = 1
const _DEBUG_TEST_DECK: bool = true  # 임시: 파티클 타입 테스트용. 완료 후 false로 되돌릴 것
const MAX_ACTS: int = 3
var current_act: int = 1
var gold: int = 0
var relics: Array = []
var run_won: bool = false
# "점점 강해지는" 렐릭용 런 누적 카운터
var battles_completed: int = 0
var enemies_killed_this_run: int = 0
var act_mythologies: Array[String] = []

# ── Plan 04: 런 스테이트 ──────────────────────────────
var run_map: Array = []             # Array[MapNodeResource]
var available_node_ids: Array = []  # 현재 클릭 가능한 노드 ID 목록
var current_node_id: int = -1
var pending_enemies: Array = []     # 다음 배틀 적 데이터
var card_rewards: Array = []        # 다음 카드 보상 목록
var pending_event: Resource = null  # 현재 이벤트 데이터 (EventResource)
# 이벤트가 트리거한 전투 — 승리 시 자동 적용할 추가 보상 (Dictionary 또는 빈 값)
# {effect_type: int, value: int, card_id: String}
var pending_event_battle_reward: Dictionary = {}
var card_rewards_pick_count: int = 1  # 카드픽 화면에서 선택 가능한 카드 수
var pending_boss_upgrade: bool = false  # 보스 후 카드 강화 대기 여부
var pending_boss_recruit: bool = false  # 보스 후 영웅 영입 대기 여부
var _last_boss_enemy_id: String = ""    # 직전 보스 enemy_id (해금 훅용)
# 보상 씬 TALLY 표시용 — complete_battle에서 채워짐
var last_battle_turns: int = 0
var last_battle_damage: int = 0
var last_battle_gold: int = 0
# ─────────────────────────────────────────────────────

signal state_changed(new_state: GameState)
signal gold_changed(new_gold: int)
signal relic_added(relic: Resource)
signal run_started()
signal node_entered(node_id: int)
signal run_ended(won: bool)

# 테스트 주입용 (production은 항상 null) — RefCounted 테스트에서 SceneTree에
# 매니저 등록 없이 의존성 제공하기 위한 hook.
var _test_tm_override: Object = null
var _test_dm_override: Object = null
var _test_bm_override: Object = null

func _get_tm() -> Object:
	if _test_tm_override:
		return _test_tm_override
	if Engine.has_singleton("TeamManager"):
		return Engine.get_singleton("TeamManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("TeamManager")
	return null

func _get_dm() -> Object:
	if _test_dm_override:
		return _test_dm_override
	if Engine.has_singleton("DeckManager"):
		return Engine.get_singleton("DeckManager")
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("DeckManager")
	return null

func _get_bm() -> Object:
	if _test_bm_override:
		return _test_bm_override
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
	# PASSIVE 렐릭은 즉시 1회 적용 (영구 효과). trigger_relics(PASSIVE) 호출은
	# 기존 보유 PASSIVE 렐릭까지 재적용하므로 방금 추가한 relic만 직접 호출.
	var _RR = load("res://resources/relic_resource.gd")
	if relic.trigger == _RR.TriggerType.PASSIVE:
		_apply_relic_effect(relic, relic.value, {})

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
	battles_completed = 0
	enemies_killed_this_run = 0
	run_map.clear()
	available_node_ids.clear()
	current_node_id = -1
	pending_enemies.clear()
	card_rewards.clear()
	pending_event = null
	pending_event_battle_reward = {}
	run_won = false
	card_rewards_pick_count = 1
	pending_boss_upgrade = false
	pending_boss_recruit = false
	act_mythologies = _get_chapter_mythology_pool(current_chapter)
	act_mythologies.shuffle()

# ── Plan 04: 런 관리 ──────────────────────────────────

func start_run(initial_hero_id: String = "napoleon", chapter: int = 1) -> void:
	current_chapter = chapter
	reset()

	var tm := _get_tm()
	if tm:
		tm.clear()
	var dm := _get_dm()
	if dm:
		dm.clear()

	if _DEBUG_TEST_DECK:
		# 임시 테스트 덱 — 가능한 VFX 최대 커버 (napoleon+joan_of_arc+cleopatra).
		# 못 트리거: ice/lightning/fire (카드 미존재), holy_slash/projectile (musashi/genghis 만).
		for hid: String in ["napoleon", "joan_of_arc", "cleopatra"]:
			var h = _make_hero_by_id(hid)
			if tm:
				tm.add_hero(h)
		if dm:
			var test_cards: Array = [
				# napoleon — slash/blunt/bullet/explosive + block
				_NapoleonCards._strike(),            # slash
				_NapoleonCards._defend(),            # block → defense_buff
				_NapoleonCards._hussar_charge(),     # blunt
				_NapoleonCards._salvo(),             # bullet → bullet_shot
				_NapoleonCards._artillery_volley(),  # explosive
				# joan_of_arc — holy_*/heal/revive/strength
				_JoanCards._holy_smite(),            # holy_strike + vulnerable → debuff_hex
				_JoanCards._holy_bolt(),             # holy_bolt → holy_arrow
				_JoanCards._orleans_charge(),        # holy_blunt
				_JoanCards._saints_flame(),          # holy_fire
				_JoanCards._holy_touch(),            # HEAL → heal_blessing
				_JoanCards._miracle_revive(),        # REVIVE → revive_blessing
				_JoanCards._crusaders_faith(),       # strength power → warrior_buff
				# cleopatra — poison/curse/charm
				_CleopatraCards._venom_needle(),     # poison → poison_splash + poison_tick
				_CleopatraCards._sandstorm(),        # curse + weak → debuff_hex
				_CleopatraCards._cleopatras_kiss(),  # charm → charm_kiss / infatuation (enthrall)
			]
			for card in test_cards:
				dm.add_card_to_deck(card)
	else:
		# 초기 영웅 생성 및 추가
		var hero := _make_hero_by_id(initial_hero_id)
		if tm:
			tm.add_hero(hero)

		# 초기 덱 생성
		_add_initial_deck_for(hero)

	# 맵 생성
	var MapGen = load("res://autoload/map_generator.gd")
	run_map = MapGen.generate(current_act)
	available_node_ids = []
	for node in run_map:
		if node.floor_num == 0:
			available_node_ids.append(node.node_id)
	run_started.emit()

func _make_hero_by_id(hero_id: String) -> Resource:
	return _HeroRegistry.make_hero(hero_id)

func enter_node(node_id: int) -> void:
	if node_id not in available_node_ids:
		return
	var node: Resource = run_map[node_id]
	node.visited = true
	current_node_id = node_id
	current_floor = node.floor_num
	node_entered.emit(node_id)

	match node.room_type:
		_MapNodeRes.RoomType.BATTLE, \
		_MapNodeRes.RoomType.ELITE, \
		_MapNodeRes.RoomType.BOSS:
			pending_enemies = _make_enemies_for_node(node)
			if node.room_type == _MapNodeRes.RoomType.BOSS and pending_enemies.size() > 0:
				_last_boss_enemy_id = pending_enemies[0].enemy_name
			else:
				_last_boss_enemy_id = ""
			change_state(GameState.BATTLE)
			_request_scene("res://scenes/battle/battle_scene.tscn")
		_MapNodeRes.RoomType.REST:
			change_state(GameState.REST)
			_request_scene("res://scenes/rest/rest_scene.tscn")
		_MapNodeRes.RoomType.EVENT:
			pending_event = _get_random_event()
			change_state(GameState.EVENT)
			_request_scene("res://scenes/event/event_scene.tscn")
		_MapNodeRes.RoomType.SHOP:
			change_state(GameState.SHOP)
			_request_scene("res://scenes/shop/shop_scene.tscn")
		_MapNodeRes.RoomType.SECRET:
			_resolve_secret_room()

func complete_battle(won: bool) -> void:
	pending_enemies.clear()
	if won:
		# BattleManager 통계 캡처 (씬 전환 전)
		var bm = _get_bm()
		last_battle_turns  = int(bm.turn_count)  if bm else 0
		last_battle_damage = int(bm.damage_taken_this_battle) if bm else 0
		last_battle_gold = 0
		# 런 카운터 누적 — "점점 강해지는" 렐릭용
		battles_completed += 1
		if bm:
			for _alive in bm._enemy_alive:
				if not _alive:
					enemies_killed_this_run += 1
		# 이벤트 트리거 전투의 추가 보상 (있다면) — 카드 보상 전에 즉시 적용
		_apply_event_battle_reward()
		card_rewards = _generate_card_rewards()
		# 룸 타입별 카드 보상 수량 및 보스 릴릭 처리
		if current_node_id >= 0 and current_node_id < run_map.size():
			var node: Resource = run_map[current_node_id]
			var pm = get_node_or_null("/root/ProgressManager")
			match node.room_type:
				_MapNodeRes.RoomType.ELITE:
					card_rewards_pick_count = 2
					last_battle_gold = randi_range(20, 25)
					add_gold(last_battle_gold)
					if pm:
						pm.increment_flag("elite_kills_total")
						pm.check_unlock_conditions()
				_MapNodeRes.RoomType.BOSS:
					card_rewards_pick_count = 2
					last_battle_gold = 40
					add_gold(last_battle_gold)
					var relic := get_random_relic()
					if relic:
						add_relic(relic)
					if pm and _last_boss_enemy_id != "":
						pm.set_flag("kill_boss:" + _last_boss_enemy_id)
						pm.check_unlock_conditions()
				_MapNodeRes.RoomType.SECRET:
					# 비밀 전투 보상: 기본 카드 픽 + 유물 1개
					card_rewards_pick_count = 1
					var secret_relic := get_random_relic()
					if secret_relic:
						add_relic(secret_relic)
				_:
					card_rewards_pick_count = 1
					last_battle_gold = randi_range(10, 15)
					add_gold(last_battle_gold)
		change_state(GameState.CARD_PICK)
		_request_scene("res://scenes/card_pick/card_pick_scene.tscn")
	else:
		run_won = false
		run_ended.emit(false)
		var _sm_fail = get_node_or_null("/root/SaveManager")
		if _sm_fail:
			_sm_fail.clear_save()
		change_state(GameState.GAME_OVER)
		_request_scene("res://scenes/game_over/game_over_scene.tscn")

func complete_card_pick() -> void:
	card_rewards.clear()
	# current_node_id 유효성 검증 (디버그 메뉴 진입 등으로 -1인 경우 run_map[-1]이
	# 마지막 노드=보스를 가리켜 act 종료가 잘못 발동하는 버그 방지)
	if current_node_id < 0 or current_node_id >= run_map.size():
		change_state(GameState.MAP)
		_request_scene("res://scenes/map/map_scene.tscn")
		return
	var node: Resource = run_map[current_node_id]
	_advance_nodes_from(current_node_id)
	if node.room_type == _MapNodeRes.RoomType.BOSS:
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
	if current_node_id >= 0 and current_node_id < run_map.size():
		_advance_nodes_from(current_node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

# 이벤트 선택지 → 전투 트리거. tier 0=일반, 1=엘리트.
# pending_event는 null로 정리 (이벤트 화면은 이미 닫혔음). 보상은 complete_battle 후 적용.
func start_event_battle(tier: int, reward: Dictionary) -> void:
	pending_event = null
	pending_event_battle_reward = reward
	if tier >= 1:
		pending_enemies = _make_elite_enemies()
	else:
		pending_enemies = _make_normal_enemies()
	_apply_act_difficulty(pending_enemies, current_act)
	_last_boss_enemy_id = ""
	change_state(GameState.BATTLE)
	_request_scene("res://scenes/battle/battle_scene.tscn")

func _apply_event_battle_reward() -> void:
	if pending_event_battle_reward.is_empty():
		return
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var etype: int = int(pending_event_battle_reward.get("effect_type", ChoiceRes.EffectType.NONE))
	var value: int = int(pending_event_battle_reward.get("value", 0))
	var card_id: String = String(pending_event_battle_reward.get("card_id", ""))
	pending_event_battle_reward = {}
	match etype:
		ChoiceRes.EffectType.GOLD:
			add_gold(value)
		ChoiceRes.EffectType.HEAL:
			var tm: Object = _get_tm()
			if tm:
				for hero in tm.heroes:
					tm.heal(hero.hero_id, value)
		ChoiceRes.EffectType.ADD_RELIC:
			var relic := get_random_relic()
			if relic:
				add_relic(relic)
		ChoiceRes.EffectType.ADD_CARD:
			if card_id != "" and ResourceLoader.exists(card_id):
				var card_res: Resource = load(card_id)
				var dm: Object = _get_dm()
				if card_res and dm:
					dm.add_card_to_deck(card_res)
		ChoiceRes.EffectType.DRAW_UP:
			for _i in range(value):
				add_relic(_RelicData.sacred_scroll())
		ChoiceRes.EffectType.REMOVE_CARD:
			var dm_rm: Object = _get_dm()
			if dm_rm:
				dm_rm.remove_random_card()
		_:
			pass

func complete_rest() -> void:
	_advance_nodes_from(current_node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

# ── 비밀룸 ─────────────────────────────────────────────

## 4가지 보상 중 랜덤 1개 지급
## 0: 레어 카드 보상  1: 유물 즉시 지급  2: 골드  3: 비밀 전투
func _resolve_secret_room() -> void:
	var roll := randi() % 4
	match roll:
		0:
			# 카드 보상 — 현재 풀에서 3장 추출 후 카드픽 화면으로 이동
			card_rewards = _generate_card_rewards()
			card_rewards_pick_count = 1
			change_state(GameState.CARD_PICK)
			_request_scene("res://scenes/card_pick/card_pick_scene.tscn")
		1:
			# 유물 즉시 지급 — 비밀룸은 랜덤 유물 바로 획득
			var relic := get_random_relic()
			if relic:
				add_relic(relic)
			_advance_nodes_from(current_node_id)
			change_state(GameState.MAP)
			_request_scene("res://scenes/map/map_scene.tscn")
		2:
			# 골드 100~150
			add_gold(randi_range(100, 150))
			_advance_nodes_from(current_node_id)
			change_state(GameState.MAP)
			_request_scene("res://scenes/map/map_scene.tscn")
		3:
			# 비밀 전투 — 엘리트급 적 1마리, 승리 시 유물 보너스 보장
			pending_enemies = _make_elite_enemies()
			_apply_act_difficulty(pending_enemies, current_act)
			_last_boss_enemy_id = ""
			change_state(GameState.BATTLE)
			_request_scene("res://scenes/battle/battle_scene.tscn")

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
	var tm := _get_tm()
	if tm:
		for h in tm.heroes:
			if h.hero_id == hero_id:
				return
	var hero: Resource = _make_hero_by_id(hero_id)
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
	available_node_ids = []
	for node in run_map:
		if node.floor_num == 0:
			available_node_ids.append(node.node_id)
	change_state(GameState.MAP)
	_request_scene("res://scenes/map/map_scene.tscn")

func _end_run_won() -> void:
	run_won = true
	run_ended.emit(true)
	var _sm = get_node_or_null("/root/SaveManager")
	if _sm:
		_sm.clear_save()
	var _pm = get_node_or_null("/root/ProgressManager")
	if _pm:
		_pm.mark_chapter_cleared(current_chapter)
		_pm.check_unlock_conditions()
	change_state(GameState.GAME_OVER)
	_request_scene("res://scenes/chapter_clear/chapter_clear_scene.tscn")

func upgrade_card(card: Resource) -> void:
	if not card.can_upgrade():
		return
	card.upgrade_level += 1
	var level: int = card.upgrade_level
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")

	var rate: float = 0.0
	match card.rarity:
		CardRes.Rarity.COMMON:     rate = 0.08
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
		EffRes.EffectType.PER_DRAW_DMG,
	]

	var INT_TYPES = [
		EffRes.EffectType.DRAW,
		EffRes.EffectType.ENERGY,
		EffRes.EffectType.GAIN_MORALE,
		EffRes.EffectType.APPLY_STATUS,
		EffRes.EffectType.CHARM,
		EffRes.EffectType.COST_NEXT,
		EffRes.EffectType.SUMMON_TOKEN,
		EffRes.EffectType.ON_KILL_DRAW,
	]

	for effect in card.effects:
		if effect.effect_type in PERCENT_TYPES:
			effect.value = int(effect.base_value * (1.0 + rate * level))
			effect.bonus_value = int(effect.base_bonus_value * (1.0 + rate * level))
		elif effect.effect_type == EffRes.EffectType.APPLY_STATUS and effect.status_type.begins_with("power."):
			effect.value = effect.base_value + level
		elif effect.effect_type in INT_TYPES:
			effect.value = effect.base_value + level
			effect.bonus_value = effect.base_bonus_value + level if effect.base_bonus_value > 0 else 0

func generate_shop_inventory() -> Dictionary:
	var tm := _get_tm()
	var card_pool: Array = []
	if tm:
		for hero in tm.heroes:
			match hero.hero_id:
				"napoleon":    card_pool.append_array(_napoleon_card_pool())
				"cleopatra":   card_pool.append_array(_cleopatra_card_pool())
				"yi_sun_sin":  card_pool.append_array(_yi_sun_sin_card_pool())
				"joan_of_arc": card_pool.append_array(_joan_of_arc_card_pool())
				"genghis_khan": card_pool.append_array(_genghis_khan_card_pool())
				"musashi":     card_pool.append_array(_musashi_card_pool())
	card_pool.shuffle()
	var shop_cards: Array = card_pool.slice(0, min(6, card_pool.size()))
	var card_prices: Array = []
	for card in shop_cards:
		card_prices.append(_shop_price_for_rarity(card.rarity))
	return {
		"cards": shop_cards,
		"card_prices": card_prices,
		"relics": _get_shop_relics(4),
		"relic_price": 150,
		"remove_price": 100,
		"upgrade_price": 150,
		"heal_price": 30,
		"heal_amount": 20,
	}

func _shop_price_for_rarity(rarity: int) -> int:
	match rarity:
		CardResource.Rarity.COMMON:    return 50
		CardResource.Rarity.UNCOMMON:  return 75
		CardResource.Rarity.RARE:      return 120
		CardResource.Rarity.LEGENDARY: return 180
		CardResource.Rarity.DIVINE:    return 250
	return 75

func _get_shop_relics(count: int) -> Array:
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
	available.shuffle()
	return available.slice(0, min(count, available.size()))

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

func _get_chapter_mythology_pool(chapter: int) -> Array[String]:
	if chapter == 1:
		return ["greek", "egyptian", "norse"]
	if chapter == 2:
		var available: Array[String] = []
		if _BuddhistAct1.elites().size() > 0:
			available.append("buddhist")
		if _DaoistAct1.elites().size() > 0:
			available.append("daoist")
		if _JapaneseAct1.elites().size() > 0:
			available.append("japanese")
		if available.is_empty():
			available = ["buddhist"]
		var pool: Array[String] = []
		for i in range(3):
			pool.append(available[i % available.size()])
		return pool
	return ["greek", "egyptian", "norse"]

func _get_mythology_registry() -> Dictionary:
	return {
		"greek":    {"normals": _GreekNormals,    "acts": [_GreekAct1,    _GreekAct2,    _GreekAct3]},
		"egyptian": {"normals": _EgyptianNormals, "acts": [_EgyptianAct1, _EgyptianAct2, _EgyptianAct3]},
		"norse":    {"normals": _NorseNormals,    "acts": [_NorseAct1,    _NorseAct2,    _NorseAct3]},
		"buddhist": {"normals": _BuddhistNormals,  "acts": [_BuddhistAct1,  _BuddhistAct2,  _BuddhistAct3]},
		"daoist":   {"normals": _DaoistNormals,   "acts": [_DaoistAct1,   _DaoistAct2,   _DaoistAct3]},
		"japanese": {"normals": _JapaneseNormals, "acts": [_JapaneseAct1, _JapaneseAct2, _JapaneseAct3]},
	}

func _scene_for(_myth: String, _fn_name: String) -> PackedScene:
	return load("res://characters/enemies/satyr/satyr.tscn")

func _make_normal_enemies() -> Array:
	var myth: String = act_mythologies[current_act - 1]
	var reg: Dictionary = _get_mythology_registry()
	var normals_mod = reg[myth]["normals"]
	var encounters: Array = normals_mod.encounters()
	if encounters.is_empty():
		push_warning("신화 %s 에 일반 인카운터가 없음" % myth)
		return []
	var encounter: Array = _pick_weighted_encounter(encounters, current_floor)
	var result: Array = []
	for fn_name in encounter:
		var scene: PackedScene = _scene_for(myth, fn_name)
		var enemy: Resource = normals_mod.call(fn_name, scene)
		result.append(enemy)
	return result

func _pick_weighted_encounter(encounters: Array, floor_idx: int) -> Array:
	var progress: float = clamp(float(floor_idx) / 9.0, 0.0, 1.0)
	var target: float = progress * float(encounters.size() - 1)
	var weights: Array[float] = []
	for i in range(encounters.size()):
		var dist: float = abs(float(i) - target)
		weights.append(maxf(0.0, 4.0 - dist))
	return _weighted_pick(encounters, weights)

func _weighted_pick(items: Array, weights: Array[float]) -> Variant:
	var total: float = 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return items.pick_random()
	var roll: float = randf() * total
	var cumulative: float = 0.0
	for i in range(items.size()):
		cumulative += weights[i]
		if roll < cumulative:
			return items[i]
	return items[-1]

const _ACT_HP_MULT: Dictionary = {1: 1.0, 2: 1.3, 3: 1.6}
const _ACT_DMG_MULT: Dictionary = {1: 1.0, 2: 1.2, 3: 1.4}

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
	var enemies: Array
	match node.room_type:
		_MapNodeRes.RoomType.BATTLE:
			enemies = _make_normal_enemies()
		_MapNodeRes.RoomType.ELITE:
			enemies = _make_elite_enemies()
		_MapNodeRes.RoomType.BOSS:
			enemies = _make_boss_enemies()
		_:
			enemies = []
	_apply_act_difficulty(enemies, current_act)
	return enemies

func _make_elite_enemies() -> Array:
	var myth: String = act_mythologies[current_act - 1]
	var reg: Dictionary = _get_mythology_registry()
	var act_mod = reg[myth]["acts"][current_act - 1]
	# act_mod이 null이면 해당 신화에 Act 데이터 없음 — 일반 전투로 대체
	if act_mod == null:
		push_warning("신화 %s Act %d 모듈 없음 — 일반 전투로 대체" % [myth, current_act])
		return _make_normal_enemies()
	var elites: Array = act_mod.elites()
	if elites.is_empty():
		push_warning("신화 %s Act %d 엘리트 없음 — 일반 전투로 대체" % [myth, current_act])
		return _make_normal_enemies()
	var fn_name: String = elites.pick_random()
	var scene: PackedScene = _scene_for(myth, fn_name)
	return [act_mod.call(fn_name, scene)]

func _make_boss_enemies() -> Array:
	var myth: String = act_mythologies[current_act - 1]
	var reg: Dictionary = _get_mythology_registry()
	var act_mod = reg[myth]["acts"][current_act - 1]
	# act_mod이 null이면 해당 신화에 Act 데이터 없음
	if act_mod == null:
		push_error("신화 %s Act %d 보스 모듈 없음" % [myth, current_act])
		return []
	var fn_name: String = act_mod.boss()
	if fn_name == "":
		push_error("신화 %s Act %d 보스 없음" % [myth, current_act])
		return []
	var scene: PackedScene = _scene_for(myth, fn_name)
	return [act_mod.call(fn_name, scene)]

func _generate_card_rewards() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	var pool: Array = []
	for hero in tm.heroes:
		match hero.hero_id:
			"napoleon":    pool.append_array(_napoleon_card_pool())
			"cleopatra":   pool.append_array(_cleopatra_card_pool())
			"yi_sun_sin":  pool.append_array(_yi_sun_sin_card_pool())
			"joan_of_arc":   pool.append_array(_joan_of_arc_card_pool())
			"genghis_khan":  pool.append_array(_genghis_khan_card_pool())
			"musashi":       pool.append_array(_musashi_card_pool())
	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func _recruit_hero_pool() -> Array:
	var tm := _get_tm()
	if tm == null:
		return []
	if tm.heroes.size() >= 3:
		return []
	var existing := []
	for h in tm.heroes:
		existing.append(h.hero_id)
	var pm = get_node_or_null("/root/ProgressManager")
	var pool := []
	for hid in _HeroRegistry.all_hero_ids():
		if hid in existing:
			continue
		if pm and not pm.is_hero_unlocked(hid):
			continue
		pool.append(_HeroRegistry.make_hero(hid))
	return pool

func _add_initial_deck_for(hero: Resource) -> void:
	var dm := _get_dm()
	if dm == null:
		return
	var cards: Array = []
	match hero.hero_id:
		"napoleon":    cards = _NapoleonCards.starter_deck()
		"cleopatra":   cards = _CleopatraCards.starter_deck()
		"yi_sun_sin":  cards = _YiSunSinCards.starter_deck()
		"joan_of_arc":  cards = _JoanCards.starter_deck()
		"genghis_khan": cards = _GenghisKhanCards.starter_deck()
		"musashi":      cards = _MusashiCards.starter_deck()
	for card in cards:
		dm.add_card_to_deck(card)

func _napoleon_card_pool() -> Array:
	return _NapoleonCards.pool()

func _cleopatra_card_pool() -> Array:
	return _CleopatraCards.pool()

func _yi_sun_sin_card_pool() -> Array:
	return _YiSunSinCards.pool()

func _joan_of_arc_card_pool() -> Array:
	return _JoanCards.pool()

func _genghis_khan_card_pool() -> Array:
	return _GenghisKhanCards.pool()

func _musashi_card_pool() -> Array:
	return _MusashiCards.pool()

func _get_random_event() -> Resource:
	var pool := _build_event_pool()
	var tm := _get_tm()
	if tm != null and tm.heroes.size() >= 3:
		var filtered := pool.filter(func(ev: Resource) -> bool:
			for c in ev.choices:
				if c.effect_type == c.EffectType.ADD_HERO:
					return false
			return true
		)
		if not filtered.is_empty():
			pool = filtered
	return pool[randi() % pool.size()]

func _build_event_pool() -> Array:
	var myth: String = act_mythologies[current_act - 1]
	match myth:
		"buddhist": return _EventsBuddhist.build_pool()
		"daoist": return _EventsDaoist.build_pool()
		"japanese": return _EventsJapanese.build_pool()
	match current_act:
		2: return _EventsAct2.build_pool()
		3: return _EventsAct3.build_pool()
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
			"parents": node.parents.duplicate(),
			"visited": node.visited,
		})
	return {
		"current_chapter": current_chapter,
		"current_act": current_act,
		"current_floor": current_floor,
		"gold": gold,
		"battles_completed": battles_completed,
		"enemies_killed_this_run": enemies_killed_this_run,
		"current_node_id": current_node_id,
		"available_node_ids": available_node_ids.duplicate(),
		"run_map": map_data,
	}

func from_dict(data: Dictionary) -> void:
	current_chapter = data.get("current_chapter", 1)
	current_act = data.get("current_act", 1)
	current_floor = data.get("current_floor", 0)
	gold = data.get("gold", 0)
	battles_completed = data.get("battles_completed", 0)
	enemies_killed_this_run = data.get("enemies_killed_this_run", 0)
	current_node_id = data.get("current_node_id", -1)
	available_node_ids = data.get("available_node_ids", [])
	run_map.clear()
	for nd in data.get("run_map", []):
		var node: Resource = _MapNodeRes.new()
		node.node_id = nd["node_id"]
		node.floor_num = nd["floor_num"]
		node.column = nd["column"]
		node.room_type = nd["room_type"]
		node.connections = nd["connections"].duplicate()
		node.parents = nd.get("parents", []).duplicate()
		node.visited = nd["visited"]
		run_map.append(node)

func _request_scene(path: String) -> void:
	if is_inside_tree():
		# 맵으로 돌아갈 때 저장
		if path == "res://scenes/map/map_scene.tscn" and not run_map.is_empty():
			var _sm = get_node_or_null("/root/SaveManager")
			if _sm:
				_sm.save()
		var _st := get_node_or_null("/root/SceneTransition")
		if _st:
			_st.go(path)

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
	# 본인 영웅 차례 한정 (PLAYER_TURN_START/END) — owner_hero_id 가 있는 렐릭은 그 영웅 차례에만 발동
	var ctx_hero: String = context.get("hero_id", "")
	for relic in relics:
		# 메인 효과
		if relic.trigger == trigger:
			if ctx_hero != "" and relic.owner_hero_id != "" and relic.owner_hero_id != ctx_hero:
				continue
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
				var _bm_pe := _get_bm()
				if _bm_pe:
					_bm_pe._check_lose_condition()
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
	# condition_value > 0 — 트리거별 발동 조건
	if relic.condition_value > 0:
		if relic.effect_type == RelicRes.EffectType.TIME_HOURGLASS:
			pass  # condition_value 는 hourglass 의 period — 효과 자체에서 처리
		elif relic.trigger == RelicRes.TriggerType.PLAYER_TURN_START:
			# 성스러운 두루마리 — condition_value번째 턴에만 발동
			if context.get("turn", 0) != relic.condition_value:
				return
		else:
			# ON_HERO_DAMAGED — 받은 피해가 condition_value 이상일 때만 발동
			if context.get("amount", 0) < relic.condition_value:
				return
	# is_inside_tree() 가드는 over-defensive. add_relic/trigger_relics는 항상 게임 진행
	# 중에 호출되며 그 시점에 GameManager는 tree에 있음. null 체크만으로 충분.
	# 본인 영웅 차례 (PLAYER_TURN_START/END) — ctx.hero_id 가 있으면 그 영웅에게만, 없으면 전체 (호환)
	var ctx_hero: String = context.get("hero_id", "")
	match relic.effect_type:
		RelicRes.EffectType.HEAL:
			if tm:
				if ctx_hero != "":
					tm.heal(ctx_hero, value)
				else:
					for hero in tm.heroes:
						tm.heal(hero.hero_id, value)
		RelicRes.EffectType.ENERGY:
			if dm:
				if ctx_hero != "":
					dm.add_energy_h(ctx_hero, value)
				else:
					for hid in dm._heroes.keys():
						dm.add_energy_h(hid, value)
		RelicRes.EffectType.DRAW:
			if dm:
				if ctx_hero != "":
					dm.draw_cards_h(ctx_hero, value)
				else:
					dm.draw_cards(value)
		RelicRes.EffectType.BLOCK:
			var bm_block := _get_bm()
			if bm_block and tm:
				if ctx_hero != "":
					bm_block._hero_block[ctx_hero] = bm_block._hero_block.get(ctx_hero, 0) + value
				else:
					for hero in tm.heroes:
						bm_block._hero_block[hero.hero_id] = \
							bm_block._hero_block.get(hero.hero_id, 0) + value
		RelicRes.EffectType.APPLY_STATUS_ENEMY:
			var bm_ase := _get_bm()
			if bm_ase and bm_ase.is_battle_active:
				# relic.status_type 사용. 빈 문자열이면 fallback으로 poison (기존 동작)
				var stype: String = relic.status_type if relic.status_type != "" else "poison"
				for i in range(bm_ase._enemies.size()):
					if bm_ase._enemy_alive[i]:
						bm_ase._apply_status_to_enemy(i, stype, value)
		RelicRes.EffectType.GAIN_MORALE:
			var bm_gm := _get_bm()
			if bm_gm:
				bm_gm._apply_status_to_hero(relic.owner_hero_id, "morale", value)
		RelicRes.EffectType.MAX_HP:
			if tm:
				for hero in tm.heroes:
					tm.increase_max_hp(hero.hero_id, value)
		RelicRes.EffectType.COST_REDUCTION:
			pass  # PASSIVE 릴릭에서 별도 처리
		RelicRes.EffectType.DAMAGE_HERO:
			if tm:
				var living: Array = tm.get_living_heroes()
				if not living.is_empty():
					var target = living[randi() % living.size()]
					tm.take_damage(target.hero_id, value)
					var _bm_re := _get_bm()
					if _bm_re:
						_bm_re._check_lose_condition()
		RelicRes.EffectType.BUFF_SPEED_TEAM:
			# 신속의 인장 — BATTLE_START 시 모든 영웅 power.speed_buff = value (덮어쓰기, 전투 끝까지)
			var bm_bst := _get_bm()
			if bm_bst == null or tm == null:
				return
			for hero in tm.heroes:
				var k_sb: String = "power.speed_buff:" + hero.hero_id
				bm_bst._active_powers[k_sb] = {"value": value, "owner_id": hero.hero_id, "params": {}}
				bm_bst._adjust_turn_queue_for_speed_change("hero:" + hero.hero_id, bm_bst._actor_speed("hero:" + hero.hero_id) - value)
			bm_bst.active_powers_changed.emit()
		RelicRes.EffectType.TIME_HOURGLASS:
			# 시간의 모래시계 — 매 영웅 차례 종료 시 counter++, condition_value 배수 시 모든 영웅 speed_buff += value 누적
			var bm_th := _get_bm()
			if bm_th == null or tm == null:
				return
			bm_th._hourglass_counter += 1
			var period: int = max(1, relic.condition_value)
			if bm_th._hourglass_counter % period == 0:
				for hero in tm.heroes:
					var k_sh: String = "power.speed_buff:" + hero.hero_id
					var cur_sh: int = bm_th._active_powers.get(k_sh, {}).get("value", 0)
					bm_th._active_powers[k_sh] = {"value": cur_sh + value, "owner_id": hero.hero_id, "params": {}}
					var _aid: String = "hero:" + hero.hero_id
					bm_th._adjust_turn_queue_for_speed_change(_aid, bm_th._actor_speed(_aid) - value)
				bm_th.active_powers_changed.emit()
		RelicRes.EffectType.RUN_STRENGTH:
			# "점점 강해지는" 렐릭 — BATTLE_START 시점에 런 카운터를 BM 파워로 세팅.
			# status_type으로 메커니즘 구분. _active_powers는 매 전투 초기화되므로 누적처럼 동작.
			var bm_rs := _get_bm()
			if bm_rs == null or tm == null:
				return
			var amount: int = 0
			var per_hit: bool = false
			match relic.status_type:
				"battles_strength":
					amount = battles_completed * value
				"battles_per_hit":
					amount = battles_completed * value
					per_hit = true
				"kills_strength":
					amount = enemies_killed_this_run * value
			if amount <= 0:
				return
			if per_hit:
				# 카드 히트당 보너스 — 전용 영웅에게만
				if relic.owner_hero_id != "":
					var k_ph: String = "power.bonus_per_hit:" + relic.owner_hero_id
					var cur_ph: int = bm_rs._active_powers.get(k_ph, {}).get("value", 0)
					bm_rs._active_powers[k_ph] = {"value": cur_ph + amount}
			else:
				# 영웅 전체 데미지 보너스
				for hero in tm.heroes:
					var k_sp: String = "power.strength_player:" + hero.hero_id
					var cur_sp: int = bm_rs._active_powers.get(k_sp, {}).get("value", 0)
					bm_rs._active_powers[k_sp] = {"value": cur_sp + amount}

func _build_relic_pool() -> Array:
	return _RelicData.build_pool()
