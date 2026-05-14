# tests/test_fire_blast.gd
# fire_blast.gd의 proj_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestFireBlast
extends RefCounted

const FireBlast = preload("res://scenes/vfx/fire_blast.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_proj_endpoints()
	test_proj_arc_apex()
	test_proj_arc_zero()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_proj_endpoints() -> void:
	print("[TestFireBlast] test_proj_endpoints")
	var a := Vector2(100, 500)
	var b := Vector2(900, 500)
	_assert(FireBlast.proj_pos(a, b, 0.0, 120.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(FireBlast.proj_pos(a, b, 1.0, 120.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_proj_arc_apex() -> void:
	print("[TestFireBlast] test_proj_arc_apex")
	# t=0.5 → 중간점에서 arc_h 만큼 위(-y)로
	var a := Vector2(0, 0)
	var b := Vector2(400, 0)
	var mid: Vector2 = FireBlast.proj_pos(a, b, 0.5, 120.0)
	_assert(mid.is_equal_approx(Vector2(200, -120)), "t=0.5 → 중간 + 최고점(-arc_h)")

func test_proj_arc_zero() -> void:
	print("[TestFireBlast] test_proj_arc_zero")
	# arc_h=0 → 직선 보간
	var a := Vector2(0, 0)
	var b := Vector2(100, 100)
	_assert(FireBlast.proj_pos(a, b, 0.5, 0.0).is_equal_approx(Vector2(50, 50)), "arc 0 → 직선 보간")
