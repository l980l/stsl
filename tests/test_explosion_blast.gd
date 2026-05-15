# tests/test_explosion_blast.gd
# explosion_blast.gd의 proj_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestExplosionBlast
extends RefCounted

const ExplosionBlast = preload("res://scenes/vfx/explosion_blast.gd")

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
	print("[TestExplosionBlast] test_proj_endpoints")
	var a := Vector2(160, 470)
	var b := Vector2(900, 560)
	_assert(ExplosionBlast.proj_pos(a, b, 0.0, 180.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(ExplosionBlast.proj_pos(a, b, 1.0, 180.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_proj_arc_apex() -> void:
	print("[TestExplosionBlast] test_proj_arc_apex")
	# t=0.5 → 중간점에서 arc_h 만큼 위(-y)로
	var a := Vector2(0, 0)
	var b := Vector2(400, 0)
	var mid: Vector2 = ExplosionBlast.proj_pos(a, b, 0.5, 180.0)
	_assert(mid.is_equal_approx(Vector2(200, -180)), "t=0.5 → 중간 + 최고점(-arc_h)")

func test_proj_arc_zero() -> void:
	print("[TestExplosionBlast] test_proj_arc_zero")
	# arc_h=0 → 직선 보간
	var a := Vector2(0, 0)
	var b := Vector2(100, 100)
	_assert(ExplosionBlast.proj_pos(a, b, 0.5, 0.0).is_equal_approx(Vector2(50, 50)), "arc 0 → 직선 보간")
