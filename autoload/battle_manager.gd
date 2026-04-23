# autoload/battle_manager.gd
class_name BattleManagerClass
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

const POISON_DMG_PER_STACK: int = 10
const TOKEN_DMG_PER_STACK: int = 25
const TOKEN_MAX_STACK: int = 6

# 의존성 주입 — 프로덕션: BattleScene이 설정, 테스트: 직접 할당
var team_mgr = null
var deck_mgr = null
var turn_interval: float = 0.0  # BattleScene이 0.2로 설정, 테스트는 기본 0.0 (await 스킵)

# 배틀 상태
var is_battle_active: bool = false
var is_player_turn: bool = false

# 적 상태
var _enemies: Array = []
var _enemy_hp: Array = []
var _enemy_alive: Array = []
var _enemy_block: Array = []
var _enemy_status: Array = []
var _enemy_intent_index: Array = []
var _enemy_phase: Array = []
var _last_attacker: Dictionary = {}

var debug_hero_invincible: bool = false

# 영웅 상태 (HP는 TeamManager가 관리)
var _hero_block: Dictionary = {}
var _hero_status: Dictionary = {}

# 지속 효과 (권능 카드): { "<key>": { "value": int, "owner_id": String, "params": Dictionary }, ... }
var _active_powers: Dictionary = {}

# 이번 플레이어 턴 카드 사용 횟수 (만리 원정용)
var _cards_played_this_turn: int = 0
# 적별 카드 타입 카운터: { enemy_index: { "count": int, "fired_count": int } }
var _enemy_card_counters: Dictionary = {}
var _cards_drawn_this_turn: int = 0
var _kills_this_card: int = 0

signal battle_started()
signal battle_won()
signal battle_lost()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_died(enemy_index: int)
signal enemy_damaged(enemy_index: int, amount: int)
signal hero_damaged(hero_id: String, amount: int)
signal status_applied(target: String, status_type: String, stacks: int)
signal morale_changed(hero_id: String, new_value: int)
signal active_powers_changed()
signal enemy_counter_changed(enemy_index: int)

func setup_battle(enemies: Array) -> void:
	_enemies = enemies.duplicate()
	_enemy_hp.clear()
	_enemy_alive.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_intent_index.clear()
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	_active_powers.clear()
	_enemy_card_counters.clear()
	# 부활 시그널 연결 (중복 방지)
	if team_mgr != null:
		if not team_mgr.hero_revived.is_connected(_on_hero_revived_clear_state):
			team_mgr.hero_revived.connect(_on_hero_revived_clear_state)
	for ei in range(_enemies.size()):
		var trig = _enemies[ei].get("card_count_trigger")
		if trig != null and trig is Dictionary and trig.size() > 0:
			_enemy_card_counters[ei] = {"count": 0, "fired_count": 0}
	for enemy in _enemies:
		_enemy_hp.append(enemy.max_hp)
		_enemy_alive.append(true)
		_enemy_block.append(0)
		var initial_status: Dictionary = {}
		if enemy.charm_resistance > 0:
			initial_status["charm_resistance"] = enemy.charm_resistance
		_enemy_status.append(initial_status)
		_enemy_intent_index.append(0)
	_enemy_phase.clear()
	for _e in _enemies:
		_enemy_phase.append(0)
	is_battle_active = true
	battle_started.emit()
	var _gm_bs = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if _gm_bs and _gm_bs.is_inside_tree():
		var RelicRes = load("res://resources/relic_resource.gd")
		_gm_bs.trigger_relics(RelicRes.TriggerType.BATTLE_START)

func start_player_turn() -> void:
	if not is_battle_active:
		return
	var pre_did: bool = _phase_player_pre()
	if pre_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	_phase_player_main()

func _phase_player_pre() -> bool:
	if team_mgr == null:
		return false
	var did_work: bool = false
	for hero in team_mgr.heroes:
		if not team_mgr.is_alive(hero.hero_id):
			continue
		var token_count: int = _hero_status.get(hero.hero_id, {}).get("tokens", 0)
		if token_count <= 0:
			continue
		for _ti in range(token_count):
			var alive_indices: Array = []
			for ei in range(_enemies.size()):
				if _enemy_alive[ei]:
					alive_indices.append(ei)
			if alive_indices.is_empty():
				break
			var pick: int = alive_indices[randi() % alive_indices.size()]
			_deal_damage_to_enemy(pick, TOKEN_DMG_PER_STACK)
			_last_attacker[pick] = hero.hero_id
			did_work = true
	return did_work

func _phase_player_main() -> void:
	is_player_turn = true
	_cards_played_this_turn = 0
	_cards_drawn_this_turn = 0
	if team_mgr:
		for hero in team_mgr.heroes:
			_hero_block[hero.hero_id] = 0
			for stype: String in ["weak", "vulnerable", "taunt"]:
				var cur: int = _hero_status.get(hero.hero_id, {}).get(stype, 0)
				if cur > 0:
					if not _hero_status.has(hero.hero_id):
						_hero_status[hero.hero_id] = {}
					_hero_status[hero.hero_id][stype] = cur - 1
	_trigger_active_powers("player_turn_start")
	if deck_mgr:
		deck_mgr.start_turn()
	var _gm_pts = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if _gm_pts and _gm_pts.is_inside_tree():
		var RelicRes = load("res://resources/relic_resource.gd")
		_gm_pts.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_START)
	player_turn_started.emit()

func _phase_player_post() -> bool:
	var did_work: bool = false
	for i in range(_enemies.size()):
		if not _enemy_alive[i]:
			continue
		var dmg: int = _enemy_status[i].get("poison_dmg", 0)
		var dur: int = _enemy_status[i].get("poison_dur", 0)
		if dmg > 0 and dur > 0:
			_tick_enemy_poison(i)
			did_work = true
	_check_win_condition()
	return did_work

