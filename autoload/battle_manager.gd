# autoload/battle_manager.gd
class_name BattleManagerClass
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes  = preload("res://resources/card_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const RelicRes = preload("res://resources/relic_resource.gd")
const InteractionSys = preload("res://autoload/enemy_interaction_system.gd")
const SignatureSys = preload("res://autoload/enemy_signature_system.gd")

const POISON_DMG_PER_STACK: int = 10
const TOKEN_DMG_PER_STACK: int = 25
const TOKEN_MAX_STACK: int = 6
const CHARM_THRESHOLD_BASE: int = 100

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

# 전투 통계 (보상 씬에서 TALLY 표시용)
var turn_count: int = 0
var damage_taken_this_battle: int = 0

# 영웅 상태 (HP는 TeamManager가 관리)
var _hero_block: Dictionary = {}
var _hero_status: Dictionary = {}

# 지속 효과 (권능 카드): { "<key>": { "value": int, "owner_id": String, "params": Dictionary }, ... }
var _active_powers: Dictionary = {}

# DISCARD_PICK_DRAW 모달 대기 중 상태 (빈 Dictionary면 대기 없음)
var _pending_discard_pick: Dictionary = {}

# 이번 플레이어 턴 카드 사용 횟수 (만리 원정용)
var _cards_played_this_turn: int = 0
# 적별 카드 타입 카운터: { enemy_index: { "count": int, "fired_count": int } }
var _enemy_card_counters: Dictionary = {}
var _cards_drawn_this_turn: int = 0
var _kills_this_card: int = 0
var _enthralls_this_card: int = 0
var _in_echo_replay: bool = false

signal battle_started()
signal battle_won()
signal battle_lost()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_died(enemy_index: int)
signal enemy_damaged(enemy_index: int, amount: int, damage_type: String)
signal hero_damaged(hero_id: String, amount: int, damage_type: String)
signal hero_block_gained(hero_id: String, amount: int)
signal status_applied(target: String, status_type: String, stacks: int)
signal morale_changed(hero_id: String, new_value: int)
signal active_powers_changed()
signal enemy_counter_changed(enemy_index: int)
signal card_pick_requested(action: String, draw_count: int)
signal boss_phase_changed(enemy_index: int, new_phase: int)
signal enemy_spawned(enemy_index: int)  # T3-SUMMON: 런타임 적 추가 알림 (UI 갱신용)

func setup_battle(enemies: Array) -> void:
	if deck_mgr != null:
		deck_mgr.consolidate_for_battle()
	turn_count = 0
	damage_taken_this_battle = 0
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
		_gm_bs.trigger_relics(RelicRes.TriggerType.BATTLE_START)

func start_player_turn() -> void:
	if not is_battle_active:
		return
	turn_count += 1
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
	_trigger_active_powers("player_turn_start")
	if deck_mgr:
		deck_mgr.start_turn()
	var _gm_pts = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if _gm_pts and _gm_pts.is_inside_tree():
		_gm_pts.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_START)
	player_turn_started.emit()

func _phase_player_post() -> bool:
	if team_mgr:
		for hero in team_mgr.heroes:
			for stype: String in ["weak", "vulnerable", "taunt"]:
				var cur: int = _hero_status.get(hero.hero_id, {}).get(stype, 0)
				if cur > 0:
					if not _hero_status.has(hero.hero_id):
						_hero_status[hero.hero_id] = {}
					_hero_status[hero.hero_id][stype] = cur - 1
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
		_gm_pte.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_END)
	if deck_mgr:
		deck_mgr.discard_hand()
	var post_did: bool = _phase_player_post()
	if post_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	_execute_enemy_turn()

const DND_KEY := "power.double_next_damage:__global__"

func _consume_double_next_damage(amount: int) -> int:
	if _active_powers.has(DND_KEY):
		amount *= 2
		_active_powers.erase(DND_KEY)
		active_powers_changed.emit()
	return amount

func _apply_discard_pick_reward(draw_count: int, energy_gain: int) -> void:
	if not deck_mgr:
		return
	deck_mgr.draw_cards(draw_count)
	_cards_drawn_this_turn += draw_count
	if energy_gain > 0:
		deck_mgr.current_energy += energy_gain
		deck_mgr.energy_changed.emit(deck_mgr.current_energy)

