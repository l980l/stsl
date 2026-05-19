# resources/enemies/daoist/daoist_act2.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func crimson_immortal(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.crimson_immortal"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "fire"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	e.charm_resistance = 20
	return e

static func nine_dragon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.nine_dragon"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 30; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "holy_slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 220; i5.target = IntentRes.TargetType.RANDOM; i5.damage_type = "holy_slash"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func twin_immortals(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.twin_immortals"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 130; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 130; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.RANDOM
	# 쌍둥이 분신 모방 — 영웅 누적 데미지 35% 반사 (Yamabiko 영감, MIMIC 35%)
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.MIMIC; i4.value = 35; i4.target = IntentRes.TargetType.LOWEST_HP
	i4.play_animation = "debuff"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 160; i5.target = IntentRes.TargetType.LOWEST_HP; i5.damage_type = "slash"
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.DEBUFF; i6.value = 2; i6.status_type = "weak"
	i6.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	e.charm_resistance = 20
	return e

static func xuanwu(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.xuanwu"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "daoist"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 1; p0i1.status_type = "strength"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 40; p0i2.status_type = "block"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 170; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "holy_slash"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "holy_fire"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "holy_slash"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 160; p1i2.target = IntentRes.TargetType.ALL; p1i2.damage_type = "holy_fire"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.RANDOM
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 180; p1i4.target = IntentRes.TargetType.LOWEST_HP; p1i4.damage_type = "holy_arrow"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 2; p1i5.status_type = "strength"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 180; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "holy_slash"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 180; p2i2.target = IntentRes.TargetType.RANDOM; p2i2.damage_type = "holy_slash"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 220; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "holy_fire"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.DEBUFF; p2i4.value = 2; p2i4.status_type = "vulnerable"
	p2i4.target = IntentRes.TargetType.ALL
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.BUFF; p2i5.value = 3; p2i5.status_type = "strength"
	# xuanwu (현무, 거북 + 뱀) — turn_modes [shell, serpent] FORM_SWITCH. 페이즈 1,2.
	# shell (방어 모드 — 거북 등껍질) / serpent (공격 모드 — 뱀의 독)
	e.turn_modes = ["shell", "serpent"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	var p2i_switch := IntentRes.new()
	p2i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p2i_switch.play_animation = "buff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i_switch, p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i_switch, p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["crimson_immortal", "nine_dragon", "twin_immortals"]

static func boss() -> String:
	return "xuanwu"
