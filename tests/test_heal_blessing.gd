# tests/test_heal_blessing.gd
# heal_blessing.gd의 leaf_shape static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestHealBlessing
extends RefCounted

const HealBlessing = preload("res://scenes/vfx/heal_blessing.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_leaf_point_count()
	test_leaf_tips()
	test_leaf_symmetry()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_leaf_point_count() -> void:
	print("[TestHealBlessing] test_leaf_point_count")
	# 큐빅 베지어 2개 × 6샘플 = 12점
	var l: PackedVector2Array = HealBlessing.leaf_shape()
	_assert(l.size() == 12, "나뭇잎 윤곽 12점 (실제: %d)" % l.size())

func test_leaf_tips() -> void:
	print("[TestHealBlessing] test_leaf_tips")
	# 첫 점은 잎 위 꼭짓점 (0,-1), 7번째 점은 잎 아래 꼭짓점 (0,1)
	var l: PackedVector2Array = HealBlessing.leaf_shape()
	_assert(l[0].is_equal_approx(Vector2(0, -1)), "첫 점 = 잎 위 꼭짓점 (0,-1)")
	_assert(l[6].is_equal_approx(Vector2(0, 1)), "7번째 점 = 잎 아래 꼭짓점 (0,1)")

func test_leaf_symmetry() -> void:
	print("[TestHealBlessing] test_leaf_symmetry")
	# 윗 꼭짓점 직후 점은 오른쪽(+x), 아래 꼭짓점 직후 점은 왼쪽(-x) — 좌우 대칭 잎
	var l: PackedVector2Array = HealBlessing.leaf_shape()
	_assert(l[1].x > 0.0, "위 꼭짓점 다음 점은 우측 곡선 (+x)")
	_assert(l[7].x < 0.0, "아래 꼭짓점 다음 점은 좌측 곡선 (-x)")
