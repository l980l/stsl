# tests/test_poison_splash.gd
# poison_splash.gd의 flask_shape / proj_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestPoisonSplash
extends RefCounted

const PoisonSplash = preload("res://scenes/vfx/poison_splash.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_flask_point_count()
	test_flask_top_corners()
	test_proj_endpoints()
	test_proj_arc_apex()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_flask_point_count() -> void:
	print("[TestPoisonSplash] test_flask_point_count")
	# 직선 3점 + 베지어 2개 × 6샘플 = 15점
	var f: PackedVector2Array = PoisonSplash.flask_shape()
	_assert(f.size() == 15, "플라스크 윤곽 15점 (실제: %d)" % f.size())

func test_flask_top_corners() -> void:
	print("[TestPoisonSplash] test_flask_top_corners")
	# 첫 두 점은 병목 좌우 모서리
	var f: PackedVector2Array = PoisonSplash.flask_shape()
	_assert(f[0].is_equal_approx(Vector2(-5, -10)), "첫 점 = 병목 좌측 (-5,-10)")
	_assert(f[1].is_equal_approx(Vector2(5, -10)), "둘째 점 = 병목 우측 (5,-10)")

func test_proj_endpoints() -> void:
	print("[TestPoisonSplash] test_proj_endpoints")
	var a := Vector2(120, 480)
	var b := Vector2(880, 480)
	_assert(PoisonSplash.proj_pos(a, b, 0.0, 100.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(PoisonSplash.proj_pos(a, b, 1.0, 100.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_proj_arc_apex() -> void:
	print("[TestPoisonSplash] test_proj_arc_apex")
	# t=0.5 → 중간점에서 arc_h 만큼 위(-y)로
	var a := Vector2(0, 0)
	var b := Vector2(400, 0)
	var mid: Vector2 = PoisonSplash.proj_pos(a, b, 0.5, 100.0)
	_assert(mid.is_equal_approx(Vector2(200, -100)), "t=0.5 → 중간 + 최고점(-arc_h)")
