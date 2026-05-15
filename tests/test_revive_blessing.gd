# tests/test_revive_blessing.gd
# revive_blessing.gd의 pillar_quad static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestReviveBlessing
extends RefCounted

const ReviveBlessing = preload("res://scenes/vfx/revive_blessing.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_pillar_point_count()
	test_pillar_grow_zero()
	test_pillar_grow_full()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_pillar_point_count() -> void:
	print("[TestReviveBlessing] test_pillar_point_count")
	var q: PackedVector2Array = ReviveBlessing.pillar_quad(Vector2(500, 400), 200.0, 420.0, 1.0)
	_assert(q.size() == 4, "빛기둥 사다리꼴 4점 (실제: %d)" % q.size())

func test_pillar_grow_zero() -> void:
	print("[TestReviveBlessing] test_pillar_grow_zero")
	# grow 0 → 위·아래 모서리 y가 동일 (높이 0)
	var t := Vector2(500, 400)
	var q: PackedVector2Array = ReviveBlessing.pillar_quad(t, 200.0, 420.0, 0.0)
	_assert(is_equal_approx(q[0].y, q[2].y), "grow 0 → 위·아래 y 동일 (높이 0)")
	_assert(is_equal_approx(q[0].y, t.y - 420.0), "grow 0 → 모두 기둥 상단 y")

func test_pillar_grow_full() -> void:
	print("[TestReviveBlessing] test_pillar_grow_full")
	# grow 1 → 위는 target.y-height, 아래는 target.y, 너비는 width
	var t := Vector2(500, 400)
	var q: PackedVector2Array = ReviveBlessing.pillar_quad(t, 200.0, 420.0, 1.0)
	_assert(is_equal_approx(q[0].y, t.y - 420.0), "grow 1 → 상단 y = target.y - height")
	_assert(is_equal_approx(q[2].y, t.y), "grow 1 → 하단 y = target.y")
	_assert(is_equal_approx(q[1].x - q[0].x, 200.0), "기둥 너비 = width")
