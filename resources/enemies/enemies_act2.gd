# resources/enemies/enemies_act2.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 일반 적 6종 ────

static func sand_scout(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "사막 척후병"; e.max_hp = 380; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func desert_scorpion(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "사막 전갈"; e.max_hp = 420; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM
	var i1b := IntentRes.new()
	i1b.action_type = IntentRes.ActionType.DEBUFF; i1b.value = 4; i1b.status_type = "poison"; i1b.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i1b, i2]
	return e

static func mummy_warrior(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "미라 전사"; e.max_hp = 600; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func sphinx_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "스핑크스 새끼"; e.max_hp = 350; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 1
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func sand_ifrit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "모래 이프리트"; e.max_hp = 450; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 230; i2.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2]
	return e

static func ka_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "카 영혼"; e.max_hp = 320; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 55; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "weak"; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 엘리트 3종 ────

static func apep_snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "아펩 뱀"; e.max_hp = 1600; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 140; i1.target = IntentRes.TargetType.RANDOM
	var i1b := IntentRes.new()
	i1b.action_type = IntentRes.ActionType.DEBUFF; i1b.value = 5; i1b.status_type = "poison"; i1b.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM
	var i2b := IntentRes.new()
	i2b.action_type = IntentRes.ActionType.DEBUFF; i2b.value = 5; i2b.status_type = "poison"; i2b.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 3; i3.status_type = "weak"; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 200; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i1b, i2, i2b, i3, i4]
	return e

static func seth_hound(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "세트의 사냥개"; e.max_hp = 1800; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 150; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 2; i2.status_type = "strength"
	var i2b := IntentRes.new()
	i2b.action_type = IntentRes.ActionType.ATTACK; i2b.value = 150; i2b.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 280; i3.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i2b, i3]
	return e

static func ba_bird(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "바 새"; e.max_hp = 1500; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 110; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 2
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

# ──── 보스 ────

static func osiris(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "오시리스"; e.max_hp = 3000; e.character_scene = scene
	e.phase_thresholds = [0.5]
	e.phase_heal_ratios = [0.6]

	# 페이즈 0 (4턴 순환)
	var p0_i1 := IntentRes.new()
	p0_i1.action_type = IntentRes.ActionType.ATTACK; p0_i1.value = 180; p0_i1.target = IntentRes.TargetType.RANDOM
	var p0_i2 := IntentRes.new()
	p0_i2.action_type = IntentRes.ActionType.ATTACK; p0_i2.value = 180; p0_i2.target = IntentRes.TargetType.RANDOM
	var p0_i3 := IntentRes.new()
	p0_i3.action_type = IntentRes.ActionType.BUFF; p0_i3.value = 1; p0_i3.status_type = "strength"
	var p0_i3b := IntentRes.new()
	p0_i3b.action_type = IntentRes.ActionType.DEBUFF; p0_i3b.value = 2; p0_i3b.status_type = "vulnerable"; p0_i3b.target = IntentRes.TargetType.ALL
	var p0_i4 := IntentRes.new()
	p0_i4.action_type = IntentRes.ActionType.ATTACK; p0_i4.value = 220; p0_i4.target = IntentRes.TargetType.ALL

	# 페이즈 1 (5턴 순환, 부활 후)
	var p1_i1 := IntentRes.new()
	p1_i1.action_type = IntentRes.ActionType.BUFF; p1_i1.value = 2; p1_i1.status_type = "strength"; p1_i1.condition = "부활"
	var p1_i2 := IntentRes.new()
	p1_i2.action_type = IntentRes.ActionType.ATTACK; p1_i2.value = 220; p1_i2.target = IntentRes.TargetType.RANDOM
	var p1_i2b := IntentRes.new()
	p1_i2b.action_type = IntentRes.ActionType.DEBUFF; p1_i2b.value = 6; p1_i2b.status_type = "poison"; p1_i2b.target = IntentRes.TargetType.RANDOM
	var p1_i3 := IntentRes.new()
	p1_i3.action_type = IntentRes.ActionType.ATTACK; p1_i3.value = 220; p1_i3.target = IntentRes.TargetType.ALL
	var p1_i4 := IntentRes.new()
	p1_i4.action_type = IntentRes.ActionType.DEBUFF; p1_i4.value = 3; p1_i4.status_type = "weak"; p1_i4.target = IntentRes.TargetType.ALL
	var p1_i4b := IntentRes.new()
	p1_i4b.action_type = IntentRes.ActionType.DEBUFF; p1_i4b.value = 3; p1_i4b.status_type = "vulnerable"; p1_i4b.target = IntentRes.TargetType.ALL
	var p1_i5 := IntentRes.new()
	p1_i5.action_type = IntentRes.ActionType.ATTACK; p1_i5.value = 300; p1_i5.target = IntentRes.TargetType.LOWEST_HP

	e.intent_pattern = [p0_i1, p0_i2, p0_i3, p0_i3b, p0_i4]
	e.phase_patterns = [
		[p0_i1, p0_i2, p0_i3, p0_i3b, p0_i4],
		[p1_i1, p1_i2, p1_i2b, p1_i3, p1_i4, p1_i4b, p1_i5],
	]
	return e
