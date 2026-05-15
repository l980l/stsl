# tests/test_lightning_beam.gd
# lightning_beam.gd의 make_bolt static 함수 검증 (autoload 비의존 — 순수 기하).
class_name TestLightningBeam
extends RefCounted

const LightningBeam = preload("res://scenes/vfx/lightning_beam.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_make_bolt_point_count()
	test_make_bolt_endpoints()
	test_make_bolt_branches()
	test_make_bolt_zero_length()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_make_bolt_point_count() -> void:
	print("[TestLightningBeam] test_make_bolt_point_count")
	var b: Dictionary = LightningBeam.make_bolt(Vector2(0, 0), Vector2(400, 0), 20, 46.0, 3)
	# HTML makeBolt: 시작점 + (segs-1) 중간점 + 끝점 = segs+1
	_assert(b["main"].size() == 21, "main 점 개수 = segs+1 (실제: %d)" % b["main"].size())

func test_make_bolt_endpoints() -> void:
	print("[TestLightningBeam] test_make_bolt_endpoints")
	var a := Vector2(100, 200)
	var z := Vector2(700, 350)
	var b: Dictionary = LightningBeam.make_bolt(a, z, 18, 38.0, 0)
	_assert(b["main"][0] == a, "첫 점 == 시전자 좌표")
	_assert(b["main"][b["main"].size() - 1] == z, "끝 점 == 타겟 좌표")

func test_make_bolt_branches() -> void:
	print("[TestLightningBeam] test_make_bolt_branches")
	var b: Dictionary = LightningBeam.make_bolt(Vector2(0, 0), Vector2(500, 0), 20, 46.0, 3)
	_assert(b["branches"].size() == 3, "가지 3개 생성 (실제: %d)" % b["branches"].size())
	var all_ok := true
	for br in b["branches"]:
		if br.size() != 9:  # 가지는 segs=8 → 9점
			all_ok = false
	_assert(all_ok, "각 가지 점 개수 = 8+1")

func test_make_bolt_zero_length() -> void:
	print("[TestLightningBeam] test_make_bolt_zero_length")
	# 시전자==타겟이어도 크래시 없이 (length 0 → maxf로 1.0 가드)
	var b: Dictionary = LightningBeam.make_bolt(Vector2(50, 50), Vector2(50, 50), 20, 46.0, 0)
	_assert(b["main"].size() == 21, "동일 좌표에서도 점 개수 정상")
