# autoload/battle_manager_v2.gd
# 개체별 턴 시스템 프로토타입 — speed 기반 turn queue + 영웅/적 개체별 차례.
# 기존 BattleManager 와 별개. 핵심 카드 효과 (DAMAGE/BLOCK/APPLY_STATUS/HEAL) +
# 적 인텐트 (ATTACK/BUFF/DEBUFF) 만 처리. 렐릭/시너지/페이즈/시그니처 등 제외.
class_name BattleManagerV2Class
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# 액터 식별: "hero:<id>" 또는 "enemy:<index>"
var _heroes: Array = []            # HeroResource[]
var _enemies: Array = []           # EnemyResource[]
var _hero_hp: Dictionary = {}      # hero_id → int
var _hero_block: Dictionary = {}   # hero_id → int
var _hero_status: Dictionary = {}  # hero_id → Dictionary (weak/vulnerable/strength)
var _enemy_hp: Array = []
var _enemy_block: Array = []
var _enemy_status: Array = []      # [Dictionary, ...]
var _enemy_alive: Array = []
var _enemy_intent_index: Array = []  # 각 적 다음 인텐트 인덱스

var _turn_queue: Array = []        # [actor_id, ...]
var _current_actor: String = ""
var _round_num: int = 0
var _battle_active: bool = false

# 디버그 토글 — battle_scene_v2 의 디버그 패널에서 변경
var debug_invincible: bool = false        # 영웅 무적 (피해 0 처리)
var debug_unlimited_energy: bool = false  # 에너지 무한 (자기 영웅 cost 무시)

signal battle_started()
signal battle_won()
signal battle_lost()
signal round_started(round_num: int)
signal turn_started(actor_id: String)
signal turn_ended(actor_id: String)
signal queue_changed()
signal hero_damaged(hero_id: String, amount: int)
signal hero_healed(hero_id: String, amount: int)
signal hero_died(hero_id: String)
signal enemy_damaged(enemy_index: int, amount: int)
signal enemy_died(enemy_index: int)
signal status_applied(actor_id: String, status_type: String, stacks: int)

func setup(heroes: Array, enemies: Array) -> void:
	_heroes = heroes
	_enemies = enemies
	_hero_hp.clear()
	_hero_block.clear()
	_hero_status.clear()
	for h in heroes:
		_hero_hp[h.hero_id] = h.max_hp
		_hero_block[h.hero_id] = 0
		_hero_status[h.hero_id] = {}
	_enemy_hp.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_alive.clear()
	_enemy_intent_index.clear()
	for e in enemies:
		_enemy_hp.append(e.max_hp)
		_enemy_block.append(0)
		_enemy_status.append({})
		_enemy_alive.append(true)
		_enemy_intent_index.append(0)
	_round_num = 0
	_battle_active = true

func start_battle() -> void:
	battle_started.emit()
	_start_round()

func _start_round() -> void:
	_round_num += 1
	round_started.emit(_round_num)
	# 영웅 블록 0, 적 블록 0 (라운드 시작에 리셋)
	for hid in _hero_hp.keys():
		_hero_block[hid] = 0
	for i in range(_enemy_block.size()):
		_enemy_block[i] = 0
	_build_turn_queue()
	_advance_turn()

func _build_turn_queue() -> void:
	# 살아있는 영웅 + 적을 speed 내림차순. 동률은 영웅 우선.
	var entries: Array = []  # [{actor_id, speed, kind}]
	for h in _heroes:
		if _hero_hp.get(h.hero_id, 0) > 0:
			entries.append({"actor": "hero:" + h.hero_id, "speed": h.speed, "kind": 0})
	for i in range(_enemies.size()):
		if _enemy_alive[i]:
			entries.append({"actor": "enemy:" + str(i), "speed": _enemies[i].speed, "kind": 1})
	entries.sort_custom(func(a, b):
		if a["speed"] != b["speed"]:
			return a["speed"] > b["speed"]
		return a["kind"] < b["kind"]
	)
	_turn_queue.clear()
	for e in entries:
		_turn_queue.append(e["actor"])
	queue_changed.emit()

