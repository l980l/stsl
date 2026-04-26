# resources/enemies/japanese/japanese_act1.gd
# 일본 신화 Act 1 — 엘리트 3종(오니 장군·야마우바·로닌 무적) + 보스(라이덴)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func oni_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.oni_general"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func yamamba(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamamba"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func invincible_ronin(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.invincible_ronin"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func raijin(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.raijin"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "japanese"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 뇌고
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.DEBUFF; p0i4.value = 2; p0i4.status_type = "vulnerable"
	p0i4.target = IntentRes.TargetType.RANDOM
	# Phase 1 — 번개 강림
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 190; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.BUFF; p1i4.value = 2; p1i4.status_type = "strength"
	# Phase 2 — 폭풍 해방
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 220; p2i1.target = IntentRes.TargetType.LOWEST_HP
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 190; p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.BUFF; p2i4.value = 3; p2i4.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["oni_general", "yamamba", "invincible_ronin"]

static func boss() -> String:
	return "raijin"
