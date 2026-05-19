# resources/enemies/egyptian/egyptian_act1.gd
# 이집트 신화 — Act1 초반 사막 엘리트 3종 + 보스(세크메트)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func jackal_warrior(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.jackal_warrior"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 130; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 130; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 4; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func scarab_queen(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.scarab_queen"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 4; i1.status_type = "poison"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 40; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 140; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func obelisk_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.obelisk_guardian"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "egyptian"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 60; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 150; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "holy_strike"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "holy_fire"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 220; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "holy_strike"
	e.phase_patterns = [[p0i1, p0i2], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func sekhmet(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sekhmet"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "egyptian"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "blunt"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 160; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "blunt"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 120; p0i3.target = IntentRes.TargetType.ALL; p0i3.damage_type = "blunt"
	# 페이즈1 (66% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "blunt"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "weak"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 200; p1i3.target = IntentRes.TargetType.ALL; p1i3.damage_type = "blunt"
	# 페이즈2 (33% HP 전환)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.value = 10; p2i1.status_type = "strength"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 220; p2i2.target = IntentRes.TargetType.ALL; p2i2.damage_type = "blunt"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 260; p2i3.target = IntentRes.TargetType.LOWEST_HP; p2i3.damage_type = "blunt"
	# sekhmet (사자 여신의 저주) — 페이즈 1 에서 영웅 전체에 weakness_fire 3턴 (사자의 화염).
	var p1i_curse := IntentRes.new()
	p1i_curse.action_type = IntentRes.ActionType.INFLICT_WEAKNESS; p1i_curse.value = 3; p1i_curse.status_type = "weakness_fire"
	p1i_curse.target = IntentRes.TargetType.ALL; p1i_curse.play_animation = "debuff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i_curse, p1i1, p1i2, p1i3],
		[p2i1, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["jackal_warrior", "scarab_queen", "obelisk_guardian"]

static func boss() -> String:
	return "sekhmet"
