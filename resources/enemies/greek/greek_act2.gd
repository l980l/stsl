# resources/enemies/greek/greek_act2.gd
# 그리스 신화 — Act2 하계·저승 엘리트 3종 + 보스(하데스)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func cerberus(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.cerberus"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 170; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 170; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "fire"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 5; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func charon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.charon"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 160; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 50; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 200; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func erinyes(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.erinyes"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "greek"
	e.phase_thresholds = [0.5]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 140; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "curse"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 2; p0i2.status_type = "vulnerable"
	p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 140; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "curse"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "curse"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 180; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "curse"
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func hades(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.hades"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "greek"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.65, 0.3]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 150; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "curse"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 2; p0i2.status_type = "weak"
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 150; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "curse"
	# 페이즈1 (65% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 180; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "curse"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 220; p1i3.target = IntentRes.TargetType.LOWEST_HP; p1i3.damage_type = "curse"
	# 페이즈2 (30% HP 전환)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.BUFF; p2i1.value = 12; p2i1.status_type = "strength"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 90; p2i2.target = IntentRes.TargetType.ALL; p2i2.damage_type = "curse"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 260; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "fire"
	# hades (저승의 왕) — 영혼 정화: 페이즈 1, 2 에서 DISPEL ALL (영웅 strength/block 제거).
	var p1i_dispel := IntentRes.new()
	p1i_dispel.action_type = IntentRes.ActionType.DISPEL
	p1i_dispel.target = IntentRes.TargetType.ALL; p1i_dispel.play_animation = "debuff"
	var p2i_dispel := IntentRes.new()
	p2i_dispel.action_type = IntentRes.ActionType.DISPEL
	p2i_dispel.target = IntentRes.TargetType.ALL; p2i_dispel.play_animation = "debuff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i_dispel, p1i1, p1i2, p1i3],
		[p2i1, p2i_dispel, p2i2, p2i3]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["cerberus", "charon", "erinyes"]

static func boss() -> String:
	return "hades"