func play_card(card: Resource, target_enemy_index: int, target_hero_id: String = "") -> bool:
	if not is_player_turn or not is_battle_active:
		return false
	if deck_mgr == null or not deck_mgr.play_card(card):
		return false
	_cards_played_this_turn += 1
	_track_card_type_counters(card)   # 카드 타입 카운터 추적
	_apply_card_effects(card, target_enemy_index, target_hero_id)
	return true

func end_player_turn() -> void:
	if not is_player_turn or not is_battle_active:
		return
	is_player_turn = false
	var _gm_pte = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if _gm_pte and _gm_pte.is_inside_tree():
		var RelicRes = load("res://resources/relic_resource.gd")
		_gm_pte.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_END)
	if deck_mgr:
		deck_mgr.discard_hand()
	var post_did: bool = _phase_player_post()
	if post_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	_execute_enemy_turn()

func _register_power(key: String, owner_id: String, value: int, params: Dictionary = {}) -> void:
	var power_key: String = key + ":" + owner_id
	_active_powers[power_key] = {
		"value": value,
		"owner_id": owner_id,
		"params": params,
	}
	active_powers_changed.emit()

func _trigger_active_powers(phase: String, ctx: Dictionary = {}) -> void:
	for power_key in _active_powers:
		var power: Dictionary = _active_powers[power_key]
		var key: String = power_key.split(":")[0] if ":" in power_key else power_key
		var owner_id: String = power.get("owner_id", "")
		var v: int = power.get("value", 0)
		match key:
			"power.poison_per_turn":
				if phase == "player_turn_start":
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_apply_status_to_enemy(ei, "poison", v)
			"power.block_per_turn":
				if phase == "player_turn_start":
					_hero_block[owner_id] = _hero_block.get(owner_id, 0) + v
			"power.heal_team_per_turn":
				if phase == "player_turn_start" and team_mgr:
					for hero in team_mgr.heroes:
						team_mgr.heal(hero.hero_id, v)
			"power.draw_per_turn":
				if phase == "player_turn_start" and deck_mgr:
					deck_mgr.draw_cards(v)
					_cards_drawn_this_turn += v
			"power.counter_per_attack":
				if phase == "enemy_attack":
					var enemy_idx: int = ctx.get("enemy_index", -1)
					var blk: int = _hero_block.get(owner_id, 0)
					if enemy_idx >= 0 and blk > 0:
						_deal_damage_to_enemy(enemy_idx, int(blk * v / 100.0))
	if phase == "player_turn_start":
		active_powers_changed.emit()

func _track_card_type_counters(card: Resource) -> void:
	for ei in _enemy_card_counters:
		if not _enemy_alive[int(ei)]:
			continue
		var trigger: Dictionary = _enemies[int(ei)].card_count_trigger
		if int(card.card_type) != int(trigger.get("card_type", -1)):
			continue
		var ctr: Dictionary = _enemy_card_counters[ei]
		ctr["count"] += 1
		var threshold: int = trigger.get("threshold", 0)
		var fired: int = ctr.get("fired_count", 0)
		var should_fire: bool = threshold > 0 and ctr["count"] >= threshold * (fired + 1)
		if should_fire and not trigger.get("repeat", true) and fired >= 1:
			should_fire = false
		if should_fire:
			ctr["fired_count"] = fired + 1
			ctr["count"] = 0
			var intent: Resource = trigger.get("intent")
			if intent != null and intent is IntentRes:
				_execute_intent(int(ei), intent)
		enemy_counter_changed.emit(int(ei))

func get_enemy_counter(enemy_index: int) -> Dictionary:
	if not _enemy_card_counters.has(enemy_index):
		return {}
	var ctr: Dictionary = _enemy_card_counters[enemy_index]
	var trigger: Dictionary = _enemies[enemy_index].card_count_trigger
	return {
		"count": ctr.get("count", 0),
		"threshold": trigger.get("threshold", 0),
		"card_type": trigger.get("card_type", -1),
		"intent": trigger.get("intent"),
		"tooltip_key": trigger.get("tooltip_key", ""),
	}

