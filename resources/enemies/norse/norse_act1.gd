# resources/enemies/norse/norse_act1.gd
# 북유럽 신화 — Act1 미드가르드 변경 초반 엘리트 3종 + 보스(피요르기닌)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func nidhogg_larva(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.nidhogg_larva"; e.max_hp = 1750; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 30; i1.status_type = "poison"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 120; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "poison"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 50; i4.status_type = "poison"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func skoll(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.skoll"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 140; i1.target = IntentRes.TargetType.LOWEST_HP; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 6; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func modgud(scene: PackedScene) -> Resource:
	# 모드구드 — 죽음의 강 갈라르 다리 수문장. 페이즈 2 영웅 1명에 heal_block 2턴
	# (삶으로 가는 길을 막는다 — 구 hrimthurs_scout 리스킨, 메커니즘 동일)
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.modgud"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 50; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 130; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "ice"
	var p1i_freeze := IntentRes.new()
	p1i_freeze.action_type = IntentRes.ActionType.DEBUFF; p1i_freeze.value = 2; p1i_freeze.status_type = "heal_block"
	p1i_freeze.target = IntentRes.TargetType.RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 170; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "ice"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "ice"
	e.phase_patterns = [[p0i1, p0i2], [p1i_freeze, p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func fjorgynn(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.fjorgynn"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "norse"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "holy_blunt"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 40; p0i2.status_type = "block"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 150; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "holy_blunt"
	# 페이즈1 (66% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "holy_blunt"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 200; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "holy_fire"
	# 페이즈2 (33% HP 전환)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.value = 10; p2i1.status_type = "strength"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 230; p2i2.target = IntentRes.TargetType.ALL; p2i2.damage_type = "holy_fire"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 260; p2i3.target = IntentRes.TargetType.LOWEST_HP; p2i3.damage_type = "holy_arrow"
	# fjorgynn (대지의 어머니) — turn_modes 정의 + FORM_SWITCH intent 페이즈 1 에 추가.
	# guardian (대지 방어 buff +block 30) / wrath (공격 모드) 순환.
	e.turn_modes = ["guardian", "wrath"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	# 페이즈 2 — 대지의 분노 차지업 (counter 가능): 2턴 후 230 LOWEST_HP holy_fire 단일 폭격
	var p2_charge_atk := IntentRes.new()
	p2_charge_atk.action_type = IntentRes.ActionType.ATTACK; p2_charge_atk.value = 230; p2_charge_atk.target = IntentRes.TargetType.LOWEST_HP; p2_charge_atk.damage_type = "holy_fire"
	var p2_charge := IntentRes.new()
	p2_charge.action_type = IntentRes.ActionType.CHARGE_UP; p2_charge.charge_turns = 2; p2_charge.payoff_intents = [p2_charge_atk]
	e.counter_window_intent = {"enabled": true}
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i_switch, p1i2, p1i3],
		[p2i1, p2_charge, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["nidhogg_larva", "skoll", "modgud"]

static func boss() -> String:
	return "fjorgynn"
