# autoload/enemy_signature_system.gd
# Phase 3 — 6 신화 시그니처 자동 적용. mythology 키 기반 분기.
# signatures_enabled=false 인 적은 모든 시그니처 미발동 (#1~3 인카운터 단순 적).
# BattleManager 인스턴스를 첫 인자로 받는 static 메서드 모음.
class_name EnemySignatureSystem
extends RefCounted

# ─── Hook: 적이 데미지 받음 ───
# 그리스 휴브리스 — 단일 25+ 피해 → 다음 턴 strength +2 (pending 플래그)
# 북유럽 라그나로크 — HP 30% 미만 도달 → 모든 적 strength +1 (전투당 1회)
static func on_enemy_damaged(bm: Object, idx: int, amount: int) -> void:
	if not _signatures_enabled(bm, idx):
		return
	var enemy: Resource = bm._enemies[idx]
	# 누적 피해 추적 (불교 인과응보용)
	bm._enemy_status[idx]["damage_taken"] = bm._enemy_status[idx].get("damage_taken", 0) + amount
	match enemy.mythology:
		"greek":
			if amount >= 25 and not bm._enemy_status[idx].get("greek_hubris_pending", false):
				bm._enemy_status[idx]["greek_hubris_pending"] = true
				bm.signature_fired.emit(idx, "hubris")  # 토스트용
		"norse":
			if not bm._enemy_status[idx].get("norse_ragnarok_fired", false) and bm._enemy_alive[idx]:
				var hp_ratio: float = float(bm._enemy_hp[idx]) / float(enemy.max_hp)
				if hp_ratio < 0.3:
					bm._enemy_status[idx]["norse_ragnarok_fired"] = true
					for i in range(bm._enemy_alive.size()):
						if bm._enemy_alive[i]:
							bm._apply_status_to_enemy(i, "strength", 1)
					bm.signature_fired.emit(idx, "ragnarok")  # 토스트용 (전투당 1회)

# ─── Hook: 적이 영웅에게 ATTACK ───
# 이집트 저주 누적 — 자기 ATTACK 적중 시 타겟에 vulnerable +1 자동 부여
static func on_enemy_attack(bm: Object, idx: int, target_hero_id: String) -> void:
	if not _signatures_enabled(bm, idx):
		return
	if target_hero_id == "":
		return
	var enemy: Resource = bm._enemies[idx]
	if enemy.mythology == "egyptian":
		bm._apply_status_to_hero(target_hero_id, "vulnerable", 1)

# ─── Hook: 적 사망 ───
# 불교 인과응보 — 받은 누적 피해의 25%를 ALL 영웅에 반환 (1회)
static func on_enemy_death(bm: Object, idx: int) -> void:
	if not _signatures_enabled(bm, idx):
		return
	var enemy: Resource = bm._enemies[idx]
	if enemy.mythology == "buddhist":
		var taken: int = bm._enemy_status[idx].get("damage_taken", 0)
		var reflect: int = int(taken * 0.25)
		if reflect > 0 and bm.team_mgr:
			for hero in bm.team_mgr.get_living_heroes():
				bm._deal_damage_to_hero(hero.hero_id, reflect, "")
			bm.signature_fired.emit(idx, "karma")  # 토스트용 (사망 시 1회)

# ─── Hook: 적 턴 시작 ───
# 그리스 휴브리스 pending 처리 — strength +2 부여 후 플래그 해제
# 도교 음양 — 공격형(strength +1) ↔ 방어형(block +15) 자동 교대
# 일본 결계 — 매 5턴마다 자기 block +20
static func on_enemy_turn_start(bm: Object, idx: int) -> void:
	if not _signatures_enabled(bm, idx):
		return
	var enemy: Resource = bm._enemies[idx]
	# Greek: hubris pending 처리
	if enemy.mythology == "greek" and bm._enemy_status[idx].get("greek_hubris_pending", false):
		bm._apply_status_to_enemy(idx, "strength", 2)
		bm._enemy_status[idx]["greek_hubris_pending"] = false
	# Daoist: 음양 자세 교대
	elif enemy.mythology == "daoist":
		var stance: int = bm._enemy_status[idx].get("daoist_stance", 0)
		if stance == 0:
			bm._apply_status_to_enemy(idx, "strength", 1)
		else:
			bm._enemy_block[idx] += 15
		bm._enemy_status[idx]["daoist_stance"] = 1 - stance
	# Japanese: 결계 매 5턴마다
	elif enemy.mythology == "japanese":
		var turn_count: int = bm._enemy_status[idx].get("japanese_turn_count", 0) + 1
		bm._enemy_status[idx]["japanese_turn_count"] = turn_count
		if turn_count % 5 == 0:
			bm._enemy_block[idx] += 20
			bm.signature_fired.emit(idx, "kekkai")  # 토스트용 (5턴마다)

# ─── 헬퍼 ───
static func _signatures_enabled(bm: Object, idx: int) -> bool:
	if bm == null or idx < 0 or idx >= bm._enemies.size():
		return false
	var enemy: Resource = bm._enemies[idx]
	if enemy == null:
		return false
	return enemy.get("signatures_enabled") if enemy.get("signatures_enabled") != null else true