func _apply_card_effects(card: Resource, target_enemy_index: int, target_hero_id: String = "") -> void:
	# 카드 소유 영웅이 사망 상태면 효과 없음
	if team_mgr and not team_mgr.is_alive(card.owner_id):
		return
	_kills_this_card = 0
	for effect in card.effects:
		# condition 필드 평가 — 조건 불충족 시 이 효과 스킵
		if effect.condition != "" and not _evaluate_condition(effect.condition, card):
			continue
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				var dmg: int = effect.value
				var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
				if owner_status.get("weak", 0) > 0:
					dmg = int(dmg * 0.75)
				for _hit in range(effect.hit_count):
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								_deal_damage_to_enemy(i, dmg)
								_last_attacker[i] = card.owner_id
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							_deal_damage_to_enemy(target_enemy_index, dmg)
							_last_attacker[target_enemy_index] = card.owner_id
			EffectRes.EffectType.BLOCK:
				_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + effect.value
			EffectRes.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					_register_power(effect.status_type, card.owner_id, effect.value)
				elif effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_apply_status_to_enemy(i, effect.status_type, effect.value)
				elif effect.target == "SELF":
					_apply_status_to_hero(card.owner_id, effect.status_type, effect.value)
				else:
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_apply_status_to_enemy(target_enemy_index, effect.status_type, effect.value)
			EffectRes.EffectType.DRAW:
				if deck_mgr:
					deck_mgr.draw_cards(effect.value)
					_cards_drawn_this_turn += effect.value
			EffectRes.EffectType.ENERGY:
				if deck_mgr:
					deck_mgr.current_energy += effect.value
					deck_mgr.energy_changed.emit(deck_mgr.current_energy)
			EffectRes.EffectType.HEAL:
				if team_mgr:
					var heal_id: String
					if effect.target == "LOWEST_HP":
						var min_ratio: float = 2.0
						heal_id = card.owner_id
						for hero in team_mgr.get_living_heroes():
							var ratio: float = float(team_mgr.get_current_hp(hero.hero_id)) / float(max(1, hero.max_hp))
							if ratio < min_ratio:
								min_ratio = ratio
								heal_id = hero.hero_id
					else:
						heal_id = target_hero_id if target_hero_id != "" else card.owner_id
					team_mgr.heal(heal_id, effect.value)
			EffectRes.EffectType.GAIN_MORALE:
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				var new_morale: int = _hero_status[card.owner_id].get("morale", 0) + effect.value
				_hero_status[card.owner_id]["morale"] = new_morale
				status_applied.emit(card.owner_id, "morale", effect.value)
				morale_changed.emit(card.owner_id, new_morale)
			EffectRes.EffectType.CHARM:
				if effect.target == "ALL":
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_apply_status_to_enemy(ei, "charm", effect.value)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_apply_status_to_enemy(target_enemy_index, "charm", effect.value)
			EffectRes.EffectType.CONSUME_MORALE:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale >= effect.value:
					var new_morale: int = morale - effect.value
					_hero_status[card.owner_id]["morale"] = new_morale
					morale_changed.emit(card.owner_id, new_morale)
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_deal_damage_to_enemy(target_enemy_index, effect.bonus_value)
					# 나폴레옹 × 클레오파트라 시너지: 소모 성공 시에만 charm 부여
					if card.owner_id == "napoleon" and team_mgr and team_mgr.is_alive("cleopatra"):
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							_apply_status_to_enemy(target_enemy_index, "charm", 1)
					# 황제의 무도 (나폴레옹×무사시): 소모 성공 시 무사시 방어도 +8
					if card.owner_id == "napoleon" and team_mgr and team_mgr.is_alive("musashi"):
						_hero_block["musashi"] = _hero_block.get("musashi", 0) + 8
			EffectRes.EffectType.POISON_BURST:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var pdmg: int = _enemy_status[target_enemy_index].get("poison_dmg", 0)
					if pdmg > 0:
						var burst_dmg: int = pdmg * effect.value / 100 * POISON_DMG_PER_STACK
						_deal_damage_to_enemy(target_enemy_index, burst_dmg)
						_enemy_status[target_enemy_index]["poison_dmg"] = 0
						_enemy_status[target_enemy_index]["poison_dur"] = 0
			EffectRes.EffectType.COUNTER_BLOCK:
				var block: int = _hero_block.get(card.owner_id, 0)
				var dmg: int = int(block * effect.value / 100.0)
				if target_enemy_index >= 0 and dmg > 0:
					_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.BLOCK_ALL:
				if team_mgr:
					for hero in team_mgr.heroes:
						_hero_block[hero.hero_id] = _hero_block.get(hero.hero_id, 0) + effect.value
			EffectRes.EffectType.HEAL_ALL:
				if team_mgr:
					var heal_amt: int = effect.value
					if effect.status_type == "dead_ally_count":
						var dead_count: int = 0
						for hero in team_mgr.heroes:
							if not team_mgr.is_alive(hero.hero_id):
								dead_count += 1
						heal_amt = effect.value * dead_count
					for hero in team_mgr.heroes:
						team_mgr.heal(hero.hero_id, heal_amt)
			EffectRes.EffectType.FORMATION_BLOCK:
				if team_mgr:
					var count: int = team_mgr.get_living_heroes().size()
					_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + count * effect.value
			EffectRes.EffectType.COST_NEXT:
				if deck_mgr:
					deck_mgr.pending_cost_reduction += effect.value
			EffectRes.EffectType.CONDITIONAL_DMG:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					if effect.status_type == "dead_ally_count":
						# 사망 아군 수 × bonus_value + value 피해
						var dead_count: int = 0
						if team_mgr:
							for h in team_mgr.heroes:
								if not team_mgr.is_alive(h.hero_id):
									dead_count += 1
						var total_dmg: int = effect.value + effect.bonus_value * dead_count
						_deal_damage_to_enemy(target_enemy_index, total_dmg)
					else:
						var condition_met: bool
						var es: Dictionary = _enemy_status[target_enemy_index]
						match effect.status_type:
							"morale":
								condition_met = _hero_status.get(card.owner_id, {}).get("morale", 0) > 0
							"has_poison":
								condition_met = es.get("poison_dmg", 0) > 0
							"has_poison_5":
								condition_met = es.get("poison_dmg", 0) >= 5
							"has_poison_10":
								condition_met = es.get("poison_dmg", 0) >= 10
							"has_debuffs_3":
								var dc: int = 0
								for dt: String in ["weak", "vulnerable"]:
									if es.get(dt, 0) > 0:
										dc += 1
								if es.get("poison_dmg", 0) > 0:
									dc += 1
								condition_met = dc >= 3
							"enemy_count_1":
								condition_met = _get_living_enemy_count() == 1
							"hand_size_0":
								condition_met = deck_mgr != null and deck_mgr.hand.size() == 0
							"enemy_hp_below_30":
								var _max_hp_30: int = _enemies[target_enemy_index].max_hp
								condition_met = _max_hp_30 > 0 and float(_enemy_hp[target_enemy_index]) / float(_max_hp_30) <= 0.30
							"enemy_hp_below_50":
								var _max_hp_50: int = _enemies[target_enemy_index].max_hp
								condition_met = _max_hp_50 > 0 and float(_enemy_hp[target_enemy_index]) / float(_max_hp_50) <= 0.50
							"team_hp_below_30":
								var below_30: bool = false
								if team_mgr:
									for h in team_mgr.heroes:
										if team_mgr.is_alive(h.hero_id):
											var ratio: float = float(team_mgr.get_current_hp(h.hero_id)) / float(h.max_hp)
											if ratio <= 0.30:
												below_30 = true
												break
								condition_met = below_30
							_:
								condition_met = es.get(effect.status_type, 0) > 0
						var dmg: int = effect.bonus_value if condition_met else effect.value
						_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.SUMMON_TOKEN:
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				var cur: int = _hero_status[card.owner_id].get("tokens", 0)
				_hero_status[card.owner_id]["tokens"] = min(cur + effect.value, TOKEN_MAX_STACK)
				status_applied.emit(card.owner_id, "tokens", effect.value)
			EffectRes.EffectType.REVIVE:
				if team_mgr:
					var revive_id: String = target_hero_id
					if revive_id == "" or team_mgr.is_alive(revive_id):
						for hero in team_mgr.heroes:
							if not team_mgr.is_alive(hero.hero_id):
								revive_id = hero.hero_id
								break
					if revive_id != "" and not team_mgr.is_alive(revive_id):
						var revive_hero = team_mgr.get_hero(revive_id)
						if revive_hero != null:
							var revive_hp: int = max(1, revive_hero.max_hp * effect.value / 100)
							team_mgr.revive(revive_id, revive_hp)
			EffectRes.EffectType.SACRIFICE_HP:
				if team_mgr:
					team_mgr.take_damage(card.owner_id, effect.value)
			EffectRes.EffectType.COST_ZERO_TURN:
				if deck_mgr:
					deck_mgr.pending_all_cost_zero = true
			EffectRes.EffectType.BLOCK_PER_CARDS_PLAYED:
				var block_amount: int = _cards_played_this_turn * effect.value
				_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + block_amount
			EffectRes.EffectType.ON_KILL_DRAW:
				# 이번 카드로 처치된 적 수만큼 드로우
				if deck_mgr:
					for _i in range(_kills_this_card):
						deck_mgr.draw_cards(effect.value)
						_cards_drawn_this_turn += effect.value
			EffectRes.EffectType.PURGE_STATUS:
				if team_mgr:
					var heroes_to_purge: Array = []
					if effect.target == "ALL":
						heroes_to_purge = team_mgr.heroes
					else:
						for h in team_mgr.heroes:
							if h.hero_id == card.owner_id:
								heroes_to_purge = [h]
								break
					for h in heroes_to_purge:
						if not _hero_status.has(h.hero_id):
							continue
						for debuff in ["weak", "vulnerable", "poison_dmg", "charm"]:
							_hero_status[h.hero_id].erase(debuff)
			EffectRes.EffectType.PER_DRAW_DMG:
				if target_enemy_index >= 0 and _cards_drawn_this_turn > 0:
					var dmg: int = _cards_drawn_this_turn * effect.value
					_deal_damage_to_enemy(target_enemy_index, dmg)
	_apply_synergy_bonus(card, target_enemy_index)

