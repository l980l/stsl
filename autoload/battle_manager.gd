# autoload/battle_manager.gd
class_name BattleManagerClass
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# 의존성 주입 — 프로덕션: BattleScene이 설정, 테스트: 직접 할당
var team_mgr = null
var deck_mgr = null

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

# 영웅 상태 (HP는 TeamManager가 관리)
var _hero_block: Dictionary = {}
var _hero_status: Dictionary = {}

signal battle_started()
signal battle_won()
signal battle_lost()
signal player_turn_started()
signal enemy_turn_started()
signal enemy_died(enemy_index: int)
signal enemy_damaged(enemy_index: int, amount: int)
signal hero_damaged(hero_id: String, amount: int)
signal status_applied(target: String, status_type: String, stacks: int)

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
	for enemy in _enemies:
		_enemy_hp.append(enemy.max_hp)
		_enemy_alive.append(true)
		_enemy_block.append(0)
		_enemy_status.append({})
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
	is_player_turn = true
	if team_mgr:
		for hero in team_mgr.heroes:
			_hero_block[hero.hero_id] = 0
			_tick_hero_poison(hero.hero_id)
	if deck_mgr:
		deck_mgr.start_turn()
	var _gm_pts = Engine.get_singleton("GameManager") if Engine.has_singleton("GameManager") else null
	if _gm_pts and _gm_pts.is_inside_tree():
		var RelicRes = load("res://resources/relic_resource.gd")
		_gm_pts.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_START)
	player_turn_started.emit()

func play_card(card: Resource, target_enemy_index: int) -> bool:
	if not is_player_turn or not is_battle_active:
		return false
	if deck_mgr == null or not deck_mgr.play_card(card):
		return false
	_apply_card_effects(card, target_enemy_index)
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
	_execute_enemy_turn()

func _apply_card_effects(card: Resource, target_enemy_index: int) -> void:
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				var dmg: int = effect.value
				var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
				if owner_status.get("weak", 0) > 0:
					dmg = int(dmg * 0.75)
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
				if effect.target == "ALL":
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
			EffectRes.EffectType.ENERGY:
				if deck_mgr:
					deck_mgr.current_energy += effect.value
					deck_mgr.energy_changed.emit(deck_mgr.current_energy)
			EffectRes.EffectType.HEAL:
				if team_mgr:
					team_mgr.heal(card.owner_id, effect.value)
			EffectRes.EffectType.GAIN_MORALE:
				var cur: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				_hero_status[card.owner_id]["morale"] = cur + effect.value
				status_applied.emit(card.owner_id, "morale", effect.value)
			EffectRes.EffectType.CONSUME_MORALE:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale >= effect.value:
					_hero_status[card.owner_id]["morale"] = morale - effect.value
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_deal_damage_to_enemy(target_enemy_index, effect.bonus_value)
			EffectRes.EffectType.POISON_BURST:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var poison: int = _enemy_status[target_enemy_index].get("poison", 0)
					if poison > 0:
						_deal_damage_to_enemy(target_enemy_index, poison)
						_enemy_status[target_enemy_index]["poison"] = 0
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
					for hero in team_mgr.heroes:
						team_mgr.heal(hero.hero_id, effect.value)
			EffectRes.EffectType.FORMATION_BLOCK:
				if team_mgr:
					var count: int = team_mgr.get_living_heroes().size()
					_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + count * effect.value
			EffectRes.EffectType.CONDITIONAL_DMG:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var has_status: bool = _enemy_status[target_enemy_index].get(effect.status_type, 0) > 0
					var dmg: int = effect.bonus_value if has_status else effect.value
					_deal_damage_to_enemy(target_enemy_index, dmg)

func _deal_damage_to_enemy(enemy_index: int, amount: int) -> void:
	if not _enemy_alive[enemy_index]:
		return
	if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
		amount = int(amount * 1.5)
	var absorbed: int = min(_enemy_block[enemy_index], amount)
	_enemy_block[enemy_index] -= absorbed
	amount -= absorbed
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
	if amount > 0:
		enemy_damaged.emit(enemy_index, amount)
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		enemy_died.emit(enemy_index)
	_check_phase_transition(enemy_index)
	_check_win_condition()

func _deal_damage_to_hero(hero_id: String, amount: int) -> void:
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
	_check_lose_condition()

func _apply_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
	_enemy_status[enemy_index][status_type] = \
		_enemy_status[enemy_index].get(status_type, 0) + stacks
	status_applied.emit("enemy_%d" % enemy_index, status_type, stacks)

func _apply_status_to_hero(hero_id: String, status_type: String, stacks: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	_hero_status[hero_id][status_type] = _hero_status[hero_id].get(status_type, 0) + stacks
	status_applied.emit(hero_id, status_type, stacks)

func _tick_hero_poison(hero_id: String) -> void:
	var status: Dictionary = _hero_status.get(hero_id, {})
	var poison: int = status.get("poison", 0)
	if poison <= 0:
		return
	team_mgr.take_damage(hero_id, poison)
	_hero_status[hero_id]["poison"] = max(0, poison - 1)

func _tick_enemy_poison(enemy_index: int) -> void:
	var poison: int = _enemy_status[enemy_index].get("poison", 0)
	if poison <= 0:
		return
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - poison)
	enemy_damaged.emit(enemy_index, poison)
	_enemy_status[enemy_index]["poison"] = poison - 1
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		enemy_died.emit(enemy_index)
		_check_win_condition()

func _execute_enemy_turn() -> void:
	enemy_turn_started.emit()
	for i in range(_enemies.size()):
		if not _enemy_alive[i]:
			continue
		_enemy_block[i] = 0
		_tick_enemy_poison(i)
		if not _enemy_alive[i]:
			continue
		var pattern: Array = _get_active_pattern(i)
		if pattern.is_empty():
			continue
		var intent: Resource = pattern[_enemy_intent_index[i]]
		_execute_intent(i, intent)
		_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern.size()
	_check_win_condition()
	_check_lose_condition()
	if is_battle_active:
		start_player_turn()

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dmg: int = intent.value
			if _enemy_status[enemy_index].get("weak", 0) > 0:
				dmg = int(dmg * 0.75)
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						_deal_damage_to_hero(hero.hero_id, dmg)
			else:
				var target_id: String = _pick_hero_target(intent.target, enemy_index)
				if target_id != "":
					_deal_damage_to_hero(target_id, dmg)
		IntentRes.ActionType.BUFF:
			_enemy_block[enemy_index] += intent.value
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
			if deck_mgr:
				deck_mgr.discard_random(intent.value)

func _pick_hero_target(target_type: int, enemy_index: int) -> String:
	if team_mgr == null:
		return ""
	var living: Array = team_mgr.get_living_heroes()
	if living.is_empty():
		return ""
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
