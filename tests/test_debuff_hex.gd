# tests/test_debuff_hex.gd
# debuff_hex.gd의 rotate_points static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestDebuffHex
extends RefCounted

const DebuffHex = preload("res://scenes/vfx/debuff_hex.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_rotate_identity()
	test_rotate_90()
	test_rotate_scale()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_rotate_identity() -> void:
	print("[TestDebuffHex] test_rotate_identity")
	# 회전 0, scale 1 → center 기준 그대로
	var pts := PackedVector2Array([Vector2(10, 0), Vector2(0, 20)])
	var c := Vector2(100, 100)
	var r: PackedVector2Array = DebuffHex.rotate_points(pts, c, 0.0, 1.0)
	_assert(r[0].is_equal_approx(Vector2(110, 100)), "회전0 → center + p")
	_assert(r[1].is_equal_approx(Vector2(100, 120)), "회전0 두 번째 점")

func test_rotate_90() -> void:
	print("[TestDebuffHex] test_rotate_90")
	# (10,0)을 90° 회전 → (0,10)
	var pts := PackedVector2Array([Vector2(10, 0)])
	var r: PackedVector2Array = DebuffHex.rotate_points(pts, Vector2.ZERO, PI / 2.0, 1.0)
	_assert(r[0].is_equal_approx(Vector2(0, 10)), "90° 회전 → (0,10)")

func test_rotate_scale() -> void:
	print("[TestDebuffHex] test_rotate_scale")
	# scale 2 → center에서 거리 2배
	var pts := PackedVector2Array([Vector2(5, 0)])
	var c := Vector2(50, 50)
	var r: PackedVector2Array = DebuffHex.rotate_points(pts, c, 0.0, 2.0)
	_assert(r[0].is_equal_approx(Vector2(60, 50)), "scale 2 → 거리 2배")
