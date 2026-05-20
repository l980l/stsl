# resources/enemies/egyptian/egyptian_act2.gd
# 이집트 신화 — Act2 엘리트 3종 + 보스(오시리스)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func apep_snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.apep_snake"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 140; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i1b := IntentRes.new()
	i1b.action_type = IntentRes.ActionType.DEBUFF; i1b.value = 50; i1b.status_type = "poison"; i1b.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i2b := IntentRes.new()
	i2b.action_type = IntentRes.ActionType.DEBUFF; i2b.value = 50; i2b.status_type = "poison"; i2b.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 3; i3.status_type = "weak"; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 200; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "poison"
	e.intent_pattern = [i1, i1b, i2, i2b, i3, i4]
	e.charm_resistance = 20
	return e

static func seth_hound(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.seth_hound"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 150; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 2; i2.status_type = "strength"
	var i2b := IntentRes.new()
	i2b.action_type = IntentRes.ActionType.ATTACK; i2b.value = 150; i2b.target = IntentRes.TargetType.RANDOM; i2b.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 280; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i2b, i3]
	e.charm_resistance = 20
	return e

static func ba_bird(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.ba_bird"; e.max_hp = 1500; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "projectile"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "projectile"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "projectile"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 110; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "projectile"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 2
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

# ──── 보스 ────

static func osiris(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.osiris"; e.max_hp = 3000; e.character_scene = scene
	e.mythology = "egyptian"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.5]
	e.phase_heal_ratios = [0.6]
	var p0_i1 := IntentRes.new()
	p0_i1.action_type = IntentRes.ActionType.ATTACK; p0_i1.value = 180; p0_i1.target = IntentRes.TargetType.RANDOM; p0_i1.damage_type = "holy_strike"
	var p0_i2 := IntentRes.new()
	p0_i2.action_type = IntentRes.ActionType.ATTACK; p0_i2.value = 180; p0_i2.target = IntentRes.TargetType.RANDOM; p0_i2.damage_type = "holy_strike"
	var p0_i3 := IntentRes.new()
	p0_i3.action_type = IntentRes.ActionType.BUFF; p0_i3.value = 1; p0_i3.status_type = "strength"
	var p0_i3b := IntentRes.new()
	p0_i3b.action_type = IntentRes.ActionType.DEBUFF; p0_i3b.value = 2; p0_i3b.status_type = "vulnerable"; p0_i3b.target = IntentRes.TargetType.ALL
	var p0_i4 := IntentRes.new()
	p0_i4.action_type = IntentRes.ActionType.ATTACK; p0_i4.value = 220; p0_i4.target = IntentRes.TargetType.ALL; p0_i4.damage_type = "holy_fire"
	var p1_i1 := IntentRes.new()
	p1_i1.action_type = IntentRes.ActionType.BUFF; p1_i1.value = 2; p1_i1.status_type = "strength"; p1_i1.condition = "부활"
	var p1_i2 := IntentRes.new()
	p1_i2.action_type = IntentRes.ActionType.ATTACK; p1_i2.value = 220; p1_i2.target = IntentRes.TargetType.RANDOM; p1_i2.damage_type = "holy_strike"
	var p1_i2b := IntentRes.new()
	p1_i2b.action_type = IntentRes.ActionType.DEBUFF; p1_i2b.value = 60; p1_i2b.status_type = "poison"; p1_i2b.target = IntentRes.TargetType.RANDOM
	var p1_i3 := IntentRes.new()
	p1_i3.action_type = IntentRes.ActionType.ATTACK; p1_i3.value = 220; p1_i3.target = IntentRes.TargetType.ALL; p1_i3.damage_type = "holy_fire"
	var p1_i4 := IntentRes.new()
	p1_i4.action_type = IntentRes.ActionType.DEBUFF; p1_i4.value = 3; p1_i4.status_type = "weak"; p1_i4.target = IntentRes.TargetType.ALL
	var p1_i4b := IntentRes.new()
	p1_i4b.action_type = IntentRes.ActionType.DEBUFF; p1_i4b.value = 3; p1_i4b.status_type = "vulnerable"; p1_i4b.target = IntentRes.TargetType.ALL
	var p1_i5 := IntentRes.new()
	p1_i5.action_type = IntentRes.ActionType.ATTACK; p1_i5.value = 300; p1_i5.target = IntentRes.TargetType.LOWEST_HP; p1_i5.damage_type = "holy_arrow"
	# p1_i6 — 죽음의 저주 (영웅 전체 speed_penalty 4 / 3턴, 부활 페이즈)
	var p1_i6 := IntentRes.new()
	p1_i6.action_type = IntentRes.ActionType.DEBUFF; p1_i6.value = 4; p1_i6.status_type = "speed_penalty"
	p1_i6.duration = 3; p1_i6.target = IntentRes.TargetType.ALL
	# osiris (죽음과 부활의 신) — 부활 페이즈에서 DISPEL ALL (영웅 buff 소멸).
	var p1_i_dispel := IntentRes.new()
	p1_i_dispel.action_type = IntentRes.ActionType.DISPEL
	p1_i_dispel.target = IntentRes.TargetType.ALL; p1_i_dispel.play_animation = "debuff"
	e.intent_pattern = [p0_i1, p0_i2, p0_i3, p0_i3b, p0_i4]
	e.phase_patterns = [
		[p0_i1, p0_i2, p0_i3, p0_i3b, p0_i4],
		[p1_i1, p1_i_dispel, p1_i2, p1_i2b, p1_i3, p1_i4, p1_i4b, p1_i5, p1_i6],
	]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["apep_snake", "seth_hound", "ba_bird"]

static func boss() -> String:
	return "osiris"
