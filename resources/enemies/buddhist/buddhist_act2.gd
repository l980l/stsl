# resources/enemies/buddhist/buddhist_act2.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func asura_king(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.asura_king"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 30; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 150; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func naga_king(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.naga_king"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "holy_strike"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "holy_fire"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func agni_buddha(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.agni_buddha"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "holy_strike"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "holy_strike"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 2; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 150; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "holy_fire"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 2; i5.status_type = "vulnerable"
	i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func guanyin(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.guanyin"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "buddhist"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.DEBUFF; p0i1.value = 2; p0i1.status_type = "weak"
	p0i1.target = IntentRes.TargetType.ALL
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 140; p0i2.target = IntentRes.TargetType.LOWEST_HP; p0i2.damage_type = "holy_arrow"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.BUFF; p0i3.value = 40; p0i3.status_type = "block"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.DEBUFF; p0i4.value = 3; p0i4.status_type = "poison"
	p0i4.target = IntentRes.TargetType.ALL
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.DEBUFF; p1i1.value = 2; p1i1.status_type = "vulnerable"
	p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 180; p1i2.target = IntentRes.TargetType.ALL; p1i2.damage_type = "holy_fire"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 4; p1i3.status_type = "poison"
	p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 160; p1i4.target = IntentRes.TargetType.RANDOM; p1i4.damage_type = "holy_strike"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 1; p1i5.status_type = "strength"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.DEBUFF; p2i1.value = 3; p2i1.status_type = "vulnerable"
	p2i1.target = IntentRes.TargetType.ALL
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "weak"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 230; p2i3.target = IntentRes.TargetType.LOWEST_HP; p2i3.damage_type = "holy_arrow"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.DEBUFF; p2i4.value = 5; p2i4.status_type = "poison"
	p2i4.target = IntentRes.TargetType.RANDOM
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.ATTACK; p2i5.value = 200; p2i5.target = IntentRes.TargetType.ALL; p2i5.damage_type = "holy_fire"
	var p2i6 := IntentRes.new()
	p2i6.action_type = IntentRes.ActionType.BUFF; p2i6.value = 2; p2i6.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i1, p2i2, p2i3, p2i4, p2i5, p2i6]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["asura_king", "naga_king", "agni_buddha"]

static func boss() -> String:
	return "guanyin"
