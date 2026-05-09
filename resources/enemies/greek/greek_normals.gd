# resources/enemies/greek/greek_normals.gd
# 그리스 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func fly_harpy(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.fly_harpy"; e.max_hp = 220; e.character_scene = scene
	e.mythology = "greek"; e.signatures_enabled = false  # 인카운터 #1 (매우 약함)
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	e.intent_pattern = [i1, i2]
	return e

static func myrmidon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.myrmidon"; e.max_hp = 250; e.character_scene = scene
	e.mythology = "greek"; e.signatures_enabled = false  # 인카운터 #2 (약함)
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 90; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func satyr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.satyr"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "greek"; e.signatures_enabled = false  # 인카운터 #3 (약함)
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	e.intent_pattern = [i1, i2]
	return e

static func snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.snake"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2]
	return e

static func harpy(scene: PackedScene) -> Resource:
	# T0-CHARGE: 평타 → PREPARE → LOWEST_HP 대상 큰 한 방. 카드 약탈은 보존(remove_card SPECIAL).
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.harpy"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 45; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.PREPARE; i2.value = 0
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.SPECIAL; i4.value = 1; i4.status_type = "remove_card"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func cyclops(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.cyclops"; e.max_hp = 700; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.PREPARE; i1.value = 0; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 200; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	e.intent_pattern = [i1, i2]
	return e

static func cerberus(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +3 (지옥 개의 마지막 광기) + 인카운터 #10 보스급
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.cerberus"; e.max_hp = 900; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 70; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 70; i5.target = IntentRes.TargetType.RANDOM; i5.damage_type = "slash"
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.ATTACK; i6.value = 90; i6.target = IntentRes.TargetType.ALL; i6.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

# ──── 신규 14종 ────

static func lamia(scene: PackedScene) -> Resource:
	# T0-DEBUFF누적: vulnerable 2회 적층 → poison 큰 한 방 (LOWEST_HP)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.lamia"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 100; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func stymphalian_bird(scene: PackedScene) -> Resource:
	# T0-RAMP: 매 사이클 strength +1 누적 → 후반에 점점 더 위협적
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.stymphalian_bird"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 50; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 50; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func giant_ant(scene: PackedScene) -> Resource:
	# T0-CHARGE: PREPARE 한 턴 → ALL 큰 한 방. 텔레그래프 분명한 위협
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.giant_ant"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.PREPARE; i2.value = 0
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func dryad(scene: PackedScene) -> Resource:
	# T1-PHASE: HP 50% 미만에서 광기 페이즈 — 패턴 풀 완전 교체 + ALL 공격 위주
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.dryad"; e.max_hp = 270; e.character_scene = scene
	e.mythology = "greek"
	# 페이즈 0 (정상): 디버프 + 약한 curse 단일
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.DEBUFF; p0i1.value = 1; p0i1.status_type = "vulnerable"; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 50; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "curse"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 2; p0i3.status_type = "weak"; p0i3.target = IntentRes.TargetType.RANDOM
	# 페이즈 1 (광기): ALL 공격 + 디버프 누적 가속
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 70; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "curse"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"; p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 65; p1i3.target = IntentRes.TargetType.RANDOM; p1i3.damage_type = "curse"
	e.phase_thresholds = [0.5]
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

static func centaur(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 도달 시 마지막 항전 — strength +2 자동 (광폭화보다 늦게 발동)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.centaur"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func ares_soldier(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 도달 시 strength +3 자동 (광폭화). 패턴은 그대로.
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.ares_soldier"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func griffin_cub(scene: PackedScene) -> Resource:
	# T2-BUFFER: 동료 strength +1 (그리핀 새끼의 가르침)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.griffin_cub"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF_ALLY; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func medusid(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 죽을 때 메두스 응시 — ALL weak +1 (인카운터 #8 사망 체인)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.medusid"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 65; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 1; dt.status_type = "weak"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func fire_crab(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +2 (불게 분노)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.fire_crab"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 20; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func stone_shard(scene: PackedScene) -> Resource:
	# T2-GUARD: 동료에게 block 부여 + 자기 block (석화 방어진)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.stone_shard"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 25; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF_ALLY; i2.value = 20; i2.status_type = "block"; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 85; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func chimera_cub(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +3 (키마이라 새끼의 광기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.chimera_cub"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.ALL; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func hydra_head(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 머리 잘리면 동료 strength +2 (히드라 신화 — 머리 자르면 더 강해짐)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.hydra_head"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 100; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.BUFF_ALLY; dt.value = 2; dt.status_type = "strength"
	e.death_trigger = dt
	return e

static func tartaros_shade(scene: PackedScene) -> Resource:
	# T3-COUNTER: COUNTER_PREPARE 후 받은 데미지 40% 누적 → 다음 ATTACK에 가산 (저주의 반사)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.tartaros_shade"; e.max_hp = 500; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.COUNTER_PREPARE; i1.value = 40
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 2; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 130; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────
# #8~10 테마 시너지 (Phase 4):
#   #8 — griffin_cub + medusid(DEATH-RATTLE) + fire_crab + stone_shard(GUARD)
#   #9 — cyclops(CHARGE) + chimera_cub + hydra_head(DEATH-RATTLE)
#   #10 — cerberus(DESPERATE) + tartaros_shade(COUNTER)

static func encounters() -> Array:
	return [
		["fly_harpy"],
		["myrmidon", "myrmidon"],
		["satyr"],
		["snake", "lamia"],
		["harpy", "harpy", "harpy"],
		["stymphalian_bird", "giant_ant", "dryad"],
		["centaur", "centaur", "ares_soldier"],
		["griffin_cub", "medusid", "fire_crab", "stone_shard"],
		["cyclops", "chimera_cub", "hydra_head"],
		["cerberus", "tartaros_shade"],
	]
