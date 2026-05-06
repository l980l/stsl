# resources/enemies/daoist/daoist_normals.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func hermit_ghost(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.hermit_ghost"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func child_immortal(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.child_immortal"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 50; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	e.intent_pattern = [i1, i2, i3]
	return e

static func celestial_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.celestial_soldier"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 30; i4.status_type = "block"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func mountain_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.mountain_spirit"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 1; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func dao_disciple(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.dao_disciple"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 2; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func azure_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.azure_guardian"; e.max_hp = 520; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func encounters() -> Array:
	return [
		["hermit_ghost"],
		["hermit_ghost", "hermit_ghost"],
		["child_immortal", "child_immortal"],
		["hermit_ghost", "child_immortal"],
		["celestial_soldier"],
		["celestial_soldier", "hermit_ghost"],
		["mountain_spirit", "mountain_spirit"],
		["dao_disciple", "dao_disciple"],
		["azure_guardian"],
		["mountain_spirit", "hermit_ghost"],
		["dao_disciple", "celestial_soldier"],
	]