func _deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	if not _enemy_alive[enemy_index]:
		return
	if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var absorbed: int = min(_enemy_block[enemy_index], amount)
	_enemy_block[enemy_index] -= absorbed
	amount -= absorbed
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
	enemy_damaged.emit(enemy_index, amount)
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		_kills_this_card += 1
		enemy_died.emit(enemy_index)
	_check_phase_transition(enemy_index)
	_check_win_condition()

func _deal_damage_to_hero(hero_id: String, amount: int) -> void:
	if debug_hero_invincible:
		return
	if team_mgr == null or not team_mgr.is_alive(hero_id):
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	if status.get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var block: int = _hero_block.get(hero_id, 0)
	var absorbed: int = min(block, amount)
	_hero_block[hero_id] = block - absorbed
	amount -= absorbed
	if amount > 0:
		team_mgr.take_damage(hero_id, amount)
		var _gm_hd = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
		if _gm_hd and _gm_hd.is_inside_tree():
			var RelicRes = load("res://resources/relic_resource.gd")
			_gm_hd.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED,
				{"hero_id": hero_id, "amount": amount})
	hero_damaged.emit(hero_id, amount)
	# 영웅 사망 시 보유 토큰 전멸
	if not team_mgr.is_alive(hero_id) and _hero_status.has(hero_id):
		_hero_status[hero_id]["tokens"] = 0
		status_applied.emit(hero_id, "tokens", 0)
	_check_lose_condition()

func _apply_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
	if status_type == "poison":
		_enemy_status[enemy_index]["poison_dmg"] = _enemy_status[enemy_index].get("poison_dmg", 0) + stacks
		_enemy_status[enemy_index]["poison_dur"] = 3
	elif status_type == "charm":
		var new_charm: int = _enemy_status[enemy_index].get("charm", 0) + stacks
		var threshold: int = 3 + _enemy_status[enemy_index].get("charm_resistance", 0)
		if new_charm >= threshold:
			_enemy_status[enemy_index]["charm"] = 0
			_enemy_status[enemy_index]["enthrall"] = _enemy_status[enemy_index].get("enthrall", 0) + 1
			status_applied.emit("enemy_%d" % enemy_index, "enthrall", 1)
			return
		else:
			_enemy_status[enemy_index]["charm"] = new_charm
	else:
		_enemy_status[enemy_index][status_type] = _enemy_status[enemy_index].get(status_type, 0) + stacks
	status_applied.emit("enemy_%d" % enemy_index, status_type, stacks)

