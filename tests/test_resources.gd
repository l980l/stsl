# tests/test_resources.gd
class_name TestResources
extends RefCounted

var EffectResource = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_effect_resource_defaults()
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, msg: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func test_effect_resource_defaults() -> void:
	print("[TestResources] test_effect_resource_defaults")
	var effect = EffectResource.new()
	_assert(effect.value == 0, "기본 value == 0")
	_assert(effect.target == "SINGLE", "기본 target == SINGLE")
	_assert(effect.status_type == "", "기본 status_type 비어있음")
