# resources/enemies/korean/korean_normals.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func death_reaper(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.death_reaper"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.LOWEST_HP; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func cheoyong(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.cheoyong"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 20; i4.status_type = "block"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func dokkaebi(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.dokkaebi"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func three_legged_crow(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.three_legged_crow"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	e.intent_pattern = [i1, i2]
	return e

static func gumiho(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.gumiho"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 60; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func bulgasari(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.bulgasari"; e.max_hp = 900; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func encounters() -> Array:
	return [
		["death_reaper"],
		["death_reaper", "death_reaper"],
		["cheoyong"],
		["death_reaper", "cheoyong"],
		["dokkaebi", "dokkaebi"],
		["three_legged_crow", "three_legged_crow"],
		["gumiho"],
		["gumiho", "dokkaebi"],
		["bulgasari"],
		["death_reaper", "three_legged_crow"],
		["dokkaebi", "dokkaebi", "three_legged_crow"],
	]
