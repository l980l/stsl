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
	is_battle_active = true
	battle_started.emit()

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
		enemy_died.emit(enemy_index)
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
		var pattern: Array = _enemies[i].intent_pattern
		if pattern.is_empty():
			continue
		var intent: Resource = pattern[_enemy_intent_index[i]]
		_execute_intent(i, intent)
		_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern.size()
	_check_win_condition()
	_check_lose_condition()

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var target_id: String = _pick_hero_target(intent.target, enemy_index)
			if target_id != "":
				var dmg: int = intent.value
				if _enemy_status[enemy_index].get("weak", 0) > 0:
					dmg = int(dmg * 0.75)
				_deal_damage_to_hero(target_id, dmg)
		IntentRes.ActionType.BUFF:
			_enemy_block[enemy_index] += intent.value
		IntentRes.ActionType.DEBUFF:
			var target_id: String = _pick_hero_target(intent.target, enemy_index)
			if target_id != "":
				_apply_status_to_hero(target_id, "weak", intent.value)
		IntentRes.ActionType.SPECIAL:
			pass

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
		IntentRes.TargetType.ALL:
			return living[0].hero_id
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

func is_enemy_alive(index: int) -> bool:
	if index < 0 or index >= _enemy_alive.size():
		return false
	return _enemy_alive[index]

func get_enemy_current_intent(index: int) -> Resource:
	if index < 0 or index >= _enemies.size():
		return null
	var pattern: Array = _enemies[index].intent_pattern
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
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	is_battle_active = false
	is_player_turn = false
