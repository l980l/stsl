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
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 180; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "strength"; i3.value = 8
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 220; i4.target = IntentRes.TargetType.ALL
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
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM
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
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 160; p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 160; p0i3.target = IntentRes.TargetType.RANDOM
	# 페이즈1: ATK ALL / BUFF strength / ATK RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 220; p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.BUFF; p1i2.status_type = "strength"; p1i2.value = 10
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 260; p1i3.target = IntentRes.TargetType.RANDOM
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func kronos(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.kronos"; e.max_hp = 5200; e.character_scene = scene
	e.mythology = "greek"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.65, 0.3]
	e.charm_resistance = 2
	# 페이즈0: ATK RANDOM / DEBUFF weak ALL / ATK RANDOM / ATK ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "weak"; p0i2.value = 2
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 160; p0i3.target = IntentRes.TargetType.RANDOM
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 140; p0i4.target = IntentRes.TargetType.ALL
	# 페이즈1 (65% HP 전환): BUFF strength / ATK ALL / DEBUFF vulnerable ALL / ATK LOWEST_HP
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.BUFF; p1i1.status_type = "strength"; p1i1.value = 8
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.status_type = "vulnerable"; p1i3.value = 3
	p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 240; p1i4.target = IntentRes.TargetType.LOWEST_HP
	# 페이즈2 (30% HP 전환): BUFF strength / ATK ALL / ATK LOWEST_HP
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.status_type = "strength"; p2i1.value = 20
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 280; p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 320; p2i3.target = IntentRes.TargetType.LOWEST_HP
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3]
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
