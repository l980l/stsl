# resources/enemies/egyptian/egyptian_normals.gd
# 이집트 신화 — 일반 적 6종 + 인카운터 조합 테이블
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 일반 적 6종 ────

static func sand_scout(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_scout"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "projectile"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "projectile"
	e.intent_pattern = [i1, i2, i3]
	return e

static func desert_scorpion(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.desert_scorpion"; e.max_hp = 420; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i1b := IntentRes.new()
	i1b.action_type = IntentRes.ActionType.DEBUFF; i1b.value = 4; i1b.status_type = "poison"; i1b.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	e.intent_pattern = [i1, i1b, i2]
	return e

static func mummy_warrior(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.mummy_warrior"; e.max_hp = 600; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func sphinx_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sphinx_cub"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.SPECIAL; i5.value = 1
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func sand_ifrit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.sand_ifrit"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"; i1.condition = "준비"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 230; i2.target = IntentRes.TargetType.ALL; i2.damage_type = "fire"
	e.intent_pattern = [i1, i2]
	return e

static func ka_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.egyptian.ka_spirit"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "egyptian"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "curse"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 55; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 2; i4.status_type = "weak"; i4.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 ────
# 각 엔트리는 팩토리 함수명 문자열 배열

static func encounters() -> Array:
	return [
		["sand_scout", "sand_scout"],               # 척후병 2마리
		["desert_scorpion", "desert_scorpion"],     # 전갈 2마리
		["ka_spirit", "ka_spirit", "ka_spirit"],    # 카 영혼 3마리
		["sand_scout", "desert_scorpion"],          # 혼성: 척후병 + 전갈
		["mummy_warrior", "ka_spirit"],             # 혼성: 미라 전사 + 카 영혼
		["sand_scout", "ka_spirit", "ka_spirit"],   # 혼성: 척후병 + 카 영혼 2마리
		["sphinx_cub"],                             # 스핑크스 새끼 단독
		["sand_ifrit"],                             # 모래 이프리트 단독 (강력 ALL 공격)
		["mummy_warrior", "desert_scorpion"],       # 혼성: 미라 전사 + 전갈
		["desert_scorpion", "ka_spirit"],           # 혼성: 전갈 + 카 영혼
	]
