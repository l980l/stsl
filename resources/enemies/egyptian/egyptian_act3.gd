# resources/enemies/egyptian/egyptian_act3.gd
# 이집트 신화 — Act3 엘리트 3종 + 보스(라-호라크티)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func apophis_serpent(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.egyptian.apophis_serpent"); e.max_hp = 2000; e.character_scene = scene
	e.mythology = "egyptian"
	# 4턴 순환: DEBUFF poison ALL / ATK RANDOM / ATK RANDOM / DEBUFF poison RANDOM
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.status_type = "poison"; i1.value = 5
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.status_type = "poison"; i4.value = 3
	i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func set_tempest(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.egyptian.set_tempest"); e.max_hp = 2100; e.character_scene = scene
	e.mythology = "egyptian"
	# 4턴 순환: ATK RANDOM / ATK RANDOM / BUFF strength / ATK ALL
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 190; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 190; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "strength"; i3.value = 6
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func isis_phantom(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.egyptian.isis_phantom"); e.max_hp = 1950; e.character_scene = scene
	e.mythology = "egyptian"
	e.phase_thresholds = [0.5]
	# 페이즈0: DEBUFF weak ALL / DEBUFF vulnerable ALL / ATK RANDOM
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.DEBUFF; p0i1.status_type = "weak"; p0i1.value = 2
	p0i1.target = IntentRes.TargetType.ALL
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "vulnerable"; p0i2.value = 2
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 150; p0i3.target = IntentRes.TargetType.RANDOM
	# 페이즈1: ATK ALL / DEBUFF vulnerable ALL / ATK LOWEST_HP
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.status_type = "vulnerable"; p1i2.value = 3
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 240; p1i3.target = IntentRes.TargetType.LOWEST_HP
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func ra_horakhty(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.egyptian.ra_horakhty"); e.max_hp = 5000; e.character_scene = scene
	e.mythology = "egyptian"
	e.phase_thresholds = [0.65, 0.3]
	e.charm_resistance = 2
	# 페이즈0: ATK RANDOM / DEBUFF weak ALL / ATK RANDOM / ATK ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "weak"; p0i2.value = 2
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 150; p0i3.target = IntentRes.TargetType.RANDOM
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 130; p0i4.target = IntentRes.TargetType.ALL
	# 페이즈1 (65% HP 전환): ATK RANDOM / DEBUFF poison ALL / ATK ALL / ATK LOWEST_HP
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.status_type = "poison"; p1i2.value = 6
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 200; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 220; p1i4.target = IntentRes.TargetType.LOWEST_HP
	# 페이즈2 (30% HP 전환): BUFF strength / ATK ALL / DEBUFF vulnerable ALL / ATK LOWEST_HP
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.status_type = "strength"; p2i1.value = 15
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 260; p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.DEBUFF; p2i3.status_type = "vulnerable"; p2i3.value = 3
	p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 300; p2i4.target = IntentRes.TargetType.LOWEST_HP
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── API ────
static func elites() -> Array: return ["apophis_serpent", "set_tempest", "isis_phantom"]
static func boss() -> String: return "ra_horakhty"