func _trigger_discard_pick(draw_count: int, energy_gain: int) -> void:
	if not deck_mgr:
		return
	if deck_mgr.hand.is_empty():
		_apply_discard_pick_reward(draw_count, energy_gain)
	else:
		_pending_discard_pick = {"draw_count": draw_count, "energy_gain": energy_gain}
		card_pick_requested.emit("discard", draw_count)

func resolve_pending_discard_pick(picked_card: Resource) -> void:
	if _pending_discard_pick.is_empty():
		return
	var draw_count: int = _pending_discard_pick.get("draw_count", 0)
	var energy_gain: int = _pending_discard_pick.get("energy_gain", 0)
	_pending_discard_pick = {}
	if deck_mgr:
		deck_mgr.discard_card(picked_card)
	_apply_discard_pick_reward(draw_count, energy_gain)

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
			"power.morale_per_turn":
				if phase == "player_turn_start":
					if not _hero_status.has(owner_id):
						_hero_status[owner_id] = {}
					var cur_morale: int = _hero_status[owner_id].get("morale", 0) + v
					_hero_status[owner_id]["morale"] = cur_morale
					morale_changed.emit(owner_id, cur_morale)
			"power.summon_per_turn":
				if phase == "player_turn_start":
					if not _hero_status.has(owner_id):
						_hero_status[owner_id] = {}
					var cur_tok: int = _hero_status[owner_id].get("tokens", 0)
					_hero_status[owner_id]["tokens"] = min(cur_tok + v, TOKEN_MAX_STACK)
					status_applied.emit(owner_id, "tokens", v)
			"power.on_enthrall_strength":
				if phase == "on_enthrall":
					var _oes_id: String = power.get("owner_id", "")
					var cur_str: int = _active_powers.get("power.strength_player:" + _oes_id, {}).get("value", 0)
					_active_powers["power.strength_player:" + _oes_id] = {
						"value": cur_str + v,
						"owner_id": _oes_id,
						"params": {},
					}
					active_powers_changed.emit()
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
		var should_fire: bool = threshold > 0 and ctr["count"] >= threshold
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
	_enthralls_this_card = 0
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
				# power.strength_player: 영웅 측 strength 플랫 보너스
				dmg += _active_powers.get("power.strength_player:" + card.owner_id, {}).get("value", 0)
				# power.bonus_per_hit: 히트당 추가 피해
				var _bph: int = _active_powers.get("power.bonus_per_hit:" + card.owner_id, {}).get("value", 0)
				for _hit in range(effect.hit_count):
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								_deal_damage_to_enemy(i, dmg, effect.damage_type)
								if _bph > 0:
									_deal_damage_to_enemy(i, _bph, effect.damage_type)
								_last_attacker[i] = card.owner_id
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							_deal_damage_to_enemy(target_enemy_index, dmg, effect.damage_type)
							if _bph > 0:
								_deal_damage_to_enemy(target_enemy_index, _bph, effect.damage_type)
							_last_attacker[target_enemy_index] = card.owner_id
				# power.every_nth_attack_bonus: N번째 DAMAGE 효과마다 추가 피해
				for _nth_pk in _active_powers:
					if _nth_pk.begins_with("power.every_nth_attack_bonus:") and _active_powers[_nth_pk].get("owner_id", "") == card.owner_id:
						var _nth: Dictionary = _active_powers[_nth_pk]
						var _interval: int = _nth.get("params", {}).get("bonus_value", 3)
						if _interval <= 0:
							_interval = 3
						if not _nth.has("params"):
							_nth["params"] = {}
						_nth["params"]["count"] = _nth["params"].get("count", 0) + 1
						if _nth["params"]["count"] >= _interval:
							_nth["params"]["count"] = 0
							var _nth_bonus: int = _nth.get("value", 0)
							if _nth_bonus > 0:
								if effect.target == "ALL":
									for i in range(_enemies.size()):
										if _enemy_alive[i]:
											_deal_damage_to_enemy(i, _nth_bonus, effect.damage_type)
								elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
									_deal_damage_to_enemy(target_enemy_index, _nth_bonus, effect.damage_type)
			EffectRes.EffectType.BLOCK:
				_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + effect.value
				hero_block_gained.emit(card.owner_id, effect.value)
			EffectRes.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					var _pw_params: Dictionary = {}
					if effect.bonus_value > 0:
						_pw_params["bonus_value"] = effect.bonus_value
					_register_power(effect.status_type, card.owner_id, effect.value, _pw_params)
				else:
					var _as_stacks: int = effect.value
					# power.debuff_amplify: 약화/취약/독 부여 시 추가 스택
					if effect.status_type in ["weak", "vulnerable", "poison"]:
						_as_stacks += _active_powers.get("power.debuff_amplify:" + card.owner_id, {}).get("value", 0)
					# power.poison_double_application: 독 부여 시 스택 ×2
					if effect.status_type == "poison" and _active_powers.has("power.poison_double_application:" + card.owner_id):
						_as_stacks = _as_stacks * 2
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								_apply_status_to_enemy(i, effect.status_type, _as_stacks)
					elif effect.target == "SELF":
						_apply_status_to_hero(card.owner_id, effect.status_type, _as_stacks)
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							_apply_status_to_enemy(target_enemy_index, effect.status_type, _as_stacks)
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
				var _charm_stacks: int = effect.value
				# power.charm_double_apply: 적용 스택 수 배증
				var _cdbl: int = _active_powers.get("power.charm_double_apply:" + card.owner_id, {}).get("value", 0)
				if _cdbl > 0:
					_charm_stacks = _charm_stacks * (1 + _cdbl)
				if effect.target == "ALL":
					for ei in range(_enemies.size()):
						if not _enemy_alive[ei]:
							continue
						if effect.condition == "enemy_hp_below_50":
							var _max_chp: int = _enemies[ei].max_hp
							if not (_max_chp > 0 and float(_enemy_hp[ei]) / float(_max_chp) <= 0.50):
								continue
						_apply_status_to_enemy(ei, "charm", _charm_stacks)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_apply_status_to_enemy(target_enemy_index, "charm", _charm_stacks)
			EffectRes.EffectType.CONSUME_MORALE:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale >= effect.value:
					var new_morale: int = morale - effect.value
					_hero_status[card.owner_id]["morale"] = new_morale
					morale_changed.emit(card.owner_id, new_morale)
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_deal_damage_to_enemy(target_enemy_index, effect.bonus_value, effect.damage_type)
					# 나폴레옹 × 클레오파트라 시너지: 소모 성공 시에만 charm 부여
					if card.owner_id == "napoleon" and team_mgr and team_mgr.is_alive("cleopatra"):
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							_apply_status_to_enemy(target_enemy_index, "charm", 1)
					# 황제의 무도 (나폴레옹×무사시): 소모 성공 시 무사시 방어도 +8
					if card.owner_id == "napoleon" and team_mgr and team_mgr.is_alive("musashi"):
						_hero_block["musashi"] = _hero_block.get("musashi", 0) + 8
			EffectRes.EffectType.POISON_BURST:
				if effect.target == "ALL":
					for _pbi in range(_enemies.size()):
						if _enemy_alive[_pbi]:
							var _pb_pdmg: int = _enemy_status[_pbi].get("poison_dmg", 0)
							if _pb_pdmg > 0:
								var _pb_dmg: int = _pb_pdmg * effect.value / 100 * POISON_DMG_PER_STACK
								_deal_damage_to_enemy(_pbi, _pb_dmg, effect.damage_type)
								_enemy_status[_pbi]["poison_dmg"] = 0
								_enemy_status[_pbi]["poison_dur"] = 0
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var pdmg: int = _enemy_status[target_enemy_index].get("poison_dmg", 0)
					if pdmg > 0:
						var burst_dmg: int = pdmg * effect.value / 100 * POISON_DMG_PER_STACK
						_deal_damage_to_enemy(target_enemy_index, burst_dmg, effect.damage_type)
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
						_deal_damage_to_enemy(target_enemy_index, total_dmg, effect.damage_type)
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
						_deal_damage_to_enemy(target_enemy_index, dmg, effect.damage_type)
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
					# power.sacrifice_bank: 전투 중 누적 희생 HP 추적
					var _bank_key: String = "power.sacrifice_bank:" + card.owner_id
					if _active_powers.has(_bank_key):
						_active_powers[_bank_key]["value"] += effect.value
					_check_lose_condition()
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
			EffectRes.EffectType.DRAW_PER_ENTHRALL:
				# 이번 카드로 반함 발동 횟수 × value 드로우
				if deck_mgr and _enthralls_this_card > 0:
					var _draw_amt: int = _enthralls_this_card * effect.value
					deck_mgr.draw_cards(_draw_amt)
					_cards_drawn_this_turn += _draw_amt
			EffectRes.EffectType.DAMAGE_PER_CHARMED_ENEMY:
				# charm 스택 보유 적 수 × value 피해
				var _charmed_count: int = 0
				for _cei in range(_enemies.size()):
					if _enemy_alive[_cei] and _enemy_status[_cei].get("charm", 0) > 0:
						_charmed_count += 1
				var _cpce_dmg: int = _charmed_count * effect.value
				if effect.target == "ALL":
					for _cei2 in range(_enemies.size()):
						if _enemy_alive[_cei2]:
							_deal_damage_to_enemy(_cei2, _cpce_dmg, effect.damage_type)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_deal_damage_to_enemy(target_enemy_index, _cpce_dmg, effect.damage_type)
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
			EffectRes.EffectType.DAMAGE_PER_BLOCK:
				var block: int = _hero_block.get(card.owner_id, 0)
				var dmg: int = int(block * effect.value / 100.0)
				if target_enemy_index >= 0 and dmg > 0:
					_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY:
				if target_enemy_index >= 0 and team_mgr:
					var dead_count: int = 0
					for h in team_mgr.heroes:
						if not team_mgr.is_alive(h.hero_id):
							dead_count += 1
					if dead_count > 0:
						_deal_damage_to_enemy(target_enemy_index, dead_count * effect.value, effect.damage_type)
			EffectRes.EffectType.DOUBLE_NEXT_DAMAGE:
				_active_powers[DND_KEY] = {"value": 1, "owner_id": "__global__", "params": {}}
				active_powers_changed.emit()
			EffectRes.EffectType.DISCARD_PICK_DRAW:
				_trigger_discard_pick(effect.value, 1)
			EffectRes.EffectType.MORALE_TO_BLOCK:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale > 0:
					_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + morale * effect.value
			EffectRes.EffectType.DAMAGE_PER_HAND_SIZE:
				if target_enemy_index >= 0 and deck_mgr:
					var hand_size: int = deck_mgr.hand.size()
					if hand_size > 0:
						_deal_damage_to_enemy(target_enemy_index, hand_size * effect.value, effect.damage_type)
			EffectRes.EffectType.DAMAGE_PER_TOKEN:
				var _dpt_tokens: int = _hero_status.get(card.owner_id, {}).get("tokens", 0)
				if _dpt_tokens > 0:
					var _dpt_bonus: int = _active_powers.get("power.token_bonus_dmg:" + card.owner_id, {}).get("value", 0)
					var _dpt_dmg: int = _dpt_tokens * (effect.value + _dpt_bonus)
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								_deal_damage_to_enemy(i, _dpt_dmg, effect.damage_type)
					elif target_enemy_index >= 0:
						_deal_damage_to_enemy(target_enemy_index, _dpt_dmg, effect.damage_type)
			EffectRes.EffectType.HEAL_PER_DEAD_ALLY:
				if team_mgr:
					var dead_count: int = 0
					for h in team_mgr.heroes:
						if not team_mgr.is_alive(h.hero_id):
							dead_count += 1
					if dead_count > 0:
						var heal_amt: int = dead_count * effect.value
						if effect.target == "ALL":
							for hero in team_mgr.heroes:
								team_mgr.heal(hero.hero_id, heal_amt)
						else:
							team_mgr.heal(card.owner_id, heal_amt)
			EffectRes.EffectType.ENERGY_TO_DAMAGE:
				if target_enemy_index >= 0 and deck_mgr:
					var energy: int = deck_mgr.current_energy
					if energy > 0:
						_deal_damage_to_enemy(target_enemy_index, energy * effect.value, effect.damage_type)
						deck_mgr.current_energy = 0
						deck_mgr.energy_changed.emit(0)
			EffectRes.EffectType.STATUS_DOUBLE:
				var sd_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							sd_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					sd_targets = [target_enemy_index]
				for i in sd_targets:
					for key in ["weak", "vulnerable", "poison_dmg", "charm"]:
						var cur: int = _enemy_status[i].get(key, 0)
						if cur > 0:
							_enemy_status[i][key] = cur * 2
							status_applied.emit("enemy_%d" % i, key, cur * 2)
			EffectRes.EffectType.SACRIFICE_PAYOFF:
				var _sbank_key: String = "power.sacrifice_bank:" + card.owner_id
				var _banked: int = _active_powers.get(_sbank_key, {}).get("value", 0)
				if _banked > 0:
					var _payout: int = (_banked / 100) * effect.value
					if _payout > 0:
						if effect.status_type == "block":
							if effect.target == "ALL" and team_mgr:
								for hero in team_mgr.heroes:
									_hero_block[hero.hero_id] = _hero_block.get(hero.hero_id, 0) + _payout
							else:
								_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + _payout
						else:
							if effect.target == "ALL":
								for i in range(_enemies.size()):
									if _enemy_alive[i]:
										_deal_damage_to_enemy(i, _payout, effect.damage_type)
							elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
								_deal_damage_to_enemy(target_enemy_index, _payout, effect.damage_type)
			EffectRes.EffectType.CHARM_TO_DAMAGE:
				var _ctd_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_ctd_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_ctd_targets = [target_enemy_index]
				for i in _ctd_targets:
					var _cstacks: int = _enemy_status[i].get("charm", 0)
					if _cstacks > 0:
						_enemy_status[i]["charm"] = 0
						_deal_damage_to_enemy(i, _cstacks * effect.bonus_value, effect.damage_type)
			EffectRes.EffectType.MULTI_HIT_RANDOM:
				var _mhr_living: Array = []
				for i in range(_enemies.size()):
					if _enemy_alive[i]:
						_mhr_living.append(i)
				for _h in range(effect.hit_count):
					if _mhr_living.is_empty():
						break
					var _rand_e: int = _mhr_living[randi() % _mhr_living.size()]
					_deal_damage_to_enemy(_rand_e, effect.value, effect.damage_type)
					_last_attacker[_rand_e] = card.owner_id
					_mhr_living.clear()
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_mhr_living.append(i)
			EffectRes.EffectType.DAMAGE_PER_STATUS_TYPE:
				var _dpst_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_dpst_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_dpst_targets.append(target_enemy_index)
				for _di in _dpst_targets:
					var _dst: Dictionary = _enemy_status[_di]
					var _types: int = 0
					if _dst.get("weak", 0) > 0: _types += 1
					if _dst.get("vulnerable", 0) > 0: _types += 1
					if _dst.get("poison", 0) > 0: _types += 1
					if _dst.get("charm", 0) > 0: _types += 1
					if _types > 0:
						_deal_damage_to_enemy(_di, _types * effect.value, effect.damage_type)
						_last_attacker[_di] = card.owner_id
	# power.echo_next_attack: 이 ATTACK 카드 효과 전체를 1회 재시전 (재진입 가드)
	if not _in_echo_replay and card.card_type == CardRes.CardType.ATTACK:
		var _echo_key: String = "power.echo_next_attack:" + card.owner_id
		if _active_powers.has(_echo_key):
			_active_powers.erase(_echo_key)
			active_powers_changed.emit()
			_in_echo_replay = true
			for effect in card.effects:
				if effect.condition != "" and not _evaluate_condition(effect.condition, card):
					continue
				match effect.effect_type:
					EffectRes.EffectType.DAMAGE:
						var dmg2: int = effect.value
						var _os2: Dictionary = _hero_status.get(card.owner_id, {})
						if _os2.get("weak", 0) > 0:
							dmg2 = int(dmg2 * 0.75)
						dmg2 += _active_powers.get("power.strength_player:" + card.owner_id, {}).get("value", 0)
						var _bph2: int = _active_powers.get("power.bonus_per_hit:" + card.owner_id, {}).get("value", 0)
						for _eh in range(effect.hit_count):
							if effect.target == "ALL":
								for i in range(_enemies.size()):
									if _enemy_alive[i]:
										_deal_damage_to_enemy(i, dmg2, effect.damage_type)
										if _bph2 > 0:
											_deal_damage_to_enemy(i, _bph2, effect.damage_type)
										_last_attacker[i] = card.owner_id
							else:
								if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
									_deal_damage_to_enemy(target_enemy_index, dmg2, effect.damage_type)
									if _bph2 > 0:
										_deal_damage_to_enemy(target_enemy_index, _bph2, effect.damage_type)
									_last_attacker[target_enemy_index] = card.owner_id
			_in_echo_replay = false
	_apply_synergy_bonus(card, target_enemy_index)

