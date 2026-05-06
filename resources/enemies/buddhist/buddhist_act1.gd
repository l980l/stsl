# resources/enemies/buddhist/buddhist_act1.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func vaisravana(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.vaisravana"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 60; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 60; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 180; i5.target = IntentRes.TargetType.RANDOM; i5.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func deva_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.deva_guardian"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func dharma_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.dharma_general"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "divine"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 180; i5.target = IntentRes.TargetType.LOWEST_HP; i5.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func mahavairocana(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.mahavairocana"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "buddhist"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "divine"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.BUFF; p0i3.value = 40; p0i3.status_type = "block"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 130; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "divine"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "divine"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.RANDOM
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 150; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "divine"
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 200; p1i4.target = IntentRes.TargetType.LOWEST_HP; p1i4.damage_type = "divine"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 220; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "divine"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.BUFF; p2i2.value = 2; p2i2.status_type = "strength"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 190; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "divine"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 240; p2i4.target = IntentRes.TargetType.LOWEST_HP; p2i4.damage_type = "divine"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.DEBUFF; p2i5.value = 2; p2i5.status_type = "weak"
	p2i5.target = IntentRes.TargetType.ALL
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["vaisravana", "deva_guardian", "dharma_general"]

static func boss() -> String:
	return "mahavairocana"
