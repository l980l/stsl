# resources/enemies/greek/greek_act1.gd
# 그리스 신화 — Act1 엘리트 4종 + 보스(히드라)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 4종 ────

static func minotaur(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.minotaur"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 150; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 260; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	e.charm_resistance = 20
	return e

static func medusa(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.medusa"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 130; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func gorgon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.gorgon"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "greek"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 140; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "slash"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 1; p0i2.status_type = "vulnerable"
	p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.BUFF; p0i3.value = 1; p0i3.status_type = "strength"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.DEBUFF; p0i4.value = 1; p0i4.status_type = "vulnerable"
	p0i4.target = IntentRes.TargetType.RANDOM
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.ATTACK; p0i5.value = 140; p0i5.target = IntentRes.TargetType.RANDOM; p0i5.damage_type = "slash"
	var p0i6 := IntentRes.new()
	p0i6.action_type = IntentRes.ActionType.DEBUFF; p0i6.value = 1; p0i6.status_type = "vulnerable"
	p0i6.target = IntentRes.TargetType.ALL
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 160; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "slash"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.RANDOM
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "curse"
	e.phase_patterns = [[p0i1, p0i2, p0i3, p0i4, p0i5, p0i6], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func scylla(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.scylla"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "greek"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 100; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "slash"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 100; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "slash"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 3; p0i3.status_type = "poison"
	p0i3.target = IntentRes.TargetType.RANDOM
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 80; p0i4.target = IntentRes.TargetType.RANDOM; p0i4.damage_type = "slash"
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.ATTACK; p0i5.value = 100; p0i5.target = IntentRes.TargetType.RANDOM; p0i5.damage_type = "slash"
	var p0i6 := IntentRes.new()
	p0i6.action_type = IntentRes.ActionType.ATTACK; p0i6.value = 100; p0i6.target = IntentRes.TargetType.RANDOM; p0i6.damage_type = "slash"
	var p0i7 := IntentRes.new()
	p0i7.action_type = IntentRes.ActionType.ATTACK; p0i7.value = 120; p0i7.target = IntentRes.TargetType.ALL; p0i7.damage_type = "slash"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 160; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "slash"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 5; p1i2.status_type = "poison"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.RANDOM; p1i3.damage_type = "slash"
	e.phase_patterns = [[p0i1, p0i2, p0i3, p0i4, p0i5, p0i6, p0i7], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── 보스 ────

static func hydra(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.hydra"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "greek"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 180; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "poison"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 180; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "poison"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 140; p0i3.target = IntentRes.TargetType.ALL; p0i3.damage_type = "poison"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "poison"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "poison"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "poison"
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 220; p1i4.target = IntentRes.TargetType.LOWEST_HP; p1i4.damage_type = "poison"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 240; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "poison"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 240; p2i2.target = IntentRes.TargetType.RANDOM; p2i2.damage_type = "poison"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 200; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "poison"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 260; p2i4.target = IntentRes.TargetType.LOWEST_HP; p2i4.damage_type = "poison"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.DEBUFF; p2i5.value = 2; p2i5.status_type = "vulnerable"
	p2i5.target = IntentRes.TargetType.ALL
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["minotaur", "scylla", "gorgon", "medusa"]

static func boss() -> String:
	return "hydra"
