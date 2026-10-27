# tests/test_card_scene.gd
class_name TestCardScene
extends RefCounted

const CardSceneScript = preload("res://scenes/card/card_scene_v2.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffectRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_card_scene_script_loads()
	test_build_desc_empty_effects()
	test_build_desc_with_effects()
	test_set_disabled()
	test_signals_defined()
	test_drag_state_initial()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_card_scene_script_loads() -> void:
	print("[TestCardScene] test_card_scene_script_loads")
	_assert(CardSceneScript != null, "card_scene_v2.gd 스크립트 로드 성공")

func test_build_desc_empty_effects() -> void:
	print("[TestCardScene] test_build_desc_empty_effects")
	# CardSceneScript.new()로 인스턴스화 — _ready() 미호출, 노드 경로 접근 없음
	var scene = CardSceneScript.new()
	var card = CardRes.new()
	card.effects = []
	scene._card_res = card
	var desc = scene._build_desc()
	_assert(desc == "", "effects 비어있으면 빈 문자열 반환")
	scene.free()

func test_build_desc_with_effects() -> void:
	print("[TestCardScene] test_build_desc_with_effects")
	var scene = CardSceneScript.new()
	var card = CardRes.new()
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE
	eff.value = 10
	card.effects = [eff]
	scene._card_res = card
	scene._mode = CardSceneScript.Mode.REWARD
	var desc = scene._build_desc()
	_assert(desc != "", "DAMAGE 이펙트 있으면 비어있지 않은 설명 반환")
	scene.free()

func test_set_disabled() -> void:
	print("[TestCardScene] test_set_disabled")
	var scene = CardSceneScript.new()
	scene.set_disabled(true)
	_assert(scene._disabled == true, "set_disabled(true) → _disabled == true")
	scene.set_disabled(false)
	_assert(scene._disabled == false, "set_disabled(false) → _disabled == false")
	scene.free()

func test_signals_defined() -> void:
	print("[TestCardScene] test_signals_defined")
	var scene = CardSceneScript.new()
	_assert(scene.has_signal("card_clicked"), "card_clicked 시그널 정의됨")
	_assert(scene.has_signal("card_drag_started"), "card_drag_started 시그널 정의됨")
	_assert(scene.has_signal("card_drag_released"), "card_drag_released 시그널 정의됨")
	_assert(scene.has_signal("card_hovered"), "card_hovered 시그널 정의됨")
	scene.free()

func test_drag_state_initial() -> void:
	print("[TestCardScene] test_drag_state_initial")
	var scene = CardSceneScript.new()
	_assert(not scene._pressing, "초기 _pressing == false")
	_assert(not scene._dragging_input, "초기 _dragging_input == false")
	scene.free()
