# resources/enemies/japanese/japanese_act3.gd
# 일본 신화 Act 3 — 엘리트 3종(아마노이와토 수문장·스사노오의 검·유키온나의 여왕) + 보스(야마타노오로치)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func iwato_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.iwato_guardian"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 70; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 50; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 190; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func susanoo_blade(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.susanoo_blade"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 190; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "lightning"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "lightning"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func blizzard_queen(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.blizzard_queen"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 3; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "ice"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "ice"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.BUFF; i5.value = 2; i5.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func yamata_no_orochi(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamata_no_orochi"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "japanese"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 여덟 머리 (8 heads)
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "poison"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 150; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "poison"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 2; p0i3.status_type = "weak"
	p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "poison"
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.BUFF; p0i5.value = 1; p0i5.status_type = "strength"
	# Phase 1 — 다섯 머리 (공격력 증가)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 190; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "poison"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 190; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "poison"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 180; p1i4.target = IntentRes.TargetType.ALL; p1i4.damage_type = "poison"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 2; p1i5.status_type = "strength"
	# Phase 2 — 두 머리 (최고 공격력)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 230; p2i1.target = IntentRes.TargetType.LOWEST_HP; p2i1.damage_type = "poison"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 230; p2i2.target = IntentRes.TargetType.RANDOM; p2i2.damage_type = "poison"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.DEBUFF; p2i3.value = 3; p2i3.status_type = "vulnerable"
	p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 220; p2i4.target = IntentRes.TargetType.ALL; p2i4.damage_type = "poison"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.BUFF; p2i5.value = 3; p2i5.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5],
		[p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["iwato_guardian", "susanoo_blade", "blizzard_queen"]

static func boss() -> String:
	return "yamata_no_orochi"
