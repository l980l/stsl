# resources/enemies/norse/norse_act2.gd
# 북유럽 신화 — Act2 요툰헤임 침입 엘리트 3종 + 보스(수르트)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func troll_warrior(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.troll_warrior"; e.max_hp = 2050; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 160; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 60; i2.status_type = "block"
	# CHARGE_UP 2턴 → 단발 강력한 둔기 한 방 (페이오프 = 강공격만, 디버프 X)
	var payoff := IntentRes.new()
	payoff.action_type = IntentRes.ActionType.ATTACK; payoff.value = 320; payoff.target = IntentRes.TargetType.RANDOM; payoff.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.CHARGE_UP; i3.charge_turns = 2; i3.payoff_intents = [payoff]
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 140; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func norn(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.norn"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 170; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "holy_blunt"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 6; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func vanir_elf(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.vanir_elf"; e.max_hp = 1850; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 130; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "projectile"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 130; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "projectile"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 40; p0i3.status_type = "poison"
	p0i3.target = IntentRes.TargetType.ALL
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 190; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "projectile"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 220; p1i2.target = IntentRes.TargetType.LOWEST_HP; p1i2.damage_type = "projectile"
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func surtr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.surtr"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "norse"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.65, 0.3]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 170; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "fire"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 170; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "fire"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 140; p0i3.target = IntentRes.TargetType.ALL; p0i3.damage_type = "fire"
	# 페이즈1 (65% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.BUFF; p1i1.value = 5; p1i1.status_type = "strength"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.ALL; p1i2.damage_type = "fire"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.ALL
	# 페이즈2 (30% HP 전환) — CHARGE_UP 등장: 2턴 숨고르기 후 ALL 강공격 + vulnerable 2 ALL
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.value = 15; p2i1.status_type = "strength"
	var p2_charge_atk := IntentRes.new()
	p2_charge_atk.action_type = IntentRes.ActionType.ATTACK; p2_charge_atk.value = 380; p2_charge_atk.target = IntentRes.TargetType.ALL; p2_charge_atk.damage_type = "fire"
	var p2_charge_dbf := IntentRes.new()
	p2_charge_dbf.action_type = IntentRes.ActionType.DEBUFF; p2_charge_dbf.value = 2; p2_charge_dbf.status_type = "vulnerable"
	p2_charge_dbf.target = IntentRes.TargetType.ALL
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.CHARGE_UP; p2i2.charge_turns = 2; p2i2.payoff_intents = [p2_charge_atk, p2_charge_dbf]
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 300; p2i3.target = IntentRes.TargetType.LOWEST_HP; p2i3.damage_type = "fire"
	# surtr (불의 거인) — turn_modes [smolder, blaze] FORM_SWITCH (충전/방출). 페이즈 1,2.
	# counter_window_intent — 페이즈 2 의 CHARGE_UP 380 ALL 가 영웅 COUNTER_CHARGE 카드로 무효 가능.
	e.counter_window_intent = {"enabled": true}
	e.turn_modes = ["smolder", "blaze"]
	var p1i_switch := IntentRes.new()
	p1i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p1i_switch.play_animation = "buff"
	var p2i_switch := IntentRes.new()
	p2i_switch.action_type = IntentRes.ActionType.FORM_SWITCH; p2i_switch.play_animation = "buff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i_switch, p1i2, p1i3],
		[p2i1, p2i_switch, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["troll_warrior", "norn", "vanir_elf"]

static func boss() -> String:
	return "surtr"
