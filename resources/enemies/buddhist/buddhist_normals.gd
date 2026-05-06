# resources/enemies/buddhist/buddhist_normals.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func yaksha(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.yaksha"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.LOWEST_HP; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func virudhaka(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.virudhaka"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "buddhist"
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

static func asura(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.asura"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func garuda(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.garuda"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "buddhist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	e.intent_pattern = [i1, i2]
	return e

static func mara_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.mara_soldier"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "buddhist"
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

static func vajrapani(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.buddhist.vajrapani"; e.max_hp = 900; e.character_scene = scene
	e.mythology = "buddhist"
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
		["yaksha"],
		["yaksha", "yaksha"],
		["virudhaka"],
		["yaksha", "virudhaka"],
		["asura", "asura"],
		["garuda", "garuda"],
		["mara_soldier"],
		["mara_soldier", "asura"],
		["vajrapani"],
		["yaksha", "garuda"],
		["asura", "asura", "garuda"],
	]
