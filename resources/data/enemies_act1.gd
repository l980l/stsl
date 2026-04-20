# resources/data/enemies_act1.gd
const EnemyRes  = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

static func satyr(scene: PackedScene, hp: int, dmg: int) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "사티로스"; enemy.max_hp = hp; enemy.character_scene = scene
	var i: Resource = IntentRes.new()
	i.action_type = IntentRes.ActionType.ATTACK; i.value = dmg; i.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i]; return enemy

static func harpy(scene: PackedScene, hp: int) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "하르피아"; enemy.max_hp = hp; enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 4; i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 4; i2.target = IntentRes.TargetType.RANDOM
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.SPECIAL; i3.value = 1
	enemy.intent_pattern = [i1, i2, i3]; return enemy

static func cyclops(scene: PackedScene, hp: int) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "사이클롭스"; enemy.max_hp = hp; enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.BUFF; i1.value = 0; i1.condition = "준비"
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 18; i2.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2]; return enemy

static func snake(scene: PackedScene, hp: int) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "메두사의 뱀"; enemy.max_hp = hp; enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 5; i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 1; i2.status_type = "vulnerable"
	i2.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2]; return enemy

static func minotaur(scene: PackedScene) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "미노타우로스"; enemy.max_hp = 90; enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 12; i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.ATTACK; i2.value = 12; i2.target = IntentRes.TargetType.RANDOM
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.ATTACK; i3.value = 20; i3.target = IntentRes.TargetType.ALL
	enemy.intent_pattern = [i1, i2, i3]; return enemy

static func medusa(scene: PackedScene) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "메두사"; enemy.max_hp = 75; enemy.character_scene = scene
	var i1: Resource = IntentRes.new()
	i1.action_type = IntentRes.ActionType.ATTACK; i1.value = 10; i1.target = IntentRes.TargetType.RANDOM
	var i2: Resource = IntentRes.new()
	i2.action_type = IntentRes.ActionType.DEBUFF; i2.value = 2; i2.status_type = "weak"
	var i3: Resource = IntentRes.new()
	i3.action_type = IntentRes.ActionType.DEBUFF; i3.value = 2; i3.status_type = "vulnerable"
	var i4: Resource = IntentRes.new()
	i4.action_type = IntentRes.ActionType.ATTACK; i4.value = 15; i4.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [i1, i2, i3, i4]; return enemy

static func hydra(scene: PackedScene) -> Resource:
	var enemy: Resource = EnemyRes.new()
	enemy.enemy_name = "히드라"; enemy.max_hp = 200; enemy.character_scene = scene
	enemy.phase_thresholds = [0.6, 0.3]

	var p0a1: Resource = IntentRes.new()
	p0a1.action_type = IntentRes.ActionType.ATTACK; p0a1.value = 10; p0a1.target = IntentRes.TargetType.RANDOM
	var p0a2: Resource = IntentRes.new()
	p0a2.action_type = IntentRes.ActionType.ATTACK; p0a2.value = 10; p0a2.target = IntentRes.TargetType.RANDOM

	var p1a1: Resource = IntentRes.new()
	p1a1.action_type = IntentRes.ActionType.ATTACK; p1a1.value = 12; p1a1.target = IntentRes.TargetType.RANDOM
	var p1a2: Resource = IntentRes.new()
	p1a2.action_type = IntentRes.ActionType.ATTACK; p1a2.value = 12; p1a2.target = IntentRes.TargetType.RANDOM
	var p1a3: Resource = IntentRes.new()
	p1a3.action_type = IntentRes.ActionType.ATTACK; p1a3.value = 12; p1a3.target = IntentRes.TargetType.LOWEST_HP

	var p2a1: Resource = IntentRes.new()
	p2a1.action_type = IntentRes.ActionType.ATTACK; p2a1.value = 12; p2a1.target = IntentRes.TargetType.RANDOM
	var p2a2: Resource = IntentRes.new()
	p2a2.action_type = IntentRes.ActionType.ATTACK; p2a2.value = 12; p2a2.target = IntentRes.TargetType.RANDOM
	var p2a3: Resource = IntentRes.new()
	p2a3.action_type = IntentRes.ActionType.ATTACK; p2a3.value = 12; p2a3.target = IntentRes.TargetType.LOWEST_HP
	var p2b: Resource = IntentRes.new()
	p2b.action_type = IntentRes.ActionType.BUFF; p2b.value = 10

	enemy.phase_patterns = [[p0a1, p0a2], [p1a1, p1a2, p1a3], [p2a1, p2a2, p2a3, p2b]]
	return enemy
