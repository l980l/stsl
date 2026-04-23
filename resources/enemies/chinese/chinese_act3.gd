# resources/enemies/chinese/chinese_act3.gd
# 중국 신화 Act 3 — 엘리트 3종(백호·주작·현무 신장) + 보스(반고)
const EnemyRes   = preload("res://resources/enemy_resource.gd")
const IntentRes  = preload("res://resources/intent_resource.gd")

static func white_tiger_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.chinese.white_tiger_general"); e.max_hp = 1900; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 3; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 160; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func vermilion_bird_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.chinese.vermilion_bird_general"); e.max_hp = 2000; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 200; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func black_tortoise_general(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.chinese.black_tortoise_general"); e.max_hp = 1800; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 70; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 3; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.ALL
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 50; i3.status_type = "block"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 2; i4.status_type = "strength"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 210; i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func pangu(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = TranslationServer.translate("enemy.chinese.pangu"); e.max_hp = 4800; e.character_scene = scene
	e.mythology = "chinese"
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0 — 혼돈
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.BUFF; p0i1.value = 50; p0i1.status_type = "block"
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.BUFF; p0i2.value = 1; p0i2.status_type = "strength"
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.ATTACK; p0i3.value = 190; p0i3.target = IntentRes.TargetType.RANDOM
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 160; p0i4.target = IntentRes.TargetType.ALL
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.DEBUFF; p0i5.value = 2; p0i5.status_type = "vulnerable"
	p0i5.target = IntentRes.TargetType.RANDOM
	# Phase 1 — 천지개벽
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.ATTACK; p1i1.value = 220; p1i1.target = IntentRes.TargetType.RANDOM
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.DEBUFF; p1i2.value = 2; p1i2.status_type = "vulnerable"
	p1i2.target = IntentRes.TargetType.ALL
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.ATTACK; p1i3.value = 190; p1i3.target = IntentRes.TargetType.ALL
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 200; p1i4.target = IntentRes.TargetType.LOWEST_HP
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.DEBUFF; p1i5.value = 3; p1i5.status_type = "weak"
	p1i5.target = IntentRes.TargetType.ALL
	var p1i6 := IntentRes.new()
	p1i6.action_type = IntentRes.ActionType.BUFF; p1i6.value = 2; p1i6.status_type = "strength"
	# Phase 2 — 만물 창조
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 160; p2i1.target = IntentRes.TargetType.RANDOM
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.ATTACK; p2i2.value = 160; p2i2.target = IntentRes.TargetType.RANDOM
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 160; p2i3.target = IntentRes.TargetType.RANDOM
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.ATTACK; p2i4.value = 160; p2i4.target = IntentRes.TargetType.RANDOM
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.ATTACK; p2i5.value = 220; p2i5.target = IntentRes.TargetType.ALL
	var p2i6 := IntentRes.new()
	p2i6.action_type = IntentRes.ActionType.DEBUFF; p2i6.value = 3; p2i6.status_type = "vulnerable"
	p2i6.target = IntentRes.TargetType.ALL
	var p2i7 := IntentRes.new()
	p2i7.action_type = IntentRes.ActionType.BUFF; p2i7.value = 3; p2i7.status_type = "strength"
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5],
		[p1i1, p1i2, p1i3, p1i4, p1i5, p1i6],
		[p2i1, p2i2, p2i3, p2i4, p2i5, p2i6, p2i7]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	# 카드 타입 카운터: 권능 카드 사용 때마다 영웅 전체에 약화 +2 부여
	var _ptrigger := IntentRes.new()
	_ptrigger.action_type = IntentRes.ActionType.DEBUFF
	_ptrigger.value = 2
	_ptrigger.target = IntentRes.TargetType.ALL
	_ptrigger.status_type = "weak"
	_ptrigger.play_animation = "buff"
	e.card_count_trigger = {
		"card_type": CardResource.CardType.POWER,
		"threshold": 1,
		"intent": _ptrigger,
		"repeat": true,
	}
	return e

static func elites() -> Array:
	return ["white_tiger_general", "vermilion_bird_general", "black_tortoise_general"]

static func boss() -> String:
	return "pangu"
