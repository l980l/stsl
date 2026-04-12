# tests/test_team_manager.gd
class_name TestTeamManager
extends RefCounted

var HeroResource = preload("res://resources/hero_resource.gd")
var TeamManagerClass = preload("res://autoload/team_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_add_hero()
	test_take_damage()
	test_hero_death()
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func _make_hero(id: String, hp: int) -> Resource:
	var hero = HeroResource.new()
	hero.hero_id = id
	hero.max_hp = hp
	return hero

func test_add_hero() -> void:
	print("[TestTeamManager] test_add_hero")
	var tm = TeamManagerClass.new()
	var hero = _make_hero("napoleon", 80)
	tm.add_hero(hero)
	_assert(tm.get_current_hp("napoleon") == 80, "추가 후 HP == max_hp")
	_assert(tm.is_alive("napoleon") == true, "추가 후 생존 상태")

func test_take_damage() -> void:
	print("[TestTeamManager] test_take_damage")
	var tm = TeamManagerClass.new()
	tm.add_hero(_make_hero("napoleon", 80))
	tm.take_damage("napoleon", 20)
	_assert(tm.get_current_hp("napoleon") == 60, "20 피해 후 HP == 60")

func test_hero_death() -> void:
	print("[TestTeamManager] test_hero_death")
	var tm = TeamManagerClass.new()
	tm.add_hero(_make_hero("napoleon", 80))
	tm.take_damage("napoleon", 80)
	_assert(tm.get_current_hp("napoleon") == 0, "치사 피해 후 HP == 0")
	_assert(tm.is_alive("napoleon") == false, "치사 피해 후 사망 상태")