func _deal_damage_to_enemy(enemy_index: int, amount: int, damage_type: String = "") -> void:
	if not _enemy_alive[enemy_index]:
		return
	# T3-WARD: invuln 활성화 시 모든 데미지 무시
	if _enemy_status[enemy_index].get("invuln", 0) > 0:
		enemy_damaged.emit(enemy_index, 0, damage_type)
		return
	amount = _consume_double_next_damage(amount)
	if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var absorbed: int = min(_enemy_block[enemy_index], amount)
	_enemy_block[enemy_index] -= absorbed
	amount -= absorbed
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
	enemy_damaged.emit(enemy_index, amount, damage_type)
	# T3-COUNTER: counter_ratio 설정된 적은 받은 데미지의 N% counter_pool에 누적
	if amount > 0:
		var counter_ratio: float = _enemy_status[enemy_index].get("counter_ratio", 0.0)
		if counter_ratio > 0.0:
			_enemy_status[enemy_index]["counter_pool"] = _enemy_status[enemy_index].get("counter_pool", 0) + int(amount * counter_ratio)
	# 시그니처 hook: 받음 (휴브리스/라그나로크/damage_taken 누적)
	if amount > 0:
		SignatureSys.on_enemy_damaged(self, enemy_index, amount)
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		_kills_this_card += 1
		_fire_death_trigger(enemy_index)
		# 시그니처 hook: 사망 (불교 인과응보)
		SignatureSys.on_enemy_death(self, enemy_index)
		enemy_died.emit(enemy_index)
		for _pke in _active_powers:
			if _pke.split(":")[0] == "power.on_kill_energy":
				if deck_mgr:
					deck_mgr.current_energy += _active_powers[_pke].get("value", 1)
					deck_mgr.energy_changed.emit(deck_mgr.current_energy)
	_check_phase_transition(enemy_index)
	_check_win_condition()

