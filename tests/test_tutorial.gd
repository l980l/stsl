# tests/test_tutorial.gd
class_name TestTutorial
extends RefCounted

const BM = preload("res://autoload/battle_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_force_crit_returns_crit()
	test_force_crit_off_by_default()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_force_crit_off_by_default() -> void:
	print("[TestTutorial] test_force_crit_off_by_default")
	var bm = BM.new()
	_assert(bm.tutorial_force_crit == false, "tutorial_force_crit 기본 false")
	bm.free()

func test_force_crit_returns_crit() -> void:
	print("[TestTutorial] test_force_crit_returns_crit")
	var bm = BM.new()
	bm.tutorial_force_crit = true
	var r: Dictionary = bm._roll_crit(0, false)
	_assert(r["is_crit"] == true, "force_crit 시 is_crit true")
	_assert(r["crit_mult"] == BM.CRIT_MULTIPLIER, "force_crit 시 crit_mult = ×2")
	bm.free()
