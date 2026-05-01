# resources/enemies/greek/greek_normals.gd
# 그리스 신화 — 일반 적 6종 + 인카운터 조합 테이블
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 일반 적 6종 ────

static func satyr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.satyr"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	e.intent_pattern = [i1, i2]
	return e

static func harpy(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.harpy"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 45; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 45; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 45; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 45; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 0
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func cyclops(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.cyclops"; e.max_hp = 700; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.PREPARE; i1.value = 0; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 200; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	e.intent_pattern = [i1, i2]
	return e

static func snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.snake"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2]
	return e

static func cerberus(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.cerberus"; e.max_hp = 900; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 70; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.ATTACK; i5.value = 70; i5.target = IntentRes.TargetType.RANDOM; i5.damage_type = "slash"
	var i6 := IntentRes.new()
	i6.action_type = IntentRes.ActionType.ATTACK; i6.value = 90; i6.target = IntentRes.TargetType.ALL; i6.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4, i5, i6]
	return e

static func myrmidon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.myrmidon"; e.max_hp = 250; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 90; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 ────
# 각 엔트리는 팩토리 함수명 문자열 배열

static func encounters() -> Array:
	return [
		["satyr", "satyr"],                     # 사티로스 2마리
		["harpy", "harpy", "harpy"],            # 하르피아 3마리
		["myrmidon", "myrmidon", "myrmidon"],   # 미르미돈 3마리
		["snake", "snake"],                     # 뱀 2마리
		["harpy", "myrmidon"],                  # 혼성: 하르피아 + 미르미돈
		["satyr", "snake"],                     # 혼성: 사티로스 + 뱀
		["cyclops"],                            # 사이클롭스 단독 (HP 700)
		["cerberus"],                           # 케르베로스 단독 (HP 900)
		["myrmidon", "snake", "harpy"],         # 혼성 3마리
		["satyr", "myrmidon"],                  # 혼성: 사티로스 + 미르미돈
	]
