# tools/encounter_simulation.gd
# 60 인카운터 단순화 시뮬레이션 — 정량적 밸런스 검증
# 영웅 팀: HP 240(=3×80), 매 턴 dps 80, block 25 흡수 가정
# 적 행동: cycle 평균 dps 적용, ALL ×3 hit, BERSERK/DESPERATE HP threshold 시 strength buff 적용
# DEATH-RATTLE: 사망 시 1회 추가 데미지 (ALL DEBUFF 무시, BUFF_ALLY는 strength로 환산)
# 시그니처 효과는 단순화 모델에서 제외 (정확도 < 인카운터 간 상대 비교 가능성)
# 실행: "H:/Program Files/Godot/Godot_v4.6.2-stable_win64_console.exe" --headless -s tools/encounter_simulation.gd
extends SceneTree

const OUT_PATH := "res://docs/balance/encounter_simulation_v1.csv"
const IntentRes = preload("res://resources/intent_resource.gd")

# 실제 게임 영웅 max_hp = 1000 (M4 카드풀 v3 스케일). 3명 팀 = 3000.
# dps/block은 카드풀 평균 추정 — 보통 영웅당 50~80 dps, 30~50 block 가능
const HERO_TEAM_HP := 3000
const HERO_TEAM_DPS := 220   # 3명 × ~73 평균
const HERO_BLOCK_PER_TURN := 80  # 3명 합산 평균 block 카드 사용
const MAX_TURNS := 30  # 무한 루프 방지

const MYTHOLOGIES := {
	"greek":     preload("res://resources/enemies/greek/greek_normals.gd"),
	"norse":     preload("res://resources/enemies/norse/norse_normals.gd"),
	"egyptian":  preload("res://resources/enemies/egyptian/egyptian_normals.gd"),
	"buddhist":  preload("res://resources/enemies/buddhist/buddhist_normals.gd"),
	"daoist":    preload("res://resources/enemies/daoist/daoist_normals.gd"),
	"japanese":  preload("res://resources/enemies/japanese/japanese_normals.gd"),
}

func _init() -> void:
	var lines: Array[String] = []
	lines.append("mythology,enc_idx,result,turns_taken,hero_hp_remaining,total_enemy_hp,first_turn_dps,monsters")

	for myth in MYTHOLOGIES.keys():
		var mod = MYTHOLOGIES[myth]
		var encs: Array = mod.encounters()
		for i in range(encs.size()):
			var sim := _simulate_encounter(myth, i, encs[i], mod)
			lines.append(sim)

	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open: %s" % OUT_PATH)
		quit(1)
		return
	for line in lines:
		f.store_line(line)
	f.close()
	print("[encounter_sim] %d rows → %s" % [lines.size() - 1, OUT_PATH])
	quit(0)

func _simulate_encounter(myth: String, idx: int, keys: Array, mod: GDScript) -> String:
	# 적 상태 초기화: [{hp, max_hp, cycle_dmg, has_berserk, berserk_threshold, berserk_strength, death_dmg}]
	var enemies: Array = []
	for key in keys:
		var er: Resource = mod.call(key, null)
		if er == null:
			continue
		enemies.append(_init_enemy_state(er))
	var hero_hp: int = HERO_TEAM_HP
	var total_enemy_hp: int = 0
	for e in enemies:
		total_enemy_hp += e["max_hp"]
	var first_turn_dps: int = 0
	for e in enemies:
		first_turn_dps += e["base_dmg_per_turn"]

	var turn: int = 0
	var result: String = "TIMEOUT"
	while turn < MAX_TURNS:
		turn += 1
		# 영웅 턴: HERO_TEAM_DPS 를 가장 낮은 HP 적에게
		_hero_attack(enemies)
		# DEATH-RATTLE 처리 (이번 턴 죽은 적)
		var death_extra_dmg: int = 0
		var ally_strength_buffs: int = 0
		for e in enemies:
			if e["just_died"]:
				death_extra_dmg += e["death_target_dmg"]
				ally_strength_buffs += e["death_ally_str"]
				e["just_died"] = false  # 한 번만 처리
		# 동료 strength 버프 분배 (DEATH-RATTLE BUFF_ALLY)
		if ally_strength_buffs > 0:
			for e in enemies:
				if e["alive"]:
					e["strength"] += ally_strength_buffs
		# 모든 적 사망 체크
		if _all_dead(enemies):
			hero_hp = max(0, hero_hp - death_extra_dmg)
			result = "WIN"
			break
		# 적 턴: 살아있는 적 base_dmg + strength × 0.1 보정 → HERO_BLOCK 흡수 후 hp 감소
		var enemy_dmg_this_turn: int = 0
		for e in enemies:
			if not e["alive"]:
				continue
			# BERSERK/DESPERATE 트리거
			if e["phase_threshold"] > 0.0:
				var hp_ratio: float = float(e["hp"]) / float(e["max_hp"])
				if hp_ratio < e["phase_threshold"] and not e["phase_fired"]:
					e["strength"] += e["phase_strength_buff"]
					e["phase_fired"] = true
			# 단일 cycle dps + strength 보정
			var dmg: int = int(e["base_dmg_per_turn"] * (1.0 + 0.1 * e["strength"]))
			enemy_dmg_this_turn += dmg
		# DEATH-RATTLE 추가 데미지 합산
		enemy_dmg_this_turn += death_extra_dmg
		var net_dmg: int = max(0, enemy_dmg_this_turn - HERO_BLOCK_PER_TURN)
		hero_hp = max(0, hero_hp - net_dmg)
		if hero_hp <= 0:
			result = "LOSS"
			break

	if result == "TIMEOUT":
		# MAX_TURNS 도달 — 영웅이 아직 살아있고 적도 일부 살아있음
		result = "WIN" if _all_dead(enemies) else "TIMEOUT"
	var monsters_str: String = "|".join(keys)
	return "%s,%d,%s,%d,%d,%d,%d,%s" % [myth, idx, result, turn, hero_hp, total_enemy_hp, first_turn_dps, monsters_str]

