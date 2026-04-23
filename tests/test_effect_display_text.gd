# tests/test_effect_display_text.gd
class_name TestEffectDisplayText
extends RefCounted

const EffectRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_all_effect_types_return_string()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_all_effect_types_return_string() -> void:
	# EffectType enum 개수: 30 (0~29)
	var eff := EffectRes.new()
	for t in range(30):
		eff.effect_type = t
		eff.value = 5
		eff.bonus_value = 10
		eff.hit_count = 1
		eff.target = "SINGLE"
		eff.status_type = "test"
		var result: String = eff.display_text()
		_assert(result != null, "EffectType %d display_text() non-null" % t)
		_assert(result is String, "EffectType %d display_text() is String" % t)
