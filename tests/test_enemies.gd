# tests/test_enemies.gd
class_name TestEnemies
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
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
	var harpy := gm._make_harpy(gm._satyr_scene(), 25)
	_assert(harpy.intent_pattern.size() == 3, "하르피아 패턴 3개")
	_assert(harpy.enemy_name == "하르피아", "하르피아 이름")
	_assert(harpy.max_hp == 25, "하르피아 HP = 25")

func test_cyclops_first_intent_is_buff() -> void:
	print("[TestEnemies] test_cyclops_first_intent_is_buff")
	var gm := _make_gm()
	var cyclops := gm._make_cyclops(gm._satyr_scene(), 45)
	_assert(cyclops.intent_pattern.size() == 2, "사이클롭스 패턴 2개")
	_assert(cyclops.intent_pattern[0].action_type == IntentRes.ActionType.BUFF,
		"사이클롭스 첫 행동 = BUFF(준비)")
	_assert(cyclops.intent_pattern[1].value == 18, "사이클롭스 강타 = 18")

func test_snake_pattern_length() -> void:
	print("[TestEnemies] test_snake_pattern_length")
	var gm := _make_gm()
	var snake := gm._make_snake(gm._satyr_scene(), 20)
	_assert(snake.intent_pattern.size() == 2, "메두사의 뱀 패턴 2개")
	_assert(snake.enemy_name == "메두사의 뱀", "메두사의 뱀 이름")
	_assert(snake.intent_pattern[1].status_type == "vulnerable", "메두사의 뱀 DEBUFF = vulnerable")

func test_elite_enemy_hp() -> void:
	print("[TestEnemies] test_elite_enemy_hp")
	var gm := _make_gm()
	var enemies := gm._make_elite_enemies()
	_assert(enemies.size() >= 1, "엘리트 룸 적 1마리 이상")
	_assert(enemies[0].max_hp >= 60, "엘리트 HP >= 60")

func test_minotaur_pattern() -> void:
	print("[TestEnemies] test_minotaur_pattern")
	var gm := _make_gm()
	var m := gm._make_minotaur(gm._satyr_scene())
	_assert(m.intent_pattern.size() == 3, "미노타우로스 패턴 3개")
	_assert(m.intent_pattern[2].value == 20, "미노타우로스 세 번째 공격 20")

func test_medusa_pattern_and_status_type() -> void:
	print("[TestEnemies] test_medusa_pattern_and_status_type")
	var gm := _make_gm()
	var med := gm._make_medusa(gm._satyr_scene())
	_assert(med.intent_pattern.size() == 4, "메두사 패턴 4개")
	_assert(med.intent_pattern[1].status_type == "weak", "메두사 2번째 = weak")
	_assert(med.intent_pattern[2].status_type == "vulnerable", "메두사 3번째 = vulnerable")

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