func _apply_status_to_hero(hero_id: String, status_type: String, stacks: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	if status_type == "poison":
		_hero_status[hero_id]["poison_dmg"] = _hero_status[hero_id].get("poison_dmg", 0) + stacks
		_hero_status[hero_id]["poison_dur"] = 3
	else:
		_hero_status[hero_id][status_type] = _hero_status[hero_id].get(status_type, 0) + stacks
	status_applied.emit(hero_id, status_type, stacks)

func _tick_hero_poison(hero_id: String) -> void:
	if debug_hero_invincible:
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	var dmg: int = status.get("poison_dmg", 0)
	var dur: int = status.get("poison_dur", 0)
	if dmg <= 0 or dur <= 0:
		return
	team_mgr.take_damage(hero_id, dmg * POISON_DMG_PER_STACK)
	dur -= 1
	if dur <= 0:
		_hero_status[hero_id]["poison_dmg"] = 0
		_hero_status[hero_id]["poison_dur"] = 0
	else:
		_hero_status[hero_id]["poison_dur"] = dur

func _tick_enemy_poison(enemy_index: int) -> void:
	var dmg: int = _enemy_status[enemy_index].get("poison_dmg", 0)
	var dur: int = _enemy_status[enemy_index].get("poison_dur", 0)
	if dmg <= 0 or dur <= 0:
		return
	var tick_dmg: int = dmg * POISON_DMG_PER_STACK
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - tick_dmg)
	enemy_damaged.emit(enemy_index, tick_dmg)
	dur -= 1
	if dur <= 0:
		_enemy_status[enemy_index]["poison_dmg"] = 0
		_enemy_status[enemy_index]["poison_dur"] = 0
	else:
		_enemy_status[enemy_index]["poison_dur"] = dur
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		enemy_died.emit(enemy_index)
		_check_win_condition()

func _execute_enemy_turn() -> void:
	if not is_battle_active:
		return
	var pre_did: bool = _phase_enemy_pre()
	if pre_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	await _phase_enemy_main()
	if not is_battle_active:
		return
	if turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	var post_did: bool = _phase_enemy_post()
	if post_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	start_player_turn()

func _phase_enemy_pre() -> bool:
	return false

func _phase_enemy_main() -> void:
	enemy_turn_started.emit()
	var first: bool = true
	for i in range(_enemies.size()):
		if not _enemy_alive[i]:
			continue
		if not first and turn_interval > 0.0:
			await get_tree().create_timer(turn_interval).timeout
		first = false
		_enemy_block[i] = 0
		for stype: String in ["weak", "vulnerable"]:
			if _enemy_status[i].get(stype, 0) > 0:
				_enemy_status[i][stype] -= 1
		var charm: int = _enemy_status[i].get("charm", 0)
		var charm_threshold: int = 3 + _enemy_status[i].get("charm_resistance", 0)
		if charm >= charm_threshold:
			_enemy_status[i]["charm"] = 0
			_enemy_status[i]["enthrall"] = _enemy_status[i].get("enthrall", 0) + 1
		var enthrall: int = _enemy_status[i].get("enthrall", 0)
		if enthrall > 0:
			_enemy_status[i]["enthrall"] = enthrall - 1
			var other_targets: Array = []
			for j in range(_enemies.size()):
				if j != i and _enemy_alive[j]:
					other_targets.append(j)
			if not other_targets.is_empty():
				var target_j: int = other_targets[randi() % other_targets.size()]
				var charm_pattern: Array = _get_active_pattern(i)
				if not charm_pattern.is_empty():
					var charm_intent: Resource = charm_pattern[_enemy_intent_index[i]]
					if charm_intent.action_type == IntentRes.ActionType.ATTACK:
						_deal_damage_to_enemy(target_j, charm_intent.value)
			_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % _get_active_pattern(i).size()
			continue
		var pattern: Array = _get_active_pattern(i)
		if pattern.is_empty():
			continue
		var intent: Resource = pattern[_enemy_intent_index[i]]
		_execute_intent(i, intent)
		_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern.size()
	_check_win_condition()
	_check_lose_condition()

func _phase_enemy_post() -> bool:
	if team_mgr == null:
		return false
	var did_work: bool = false
	for hero in team_mgr.heroes:
		if not team_mgr.is_alive(hero.hero_id):
			continue
		var dmg: int = _hero_status.get(hero.hero_id, {}).get("poison_dmg", 0)
		var dur: int = _hero_status.get(hero.hero_id, {}).get("poison_dur", 0)
		if dmg > 0 and dur > 0:
			_tick_hero_poison(hero.hero_id)
			did_work = true
	return did_work

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dmg: int = intent.value
			var strength: int = _enemy_status[enemy_index].get("strength", 0)
			if strength > 0:
				dmg = int(dmg * (1.0 + 0.1 * strength))
			if _enemy_status[enemy_index].get("weak", 0) > 0:
				dmg = int(dmg * 0.75)
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_deal_damage_to_hero(hero.hero_id, dmg)
				_trigger_active_powers("enemy_attack", {"enemy_index": enemy_index, "target_hero_id": ""})
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.ATTACK)
				if target_id != "":
					_deal_damage_to_hero(target_id, dmg)
				_trigger_active_powers("enemy_attack", {"enemy_index": enemy_index, "target_hero_id": target_id})
		IntentRes.ActionType.BUFF:
			if intent.status_type == "block" or intent.status_type == "":
				_enemy_block[enemy_index] += intent.value
			else:
				_apply_status_to_enemy(enemy_index, intent.status_type, intent.value)
		IntentRes.ActionType.DEBUFF:
			var stype: String = intent.status_type
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_apply_status_to_hero(hero.hero_id, stype, intent.value)
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index)
				if target_id != "":
					_apply_status_to_hero(target_id, stype, intent.value)
		IntentRes.ActionType.SPECIAL:
			# 플레이어 덱에서 카드 영구 제거 (손패가 아닌 전체 덱 기준)
			if deck_mgr:
				var full: Array = deck_mgr.get_full_deck()
				for _i in range(intent.value):
					if full.is_empty():
						break
					var idx: int = randi() % full.size()
					deck_mgr.remove_from_deck(full[idx])
					full.remove_at(idx)
		IntentRes.ActionType.PREPARE:
			pass  # 준비 턴 — 아무 효과 없음