func _deal_damage_to_hero(hero_id: String, amount: int, damage_type: String = "") -> void:
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
		damage_taken_this_battle += amount
		team_mgr.take_damage(hero_id, amount)
		var _gm_hd = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
		if _gm_hd and _gm_hd.is_inside_tree():
			_gm_hd.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED,
				{"hero_id": hero_id, "amount": amount})
	hero_damaged.emit(hero_id, amount, damage_type)
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
		# power.charm_threshold_minus: 임계치 하향 (모든 영웅의 합산)
		var _charm_reduce: int = 0
		for _cpk in _active_powers:
			if _cpk.begins_with("power.charm_threshold_minus:"):
				_charm_reduce += _active_powers[_cpk].get("value", 0)
		var threshold: int = max(1, CHARM_THRESHOLD_BASE + _enemy_status[enemy_index].get("charm_resistance", 0) - _charm_reduce)
		if new_charm >= threshold:
			_enemy_status[enemy_index]["charm"] = 0
			_enemy_status[enemy_index]["enthrall"] = _enemy_status[enemy_index].get("enthrall", 0) + 1
			status_applied.emit("enemy_%d" % enemy_index, "enthrall", 1)
			_enthralls_this_card += 1
			_trigger_active_powers("on_enthrall", {"enemy_index": enemy_index})
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
	var tick_dmg: int = _consume_double_next_damage(dmg * POISON_DMG_PER_STACK)
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - tick_dmg)
	enemy_damaged.emit(enemy_index, tick_dmg, "poison")
	dur -= 1
	if dur <= 0:
		_enemy_status[enemy_index]["poison_dmg"] = 0
		_enemy_status[enemy_index]["poison_dur"] = 0
	else:
		_enemy_status[enemy_index]["poison_dur"] = dur
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		_fire_death_trigger(enemy_index)
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
		# 시그니처 hook: 턴 시작 (휴브리스 pending 처리, 도교 음양, 일본 결계)
		SignatureSys.on_enemy_turn_start(self, i)
		for stype: String in ["weak", "vulnerable"]:
			if _enemy_status[i].get(stype, 0) > 0:
				_enemy_status[i][stype] -= 1
		# T3-WARD: invuln 카운트 매 턴 감소 (만료 시 0)
		if _enemy_status[i].get("invuln", 0) > 0:
			_enemy_status[i]["invuln"] -= 1
		var charm: int = _enemy_status[i].get("charm", 0)
		var _charm_reduce_turn: int = 0
		for _cpk2 in _active_powers:
			if _cpk2.begins_with("power.charm_threshold_minus:"):
				_charm_reduce_turn += _active_powers[_cpk2].get("value", 0)
		var charm_threshold: int = max(1, CHARM_THRESHOLD_BASE + _enemy_status[i].get("charm_resistance", 0) - _charm_reduce_turn)
		if charm >= charm_threshold:
			_enemy_status[i]["charm"] = 0
			_enemy_status[i]["enthrall"] = _enemy_status[i].get("enthrall", 0) + 1
			status_applied.emit("enemy_%d" % i, "enthrall", 1)
			_trigger_active_powers("on_enthrall", {"enemy_index": i})
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
	_check_lose_condition()
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
			# T3-COUNTER: 누적된 counter_pool 가산 후 소진
			var counter_pool: int = _enemy_status[enemy_index].get("counter_pool", 0)
			if counter_pool > 0:
				dmg += counter_pool
				_enemy_status[enemy_index]["counter_pool"] = 0
				_enemy_status[enemy_index]["counter_ratio"] = 0.0
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_deal_damage_to_hero(hero.hero_id, dmg, intent.damage_type)
				_trigger_active_powers("enemy_attack", {"enemy_index": enemy_index, "target_hero_id": ""})
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.ATTACK)
				if target_id != "":
					# T3-MARK: 마킹한 영웅 공격 시 데미지 +50%
					var marked_by: Array = _hero_status.get(target_id, {}).get("marked_by", [])
					if marked_by.has(enemy_index):
						dmg = int(dmg * 1.5)
					_deal_damage_to_hero(target_id, dmg, intent.damage_type)
					# 시그니처 hook: 적의 단일 타겟 공격 (이집트 저주 누적)
					SignatureSys.on_enemy_attack(self, enemy_index, target_id)
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
			_execute_special(enemy_index, intent)
		IntentRes.ActionType.PREPARE:
			pass  # 준비 턴 — 아무 효과 없음
		IntentRes.ActionType.HEAL_ALLY:
			# 동료 1명 HP 회복 (target=LOWEST_HP 우선, 그 외 무작위)
			var target_idx: int = -1
			if intent.target == IntentRes.TargetType.LOWEST_HP:
				target_idx = InteractionSys.pick_lowest_hp_ally(self, enemy_index)
			else:
				target_idx = InteractionSys.pick_random_ally(self, enemy_index)
			if target_idx >= 0:
				InteractionSys.heal_ally(self, enemy_index, target_idx, intent.value)
		IntentRes.ActionType.BUFF_ALLY:
			# 동료 1명에게 status 부여 (strength/block/weak 무관 status_type 따름)
			var target_idx: int = -1
			if intent.target == IntentRes.TargetType.LOWEST_HP:
				target_idx = InteractionSys.pick_lowest_hp_ally(self, enemy_index)
			else:
				target_idx = InteractionSys.pick_random_ally(self, enemy_index)
			if target_idx >= 0:
				InteractionSys.buff_ally(self, enemy_index, target_idx, intent.status_type, intent.value)
		IntentRes.ActionType.COUNTER_PREPARE:
			# T3-COUNTER: 다음 ATTACK까지 받은 데미지의 N% 누적 (intent.value = 퍼센트, 30 = 30%)
			_enemy_status[enemy_index]["counter_ratio"] = float(intent.value) / 100.0
			_enemy_status[enemy_index]["counter_pool"] = 0
		IntentRes.ActionType.MARK_TARGET:
			# T3-MARK: 한 영웅 마킹 — 마킹 동안 그 enemy의 ATTACK +50% 데미지
			var mark_target: String = _pick_hero_target(intent.target, enemy_index)
			if mark_target != "" and team_mgr:
				if not _hero_status.has(mark_target):
					_hero_status[mark_target] = {}
				if not _hero_status[mark_target].has("marked_by"):
					_hero_status[mark_target]["marked_by"] = []
				if not _hero_status[mark_target]["marked_by"].has(enemy_index):
					_hero_status[mark_target]["marked_by"].append(enemy_index)
		IntentRes.ActionType.SACRIFICE:
			# T3-SACRIFICE: 자기 HP -10×value 깎고 strength +value (intent.value = strength gain)
			var hp_cost: int = intent.value * 10
			_enemy_hp[enemy_index] = max(1, _enemy_hp[enemy_index] - hp_cost)
			_apply_status_to_enemy(enemy_index, "strength", intent.value)
			enemy_damaged.emit(enemy_index, hp_cost, "")
		IntentRes.ActionType.WARD:
			# T3-WARD: N턴(intent.value) 동안 자기 invuln (모든 데미지 무시)
			_enemy_status[enemy_index]["invuln"] = intent.value
		IntentRes.ActionType.SUMMON:
			# T3-SUMMON: 같은 mythology 의 normals 모듈에서 팩토리 호출, value 마릿수 spawn
			# intent.status_type = 팩토리 함수 이름 (예: "scarab")
			var src: Resource = _enemies[enemy_index]
			var factory_name: String = intent.status_type
			if factory_name == "" or src == null or src.mythology == "":
				push_warning("[battle_manager] SUMMON 누락: factory_name 또는 mythology 미설정")
			else:
				var module_path: String = "res://resources/enemies/%s/%s_normals.gd" % [src.mythology, src.mythology]
				var module: GDScript = load(module_path)
				if module != null:
					for _i in range(max(1, intent.value)):
						var spawned: Resource = module.call(factory_name, null)
						if spawned != null:
							_add_enemy_to_battle(spawned)

