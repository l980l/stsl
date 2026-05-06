# resources/enemies/daoist/daoist_normals.gd
# 도교 신화 — 일반 적 20종 + 인카운터 10개 (난이도 오름차순)
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

# ──── 기존 6종 (재배치) ────

static func child_immortal(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.child_immortal"; e.max_hp = 280; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 50; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 50; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	e.intent_pattern = [i1, i2, i3]
	return e

static func dao_disciple(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.dao_disciple"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 2; i3.status_type = "strength"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func hermit_ghost(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.hermit_ghost"; e.max_hp = 340; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 1; i2.status_type = "strength"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func mountain_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.mountain_spirit"; e.max_hp = 380; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "vulnerable"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 60; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.DEBUFF; i4.value = 1; i4.status_type = "vulnerable"; i4.target = IntentRes.TargetType.ALL
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func celestial_soldier(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.celestial_soldier"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 50; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 30; i4.status_type = "block"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func azure_guardian(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.azure_guardian"; e.max_hp = 520; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.BUFF; i2.value = 40; i2.status_type = "block"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 100; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 120; i4.target = IntentRes.TargetType.RANDOM; i4.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

# ──── 신규 14종 ────

static func thunder_messenger(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.thunder_messenger"; e.max_hp = 320; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 75; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "divine"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func immortal_sprite(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.immortal_sprite"; e.max_hp = 260; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 55; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "divine"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 55; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	e.intent_pattern = [i1, i2]
	return e

static func cloud_beast(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.cloud_beast"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func jade_puppet(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.jade_puppet"; e.max_hp = 290; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 65; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 65; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func river_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.river_spirit"; e.max_hp = 300; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 70; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "poison"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"; i2.target = IntentRes.TargetType.RANDOM
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 70; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "poison"
	e.intent_pattern = [i1, i2, i3]
	return e

static func elder_hermit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.elder_hermit"; e.max_hp = 390; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 95; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 95; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "divine"
	var i4 := IntentRes.new()
	i4.action_type = IntentRes.ActionType.BUFF; i4.value = 1; i4.status_type = "strength"
	e.intent_pattern = [i1, i2, i3, i4]
	return e

static func fire_salamander(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.fire_salamander"; e.max_hp = 330; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 80; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "fire"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 80; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "fire"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.BUFF; i3.value = 1; i3.status_type = "strength"
	e.intent_pattern = [i1, i2, i3]
	return e

static func iron_guard(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.iron_guard"; e.max_hp = 350; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 40; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 90; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 90; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "blunt"
	e.intent_pattern = [i1, i2, i3]
	return e

static func wind_sprite(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.wind_sprite"; e.max_hp = 270; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 60; i1.target = IntentRes.TargetType.RANDOM; i1.damage_type = "slash"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 60; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 1; i3.status_type = "weak"; i3.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i1, i2, i3]
	return e

static func earth_dragon(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.earth_dragon"; e.max_hp = 310; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 75; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "blunt"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 75; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

static func celestial_lion(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.celestial_lion"; e.max_hp = 480; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 1; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 110; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 110; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func nine_tailed_spirit(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.nine_tailed_spirit"; e.max_hp = 450; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.DEBUFF; i1.value = 2; i1.status_type = "weak"; i1.target = IntentRes.TargetType.RANDOM
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 105; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "curse"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 105; i3.target = IntentRes.TargetType.RANDOM; i3.damage_type = "curse"
	e.intent_pattern = [i1, i2, i3]
	return e

static func dragon_king_child(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.dragon_king_child"; e.max_hp = 720; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 60; i1.status_type = "block"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 150; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "divine"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 120; i3.target = IntentRes.TargetType.ALL; i3.damage_type = "divine"
	e.intent_pattern = [i1, i2, i3]
	return e

static func immortal_warrior(scene: PackedScene) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "enemy.daoist.immortal_warrior"; e.max_hp = 680; e.character_scene = scene
	e.mythology = "daoist"
	var i1 := IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 2; i1.status_type = "strength"
	var i2 := IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 140; i2.target = IntentRes.TargetType.RANDOM; i2.damage_type = "slash"
	var i3 := IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 140; i3.target = IntentRes.TargetType.LOWEST_HP; i3.damage_type = "slash"
	e.intent_pattern = [i1, i2, i3]
	return e

# ──── 인카운터 조합 테이블 (난이도 오름차순 1~10) ────

static func encounters() -> Array:
	return [
		["child_immortal"],
		["dao_disciple", "dao_disciple"],
		["hermit_ghost"],
		["mountain_spirit", "thunder_messenger"],
		["immortal_sprite", "immortal_sprite", "immortal_sprite"],
		["cloud_beast", "jade_puppet", "river_spirit"],
		["elder_hermit", "elder_hermit", "celestial_soldier"],
		["fire_salamander", "iron_guard", "wind_sprite", "earth_dragon"],
		["azure_guardian", "celestial_lion", "nine_tailed_spirit"],
		["dragon_king_child", "immortal_warrior"],
	]