func _get_taunting_heroes() -> Array:
	var result: Array = []
	if team_mgr == null:
		return result
	for hero in team_mgr.get_living_heroes():
		var status: Dictionary = _hero_status.get(hero.hero_id, {})
		if status.get("taunt", 0) > 0:
			result.append(hero.hero_id)
	return result

func _pick_highest_hp(hero_ids: Array) -> String:
	if hero_ids.is_empty():
		return ""
	var best_id: String = hero_ids[0]
	var best_hp: int = team_mgr.get_current_hp(best_id)
	for hid in hero_ids:
		var hp: int = team_mgr.get_current_hp(hid)
		if hp > best_hp:
			best_hp = hp
			best_id = hid
	return best_id

func _pick_hero_target(target_type: int, enemy_index: int, action_type: int = -1) -> String:
	if team_mgr == null:
		return ""
	var living: Array = team_mgr.get_living_heroes()
	if living.is_empty():
		return ""
	# 도발 우회: ATTACK 인텐트이면 도발 영웅 강제 선택
	if action_type == IntentRes.ActionType.ATTACK:
		var taunters: Array = _get_taunting_heroes()
		if taunters.size() > 0:
			return _pick_highest_hp(taunters)
	match target_type:
		IntentRes.TargetType.RANDOM:
			return living[randi() % living.size()].hero_id
		IntentRes.TargetType.LOWEST_HP:
			var lowest: Resource = living[0]
			for hero in living:
				if team_mgr.get_current_hp(hero.hero_id) < team_mgr.get_current_hp(lowest.hero_id):
					lowest = hero
			return lowest.hero_id
		IntentRes.TargetType.LAST_ATTACKER:
			var last_id: String = _last_attacker.get(enemy_index, "")
			if last_id != "" and team_mgr.is_alive(last_id):
				return last_id
			return living[randi() % living.size()].hero_id
	return ""

func debug_instant_win() -> void:
	if not is_battle_active:
		return
	for i in range(_enemies.size()):
		if _enemy_alive[i]:
			_enemy_hp[i] = 0
			_enemy_alive[i] = false
			enemy_died.emit(i)
	is_battle_active = false
	battle_won.emit()

func _check_win_condition() -> void:
	if not is_battle_active:
		return
	for alive in _enemy_alive:
		if alive:
			return
	is_battle_active = false
	battle_won.emit()

func _check_lose_condition() -> void:
	if not is_battle_active:
		return
	if team_mgr == null:
		return
	if team_mgr.get_living_heroes().is_empty():
		is_battle_active = false
		battle_lost.emit()

func _get_living_enemy_count() -> int:
	var count: int = 0
	for alive in _enemy_alive:
		if alive:
			count += 1
	return count

func get_enemy_hp(index: int) -> int:
	if index < 0 or index >= _enemy_hp.size():
		return 0
	return _enemy_hp[index]

func get_enemy_block(index: int) -> int:
	if index < 0 or index >= _enemy_block.size():
		return 0
	return _enemy_block[index]

func get_hero_block(hero_id: String) -> int:
	return _hero_block.get(hero_id, 0)

func is_enemy_alive(index: int) -> bool:
	if index < 0 or index >= _enemy_alive.size():
		return false
	return _enemy_alive[index]

func get_enemy_current_intent(index: int) -> Resource:
	if index < 0 or index >= _enemies.size():
		return null
	var pattern: Array = _get_active_pattern(index)
	if pattern.is_empty():
		return null
	return pattern[_enemy_intent_index[index]]

func get_enemy(index: int) -> Resource:
	if index < 0 or index >= _enemies.size():
		return null
	return _enemies[index]

func get_hero_status(hero_id: String) -> Dictionary:
	return _hero_status.get(hero_id, {}).duplicate()

func get_enemy_status(index: int) -> Dictionary:
	if index < 0 or index >= _enemy_status.size():
		return {}
	return _enemy_status[index].duplicate()

func get_active_power(key: String) -> Dictionary:
	return _active_powers.get(key, {}).duplicate()

func get_all_active_powers() -> Dictionary:
	return _active_powers.duplicate()

func clear() -> void:
	_enemies.clear()
	_enemy_hp.clear()
	_enemy_alive.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_intent_index.clear()
	_enemy_phase.clear()
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	is_battle_active = false
	is_player_turn = false

func _on_hero_revived_clear_state(hero_id: String) -> void:
	# 부활 시 블록·상태 초기화 (사망 전 독/출혈/블록 제거)
	_hero_block[hero_id] = 0
	_hero_status[hero_id] = {}

