# tests/test_card_scene.gd
class_name TestCardScene
extends RefCounted

const CardSceneScript = preload("res://scenes/card/card_scene.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffectRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_card_scene_script_loads()
	test_resolve_frame_fallback()
	test_build_desc_empty_effects()
	test_build_desc_with_effects()
	test_set_disabled()
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
	_assert(CardSceneScript != null, "card_scene.gd 스크립트 로드 성공")

func test_resolve_frame_fallback() -> void:
	print("[TestCardScene] test_resolve_frame_fallback")
	# CardSceneScript.new()로 인스턴스화 — _ready() 미호출, 노드 경로 접근 없음
	var scene = CardSceneScript.new()
	var tex = scene._resolve_frame_texture("nonexistent_hero_xxx")
	_assert(tex != null, "존재하지 않는 영웅 ID → sampleframe.png fallback, null 아님")
	scene.free()

func test_build_desc_empty_effects() -> void:
	print("[TestCardScene] test_build_desc_empty_effects")
	var scene = CardSceneScript.new()
	var card = CardRes.new()
	card.effects = []
	scene._card = card
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
	scene._card = card
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
