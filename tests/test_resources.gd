# tests/test_resources.gd
class_name TestResources
extends RefCounted

var EffectResource = preload("res://resources/effect_resource.gd")
var CardResource = preload("res://resources/card_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_effect_resource_defaults()
	test_card_resource_defaults()
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

func test_card_resource_defaults() -> void:
	print("[TestResources] test_card_resource_defaults")
	var card = CardResource.new()
	_assert(card.cost == 1, "기본 cost == 1")
	_assert(card.upgraded == false, "기본 upgraded == false")
	_assert(card.card_type == CardResource.CardType.ATTACK, "기본 타입 ATTACK")
	_assert(card.effects.size() == 0, "기본 effects 비어있음")
	_assert(card.owner_id == "", "기본 owner_id 비어있음")
	_assert(card.play_animation == "", "기본 play_animation 비어있음")