func _evaluate_condition(cond: String, _card: Resource) -> bool:
	match cond:
		"hand_size_0":
			return deck_mgr != null and deck_mgr.hand.size() == 0
		"enemy_count_1":
			return _get_living_enemy_count() == 1
		"team_hp_below_30":
			if team_mgr:
				for h in team_mgr.heroes:
					if team_mgr.is_alive(h.hero_id):
						var ratio: float = float(team_mgr.get_current_hp(h.hero_id)) / float(h.max_hp)
						if ratio <= 0.30:
							return true
			return false
		"dead_ally_any":
			if team_mgr:
				for hero in team_mgr.heroes:
					if not team_mgr.is_alive(hero.hero_id):
						return true
			return false
	return false  # 알 수 없는 조건 키는 조건 불충족으로 처리

func _get_active_pattern(enemy_index: int) -> Array:
	var enemy: Resource = _enemies[enemy_index]
	var phase: int = _enemy_phase[enemy_index]
	if not enemy.phase_patterns.is_empty() and phase < enemy.phase_patterns.size():
		return enemy.phase_patterns[phase]
	return enemy.intent_pattern

func _check_phase_transition(enemy_index: int) -> void:
	if not _enemy_alive[enemy_index]:
		return
	var enemy: Resource = _enemies[enemy_index]
	if enemy.phase_thresholds.is_empty():
		return
	var current_phase: int = _enemy_phase[enemy_index]
	if current_phase >= enemy.phase_thresholds.size():
		return
	var hp_ratio: float = float(_enemy_hp[enemy_index]) / float(enemy.max_hp)
	if hp_ratio <= enemy.phase_thresholds[current_phase]:
		_enemy_phase[enemy_index] += 1
		_enemy_intent_index[enemy_index] = 0
		if enemy.get("phase_heal_ratios") != null and current_phase < enemy.phase_heal_ratios.size():
			var heal_ratio: float = enemy.phase_heal_ratios[current_phase]
			if heal_ratio > 0.0:
				_enemy_hp[enemy_index] = int(enemy.max_hp * heal_ratio)
				enemy_damaged.emit(enemy_index, _enemy_hp[enemy_index])


func _apply_synergy_bonus(card: Resource, target_enemy_index: int) -> void:
	if team_mgr == null:
		return
	var card_owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.GAIN_MORALE:
				# 철벽 진군 (나폴레옹×이순신)
				if card_owner == "napoleon" and team_mgr.is_alive("yi_sun_sin"):
					_hero_block["yi_sun_sin"] = _hero_block.get("yi_sun_sin", 0) + 3
				# 정복자의 기세 (나폴레옹×칭기즈칸)
				if card_owner == "napoleon" and team_mgr.is_alive("genghis_khan"):
					deck_mgr.draw_cards(1)
			EffectRes.EffectType.REVIVE:
				# 성녀의 방패 (잔다르크×이순신)
				if card_owner == "joan_of_arc" and team_mgr.is_alive("yi_sun_sin"):
					_hero_block["yi_sun_sin"] = _hero_block.get("yi_sun_sin", 0) + 20
			EffectRes.EffectType.PURGE_STATUS:
				# 성스러운 독 (잔다르크×클레오파트라)
				if card_owner == "joan_of_arc" and team_mgr.is_alive("cleopatra"):
					var _alive_ei: Array = []
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_alive_ei.append(ei)
					if not _alive_ei.is_empty():
						_apply_status_to_enemy(_alive_ei[randi() % _alive_ei.size()], "poison", 3)
			EffectRes.EffectType.SACRIFICE_HP:
				# 희생의 칼날 (잔다르크×무사시)
				if card_owner == "joan_of_arc" and team_mgr.is_alive("musashi"):
					_hero_block["musashi"] = _hero_block.get("musashi", 0) + 10
			EffectRes.EffectType.DAMAGE:
				# 독침 반격 (이순신×클레오파트라)
				if card_owner == "yi_sun_sin" and team_mgr.is_alive("cleopatra"):
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						if _enemy_status[target_enemy_index].get("poison_dmg", 0) > 0:
							_deal_damage_to_enemy(target_enemy_index, 4)
				# 수륙 협공 (이순신×칭기즈칸): 전체 공격 시 드로우 +1
				if card_owner == "yi_sun_sin" and effect.target == "ALL" and team_mgr.is_alive("genghis_khan"):
					deck_mgr.draw_cards(1)
				# 약탈과 독 (칭기즈칸×클레오파트라): 전체 공격 시 모든 적에 독 +2
				if card_owner == "genghis_khan" and effect.target == "ALL" and team_mgr.is_alive("cleopatra"):
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_apply_status_to_enemy(ei, "poison", 2)
				# 초원의 결투사 (칭기즈칸×무사시): 무사시 공격 시 칭기즈칸 방어도 +4
				if card_owner == "musashi" and team_mgr.is_alive("genghis_khan"):
					_hero_block["genghis_khan"] = _hero_block.get("genghis_khan", 0) + 4
				# 독날 (클레오파트라×무사시): 무사시 공격 시 대상 독 +1
				if card_owner == "musashi" and team_mgr.is_alive("cleopatra"):
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_apply_status_to_enemy(target_enemy_index, "poison", 1)
			EffectRes.EffectType.CONDITIONAL_DMG:
				# 검사의 약속 (무사시×이순신): enemy_count_1 조건 카드 시 이순신 BLOCK +15
				if card_owner == "musashi" and effect.status_type == "enemy_count_1" and team_mgr.is_alive("yi_sun_sin"):
					_hero_block["yi_sun_sin"] = _hero_block.get("yi_sun_sin", 0) + 15
			EffectRes.EffectType.HEAL_ALL:
				# 성전 (잔다르크×나폴레옹): HEAL_ALL 시 나폴레옹 MORALE +2
				if card_owner == "joan_of_arc" and team_mgr.is_alive("napoleon"):
					if not _hero_status.has("napoleon"):
						_hero_status["napoleon"] = {}
					var new_morale: int = _hero_status["napoleon"].get("morale", 0) + 2
					_hero_status["napoleon"]["morale"] = new_morale
					morale_changed.emit("napoleon", new_morale)
				# 신의 원정 (잔다르크×칭기즈칸): HEAL_ALL 시 드로우 +1
				if card_owner == "joan_of_arc" and team_mgr.is_alive("genghis_khan"):
					deck_mgr.draw_cards(1)


