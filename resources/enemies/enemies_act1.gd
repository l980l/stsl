# resources/enemies/enemies_act1.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 일반 적 6종 ────

static func satyr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "사티로스"; e.max_hp = 350; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2]
	return e

static func harpy(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "하르피아"; e.max_hp = 280; e.character_scene = scene
	# 턴1: ATTACK 45 x2, 턴2: ATTACK 45 x2, 턴3: SPECIAL(카드 버리기)
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 45; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 45; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 45; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 45; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 0
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func cyclops(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "사이클롭스"; e.max_hp = 700; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.PREPARE; i1.value = 0; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 200; i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2]
	return e

static func snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "메두사의 뱀"; e.max_hp = 300; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2]
	return e

static func cerberus(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "케르베로스"; e.max_hp = 900; e.character_scene = scene
	# 턴1: ATK 70 x3, 턴2: ATK 70 x2 + ATK 90 ALL
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 70; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 70; i5.target = IntentRes.TargetType.RANDOM
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.ATTACK; i6.value = 90; i6.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	return e

static func myrmidon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "미르미돈 병사"; e.max_hp = 250; e.character_scene = scene
	# 턴1: ATK 60, 턴2: BUFF strength + ATK 60, 턴3: ATK 90
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 90; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 엘리트 ────

static func minotaur(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "미노타우로스"; e.max_hp = 2000; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 150; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 260; i3.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3]
	return e

static func medusa(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "메두사"; e.max_hp = 1700; e.character_scene = scene
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 130; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 180; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func gorgon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "고르곤"; e.max_hp = 1800; e.character_scene = scene
	e.phase_thresholds = [0.5]
	# 페이즈 0 패턴 (3턴 순환)
	# 턴1: ATK 140 RANDOM + DEBUFF vulnerable 1 RANDOM
	# 턴2: BUFF strength 1 + DEBUFF vulnerable 1 RANDOM
	# 턴3: ATK 140 RANDOM + DEBUFF vulnerable 1 ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 140; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 1; p0i2.status_type = "vulnerable"
	p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.BUFF; p0i3.value = 1; p0i3.status_type = "strength"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.DEBUFF; p0i4.value = 1; p0i4.status_type = "vulnerable"
	p0i4.target = IntentRes.TargetType.RANDOM
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.ATTACK; p0i5.value = 140; p0i5.target = IntentRes.TargetType.RANDOM
	var p0i6 := IntentRes.new()
	p0i6.action_type = IntentRes.ActionType.DEBUFF; p0i6.value = 1; p0i6.status_type = "vulnerable"
	p0i6.target = IntentRes.TargetType.ALL
	# 페이즈 1 패턴 (2턴 순환)
	# 턴1: ATK 160 RANDOM + DEBUFF vulnerable 2 RANDOM
	# 턴2: ATK 160 ALL
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 160; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.RANDOM
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL
	e.phase_patterns = [[p0i1, p0i2, p0i3, p0i4, p0i5, p0i6], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

static func scylla(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "스킬라"; e.max_hp = 1900; e.character_scene = scene
	e.phase_thresholds = [0.5]
	# 페이즈 0 (머리 2개, 4턴 순환): ATK×2 / DEBUFF poison 3 + ATK / ATK×2 / ATK ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 100; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 100; p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 3; p0i3.status_type = "poison"
	p0i3.target = IntentRes.TargetType.RANDOM
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 80; p0i4.target = IntentRes.TargetType.RANDOM
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.ATTACK; p0i5.value = 100; p0i5.target = IntentRes.TargetType.RANDOM
	var p0i6 := IntentRes.new()
	p0i6.action_type = IntentRes.ActionType.ATTACK; p0i6.value = 100; p0i6.target = IntentRes.TargetType.RANDOM
	var p0i7 := IntentRes.new()
	p0i7.action_type = IntentRes.ActionType.ATTACK; p0i7.value = 120; p0i7.target = IntentRes.TargetType.ALL
	# 페이즈 1 (머리 1개 잔존, 3턴 순환): ATK 160 / DEBUFF poison 5 ALL / ATK 160
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 160; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 5; p1i2.status_type = "poison"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.RANDOM
	e.phase_patterns = [[p0i1, p0i2, p0i3, p0i4, p0i5, p0i6, p0i7], [p1i1, p1i2, p1i3]]
	e.intent_pattern = e.phase_patterns[0]
	return e

# ──── 보스 ────

static func hydra(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "히드라"; e.max_hp = 4500; e.character_scene = scene
	e.phase_thresholds = [0.66, 0.33]
	# 페이즈 0 (2턴 순환): ATK 180 x2 / ATK 140 ALL
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 180; p0i1.target = IntentRes.TargetType.RANDOM
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.ATTACK; p0i2.value = 180; p0i2.target = IntentRes.TargetType.RANDOM
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 140; p0i3.target = IntentRes.TargetType.ALL
	# 페이즈 1 (3턴 순환): ATK 200 x2 / ATK 160 ALL / ATK 220 LOWEST_HP
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 200; p1i2.target = IntentRes.TargetType.RANDOM
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 160; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 220; p1i4.target = IntentRes.TargetType.LOWEST_HP
	# 페이즈 2 (3턴 순환): ATK 240 x2 / ATK 200 ALL / ATK 260 LOWEST_HP + DEBUFF vulnerable 2 ALL
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 240; p2i1.target = IntentRes.TargetType.RANDOM
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 240; p2i2.target = IntentRes.TargetType.RANDOM
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 200; p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 260; p2i4.target = IntentRes.TargetType.LOWEST_HP
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.DEBUFF; p2i5.value = 2; p2i5.status_type = "vulnerable"
	p2i5.target = IntentRes.TargetType.ALL
	e.phase_patterns = [
		[p0i1, p0i2, p0i3],
		[p1i1, p1i2, p1i3, p1i4],
		[p2i1, p2i2, p2i3, p2i4, p2i5]
	]
	e.intent_pattern = e.phase_patterns[0]
	return e
