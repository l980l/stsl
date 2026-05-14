# tests/test_ice_shards.gd
# ice_shards.gd의 diamond static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestIceShards
extends RefCounted

const IceShards = preload("res://scenes/vfx/ice_shards.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_diamond_point_count()
	test_diamond_symmetry()
	test_diamond_orientation()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_diamond_point_count() -> void:
	print("[TestIceShards] test_diamond_point_count")
	var d: PackedVector2Array = IceShards.diamond(Vector2(100, 100), 0.0, 20.0, 8.0)
	_assert(d.size() == 4, "다이아몬드 점 4개 (실제: %d)" % d.size())

func test_diamond_symmetry() -> void:
	print("[TestIceShards] test_diamond_symmetry")
	var c := Vector2(50, 50)
	var d: PackedVector2Array = IceShards.diamond(c, 0.0, 30.0, 10.0)
	_assert(d[0].is_equal_approx(c + Vector2(30, 0)), "앞 점 = 중심 + 전방*half_len")
	_assert(d[2].is_equal_approx(c - Vector2(30, 0)), "뒤 점 = 중심 - 전방*half_len")
	_assert(d[1].is_equal_approx(c + (c - d[3])), "옆 두 점은 중심 대칭")

func test_diamond_orientation() -> void:
	print("[TestIceShards] test_diamond_orientation")
	# ang = 90° (아래 방향) → 앞 점이 +y 쪽
	var d: PackedVector2Array = IceShards.diamond(Vector2.ZERO, PI / 2.0, 25.0, 5.0)
	_assert(d[0].is_equal_approx(Vector2(0, 25)), "ang=90°일 때 앞 점 = (0, half_len)")