func _init_enemy_state(enemy: Resource) -> Dictionary:
	var pat: Array = enemy.intent_pattern
	if not enemy.phase_patterns.is_empty():
		pat = enemy.phase_patterns[0]
	# cycle 평균 dps 계산: ATTACK value 합 (ALL ×3) / pattern length (PREPARE 포함)
	var cycle_total: int = 0
	for intent in pat:
		if intent.action_type == IntentRes.ActionType.ATTACK:
			var v: int = intent.value
			if intent.target == IntentRes.TargetType.ALL:
				v *= 3
			cycle_total += v
	var pattern_len: int = max(1, pat.size())
	var avg_dmg: int = int(cycle_total / float(pattern_len))

	# DEATH-RATTLE 분석
	var death_target: int = 0
	var death_ally_str: int = 0
	if enemy.death_trigger != null:
		var dt: Resource = enemy.death_trigger
		match dt.action_type:
			IntentRes.ActionType.ATTACK:
				death_target = dt.value * (3 if dt.target == IntentRes.TargetType.ALL else 1)
			IntentRes.ActionType.DEBUFF:
				# vul/weak DEBUFF 는 단순화에서 ~10 가량 가산 효과 가정
				if dt.target == IntentRes.TargetType.ALL:
					death_target = 30  # heroes are debuffed for next turn
			IntentRes.ActionType.BUFF_ALLY:
				if dt.status_type == "strength":
					death_ally_str = dt.value

	# phase_buffs 분석 (BERSERK/DESPERATE)
	var threshold: float = 0.0
	var strength_buff: int = 0
	if not enemy.phase_thresholds.is_empty() and not enemy.phase_buffs.is_empty():
		threshold = enemy.phase_thresholds[0]
		var buffs: Array = enemy.phase_buffs[0]
		for b in buffs:
			if b.get("status", "") == "strength":
				strength_buff = b.get("value", 0)

	return {
		"hp": enemy.max_hp,
		"max_hp": enemy.max_hp,
		"base_dmg_per_turn": avg_dmg,
		"strength": 0,
		"phase_threshold": threshold,
		"phase_strength_buff": strength_buff,
		"phase_fired": false,
		"alive": true,
		"just_died": false,
		"death_target_dmg": death_target,
		"death_ally_str": death_ally_str,
	}

func _hero_attack(enemies: Array) -> void:
	# HERO_TEAM_DPS 를 가장 낮은 HP 살아있는 적에게 (overflow 시 다음 적)
	var dmg_left: int = HERO_TEAM_DPS
	while dmg_left > 0:
		var target_idx: int = -1
		var lowest_hp: int = 99999
		for i in range(enemies.size()):
			if enemies[i]["alive"] and enemies[i]["hp"] < lowest_hp:
				lowest_hp = enemies[i]["hp"]
				target_idx = i
		if target_idx == -1:
			break  # 모든 적 사망
		var dealt: int = min(dmg_left, enemies[target_idx]["hp"])
		enemies[target_idx]["hp"] -= dealt
		dmg_left -= dealt
		if enemies[target_idx]["hp"] <= 0:
			enemies[target_idx]["alive"] = false
			enemies[target_idx]["just_died"] = true

func _all_dead(enemies: Array) -> bool:
	for e in enemies:
		if e["alive"]:
			return false
	return true
