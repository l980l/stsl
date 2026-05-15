# tests/test_blunt_smash.gd
# blunt_smash.gd의 star_poly static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestBluntSmash
extends RefCounted

const BluntSmash = preload("res://scenes/vfx/blunt_smash.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_star_5_point_count()
	test_star_8_point_count()
	test_star_outer_first()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_star_5_point_count() -> void:
	print("[TestBluntSmash] test_star_5_point_count")
	# 5각 별 → 바깥/안쪽 교대 = 10점
	var s: PackedVector2Array = BluntSmash.star_poly(Vector2.ZERO, 10.0, 4.0, 5, 0.0)
	_assert(s.size() == 10, "5각 별 윤곽 10점 (실제: %d)" % s.size())

func test_star_8_point_count() -> void:
	print("[TestBluntSmash] test_star_8_point_count")
	# 8각 별 → 16점
	var s: PackedVector2Array = BluntSmash.star_poly(Vector2.ZERO, 88.0, 36.0, 8, 0.0)
	_assert(s.size() == 16, "8각 별 윤곽 16점 (실제: %d)" % s.size())

func test_star_outer_first() -> void:
	print("[TestBluntSmash] test_star_outer_first")
	# 첫 점은 위쪽 바깥 꼭짓점 (rot=0, ang = -PI/2): center + (0, -outer_r)
	var c := Vector2(50, 50)
	var s: PackedVector2Array = BluntSmash.star_poly(c, 10.0, 4.0, 5, 0.0)
	_assert(s[0].is_equal_approx(c + Vector2(0, -10)), "첫 점 = 위쪽 바깥 꼭짓점")
