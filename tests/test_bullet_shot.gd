# tests/test_bullet_shot.gd
# bullet_shot.gd의 bullet_pos static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestBulletShot
extends RefCounted

const BulletShot = preload("res://scenes/vfx/bullet_shot.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_bullet_endpoints()
	test_bullet_midpoint()
	test_bullet_clamp()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_bullet_endpoints() -> void:
	print("[TestBulletShot] test_bullet_endpoints")
	var a := Vector2(160, 470)
	var b := Vector2(900, 480)
	_assert(BulletShot.bullet_pos(a, b, 0.0).is_equal_approx(a), "t=0 → 시전자 좌표")
	_assert(BulletShot.bullet_pos(a, b, 1.0).is_equal_approx(b), "t=1 → 타겟 좌표")

func test_bullet_midpoint() -> void:
	print("[TestBulletShot] test_bullet_midpoint")
	var a := Vector2(0, 0)
	var b := Vector2(400, 200)
	_assert(BulletShot.bullet_pos(a, b, 0.5).is_equal_approx(Vector2(200, 100)), "t=0.5 → 직선 중간점")

func test_bullet_clamp() -> void:
	print("[TestBulletShot] test_bullet_clamp")
	var a := Vector2(0, 0)
	var b := Vector2(100, 0)
	_assert(BulletShot.bullet_pos(a, b, 1.5).is_equal_approx(b), "t>1 → 타겟에서 클램프")
	_assert(BulletShot.bullet_pos(a, b, -0.5).is_equal_approx(a), "t<0 → 시전자에서 클램프")
