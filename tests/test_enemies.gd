# tests/test_enemies.gd
class_name TestEnemies
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const EnemiesAct1 = preload("res://resources/enemies/enemies_act1.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_normal_enemy_variety()
	test_harpy_pattern_length()
	test_cyclops_first_intent_is_buff()
	test_snake_pattern_length()
	test_discard_random()
	test_elite_enemy_hp()
	test_minotaur_pattern()
	test_medusa_pattern_and_status_type()
	test_scylla_pattern()
	test_hydra_phase_count()
	test_phase_transition()
	test_phase2_transition()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func _make_gm() -> GameManagerClass:
	var gm := GameManagerClass.new()
	gm.run_map = preload("res://autoload/map_generator.gd").generate()
	gm.available_node_ids = [0, 1, 2]
	gm.current_node_id = -1
	gm.pending_enemies = []
	gm.card_rewards = []
	return gm

func test_normal_enemy_variety() -> void:
	print("[TestEnemies] test_normal_enemy_variety")
	var gm := _make_gm()
	var seen := {}
	for _i in range(30):
		var enemies := gm._make_normal_enemies()
		seen[enemies[0].enemy_name] = true
	_assert(seen.size() >= 2, "랜덤 일반 적 — 30회 중 2종 이상 등장")

func test_harpy_pattern_length() -> void:
	print("[TestEnemies] test_harpy_pattern_length")
	var gm := _make_gm()
	var harpy: Resource = EnemiesAct1.harpy(gm._satyr_scene())
	_assert(harpy.intent_pattern.size() == 5, "하르피아 패턴 5개")
	_assert(harpy.enemy_name == "하르피아", "하르피아 이름")
	_assert(harpy.max_hp == 280, "하르피아 HP = 280")

func test_cyclops_first_intent_is_buff() -> void:
	print("[TestEnemies] test_cyclops_first_intent_is_buff")
	var gm := _make_gm()
	var cyclops: Resource = EnemiesAct1.cyclops(gm._satyr_scene())
	_assert(cyclops.intent_pattern.size() == 2, "사이클롭스 패턴 2개")
	_assert(cyclops.intent_pattern[0].action_type == IntentRes.ActionType.BUFF,
		"사이클롭스 첫 행동 = BUFF(준비)")
	_assert(cyclops.intent_pattern[1].value == 200, "사이클롭스 강타 = 200")

func test_snake_pattern_length() -> void:
	print("[TestEnemies] test_snake_pattern_length")
	var gm := _make_gm()
	var snake: Resource = EnemiesAct1.snake(gm._satyr_scene())
	_assert(snake.intent_pattern.size() == 2, "메두사의 뱀 패턴 2개")
	_assert(snake.enemy_name == "메두사의 뱀", "메두사의 뱀 이름")
	_assert(snake.intent_pattern[1].status_type == "vulnerable", "메두사의 뱀 DEBUFF = vulnerable")

func test_elite_enemy_hp() -> void:
	print("[TestEnemies] test_elite_enemy_hp")
	var gm := _make_gm()
	var enemies := gm._make_elite_enemies()
	_assert(enemies.size() >= 1, "엘리트 룸 적 1마리 이상")
	_assert(enemies[0].max_hp >= 1700, "엘리트 HP >= 1700")

func test_minotaur_pattern() -> void:
	print("[TestEnemies] test_minotaur_pattern")
	var gm := _make_gm()
	var m: Resource = EnemiesAct1.minotaur(gm._satyr_scene())
	_assert(m.intent_pattern.size() == 3, "미노타우로스 패턴 3개")
	_assert(m.intent_pattern[2].value == 260, "미노타우로스 세 번째 공격 260")

func test_medusa_pattern_and_status_type() -> void:
	print("[TestEnemies] test_medusa_pattern_and_status_type")
	var gm := _make_gm()
	var med: Resource = EnemiesAct1.medusa(gm._satyr_scene())
	_assert(med.intent_pattern.size() == 4, "메두사 패턴 4개")
	_assert(med.intent_pattern[1].status_type == "weak", "메두사 2번째 = weak")
	_assert(med.intent_pattern[2].status_type == "vulnerable", "메두사 3번째 = vulnerable")
	_assert(med.max_hp == 1700, "메두사 HP = 1700")

func test_scylla_pattern() -> void:
	print("[TestEnemies] test_scylla_pattern")
	var gm := _make_gm()
	var s: Resource = EnemiesAct1.scylla(gm._satyr_scene())
	_assert(s.enemy_name == "스킬라", "스킬라 이름")
	_assert(s.max_hp == 1900, "스킬라 HP = 1900")
	_assert(s.phase_thresholds.size() == 1, "스킬라 페이즈 임계값 1개")
	_assert(s.phase_patterns.size() == 2, "스킬라 페이즈 패턴 2개")
	_assert(s.phase_patterns[0].size() == 7, "스킬라 페이즈 0 패턴 7개")
	_assert(s.phase_patterns[1].size() == 3, "스킬라 페이즈 1 패턴 3개")
	_assert(s.phase_patterns[1][1].status_type == "poison", "스킬라 페이즈 1 독 DEBUFF")

func _make_hydra() -> Array:
	# game_manager._make_boss_enemies()와 동일 로직 — Autoload 없이 테스트용
	var EnemyRes = preload("res://resources/enemy_resource.gd")
	var IntentRes = preload("res://resources/intent_resource.gd")
	var hydra: Resource = EnemyRes.new()
	hydra.enemy_name = "히드라"
	hydra.max_hp = 200
	hydra.phase_thresholds = [0.6, 0.3]
	var p0a1: Resource = IntentRes.new(); p0a1.action_type = IntentRes.ActionType.ATTACK; p0a1.value = 10; p0a1.target = IntentRes.TargetType.RANDOM
	var p0a2: Resource = IntentRes.new(); p0a2.action_type = IntentRes.ActionType.ATTACK; p0a2.value = 10; p0a2.target = IntentRes.TargetType.RANDOM
	var p1a1: Resource = IntentRes.new(); p1a1.action_type = IntentRes.ActionType.ATTACK; p1a1.value = 12; p1a1.target = IntentRes.TargetType.RANDOM
	var p1a2: Resource = IntentRes.new(); p1a2.action_type = IntentRes.ActionType.ATTACK; p1a2.value = 12; p1a2.target = IntentRes.TargetType.RANDOM
	var p1a3: Resource = IntentRes.new(); p1a3.action_type = IntentRes.ActionType.ATTACK; p1a3.value = 12; p1a3.target = IntentRes.TargetType.LOWEST_HP
	var p2a1: Resource = IntentRes.new(); p2a1.action_type = IntentRes.ActionType.ATTACK; p2a1.value = 12; p2a1.target = IntentRes.TargetType.RANDOM
	var p2a2: Resource = IntentRes.new(); p2a2.action_type = IntentRes.ActionType.ATTACK; p2a2.value = 12; p2a2.target = IntentRes.TargetType.RANDOM
	var p2a3: Resource = IntentRes.new(); p2a3.action_type = IntentRes.ActionType.ATTACK; p2a3.value = 12; p2a3.target = IntentRes.TargetType.LOWEST_HP
	var p2b: Resource = IntentRes.new(); p2b.action_type = IntentRes.ActionType.BUFF; p2b.value = 10
	hydra.phase_patterns = [[p0a1, p0a2], [p1a1, p1a2, p1a3], [p2a1, p2a2, p2a3, p2b]]
	hydra.intent_pattern = hydra.phase_patterns[0]
	return [hydra]

func test_hydra_phase_count() -> void:
	print("[TestEnemies] test_hydra_phase_count")
	var enemies: Array = _make_hydra()
	_assert(enemies.size() == 1, "보스 1마리")
	_assert(enemies[0].enemy_name == "히드라", "보스 이름 = 히드라")
	_assert(enemies[0].phase_thresholds.size() == 2, "히드라 페이즈 임계값 2개")
	_assert(enemies[0].phase_patterns.size() == 3, "히드라 페이즈 패턴 3개")

func test_phase_transition() -> void:
	print("[TestEnemies] test_phase_transition")
	var BM = preload("res://autoload/battle_manager.gd")
	var TM = preload("res://autoload/team_manager.gd")
	var HeroRes = preload("res://resources/hero_resource.gd")
	var bm: Node = BM.new()
	var tm: Node = TM.new()
	var hero: Resource = HeroRes.new()
	hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
	tm.add_hero(hero)
	bm.team_mgr = tm
	var enemies: Array = _make_hydra()
	bm.setup_battle(enemies)
	_assert(bm._enemy_phase[0] == 0, "초기 페이즈 = 0")
	# HP를 59%로 설정
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
	bm._check_phase_transition(0)
	_assert(bm._enemy_phase[0] == 1, "HP 59% → 페이즈 1")
	bm.free()
	tm.free()

func test_phase2_transition() -> void:
	print("[TestEnemies] test_phase2_transition")
	var BM = preload("res://autoload/battle_manager.gd")
	var TM = preload("res://autoload/team_manager.gd")
	var HeroRes = preload("res://resources/hero_resource.gd")
	var bm: Node = BM.new()
	var tm: Node = TM.new()
	var hero: Resource = HeroRes.new()
	hero.hero_id = "napoleon"; hero.max_hp = 70; hero.hero_name = "나폴레옹"
	tm.add_hero(hero)
	bm.team_mgr = tm
	var enemies: Array = _make_hydra()
	bm.setup_battle(enemies)
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.59)
	bm._check_phase_transition(0)
	bm._enemy_hp[0] = int(enemies[0].max_hp * 0.29)
	bm._check_phase_transition(0)
	_assert(bm._enemy_phase[0] == 2, "HP 29% → 페이즈 2")
	bm.free()
	tm.free()

func test_discard_random() -> void:
	print("[TestEnemies] test_discard_random")
	var DM = preload("res://autoload/deck_manager.gd")
	var dm := DM.new()
	var CardRes = preload("res://resources/card_resource.gd")
	var EffRes = preload("res://resources/effect_resource.gd")
	# 손패에 카드 3장 추가
	for i in range(3):
		var c := CardRes.new(); c.card_name = "test%d" % i; c.owner_id = "napoleon"; c.cost = 1
		var e := EffRes.new(); e.effect_type = EffRes.EffectType.DAMAGE; e.value = 1
		c.effects = [e]
		dm.hand.append(c)
	dm.discard_random(2)
	_assert(dm.hand.size() == 1, "discard_random(2) 후 hand 1장 남음")
	_assert(dm.discard_pile.size() == 2, "discard_pile에 2장 추가")
