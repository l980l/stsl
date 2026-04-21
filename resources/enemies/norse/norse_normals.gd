# resources/enemies/norse/norse_normals.gd
# 북유럽 신화 — 일반 적 6종 + 인카운터 조합 테이블
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 일반 적 6종 ────

static func draugr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "드라우그르"; e.max_hp = 420; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "strength"; i3.value = 10
	e.intent_pattern = [i1, i2, i3]
	return e

static func urdr_spider(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "우르드의 거미"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "norse"
	# 3턴 루프: 독공격, 일반공격, 독공격
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.status_type = "poison"; i2.value = 3
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 60; i4.target = IntentRes.TargetType.RANDOM
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.status_type = "poison"; i5.value = 3
	i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func jotun_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "요툰 병사"; e.max_hp = 600; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.status_type = "block"; i1.value = 80
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3]
	return e

static func volva_witch(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "볼바 마녀"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.status_type = "weak"; i1.value = 2
	i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.status_type = "vulnerable"; i2.value = 2
	i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func hrimfaxi_rider(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "흐림팍시 기수"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.LOWEST_HP
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func garlarr_snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "갸르라르 뱀"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "norse"
	# SPECIAL value=1: 카드 1장 버리기
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SPECIAL; i1.value = 1
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 85; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 85; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

# ──── 인카운터 조합 테이블 ────
# 각 엔트리는 팩토리 함수명 문자열 배열

static func encounters() -> Array:
	return [
		["draugr", "draugr"],
		["urdr_spider", "urdr_spider", "urdr_spider"],
		["jotun_soldier"],
		["volva_witch", "hrimfaxi_rider"],
		["garlarr_snake", "garlarr_snake"],
		["draugr", "volva_witch"],
		["hrimfaxi_rider", "urdr_spider", "urdr_spider"],
		["jotun_soldier", "garlarr_snake"],
		["draugr", "urdr_spider"],
		["volva_witch", "volva_witch"],
	]
