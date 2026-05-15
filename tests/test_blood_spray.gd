# tests/test_blood_spray.gd
# blood_spray.gd의 ellipse_poly static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestBloodSpray
extends RefCounted

const BloodSpray = preload("res://scenes/vfx/blood_spray.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_ellipse_point_count()
	test_ellipse_axis_aligned()
	test_ellipse_rotated()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_ellipse_point_count() -> void:
	print("[TestBloodSpray] test_ellipse_point_count")
	var e: PackedVector2Array = BloodSpray.ellipse_poly(Vector2(100, 100), 16.0, 7.0, 0.0, 10)
	_assert(e.size() == 10, "타원 윤곽 10점 (실제: %d)" % e.size())

func test_ellipse_axis_aligned() -> void:
	print("[TestBloodSpray] test_ellipse_axis_aligned")
	# 회전 0 → i=0 점은 center + (rx, 0)
	var c := Vector2(50, 50)
	var e: PackedVector2Array = BloodSpray.ellipse_poly(c, 16.0, 7.0, 0.0, 8)
	_assert(e[0].is_equal_approx(c + Vector2(16, 0)), "회전0 첫 점 = center + (rx,0)")
	_assert(e[2].is_equal_approx(c + Vector2(0, 7)), "회전0 1/4점 = center + (0,ry)")

func test_ellipse_rotated() -> void:
	print("[TestBloodSpray] test_ellipse_rotated")
	# 90° 회전 → i=0 점 (rx,0) → (0,rx)
	var e: PackedVector2Array = BloodSpray.ellipse_poly(Vector2.ZERO, 16.0, 7.0, PI / 2.0, 8)
	_assert(e[0].is_equal_approx(Vector2(0, 16)), "90° 회전 첫 점 → (0,rx)")