func get_active_synergies() -> Array:
	if team_mgr == null:
		return []
	var synergies: Array = []
	var n: bool = team_mgr.is_alive("napoleon")
	var y: bool = team_mgr.is_alive("yi_sun_sin")
	var c: bool = team_mgr.is_alive("cleopatra")
	var j: bool = team_mgr.is_alive("joan_of_arc")
	var g: bool = team_mgr.is_alive("genghis_khan")
	var m: bool = team_mgr.is_alive("musashi")
	if n and y:
		synergies.append({"name_key": "synergy.napoleon_yi.name", "desc_key": "synergy.napoleon_yi.desc"})
	if y and c:
		synergies.append({"name_key": "synergy.yi_cleopatra.name", "desc_key": "synergy.yi_cleopatra.desc"})
	if n and c:
		synergies.append({"name_key": "synergy.napoleon_cleopatra.name", "desc_key": "synergy.napoleon_cleopatra.desc"})
	if j and n:
		synergies.append({"name_key": "synergy.joan_napoleon.name", "desc_key": "synergy.joan_napoleon.desc"})
	if g and c:
		synergies.append({"name_key": "synergy.genghis_cleopatra.name", "desc_key": "synergy.genghis_cleopatra.desc"})
	if m and y:
		synergies.append({"name_key": "synergy.musashi_yi.name", "desc_key": "synergy.musashi_yi.desc"})
	if j and y:
		synergies.append({"name_key": "synergy.joan_yi.name", "desc_key": "synergy.joan_yi.desc"})
	if j and c:
		synergies.append({"name_key": "synergy.joan_cleopatra.name", "desc_key": "synergy.joan_cleopatra.desc"})
	if j and g:
		synergies.append({"name_key": "synergy.joan_genghis.name", "desc_key": "synergy.joan_genghis.desc"})
	if j and m:
		synergies.append({"name_key": "synergy.joan_musashi.name", "desc_key": "synergy.joan_musashi.desc"})
	if n and g:
		synergies.append({"name_key": "synergy.napoleon_genghis.name", "desc_key": "synergy.napoleon_genghis.desc"})
	if n and m:
		synergies.append({"name_key": "synergy.napoleon_musashi.name", "desc_key": "synergy.napoleon_musashi.desc"})
	if y and g:
		synergies.append({"name_key": "synergy.yi_genghis.name", "desc_key": "synergy.yi_genghis.desc"})
	if g and m:
		synergies.append({"name_key": "synergy.genghis_musashi.name", "desc_key": "synergy.genghis_musashi.desc"})
	if c and m:
		synergies.append({"name_key": "synergy.cleopatra_musashi.name", "desc_key": "synergy.cleopatra_musashi.desc"})
	return synergies


func has_synergy_bonus(card: Resource) -> bool:
	if team_mgr == null:
		return false
	var card_owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.GAIN_MORALE:
				if card_owner == "napoleon" and (team_mgr.is_alive("yi_sun_sin") or team_mgr.is_alive("genghis_khan")):
					return true
			EffectRes.EffectType.CONSUME_MORALE:
				if card_owner == "napoleon" and (team_mgr.is_alive("cleopatra") or team_mgr.is_alive("musashi")):
					return true
			EffectRes.EffectType.REVIVE:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("yi_sun_sin"):
					return true
			EffectRes.EffectType.PURGE_STATUS:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("cleopatra"):
					return true
			EffectRes.EffectType.SACRIFICE_HP:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("musashi"):
					return true
			EffectRes.EffectType.DAMAGE:
				if card_owner == "yi_sun_sin" and team_mgr.is_alive("cleopatra"):
					return true
				if card_owner == "yi_sun_sin" and effect.target == "ALL" and team_mgr.is_alive("genghis_khan"):
					return true
				if card_owner == "genghis_khan" and effect.target == "ALL" and team_mgr.is_alive("cleopatra"):
					return true
				if card_owner == "musashi" and (team_mgr.is_alive("genghis_khan") or team_mgr.is_alive("cleopatra")):
					return true
			EffectRes.EffectType.CONDITIONAL_DMG:
				if card_owner == "musashi" and effect.status_type == "enemy_count_1" and team_mgr.is_alive("yi_sun_sin"):
					return true
			EffectRes.EffectType.HEAL_ALL:
				if card_owner == "joan_of_arc" and (team_mgr.is_alive("napoleon") or team_mgr.is_alive("genghis_khan")):
					return true
	return false

func debug_set_enemy_hp(index: int, hp: int) -> void:
	if index < 0 or index >= _enemy_hp.size():
		return
	hp = max(0, hp)
	_enemy_hp[index] = hp
	if hp == 0 and _enemy_alive[index]:
		_enemy_alive[index] = false
		enemy_died.emit(index)
		_check_win_condition()
	elif hp > 0 and not _enemy_alive[index]:
		_enemy_alive[index] = true
	enemy_damaged.emit(index, 0)
	_check_phase_transition(index)
