# resources/enemies/norse/norse_act1.gd
# 북유럽 신화 — Act1 미드가르드 변경 초반 엘리트 3종 + 보스(피요르기닌)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func nidhogg_larva(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "니드호그 유충"; e.max_hp = 1750; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 3; i1.status_type = "poison"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 120; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 5; i4.status_type = "poison"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func skoll(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "스콜 늑대"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 140; i1.target = IntentRes.TargetType.LOWEST_HP
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 6; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func hrimthurs_scout(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "서리 거인 척후"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 50; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 130; p0i2.target = IntentRes.TargetType.RANDOM
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 170; p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.RANDOM
	e.phase_patterns = [[p0i1, p0i2], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func fjorgynn(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "피요르기닌"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.66, 0.33]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 40; p0i2.status_type = "block"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 150; p0i3.target = IntentRes.TargetType.RANDOM
	# 페이즈1 (66% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 200; p1i3.target = IntentRes.TargetType.ALL
	# 페이즈2 (33% HP 전환)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.value = 10; p2i1.status_type = "strength"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 230; p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 260; p2i3.target = IntentRes.TargetType.LOWEST_HP
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i2, p1i3],
		[p2i1, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

# ──── API ────

static func elites() -> Array:
	return ["nidhogg_larva", "skoll", "hrimthurs_scout"]

static func boss() -> String:
	return "fjorgynn"
