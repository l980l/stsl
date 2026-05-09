# resources/enemies/buddhist/buddhist_normals.gd
# 불교 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치, vajrapani HP 900→500 리밸런싱) ────

static func garuda(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.garuda"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "buddhist"; e.signatures_enabled = false  # 인카운터 #1
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	e.intent_pattern = [i1, i2]
	return e

static func yaksha(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.yaksha"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "buddhist"; e.signatures_enabled = false  # 인카운터 #2
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.LOWEST_HP; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func mara_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.mara_soldier"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "buddhist"; e.signatures_enabled = false  # 인카운터 #3
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 60; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func asura(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.asura"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func virudhaka(scene: PackedScene) -> Resource:
	# T2-GUARD: 매 사이클 동료에게 block 부여 + 자기 block (사천왕 광목천)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.virudhaka"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 30; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF_ALLY; i2.value = 20; i2.status_type = "block"; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func vajrapani(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.vajrapani"; e.max_hp = 500; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

# ──── 신규 14종 ────

static func dharma_puppet(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.dharma_puppet"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func lotus_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.lotus_spirit"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func hungry_ghost(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.hungry_ghost"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func naga_spawn(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.naga_spawn"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "poison"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func demon_soldier(scene: PackedScene) -> Resource:
	# T1-DESPERATE: HP 30% 미만 strength +2
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.demon_soldier"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	e.phase_thresholds = [0.3]
	e.phase_buffs = [[{"status": "strength", "value": 2}]]
	return e

static func karmic_fiend(scene: PackedScene) -> Resource:
	# T2-DEATH-RATTLE: 죽을 때 업의 저주 — ALL vulnerable +2
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.karmic_fiend"; e.max_hp = 370; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	var dt := IntentRes.new()
	dt.action_type = IntentRes.ActionType.DEBUFF; dt.value = 2; dt.status_type = "vulnerable"; dt.target = IntentRes.TargetType.ALL
	e.death_trigger = dt
	return e

static func sky_beast(scene: PackedScene) -> Resource:
	# T2-BUFFER: 매 사이클 동료 strength +1 부여
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.sky_beast"; e.max_hp = 330; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF_ALLY; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func earth_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.earth_spirit"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func wrathful_spirit(scene: PackedScene) -> Resource:
	# T1-PHASE: HP 50% 미만 → 분노 페이즈 (ALL curse)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.wrathful_spirit"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "buddhist"
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 75; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "curse"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 1; p0i2.status_type = "weak"; p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 90; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "curse"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 80; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "curse"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"; p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 80; p1i3.target = IntentRes.TargetType.RANDOM; p1i3.damage_type = "curse"
	e.phase_thresholds = [0.5]
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

static func cursed_monk(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.cursed_monk"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SPECIAL; i1.value = 1
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 65; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func deva_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.deva_soldier"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func ashura_warrior(scene: PackedScene) -> Resource:
	# T3-SACRIFICE: 자기 HP -50 → strength +5 (아수라의 광폭한 헌신)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.ashura_warrior"; e.max_hp = 450; e.character_scene = scene  # HP 상향 (희생 보상)
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SACRIFICE; i1.value = 5  # HP -50, strength +5
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 95; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func mara_general(scene: PackedScene) -> Resource:
	# T3-SUMMON: 마라 군단 — mara_soldier 1마리 소환 후 강력한 공격 사이클
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.mara_general"; e.max_hp = 680; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SUMMON; i1.value = 1; i1.status_type = "mara_soldier"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 90; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func hell_guardian(scene: PackedScene) -> Resource:
	# T3-COUNTER: 지옥 수호자 — 받은 데미지 50% 누적 → 다음 ATTACK 폭발 가산
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.hell_guardian"; e.max_hp = 690; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 60; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.COUNTER_PREPARE; i2.value = 50
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 100; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────

static func encounters() -> Array:
	return [
		["garuda"],
		["yaksha", "yaksha"],
		["mara_soldier"],
		["dharma_puppet", "lotus_spirit"],
		["hungry_ghost", "hungry_ghost", "hungry_ghost"],
		["asura", "naga_spawn", "demon_soldier"],
		["virudhaka", "virudhaka", "karmic_fiend"],
		["sky_beast", "earth_spirit", "wrathful_spirit", "cursed_monk"],
		["vajrapani", "deva_soldier", "ashura_warrior"],
		["mara_general", "hell_guardian"],
	]
