# resources/enemies/norse/norse_normals.gd
# 북유럽 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func urdr_spider(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.urdr_spider"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.status_type = "poison"; i2.value = 3; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "poison"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 60; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "poison"
	var i5 := IntentRes.new()
	i5.action_type = IntentRes.ActionType.DEBUFF; i5.status_type = "poison"; i5.value = 3; i5.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3, i4, i5]
	return e

static func volva_witch(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.volva_witch"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.status_type = "weak"; i1.value = 2; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.status_type = "vulnerable"; i2.value = 2; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func garlarr_snake(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.garlarr_snake"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.SPECIAL; i1.value = 1
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 85; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "poison"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 85; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3]
	return e

static func hrimfaxi_rider(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.hrimfaxi_rider"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.LOWEST_HP; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func draugr(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.draugr"; e.max_hp = 420; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.status_type = "strength"; i3.value = 10
	e.intent_pattern = [i1, i2, i3]
	return e

static func jotun_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.jotun_soldier"; e.max_hp = 600; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.status_type = "block"; i1.value = 80
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 180; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

# ──── 신규 14종 ────

static func ice_wolf(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.ice_wolf"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 75; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func raven_scout(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.raven_scout"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "poison"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func frost_giant_pup(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.frost_giant_pup"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 25; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 70; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func bone_archer(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.bone_archer"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func dark_elf(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.dark_elf"; e.max_hp = 295; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 65; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func berserker(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.berserker"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func runestone_golem(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.runestone_golem"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 95; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 95; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func night_hag(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.night_hag"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func lindworm_spawn(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.lindworm_spawn"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 75; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "poison"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func einherjar_ghost(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.einherjar_ghost"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 80; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func fenrir_pup(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.fenrir_pup"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 110; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "blunt"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 130; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func nidhogg_scale(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.nidhogg_scale"; e.max_hp = 400; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 90; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 3; i2.status_type = "poison"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func frost_giant(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.frost_giant"; e.max_hp = 680; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 60; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func ragnarok_herald(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.norse.ragnarok_herald"; e.max_hp = 670; e.character_scene = scene
	e.mythology = "norse"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 80; i4.target = IntentRes.TargetType.ALL; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────

static func encounters() -> Array:
	return [
		["urdr_spider"],
		["volva_witch", "volva_witch"],
		["garlarr_snake"],
		["hrimfaxi_rider", "ice_wolf"],
		["raven_scout", "raven_scout", "raven_scout"],
		["frost_giant_pup", "bone_archer", "dark_elf"],
		["draugr", "draugr", "berserker"],
		["runestone_golem", "night_hag", "lindworm_spawn", "einherjar_ghost"],
		["jotun_soldier", "fenrir_pup", "nidhogg_scale"],
		["frost_giant", "ragnarok_herald"],
	]
