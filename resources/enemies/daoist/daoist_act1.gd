# resources/enemies/daoist/daoist_act1.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func golden_elixir(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.golden_elixir"; e.max_hp = 1600; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "holy_slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 130; i5.target = IntentRes.TargetType.ALL; i5.damage_type = "holy_fire"
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.DEBUFF; i6.value = 2; i6.status_type = "vulnerable"
	i6.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	e.charm_resistance = 20
	return e

static func silver_elixir(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.silver_elixir"; e.max_hp = 1700; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 2; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "holy_slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "holy_slash"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 20
	return e

static func black_wind_immortal(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.black_wind_immortal"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 120; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 150; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 1; i5.status_type = "vulnerable"
	i5.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 20
	return e

static func eastern_king(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.eastern_king"; e.max_hp = 4500; e.character_scene = scene
	e.mythology = "daoist"; e.grade = EnemyRes.Grade.BOSS
	e.phase_thresholds = [0.66, 0.33]
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 160; p0i1.target = IntentRes.TargetType.RANDOM; p0i1.damage_type = "blunt"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 130; p0i3.target = IntentRes.TargetType.ALL; p0i3.damage_type = "blunt"
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.BUFF; p0i4.value = 1; p0i4.status_type = "strength"
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 200; p1i1.target = IntentRes.TargetType.RANDOM; p1i1.damage_type = "blunt"
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 160; p1i2.target = IntentRes.TargetType.ALL; p1i2.damage_type = "blunt"
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "vulnerable"
	p1i3.target = IntentRes.TargetType.RANDOM
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 180; p1i4.target = IntentRes.TargetType.RANDOM; p1i4.damage_type = "blunt"
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 2; p1i5.status_type = "strength"
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 240; p2i1.target = IntentRes.TargetType.RANDOM; p2i1.damage_type = "blunt"
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 200; p2i3.target = IntentRes.TargetType.ALL; p2i3.damage_type = "blunt"
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.BUFF; p2i4.value = 3; p2i4.status_type = "strength"
	# eastern_king (동방청제) — 오행 변환: 페이즈 1 부터 매번 CHANGE_AFFINITY 로 공격 속성 순환.
	# 음양오행 5 속성 (목/화/토/금/수) — 영웅 저항 빌드 무력화.
	e.dynamic_affinity_pool = ["blunt", "holy_fire", "poison", "holy_strike", "holy_arrow"]
	var p1i_aff := IntentRes.new()
	p1i_aff.action_type = IntentRes.ActionType.CHANGE_AFFINITY; p1i_aff.play_animation = "buff"
	var p2i_aff := IntentRes.new()
	p2i_aff.action_type = IntentRes.ActionType.CHANGE_AFFINITY; p2i_aff.play_animation = "buff"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4],
		[p1i_aff, p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i_aff, p2i1, p2i2, p2i3, p2i4]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 20
	return e

static func elites() -> Array:
	return ["golden_elixir", "silver_elixir", "black_wind_immortal"]

static func boss() -> String:
	return "eastern_king"
