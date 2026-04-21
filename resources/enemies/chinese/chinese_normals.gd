# resources/enemies/chinese/chinese_normals.gd
# 중국 신화 — 일반 적 6종 + 인카운터 조합
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func yaksha(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "야차"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func nezha_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "나타 병사"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 50; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	e.intent_pattern = [i1, i2, i3]
	return e

static func heavenly_king_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "사대천왕 병사"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 30; i4.status_type = "block"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func shanhaijing_beast(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "산해경 괴수"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.ALL
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 1; i4.status_type = "vulnerable"
	i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func immortal_trainee(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "선인 수련생"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 2; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func azure_dragon_guard(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "청룡 수호병"; e.max_hp = 520; e.character_scene = scene
	e.mythology = "chinese"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func encounters() -> Array:
	return [
		["yaksha"],
		["yaksha", "yaksha"],
		["nezha_soldier", "nezha_soldier"],
		["yaksha", "nezha_soldier"],
		["heavenly_king_soldier"],
		["heavenly_king_soldier", "yaksha"],
		["shanhaijing_beast", "shanhaijing_beast"],
		["immortal_trainee", "immortal_trainee"],
		["azure_dragon_guard"],
		["shanhaijing_beast", "yaksha"],
		["immortal_trainee", "heavenly_king_soldier"],
	]
