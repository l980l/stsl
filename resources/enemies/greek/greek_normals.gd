# resources/enemies/greek/greek_normals.gd
# 그리스 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func fly_harpy(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.fly_harpy"; e.max_hp = 220; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	e.intent_pattern = [i1, i2]
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

static func snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.snake"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
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

# ──── 신규 14종 ────

static func lamia(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.lamia"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3]
	return e

static func stymphalian_bird(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.stymphalian_bird"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 55; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func giant_ant(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.giant_ant"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func dryad(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.dryad"; e.max_hp = 270; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 1; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 50; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func centaur(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.centaur"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func ares_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.ares_soldier"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func griffin_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.griffin_cub"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func medusid(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.medusid"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "vulnerable"; i3.target = IntentRes.TargetType.RANDOM
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 65; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func fire_crab(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.fire_crab"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 20; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	return e

static func stone_shard(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.stone_shard"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 30; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func chimera_cub(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.chimera_cub"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.ALL; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "fire"
	e.intent_pattern = [i1, i2, i3]
	return e

static func hydra_head(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.hydra_head"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 100; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 100; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func tartaros_shade(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.greek.tartaros_shade"; e.max_hp = 500; e.character_scene = scene
	e.mythology = "greek"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 130; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────

static func encounters() -> Array:
	return [
		["fly_harpy"],
		["myrmidon", "myrmidon"],
		["satyr"],
		["snake", "lamia"],
		["harpy", "harpy", "harpy"],
		["stymphalian_bird", "giant_ant", "dryad"],
		["centaur", "centaur", "ares_soldier"],
		["griffin_cub", "medusid", "fire_crab", "stone_shard"],
		["cyclops", "chimera_cub", "hydra_head"],
		["cerberus", "tartaros_shade"],
	]
