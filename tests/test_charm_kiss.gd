# tests/test_charm_kiss.gd
# charm_kiss.gd의 heart_unit / charm_proj_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestCharmKiss
extends RefCounted

const CharmKiss = preload("res://scenes/vfx/charm_kiss.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_heart_unit_point_count()
	test_heart_unit_bottom_tip()
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

func test_heart_unit_point_count() -> void:
	print("[TestCharmKiss] test_heart_unit_point_count")
	# 4개 베지어 × 8샘플 = 32점
	var h: PackedVector2Array = CharmKiss.heart_unit()
	_assert(h.size() == 32, "하트 윤곽 32점 (실제: %d)" % h.size())

func test_heart_unit_bottom_tip() -> void:
	print("[TestCharmKiss] test_heart_unit_bottom_tip")
	# 첫 점은 하트 아래 뾰족점 (0, 12)
	var h: PackedVector2Array = CharmKiss.heart_unit()
	_assert(h[0].is_equal_approx(Vector2(0, 12)), "첫 점 = 하트 아래 꼭짓점 (0,12)")

func test_proj_endpoints() -> void:
	print("[TestCharmKiss] test_proj_endpoints")
	var a := Vector2(100, 500)
	var b := Vector2(900, 500)
	_assert(CharmKiss.charm_proj_pos(a, b, 0.0, 50.0, 22.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(CharmKiss.charm_proj_pos(a, b, 1.0, 50.0, 22.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_proj_arc_apex() -> void:
	print("[TestCharmKiss] test_proj_arc_apex")
	# t=0.5 → 중간점에서 위(-y)로 솟음 (arc + wobble, wobble은 sin(1.5π)=-1 기여)
	var a := Vector2(0, 0)
	var b := Vector2(400, 0)
	var mid: Vector2 = CharmKiss.charm_proj_pos(a, b, 0.5, 50.0, 22.0)
	_assert(mid.x == 200.0, "t=0.5 → x는 중간점")
	_assert(mid.y < 0.0, "t=0.5 → y는 위로 솟음 (arc 음수)")
