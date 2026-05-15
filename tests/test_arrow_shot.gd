# tests/test_arrow_shot.gd
# arrow_shot.gd의 arrow_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestArrowShot
extends RefCounted

const ArrowShot = preload("res://scenes/vfx/arrow_shot.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_arrow_endpoints()
	test_arrow_midpoint()
	test_arrow_clamp()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_arrow_endpoints() -> void:
	print("[TestArrowShot] test_arrow_endpoints")
	var a := Vector2(140, 480)
	var b := Vector2(900, 470)
	_assert(ArrowShot.arrow_pos(a, b, 0.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(ArrowShot.arrow_pos(a, b, 1.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_arrow_midpoint() -> void:
	print("[TestArrowShot] test_arrow_midpoint")
	var a := Vector2(0, 0)
	var b := Vector2(400, 200)
	_assert(ArrowShot.arrow_pos(a, b, 0.5).is_equal_approx(Vector2(200, 100)), "t=0.5 → 직선 중간점")

func test_arrow_clamp() -> void:
	print("[TestArrowShot] test_arrow_clamp")
	var a := Vector2(0, 0)
	var b := Vector2(100, 0)
	# t 범위를 벗어나도 0~1 로 클램프
	_assert(ArrowShot.arrow_pos(a, b, 1.5).is_equal_approx(b), "t>1 → 타겟에서 클램프")
	_assert(ArrowShot.arrow_pos(a, b, -0.5).is_equal_approx(a), "t<0 → 시전자에서 클램프")