func _advance_turn() -> void:
	if not _battle_active:
		return
	# 사망 처리 — 큐에서 죽은 액터 제거
	_turn_queue = _turn_queue.filter(_is_actor_alive)
	queue_changed.emit()
	if _turn_queue.is_empty():
		_start_round()
		return
	_current_actor = _turn_queue.pop_front()
	turn_started.emit(_current_actor)
	if _current_actor.begins_with("hero:"):
		var hid: String = _current_actor.substr(5)
		# 본인 차례 시작 시 status 카운트다운 -1
		_decrement_status("hero:" + hid)
		_check_poison_tick_hero(hid)
		DeckManagerV2.start_hero_turn(hid)
	else:
		var idx: int = _current_actor.substr(6).to_int()
		_decrement_status("enemy:" + str(idx))
		_check_poison_tick_enemy(idx)
		_execute_enemy_turn(idx)
		# 적 차례 자동 종료
		end_current_turn()

func _is_actor_alive(actor_id: String) -> bool:
	if actor_id.begins_with("hero:"):
		var hid: String = actor_id.substr(5)
		return _hero_hp.get(hid, 0) > 0
	else:
		var idx: int = actor_id.substr(6).to_int()
		return idx < _enemy_alive.size() and _enemy_alive[idx]

func end_current_turn() -> void:
	if not _battle_active:
		return
	var actor: String = _current_actor
	if actor.begins_with("hero:"):
		var hid: String = actor.substr(5)
		DeckManagerV2.end_hero_turn(hid)
	turn_ended.emit(actor)
	_current_actor = ""
	_advance_turn()

# 영웅이 카드 사용 — battle_scene_v2 가 호출
func play_card(card: Resource, target_enemy_index: int = -1, target_hero_id: String = "") -> bool:
	if not _current_actor.begins_with("hero:"):
		return false
	var hid: String = _current_actor.substr(5)
	if not DeckManagerV2.can_play(hid, card):
		return false
	if not DeckManagerV2.play_card(hid, card):
		return false
	_apply_card_effects(hid, card, target_enemy_index, target_hero_id)
	_check_battle_end()
	return true

func _apply_card_effects(caster_hero: String, card: Resource, target_enemy: int, target_hero: String) -> void:
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				_apply_damage(caster_hero, effect, target_enemy)
			EffectRes.EffectType.BLOCK:
				_add_block_hero(caster_hero, effect.value)
			EffectRes.EffectType.BLOCK_ALL:
				for h in _heroes:
					if _hero_hp.get(h.hero_id, 0) > 0:
						_add_block_hero(h.hero_id, effect.value)
			EffectRes.EffectType.HEAL:
				var tgt_hid: String = caster_hero if effect.target == "SELF" else target_hero
				if tgt_hid != "":
					_heal_hero(tgt_hid, effect.value)
			EffectRes.EffectType.HEAL_ALL:
				for h in _heroes:
					if _hero_hp.get(h.hero_id, 0) > 0:
						_heal_hero(h.hero_id, effect.value)
			EffectRes.EffectType.APPLY_STATUS:
				_apply_status_effect(caster_hero, effect, target_enemy)

func _apply_damage(caster_hero: String, effect: Resource, target_enemy: int) -> void:
	var dmg: int = effect.value
	var owner_status: Dictionary = _hero_status.get(caster_hero, {})
	if owner_status.get("weak", 0) > 0:
		dmg = int(dmg * 0.75)
	dmg += owner_status.get("strength", 0)
	var targets: Array = []
	if effect.target == "ALL":
		for i in range(_enemies.size()):
			if _enemy_alive[i]:
				targets.append(i)
	elif target_enemy >= 0 and target_enemy < _enemies.size() and _enemy_alive[target_enemy]:
		targets.append(target_enemy)
	for ti in targets:
		var t_dmg: int = dmg
		if _enemy_status[ti].get("vulnerable", 0) > 0:
			t_dmg = int(t_dmg * 1.5)
		for _hit in range(effect.hit_count):
			_damage_enemy(ti, t_dmg)
			if not _enemy_alive[ti]:
				break

