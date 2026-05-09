# resources/enemies/japanese/japanese_normals.gd
# 일본 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func yuki_onna(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yuki_onna"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "japanese"; e.signatures_enabled = false  # 인카운터 #1
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "ice"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func tengu(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.tengu"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "japanese"; e.signatures_enabled = false  # 인카운터 #2
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 1; i4.status_type = "vulnerable"; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func shuten_minion(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.shuten_minion"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "japanese"; e.signatures_enabled = false  # 인카운터 #3
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 100; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func kappa(scene: PackedScene) -> Resource:
	# T0-DEBUFF누적: weak 2회 적층 → 큰 한 방
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.kappa"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 110; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func oni(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +4 (오니의 본성)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.oni"; e.max_hp = 420; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 4}]]
	return e

static func ronin_ghost(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +3 (낭인 망령 마지막 결투)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.ronin_ghost"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 130; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

# ──── 신규 14종 ────

static func foxfire(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +2 (도깨비불 폭발)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.foxfire"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func koropokkuru(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +2 (코로보쿠루 작은 종족 광기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.koropokkuru"; e.max_hp = 260; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	e.intent_pattern = [i1, i2]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func yamabiko(scene: PackedScene) -> Resource:
	# DEATH-RATTLE: 죽을 때 ALL weak +1 (산울림의 마지막 메아리)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamabiko"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 65; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 1; dt.status_type = "weak"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func ittan_momen(scene: PackedScene) -> Resource:
	# T1-BERSERK: HP 50% 미만 strength +2 (잇탄모멘 천 요괴 광기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.ittan_momen"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.5]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func azuki_washer(scene: PackedScene) -> Resource:
	# DEATH-RATTLE: 죽을 때 ALL vulnerable +1 (팥씻기 요괴 마지막 저주)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.azuki_washer"; e.max_hp = 270; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 1; dt.status_type = "vulnerable"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func samurai_ghost(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +3 (사무라이 망령 마지막 충성)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.samurai_ghost"; e.max_hp = 430; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func river_kappa(scene: PackedScene) -> Resource:
	# T2-HEALER: LOWEST_HP 동료 HP +25 (강물 카파의 치유)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.river_kappa"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.HEAL_ALLY; i1.value = 25; i1.target = IntentRes.TargetType.LOWEST_HP
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func snow_woman(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +2 (눈여인의 마지막 한기)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.snow_woman"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "ice"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func cursed_scroll(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 죽을 때 저주 두루마리 폭발 — ALL vulnerable +2
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.cursed_scroll"; e.max_hp = 270; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SPECIAL; i1.value = 1; i1.status_type = "remove_card"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 65; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 2; dt.status_type = "vulnerable"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func tatami_monster(scene: PackedScene) -> Resource:
	# T1-PHASE: HP 50% 미만 → 폭주 페이즈 (block 포기, ALL 공격)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.tatami_monster"; e.max_hp = 330; e.character_scene = scene
	e.mythology = "japanese"
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 30; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 80; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "blunt"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 95; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "blunt"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 70; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "blunt"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 110; p1i2.target = IntentRes.TargetType.LOWEST_HP; p1i2.damage_type = "blunt"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 90; p1i3.target = IntentRes.TargetType.RANDOM; p1i3.damage_type = "blunt"
	e.phase_thresholds = [0.5]
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

static func yamabushi_ghost(scene: PackedScene) -> Resource:
	# T2-BUFFER: 동료 strength +1 (산악 수도승의 가르침)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamabushi_ghost"; e.max_hp = 480; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF_ALLY; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func dragon_serpent(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +3 (용뱀의 마지막 항전)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.dragon_serpent"; e.max_hp = 440; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 100; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 3}]]
	return e

static func oni_king(scene: PackedScene) -> Resource:
	# T3-WARD: 오니 왕의 결계 — hannya와 함께 TH-WARD-ROTATE 테마 (인카운터 #10)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.oni_king"; e.max_hp = 700; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.WARD; i1.value = 1
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func hannya(scene: PackedScene) -> Resource:
	# T3-WARD: 한냐 가면의 결계 — WARD 1턴 사이클로 무적 윈도우
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.hannya"; e.max_hp = 680; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.WARD; i1.value = 1  # 1턴 무적
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 90; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────
# #8~10 테마 시너지 (Phase 4):
#   #8 — river_kappa + snow_woman + cursed_scroll(DEATH-RATTLE) + tatami_monster(PHASE)
#   #9 — ronin_ghost + yamabushi_ghost + dragon_serpent(DESPERATE)
#   #10 TH-WARD-ROTATE — oni_king(WARD) + hannya(WARD) — 2 마리 무적 사이클

static func encounters() -> Array:
	return [
		["yuki_onna"],
		["tengu", "tengu"],
		["shuten_minion"],
		["kappa", "foxfire"],
		["koropokkuru", "koropokkuru", "koropokkuru"],
		["yamabiko", "ittan_momen", "azuki_washer"],
		["oni", "oni", "samurai_ghost"],
		["river_kappa", "snow_woman", "cursed_scroll", "tatami_monster"],
		["ronin_ghost", "yamabushi_ghost", "dragon_serpent"],
		["oni_king", "hannya"],
	]
