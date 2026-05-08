# autoload/enemy_interaction_system.gd
# Phase 2 — 적간 상호작용 (T2-BUFFER, T2-HEALER, T2-DEATH-RATTLE 등) 헬퍼.
# BattleManager 인스턴스를 첫 인자로 받는 static 메서드 모음. 자체 상태 보유 안 함.
class_name EnemyInteractionSystem
extends RefCounted

# 동료(자기 자신 제외) 중 살아있는 적 인덱스 목록
static func _get_living_allies(bm: Object, source_idx: int) -> Array:
	var result: Array = []
	if bm == null:
		return result
	for i in range(bm._enemy_alive.size()):
		if i == source_idx:
			continue
		if bm._enemy_alive[i]:
			result.append(i)
	return result

# 살아있는 동료 중 HP가 가장 낮은 적 인덱스 (없으면 -1)
static func pick_lowest_hp_ally(bm: Object, source_idx: int) -> int:
	var allies: Array = _get_living_allies(bm, source_idx)
	if allies.is_empty():
		return -1
	var best: int = allies[0]
	for idx in allies:
		if bm._enemy_hp[idx] < bm._enemy_hp[best]:
			best = idx
	return best

# 살아있는 동료 중 무작위 적 인덱스 (없으면 -1)
static func pick_random_ally(bm: Object, source_idx: int) -> int:
	var allies: Array = _get_living_allies(bm, source_idx)
	if allies.is_empty():
		return -1
	return allies[randi() % allies.size()]

# 동료 1명에게 HP 회복 (max_hp 상한 적용). 동료 없으면 no-op.
static func heal_ally(bm: Object, source_idx: int, target_idx: int, value: int) -> bool:
	if bm == null or target_idx < 0 or target_idx == source_idx:
		return false
	if target_idx >= bm._enemy_alive.size() or not bm._enemy_alive[target_idx]:
		return false
	var max_hp: int = bm._enemies[target_idx].max_hp
	var new_hp: int = min(bm._enemy_hp[target_idx] + value, max_hp)
	bm._enemy_hp[target_idx] = new_hp
	bm.enemy_damaged.emit(target_idx, new_hp, "")  # HP 변경 시그널 재사용
	return true

# 동료 1명에게 status 부여 (strength/block 등). status_type=block 은 직접 _enemy_block 갱신.
static func buff_ally(bm: Object, source_idx: int, target_idx: int, status_type: String, value: int) -> bool:
	if bm == null or target_idx < 0 or target_idx == source_idx:
		return false
	if target_idx >= bm._enemy_alive.size() or not bm._enemy_alive[target_idx]:
		return false
	if status_type == "block" or status_type == "":
		bm._enemy_block[target_idx] += value
	else:
		bm._apply_status_to_enemy(target_idx, status_type, value)
	return true
