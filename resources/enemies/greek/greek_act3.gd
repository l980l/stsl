# resources/enemies/greek/greek_act3.gd
# 그리스 신화 — Act3 엘리트 3종 + 보스(크로노스)
const EnemyRes   = preload("res://resources/enemy_resource.gd")
const IntentRes  = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func ares_hound(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.ares_hound"; e.max_hp = 2100; e.character_scene = scene
	e.mythology = "greek"
	# 4턴 순환: ATK RANDOM / ATK RANDOM / BUFF strength / ATK ALL
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 180; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "strength"; i3.value = 8
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 220; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func poseidon_apostle(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.poseidon_apostle"; e.max_hp = 1950; e.character_scene = scene
	e.mythology = "greek"
	# 4턴 순환: DEBUFF weak ALL / ATK RANDOM / ATK RANDOM / DEBUFF vulnerable ALL
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.status_type = "weak"; i1.value = 3
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.status_type = "vulnerable"; i4.value = 2
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func hephaestus_automaton(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.hephaestus_automaton"; e.max_hp = 2200; e.character_scene = scene
	e.mythology = "greek"
	e.phase_thresholds = [0.5]
	# 페이즈0: BUFF block / ATK RANDOM / ATK RANDOM
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.status_type = "block"; p0i1.value = 80
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 160; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "explosive"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 160; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "explosive"
	# 페이즈1: ATK ALL / BUFF strength / ATK RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 220; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "explosive"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.BUFF; p1i2.status_type = "strength"; p1i2.value = 10
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 260; p1i3.target = IntentRes.TargetType.RANDOM; p1i3.damage_type = "explosive"
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func kronos(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.kronos"; e.max_hp = 5200; e.character_scene = scene
	e.mythology = "greek"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.65, 0.3]
	e.charm_resistance = 20
	# 페이즈0: ATK RANDOM / DEBUFF weak ALL / ATK RANDOM / ATK ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "holy_strike"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "weak"; p0i2.value = 2
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 160; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "holy_strike"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL; p0i4.damage_type = "holy_fire"
	# 페이즈1 (65% HP 전환): BUFF strength / ATK ALL / DEBUFF vulnerable ALL / ATK LOWEST_HP
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.BUFF; p1i1.status_type = "strength"; p1i1.value = 8
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.ALL; p1i2.damage_type = "holy_fire"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.status_type = "vulnerable"; p1i3.value = 3
	p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 240; p1i4.target = IntentRes.TargetType.LOWEST_HP; p1i4.damage_type = "holy_arrow"
	# 페이즈2 (30% HP 전환): BUFF strength / ATK ALL / ATK LOWEST_HP
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.status_type = "strength"; p2i1.value = 20
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 280; p2i2.target = IntentRes.TargetType.ALL; p2i2.damage_type = "holy_fire"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 320; p2i3.target = IntentRes.TargetType.LOWEST_HP; p2i3.damage_type = "holy_arrow"
	# kronos (시간의 신) — 시간의 변천: 페이즈 1, 2 에서 CHANGE_AFFINITY (신성 속성 동적 변경).
	# 페이즈 2 진입 시 double_action 5 (Renoir Enrage 영감) — 가속화 시간.
	e.phase_buffs = [[], [], [{"status": "double_action", "value": 5}]]
	e.dynamic_affinity_pool = ["holy_strike", "holy_fire", "holy_arrow", "holy_slash"]
	var p1i_aff := IntentRes.new()
	p1i_aff.action_type = IntentRes.ActionType.CHANGE_AFFINITY; p1i_aff.play_animation = "buff"
	var p2i_aff := IntentRes.new()
	p2i_aff.action_type = IntentRes.ActionType.CHANGE_AFFINITY; p2i_aff.play_animation = "buff"
	# 페이즈 2 — 시간 응집 차지업 (counter 가능): 2턴 후 280 ALL holy_fire + vulnerable 3 ALL
	var p2_charge_atk := IntentRes.new()
	p2_charge_atk.action_type = IntentRes.ActionType.ATTACK; p2_charge_atk.value = 280; p2_charge_atk.target = IntentRes.TargetType.ALL; p2_charge_atk.damage_type = "holy_fire"
	var p2_charge_dbf := IntentRes.new()
	p2_charge_dbf.action_type = IntentRes.ActionType.DEBUFF; p2_charge_dbf.value = 3; p2_charge_dbf.status_type = "vulnerable"
	p2_charge_dbf.target = IntentRes.TargetType.ALL
	var p2_charge := IntentRes.new()
	p2_charge.action_type = IntentRes.ActionType.CHARGE_UP; p2_charge.charge_turns = 2; p2_charge.payoff_intents = [p2_charge_atk, p2_charge_dbf]
	e.counter_window_intent = {"enabled": true}
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i_aff, p1i1, p1i2, p1i3, p1i4],
		[p2i_aff, p2i1, p2_charge, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	# 카드 타입 카운터: 기술 카드 5장마다 영웅 전체에 취약 +2 부여
	var _ktrigger := IntentRes.new()
	_ktrigger.action_type = IntentRes.ActionType.DEBUFF
	_ktrigger.value = 2
	_ktrigger.target = IntentRes.TargetType.ALL
	_ktrigger.status_type = "vulnerable"
	_ktrigger.play_animation = "buff"
	e.card_count_trigger = {
		"card_type": CardResource.CardType.SKILL,
		"threshold": 5,
		"intent": _ktrigger,
		"repeat": true,
		"tooltip_key": "enemy.greek.kronos.counter",
	}
	return e

# ──── API ────
static func elites() -> Array: return ["ares_hound", "poseidon_apostle", "hephaestus_automaton"]
static func boss() -> String: return "kronos"
