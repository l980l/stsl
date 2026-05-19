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
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func yamamba(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.yamamba"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func invincible_ronin(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.invincible_ronin"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "japanese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func raijin(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.japanese.raijin"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "japanese"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 뇌고
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "lightning"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.ALL; p0i3.damage_type = "lightning"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.DEBUFF; p0i4.value = 2; p0i4.status_type = "vulnerable"
	p0i4.target = IntentRes.TargetType.RANDOM
	# Phase 1 — 번개 강림
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 190; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "lightning"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "lightning"
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.BUFF; p1i4.value = 2; p1i4.status_type = "strength"
	# Phase 2 — 폭풍 해방
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 220; p2i1.target = IntentRes.TargetType.LOWEST_HP; p2i1.damage_type = "lightning"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 190; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "lightning"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.BUFF; p2i4.value = 3; p2i4.status_type = "strength"
	# raijin (천둥신) — 충전(charge)/방전(discharge) 모드 순환. 페이즈 1 부터 FORM_SWITCH 활성.
	e.turn_modes = ["charge", "discharge"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	var p2i_switch := IntentRes.new()
	p2i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p2i_switch.play_animation = "buff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i_switch, p1i1, p1i2, p1i3, p1i4],
		[p2i_switch, p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["oni_general", "yamamba", "invincible_ronin"]

static func boss() -> String:
	return "raijin"