func _damage_enemy(idx: int, raw: int) -> void:
	if not _enemy_alive[idx] or raw <= 0:
		return
	var blk: int = _enemy_block[idx]
	var after_block: int = max(0, raw - blk)
	_enemy_block[idx] = max(0, blk - raw)
	_enemy_hp[idx] = max(0, _enemy_hp[idx] - after_block)
	enemy_damaged.emit(idx, after_block)
	if _enemy_hp[idx] == 0:
		_enemy_alive[idx] = false
		enemy_died.emit(idx)

func _damage_hero(hid: String, raw: int) -> void:
	if _hero_hp.get(hid, 0) <= 0 or raw <= 0:
		return
	if debug_invincible:
		return
	var blk: int = _hero_block.get(hid, 0)
	var after_block: int = max(0, raw - blk)
	_hero_block[hid] = max(0, blk - raw)
	_hero_hp[hid] = max(0, _hero_hp[hid] - after_block)
	hero_damaged.emit(hid, after_block)
	if _hero_hp[hid] == 0:
		hero_died.emit(hid)

func _add_block_hero(hid: String, amount: int) -> void:
	_hero_block[hid] = _hero_block.get(hid, 0) + amount

func _heal_hero(hid: String, amount: int) -> void:
	if _hero_hp.get(hid, 0) <= 0:
		return
	var hero: Resource = _get_hero_by_id(hid)
	if hero == null:
		return
	var prev: int = _hero_hp[hid]
	_hero_hp[hid] = min(hero.max_hp, prev + amount)
	hero_healed.emit(hid, _hero_hp[hid] - prev)

func _apply_status_effect(caster_hero: String, effect: Resource, target_enemy: int) -> void:
	# power.* (strength_player 등) — caster 영웅에 power 적용 (간략화: status 로 저장)
	if effect.status_type.begins_with("power."):
		var key: String = effect.status_type.replace("power.", "")
		if key == "strength_player":
			_hero_status[caster_hero]["strength"] = _hero_status[caster_hero].get("strength", 0) + effect.value
			status_applied.emit("hero:" + caster_hero, "strength", effect.value)
		return
	# weak/vulnerable/poison/strength → SELF/ALLY/SINGLE/ALL 분기
	if effect.target == "SELF":
		_add_status_hero(caster_hero, effect.status_type, effect.value)
	elif effect.target == "ALL":
		for i in range(_enemies.size()):
			if _enemy_alive[i]:
				_add_status_enemy(i, effect.status_type, effect.value)
	else:
		if target_enemy >= 0 and target_enemy < _enemies.size() and _enemy_alive[target_enemy]:
			_add_status_enemy(target_enemy, effect.status_type, effect.value)

func _add_status_hero(hid: String, stype: String, stacks: int) -> void:
	_hero_status[hid][stype] = _hero_status[hid].get(stype, 0) + stacks
	status_applied.emit("hero:" + hid, stype, stacks)

func _add_status_enemy(idx: int, stype: String, stacks: int) -> void:
	_enemy_status[idx][stype] = _enemy_status[idx].get(stype, 0) + stacks
	status_applied.emit("enemy:" + str(idx), stype, stacks)

# 각 액터 본인 차례 시작 시 weak/vulnerable -1
func _decrement_status(actor_id: String) -> void:
	var status: Dictionary
	if actor_id.begins_with("hero:"):
		status = _hero_status.get(actor_id.substr(5), {})
	else:
		var idx: int = actor_id.substr(6).to_int()
		if idx >= _enemy_status.size():
			return
		status = _enemy_status[idx]
	for k: String in ["weak", "vulnerable"]:
		if status.get(k, 0) > 0:
			status[k] = max(0, status[k] - 1)

func _check_poison_tick_hero(hid: String) -> void:
	var p: int = _hero_status[hid].get("poison", 0)
	if p <= 0:
		return
	_damage_hero(hid, p)
	_hero_status[hid]["poison"] = max(0, p - 1)

func _check_poison_tick_enemy(idx: int) -> void:
	var p: int = _enemy_status[idx].get("poison", 0)
	if p <= 0:
		return
	_damage_enemy(idx, p)
	_enemy_status[idx]["poison"] = max(0, p - 1)

