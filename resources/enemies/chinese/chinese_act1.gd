# resources/enemies/chinese/chinese_act1.gd
# 중국 신화 Act 1 — 엘리트 3종(금각·은각·흑풍괴) + 보스(치우)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func golden_horn_king(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "금각 대왕"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 130; i5.target = IntentRes.TargetType.ALL
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.DEBUFF; i6.value = 2; i6.status_type = "vulnerable"
	i6.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	e.charm_resistance = 1
	return e

static func silver_horn_king(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "은각 대왕"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 2; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func black_wind_demon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "흑풍괴"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 120; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 1; i5.status_type = "vulnerable"
	i5.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func chiyou(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "치우"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "chinese"
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 청동 창
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.BUFF; p0i4.value = 1; p0i4.status_type = "strength"
	# Phase 1 — 혈철 도끼
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 160; p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.RANDOM
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 180; p1i4.target = IntentRes.TargetType.RANDOM
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 2; p1i5.status_type = "strength"
	# Phase 2 — 천계 혈창
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 240; p2i1.target = IntentRes.TargetType.RANDOM
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 200; p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.BUFF; p2i4.value = 3; p2i4.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["golden_horn_king", "silver_horn_king", "black_wind_demon"]

static func boss() -> String:
	return "chiyou"
