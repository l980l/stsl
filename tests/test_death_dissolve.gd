# tests/test_death_dissolve.gd
# death_dissolve.gd의 ash_quad static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestDeathDissolve
extends RefCounted

const DeathDissolve = preload("res://scenes/vfx/death_dissolve.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_ash_quad_point_count()
	test_ash_quad_axis_aligned()
	test_ash_quad_rotated()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_ash_quad_point_count() -> void:
	print("[TestDeathDissolve] test_ash_quad_point_count")
	var q: PackedVector2Array = DeathDissolve.ash_quad(Vector2(100, 100), 10.0, 4.0, 0.0)
	_assert(q.size() == 4, "재 사각형 4점 (실제: %d)" % q.size())

func test_ash_quad_axis_aligned() -> void:
	print("[TestDeathDissolve] test_ash_quad_axis_aligned")
	# 회전 0 → 축정렬 사각형 (center ± half)
	var c := Vector2(50, 50)
	var q: PackedVector2Array = DeathDissolve.ash_quad(c, 10.0, 4.0, 0.0)
	_assert(q[0].is_equal_approx(c + Vector2(-10, -4)), "회전0 좌상단 = center + (-w,-h)")
	_assert(q[2].is_equal_approx(c + Vector2(10, 4)), "회전0 우하단 = center + (w,h)")

func test_ash_quad_rotated() -> void:
	print("[TestDeathDissolve] test_ash_quad_rotated")
	# 90° 회전 → (-10,-4) → (4,-10)
	var q: PackedVector2Array = DeathDissolve.ash_quad(Vector2.ZERO, 10.0, 4.0, PI / 2.0)
	_assert(q[0].is_equal_approx(Vector2(4, -10)), "90° 회전 좌상단 → (4,-10)")