func _execute_enemy_turn(idx: int) -> void:
	if not _enemy_alive[idx]:
		return
	var enemy: Resource = _enemies[idx]
	if enemy.intent_pattern.is_empty():
		return
	var intent: Resource = enemy.intent_pattern[_enemy_intent_index[idx] % enemy.intent_pattern.size()]
	_enemy_intent_index[idx] += 1
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dmg: int = intent.value
			var e_status: Dictionary = _enemy_status[idx]
			dmg += e_status.get("strength", 0)
			if e_status.get("weak", 0) > 0:
				dmg = int(dmg * 0.75)
			var targets: Array = _select_attack_targets(intent)
			for tgt_hid in targets:
				var t_dmg: int = dmg
				if _hero_status[tgt_hid].get("vulnerable", 0) > 0:
					t_dmg = int(t_dmg * 1.5)
				_damage_hero(tgt_hid, t_dmg)
		IntentRes.ActionType.BUFF:
			if intent.status_type == "block":
				_enemy_block[idx] += intent.value
			else:
				_add_status_enemy(idx, intent.status_type, intent.value)
		IntentRes.ActionType.DEBUFF:
			var targets2: Array = _select_attack_targets(intent)
			for tgt_hid in targets2:
				_add_status_hero(tgt_hid, intent.status_type, intent.value)

func _select_attack_targets(intent: Resource) -> Array:
	var alive: Array = []
	for h in _heroes:
		if _hero_hp.get(h.hero_id, 0) > 0:
			alive.append(h.hero_id)
	if alive.is_empty():
		return []
	if intent.target == IntentRes.TargetType.ALL:
		return alive
	if intent.target == IntentRes.TargetType.LOWEST_HP:
		var lowest_id: String = alive[0]
		var lowest_hp: int = _hero_hp[lowest_id]
		for hid in alive:
			if _hero_hp[hid] < lowest_hp:
				lowest_hp = _hero_hp[hid]
				lowest_id = hid
		return [lowest_id]
	return [alive[randi() % alive.size()]]

func _check_battle_end() -> void:
	var any_alive_enemy: bool = false
	for a in _enemy_alive:
		if a:
			any_alive_enemy = true
			break
	if not any_alive_enemy:
		_battle_active = false
		battle_won.emit()
		return
	var any_alive_hero: bool = false
	for h in _heroes:
		if _hero_hp.get(h.hero_id, 0) > 0:
			any_alive_hero = true
			break
	if not any_alive_hero:
		_battle_active = false
		battle_lost.emit()

func _get_hero_by_id(hid: String) -> Resource:
	for h in _heroes:
		if h.hero_id == hid:
			return h
	return null

# Getters for UI
func get_hero_hp(hid: String) -> int:           return _hero_hp.get(hid, 0)
func get_hero_max_hp(hid: String) -> int:       return _get_hero_by_id(hid).max_hp if _get_hero_by_id(hid) else 0
func get_hero_block(hid: String) -> int:        return _hero_block.get(hid, 0)
func get_hero_status(hid: String) -> Dictionary: return _hero_status.get(hid, {}).duplicate()
func get_enemy_hp(idx: int) -> int:             return _enemy_hp[idx] if idx < _enemy_hp.size() else 0
func get_enemy_max_hp(idx: int) -> int:         return _enemies[idx].max_hp if idx < _enemies.size() else 0
func get_enemy_block(idx: int) -> int:          return _enemy_block[idx] if idx < _enemy_block.size() else 0
func get_enemy_status(idx: int) -> Dictionary:  return _enemy_status[idx].duplicate() if idx < _enemy_status.size() else {}
func is_enemy_alive(idx: int) -> bool:          return idx < _enemy_alive.size() and _enemy_alive[idx]
func get_current_actor() -> String:             return _current_actor
func get_turn_queue() -> Array:                 return _turn_queue.duplicate()
func get_enemy_current_intent(idx: int) -> Resource:
	if idx >= _enemies.size() or _enemies[idx].intent_pattern.is_empty():
		return null
	return _enemies[idx].intent_pattern[_enemy_intent_index[idx] % _enemies[idx].intent_pattern.size()]
func get_heroes() -> Array: return _heroes
func get_enemies() -> Array: return _enemies
