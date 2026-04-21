# tests/test_chapter_system.gd
class_name TestChapterSystem
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_chapter_pool_dispatch()
	test_reset_uses_current_chapter_pool()
	test_start_run_sets_chapter()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_chapter_pool_dispatch() -> void:
	print("[TestChapterSystem] test_chapter_pool_dispatch")
	var gm = GameManagerClass.new()
	var pool1 = gm._get_chapter_mythology_pool(1)
	var pool2 = gm._get_chapter_mythology_pool(2)
	_assert("greek" in pool1 and "egyptian" in pool1 and "norse" in pool1, "챕터 1 풀 = 그리스/이집트/북유럽")
	_assert(pool1.size() == 3, "챕터 1 풀 크기 3")
	_assert("korean" in pool2 and "chinese" in pool2 and "japanese" in pool2, "챕터 2 풀 = 한국/중국/일본")
	_assert(pool2.size() == 3, "챕터 2 풀 크기 3")

func test_reset_uses_current_chapter_pool() -> void:
	print("[TestChapterSystem] test_reset_uses_current_chapter_pool")
	var gm = GameManagerClass.new()
	gm.current_chapter = 2
	gm.reset()
	for myth in gm.act_mythologies:
		_assert(myth in ["korean", "chinese", "japanese"], "reset 후 act_mythologies 원소는 챕터 2 신화: " + myth)
	_assert(gm.act_mythologies.size() == 3, "act_mythologies 크기 3")

func test_start_run_sets_chapter() -> void:
	print("[TestChapterSystem] test_start_run_sets_chapter")
	var gm = GameManagerClass.new()
	gm.current_chapter = 1
	_assert(gm.current_chapter == 1, "기본 챕터는 1")
	gm.current_chapter = 2
	gm.reset()
	_assert(gm.current_chapter == 2, "current_chapter는 reset 후에도 유지")
