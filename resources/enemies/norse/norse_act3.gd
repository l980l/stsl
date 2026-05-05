# resources/enemies/norse/norse_act3.gd
# 북유럽 신화 — Act3 엘리트 3종 + 보스(요르문간드르)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 엘리트 3종 ────

static func fenrir_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.fenrir_cub"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.5]
	# 페이즈0: strength 버프 후 공격 (매 루프 강해짐)
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.status_type = "strength"; p0i1.value = 8
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 170; p0i2.target = IntentRes.TargetType.RANDOM; p0i2.damage_type = "slash"
	# 페이즈1: 2연타
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "slash"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.RANDOM; p1i2.damage_type = "slash"
	e.phase_patterns = [[p0i1, p0i2], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

static func valkyrie(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.valkyrie"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "norse"
	# 단일 페이즈 5턴 패턴
	e.phase_thresholds = []
	e.phase_patterns = []
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 160; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.status_type = "weak"; i2.value = 2
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "block"; i3.value = 60
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 250; i4.target = IntentRes.TargetType.LOWEST_HP; i4.damage_type = "slash"
	# SPECIAL value=2: 자가 회복 표시
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 2
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func jormungandr_shard(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.jormungandr_shard"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "norse"
	e.phase_thresholds = [0.4]
	# 페이즈0: 공격 후 독 부여 (2인텐트 분리)
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 140; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "poison"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "poison"; p0i2.value = 4
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 140; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "poison"
	# 페이즈1: 전체 공격 + 강독
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.ALL; p1i1.damage_type = "poison"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.status_type = "poison"; p1i2.value = 6
	p1i2.target = IntentRes.TargetType.ALL
	e.phase_patterns = [[p0i1, p0i2, p0i3], [p1i1, p1i2]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func jormungandr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.jormungandr"; e.max_hp = 5000; e.character_scene = scene
	e.mythology = "norse"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.65, 0.3]
	# 페이즈0
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 130; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "poison"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.status_type = "poison"; p0i2.value = 5
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.RANDOM; p0i3.damage_type = "poison"
	# 페이즈1 (65% HP 전환)
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 160; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "poison"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.status_type = "poison"; p1i2.value = 6
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 200; p1i3.target = IntentRes.TargetType.LOWEST_HP; p1i3.damage_type = "poison"
	# 페이즈2 (30% HP 전환) — 강독+전체공격+strength+강타 (분리)
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.DEBUFF; p2i1.status_type = "poison"; p2i1.value = 10
	p2i1.target = IntentRes.TargetType.ALL
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 80; p2i2.target = IntentRes.TargetType.ALL; p2i2.damage_type = "poison"
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.BUFF; p2i3.status_type = "strength"; p2i3.value = 15
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 250; p2i4.target = IntentRes.TargetType.ALL; p2i4.damage_type = "poison"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i2, p1i3],
		[p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

# ──── API ────

static func elites() -> Array:
	return ["fenrir_cub", "valkyrie", "jormungandr_shard"]

static func boss() -> String:
	return "jormungandr"
