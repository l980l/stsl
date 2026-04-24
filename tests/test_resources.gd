# tests/test_resources.gd
class_name TestResources
extends RefCounted

var EffectResource = preload("res://resources/effect_resource.gd")
var CardResource = preload("res://resources/card_resource.gd")
var HeroResource = preload("res://resources/hero_resource.gd")
var IntentResource = preload("res://resources/intent_resource.gd")
var EnemyResource = preload("res://resources/enemy_resource.gd")
var RelicResource = preload("res://resources/relic_resource.gd")
var GameManagerClass = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_effect_resource_defaults()
	test_card_resource_defaults()
	test_hero_resource_defaults()
	test_enemy_resource_defaults()
	test_relic_resource_defaults()
	test_game_manager_defaults()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
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
	_assert(card.upgrade_level == 0, "기본 upgrade_level == 0")
	_assert(card.card_type == CardResource.CardType.ATTACK, "기본 타입 ATTACK")
	_assert(card.effects.size() == 0, "기본 effects 비어있음")
	_assert(card.owner_id == "", "기본 owner_id 비어있음")
	_assert(card.play_animation == "", "기본 play_animation 비어있음")

func test_hero_resource_defaults() -> void:
	print("[TestResources] test_hero_resource_defaults")
	var hero = HeroResource.new()
	_assert(hero.max_hp == 70, "기본 max_hp == 70")
	_assert(hero.card_pool.size() == 0, "기본 카드풀 비어있음")
	_assert(hero.hero_id == "", "기본 hero_id 비어있음")

func test_enemy_resource_defaults() -> void:
	print("[TestResources] test_enemy_resource_defaults")
	var enemy = EnemyResource.new()
	_assert(enemy.grade == EnemyResource.Grade.NORMAL, "기본 등급 NORMAL")
	_assert(enemy.max_hp == 30, "기본 max_hp == 30")
	_assert(enemy.intent_pattern.size() == 0, "기본 행동 패턴 비어있음")
	_assert(enemy.phase_thresholds.size() == 0, "기본 페이즈 비어있음")

	var intent = IntentResource.new()
	_assert(intent.value == 0, "intent 기본 value == 0")
	_assert(intent.action_type == IntentResource.ActionType.ATTACK, "기본 행동 ATTACK")
	_assert(intent.target == IntentResource.TargetType.RANDOM, "기본 타겟 RANDOM")
	_assert(intent.play_animation == "", "기본 play_animation 비어있음")

func test_relic_resource_defaults() -> void:
	print("[TestResources] test_relic_resource_defaults")
	var relic = RelicResource.new()
	_assert(relic.owner_hero_id == "", "기본 owner_hero_id 비어있음 = 공용 릴릭")
	_assert(relic.relic_name == "", "기본 relic_name 비어있음")

func test_game_manager_defaults() -> void:
	print("[TestResources] test_game_manager_defaults")
	var gm = GameManagerClass.new()
	_to_free.append(gm)
	_assert(gm.current_state == GameManagerClass.GameState.MAP, "초기 상태 MAP")
	_assert(gm.current_act == 1, "초기 액트 1")
	_assert(gm.gold == 0, "초기 골드 0")
	_assert(gm.relics.size() == 0, "초기 릴릭 없음")
