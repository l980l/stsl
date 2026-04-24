# resources/enemies/korean/korean_act3.gd
# 한국 신화 — Act 3 엘리트 3종(저승 판관·갓신·처용신) + 보스(구삼승할망)
const EnemyRes   = preload("res://resources/enemy_resource.gd")
const IntentRes  = preload("res://resources/intent_resource.gd")

static func underworld_judge(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.underworld_judge"; e.max_hp = 1900; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.ALL
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 180; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 160; i4.target = IntentRes.TargetType.ALL
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.value = 2; i5.status_type = "weak"
	i5.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	# 카드 타입 카운터: 공격 카드 4장마다 HP 가장 낮은 영웅에게 50 즉결 데미지
	var _jtrigger := IntentRes.new()
	_jtrigger.action_type = IntentRes.ActionType.ATTACK
	_jtrigger.value = 50
	_jtrigger.target = IntentRes.TargetType.LOWEST_HP
	_jtrigger.play_animation = "attack"
	e.card_count_trigger = {
		"card_type": CardResource.CardType.ATTACK,
		"threshold": 4,
		"intent": _jtrigger,
		"repeat": true,
		"tooltip_key": "enemy.korean.underworld_judge.counter",
	}
	return e

static func gat_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.gat_spirit"; e.max_hp = 2000; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 180; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 200; i4.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3, i4]
	e.charm_resistance = 1
	return e

static func cheoyong_god(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.cheoyong_god"; e.max_hp = 1800; e.character_scene = scene
	e.mythology = "korean"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 170; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 190; i5.target = IntentRes.TargetType.LOWEST_HP
	e.intent_pattern = [i1, i2, i3, i4, i5]
	e.charm_resistance = 1
	return e

static func gusamseung_halmang(scene: PackedScene) -> Resource:
	# 제주 무속의 생사 경계 여신 — Phase 0 "생명의 실" → Phase 1 "운명의 저울" → Phase 2 "저승 인도"
	var e := EnemyRes.new()
	e.enemy_name = "enemy.korean.gusamseung_halmang"; e.max_hp = 4800; e.character_scene = scene
	e.mythology = "korean"
	e.phase_thresholds = [0.66, 0.33]
	# Phase 0: 생명의 실
	var p0i1 := IntentRes.new()
	p0i1.action_type = IntentRes.ActionType.ATTACK; p0i1.value = 180; p0i1.target = IntentRes.TargetType.LOWEST_HP
	var p0i2 := IntentRes.new()
	p0i2.action_type = IntentRes.ActionType.DEBUFF; p0i2.value = 2; p0i2.status_type = "vulnerable"
	p0i2.target = IntentRes.TargetType.ALL
	var p0i3 := IntentRes.new()
	p0i3.action_type = IntentRes.ActionType.DEBUFF; p0i3.value = 3; p0i3.status_type = "weak"
	p0i3.target = IntentRes.TargetType.ALL
	var p0i4 := IntentRes.new()
	p0i4.action_type = IntentRes.ActionType.ATTACK; p0i4.value = 160; p0i4.target = IntentRes.TargetType.ALL
	var p0i5 := IntentRes.new()
	p0i5.action_type = IntentRes.ActionType.BUFF; p0i5.value = 2; p0i5.status_type = "strength"
	var p0i6 := IntentRes.new()
	p0i6.action_type = IntentRes.ActionType.BUFF; p0i6.value = 50; p0i6.status_type = "block"
	# Phase 1: 운명의 저울
	var p1i1 := IntentRes.new()
	p1i1.action_type = IntentRes.ActionType.DEBUFF; p1i1.value = 3; p1i1.status_type = "vulnerable"
	p1i1.target = IntentRes.TargetType.ALL
	var p1i2 := IntentRes.new()
	p1i2.action_type = IntentRes.ActionType.ATTACK; p1i2.value = 220; p1i2.target = IntentRes.TargetType.LOWEST_HP
	var p1i3 := IntentRes.new()
	p1i3.action_type = IntentRes.ActionType.DEBUFF; p1i3.value = 2; p1i3.status_type = "weak"
	p1i3.target = IntentRes.TargetType.RANDOM
	var p1i4 := IntentRes.new()
	p1i4.action_type = IntentRes.ActionType.ATTACK; p1i4.value = 190; p1i4.target = IntentRes.TargetType.ALL
	var p1i5 := IntentRes.new()
	p1i5.action_type = IntentRes.ActionType.BUFF; p1i5.value = 3; p1i5.status_type = "strength"
	# Phase 2: 저승 인도
	var p2i1 := IntentRes.new()
	p2i1.action_type = IntentRes.ActionType.ATTACK; p2i1.value = 260; p2i1.target = IntentRes.TargetType.LOWEST_HP
	var p2i2 := IntentRes.new()
	p2i2.action_type = IntentRes.ActionType.DEBUFF; p2i2.value = 3; p2i2.status_type = "vulnerable"
	p2i2.target = IntentRes.TargetType.ALL
	var p2i3 := IntentRes.new()
	p2i3.action_type = IntentRes.ActionType.ATTACK; p2i3.value = 210; p2i3.target = IntentRes.TargetType.ALL
	var p2i4 := IntentRes.new()
	p2i4.action_type = IntentRes.ActionType.DEBUFF; p2i4.value = 3; p2i4.status_type = "weak"
	p2i4.target = IntentRes.TargetType.ALL
	var p2i5 := IntentRes.new()
	p2i5.action_type = IntentRes.ActionType.ATTACK; p2i5.value = 190; p2i5.target = IntentRes.TargetType.ALL
	var p2i6 := IntentRes.new()
	p2i6.action_type = IntentRes.ActionType.DEBUFF; p2i6.value = 5; p2i6.status_type = "poison"
	p2i6.target = IntentRes.TargetType.RANDOM
	e.phase_patterns = [
		[p0i1, p0i2, p0i3, p0i4, p0i5, p0i6],
		[p1i1, p1i2, p1i3, p1i4, p1i5],
		[p2i1, p2i2, p2i3, p2i4, p2i5, p2i6]
	]
	e.intent_pattern = e.phase_patterns[0]
	e.charm_resistance = 2
	return e

static func elites() -> Array:
	return ["underworld_judge", "gat_spirit", "cheoyong_god"]

static func boss() -> String:
	return "gusamseung_halmang"
