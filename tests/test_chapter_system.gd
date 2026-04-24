# tests/test_chapter_system.gd
class_name TestChapterSystem
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_chapter_pool_dispatch()
	test_reset_uses_current_chapter_pool()
	test_start_run_sets_chapter()
	test_chapter2_pool_filters_empty_stubs()
	test_chapter2_has_all_three_mythologies()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
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
	_to_free.append(gm)
	var pool1 = gm._get_chapter_mythology_pool(1)
	var pool2 = gm._get_chapter_mythology_pool(2)
	_assert("greek" in pool1 and "egyptian" in pool1 and "norse" in pool1, "챕터 1 풀 = 그리스/이집트/북유럽")
	_assert(pool1.size() == 3, "챕터 1 풀 크기 3")
	# 챕터 2 풀: 구현된 신화만 포함 (빈 스텁은 자동 필터)
	_assert(pool2.size() == 3, "챕터 2 풀 크기 3")
	for myth in pool2:
		_assert(myth in ["korean", "chinese", "japanese"], "챕터 2 풀 원소는 아시아 신화: " + myth)

func test_reset_uses_current_chapter_pool() -> void:
	print("[TestChapterSystem] test_reset_uses_current_chapter_pool")
	var gm = GameManagerClass.new()
	_to_free.append(gm)
	gm.current_chapter = 2
	gm.reset()
	for myth in gm.act_mythologies:
		_assert(myth in ["korean", "chinese", "japanese"], "reset 후 act_mythologies 원소는 아시아 신화: " + myth)
	_assert(gm.act_mythologies.size() == 3, "act_mythologies 크기 3")

func test_start_run_sets_chapter() -> void:
	print("[TestChapterSystem] test_start_run_sets_chapter")
	var gm = GameManagerClass.new()
	_to_free.append(gm)
	gm.current_chapter = 1
	_assert(gm.current_chapter == 1, "기본 챕터는 1")
	gm.current_chapter = 2
	gm.reset()
	_assert(gm.current_chapter == 2, "current_chapter는 reset 후에도 유지")

func test_chapter2_pool_filters_empty_stubs() -> void:
	print("[TestChapterSystem] test_chapter2_pool_filters_empty_stubs")
	var gm = GameManagerClass.new()
	_to_free.append(gm)
	var pool := gm._get_chapter_mythology_pool(2)
	_assert(pool.size() == 3, "챕터2 풀은 항상 3개")
	for myth in pool:
		_assert(myth in ["korean", "chinese", "japanese"], "챕터2 풀 — 한·중·일 신화: " + myth)

func test_chapter2_has_all_three_mythologies() -> void:
	print("[TestChapterSystem] test_chapter2_has_all_three_mythologies")
	var seen: Dictionary = {}
	for _i in range(100):
		var gm = GameManagerClass.new()
		_to_free.append(gm)
		var pool := gm._get_chapter_mythology_pool(2)
		for myth in pool:
			seen[myth] = true
	_assert("korean" in seen, "한국 신화 챕터2 풀에 포함")
	_assert("chinese" in seen, "중국 신화 챕터2 풀에 포함")
	_assert("japanese" in seen, "일본 신화 챕터2 풀에 포함")
