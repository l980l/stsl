# resources/enemies/daoist/daoist_act3.gd
const EnemyRes   = preload("res://resources/enemy_resource.gd")
const IntentRes  = preload("res://resources/intent_resource.gd")

static func white_tiger(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.white_tiger"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func vermilion_bird(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.vermilion_bird"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 200; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func black_tortoise(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.black_tortoise"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 70; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 3; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 50; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 210; i5.target = IntentRes.TargetType.RANDOM; i5.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func jade_emperor(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.jade_emperor"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "daoist"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 50; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 190; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "holy_slash"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 160; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "holy_fire"
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.DEBUFF; p0i5.value = 2; p0i5.status_type = "vulnerable"
	p0i5.target = IntentRes.TargetType.RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 220; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "holy_slash"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 190; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "holy_fire"
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 200; p1i4.target = IntentRes.TargetType.LOWEST_HP; p1i4.damage_type = "holy_arrow"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.DEBUFF; p1i5.value = 3; p1i5.status_type = "weak"
	p1i5.target = IntentRes.TargetType.ALL
	var p1i6 := IntentRes.new()
	p1i6.action_type = IntentRes.ActionType.BUFF; p1i6.value = 2; p1i6.status_type = "strength"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 160; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "holy_slash"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 160; p2i2.target = IntentRes.TargetType.RANDOM; p2i2.damage_type = "holy_slash"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 160; p2i3.target = IntentRes.TargetType.RANDOM; p2i3.damage_type = "holy_slash"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 160; p2i4.target = IntentRes.TargetType.RANDOM; p2i4.damage_type = "holy_slash"
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.ATTACK; p2i5.value = 220; p2i5.target = IntentRes.TargetType.ALL; p2i5.damage_type = "holy_fire"
	var p2i6 := IntentRes.new()
	p2i6.action_type = IntentRes.ActionType.DEBUFF; p2i6.value = 3; p2i6.status_type = "vulnerable"
	p2i6.target = IntentRes.TargetType.ALL
	var p2i7 := IntentRes.new()
	p2i7.action_type = IntentRes.ActionType.BUFF; p2i7.value = 3; p2i7.status_type = "strength"
	# jade_emperor (옥황상제) — turn_modes [heaven, earth] FORM_SWITCH. 페이즈 1,2 천계/지상 모드 순환.
	# dynamic_resistance_pool — 오행 면역 (Kunino Quad-Converge 영감, 매 enemy turn 1 속성만 통함).
	e.dynamic_resistance_pool = ["holy_strike", "holy_arrow", "holy_fire", "holy_slash", "blunt"]
	e.turn_modes = ["heaven", "earth"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	var p2i_switch := IntentRes.new()
	p2i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p2i_switch.play_animation = "buff"
	# 페이즈 2 — 천제의 의지 차지업 (counter 가능): 2턴 후 220 ALL holy_fire 천벌
	var p2_charge_atk := IntentRes.new()
	p2_charge_atk.action_type = IntentRes.ActionType.ATTACK; p2_charge_atk.value = 220; p2_charge_atk.target = IntentRes.TargetType.ALL; p2_charge_atk.damage_type = "holy_fire"
	var p2_charge := IntentRes.new()
	p2_charge.action_type = IntentRes.ActionType.CHARGE_UP; p2_charge.charge_turns = 2; p2_charge.payoff_intents = [p2_charge_atk]
	e.counter_window_intent = {"enabled": true}
	# 페이즈 1·2 — 천계 군단 SUMMON (celestial_lion 2마리, 각 페이즈 1회)
	var p1i_summon := IntentRes.new()
	p1i_summon.action_type = IntentRes.ActionType.SUMMON; p1i_summon.value = 2; p1i_summon.status_type = "celestial_lion"
	p1i_summon.play_animation = "buff"
	var p2i_summon := IntentRes.new()
	p2i_summon.action_type = IntentRes.ActionType.SUMMON; p2i_summon.value = 2; p2i_summon.status_type = "celestial_lion"
	p2i_summon.play_animation = "buff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5],
		[p1i_switch, p1i1, p1i_summon, p1i2, p1i3, p1i4, p1i5, p1i6],
		[p2i_switch, p2i1, p2_charge, p2i_summon, p2i2, p2i3, p2i4, p2i5, p2i6, p2i7]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	var _trigger := IntentRes.new()
	_trigger.action_type = IntentRes.ActionType.DEBUFF
	_trigger.value = 2
	_trigger.target = IntentRes.TargetType.ALL
	_trigger.status_type = "weak"
	_trigger.play_animation = "buff"
	e.card_count_trigger = {
		"card_type": CardResource.CardType.POWER,
		"threshold": 1,
		"intent": _trigger,
		"repeat": true,
		"tooltip_key": "enemy.daoist.jade_emperor.counter",
	}
	return e

static func elites() -> Array:
	return ["white_tiger", "vermilion_bird", "black_tortoise"]

static func boss() -> String:
	return "jade_emperor"