# T3-SUMMON: 런타임에 적 1마리를 전투에 추가. 모든 _enemy_* 배열 동기화 + 시그널 발화.
func _add_enemy_to_battle(enemy: Resource) -> void:
	if enemy == null:
		return
	_enemies.append(enemy)
	_enemy_alive.append(true)
	_enemy_hp.append(enemy.max_hp)
	_enemy_block.append(0)
	_enemy_status.append({})
	_enemy_phase.append(0)
	_enemy_intent_index.append(0)
	enemy_spawned.emit(_enemies.size() - 1)

# DEATH-RATTLE: 사망 직후 1회 실행. 자기 자신은 이미 _enemy_alive=false 상태이므로
# BUFF_ALLY 등 동료 효과는 자신을 제외한 살아있는 동료에게만 적용됨.
func _fire_death_trigger(enemy_index: int) -> void:
	var enemy: Resource = _enemies[enemy_index]
	if enemy.get("death_trigger") == null:
		return
	_execute_intent(enemy_index, enemy.death_trigger)

# SPECIAL 액션 분기 — status_type 으로 변종 식별.
# 하위 호환: IntentResource.status_type 기본값 "weak"는 DEBUFF용으로, SPECIAL에선 미설정과 동일 취급 → remove_card.
func _execute_special(_enemy_index: int, intent: Resource) -> void:
	var variant: String = intent.status_type
	if variant == "" or variant == "weak":
		variant = "remove_card"
	match variant:
		"remove_card":
			# 플레이어 덱에서 카드 영구 제거 (손패가 아닌 전체 덱 기준)
			if deck_mgr:
				var full: Array = deck_mgr.get_full_deck()
				for _i in range(intent.value):
					if full.is_empty():
						break
					var idx: int = randi() % full.size()
					deck_mgr.remove_from_deck(full[idx])
					full.remove_at(idx)
		_:
			push_warning("[battle_manager] 알 수 없는 SPECIAL variant: %s" % variant)

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
	turn_count = 0
	damage_taken_this_battle = 0

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
		"not_enemy_count_1":
			return _get_living_enemy_count() != 1
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
		boss_phase_changed.emit(enemy_index, _enemy_phase[enemy_index])
		if enemy.get("phase_heal_ratios") != null and current_phase < enemy.phase_heal_ratios.size():
			var heal_ratio: float = enemy.phase_heal_ratios[current_phase]
			if heal_ratio > 0.0:
				_enemy_hp[enemy_index] = int(enemy.max_hp * heal_ratio)
				enemy_damaged.emit(enemy_index, _enemy_hp[enemy_index], "")
		# Phase 전환 시 자동 status 부여 (광폭화·디스트레스 등)
		if enemy.get("phase_buffs") != null and current_phase < enemy.phase_buffs.size():
			var buffs: Array = enemy.phase_buffs[current_phase]
			for buff in buffs:
				_apply_status_to_enemy(enemy_index, buff.get("status", ""), int(buff.get("value", 0)))


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

func debug_add_dummy_enemy(max_count: int = 6) -> bool:
	if _enemies.size() >= max_count:
		return false
	var e := EnemyResource.new()
	e.enemy_name = "debug.dummy_enemy"
	e.max_hp = 100
	_enemies.append(e)
	_enemy_hp.append(e.max_hp)
	_enemy_alive.append(true)
	_enemy_block.append(0)
	_enemy_status.append({})
	_enemy_intent_index.append(0)
	_enemy_phase.append(0)
	return true

func debug_add_dummy_token(hero_id: String) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	var cur: int = _hero_status[hero_id].get("tokens", 0)
	_hero_status[hero_id]["tokens"] = min(cur + 1, TOKEN_MAX_STACK)

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
	enemy_damaged.emit(index, 0, "")
	_check_phase_transition(index)
