# resources/enemies/japanese/japanese_act2.gd
# 일본 신화 Act 2 — 엘리트 3종(혼돈의 텐구·야샤·누레리온) + 보스(슈텐도지)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func chaos_tengu(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.chaos_tengu"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "claw_attack"
	var i3 := IntentRes.new()
	# 텐구의 바람 — 영웅 1명 speed_penalty 3 (3턴 일정 효과)
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 3; i3.status_type = "speed_penalty"
	i3.duration = 3; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	e.charm_resistance = 20
	return e

static func yasha(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yasha"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func nureriyon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.nureriyon"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 120; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 150; i5.target = IntentRes.TargetType.LOWEST_HP; i5.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func shuten_doji(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.shuten_doji"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "japanese"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 술판
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 1; p0i1.status_type = "strength"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 160; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "blunt"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 2; p0i3.status_type = "weak"
	p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "blunt"
	# Phase 1 — 광란
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.LOWEST_HP; p1i1.damage_type = "blunt"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 170; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "blunt"
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.BUFF; p1i4.value = 2; p1i4.status_type = "strength"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.ATTACK; p1i5.value = 180; p1i5.target = IntentRes.TargetType.RANDOM; p1i5.damage_type = "blunt"
	# Phase 2 — 주귀 해방
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 180; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "blunt"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 180; p2i2.target = IntentRes.TargetType.RANDOM; p2i2.damage_type = "blunt"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.DEBUFF; p2i3.value = 3; p2i3.status_type = "weak"
	p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 210; p2i4.target = IntentRes.TargetType.ALL; p2i4.damage_type = "blunt"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.BUFF; p2i5.value = 3; p2i5.status_type = "strength"
	# p2i6 — 주귀 광기 가속 (보스 self speed_bonus 5 / 3턴)
	var p2i6 := IntentRes.new()
	p2i6.action_type = IntentRes.ActionType.BUFF; p2i6.value = 5; p2i6.status_type = "speed_bonus"
	p2i6.duration = 3
	# shuten_doji (술 마시는 오니 두목) — 술의 저주: weakness_curse 3턴 (모든 공격 약점화).
	var p1i_curse := IntentRes.new()
	p1i_curse.action_type = IntentRes.ActionType.INFLICT_WEAKNESS; p1i_curse.value = 3; p1i_curse.status_type = "weakness_curse"
	p1i_curse.target = IntentRes.TargetType.ALL; p1i_curse.play_animation = "debuff"
	var p2i_curse := IntentRes.new()
	p2i_curse.action_type = IntentRes.ActionType.INFLICT_WEAKNESS; p2i_curse.value = 3; p2i_curse.status_type = "weakness_curse"
	p2i_curse.target = IntentRes.TargetType.ALL; p2i_curse.play_animation = "debuff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i_curse, p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i_curse, p2i1, p2i2, p2i3, p2i4, p2i5, p2i6]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["chaos_tengu", "yasha", "nureriyon"]

static func boss() -> String:
	return "shuten_doji"
