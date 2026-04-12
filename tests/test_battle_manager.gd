# tests/test_battle_manager.gd
class_name TestBattleManager
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_setup_battle()
	return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

func _make_bm() -> BattleManagerClass:
	var bm := BattleManagerClass.new()
	bm.team_mgr = TeamManagerClass.new()
	bm.deck_mgr = DeckManagerClass.new()
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_enemy(hp: int, intents: Array) -> Resource:
	var e := EnemyRes.new()
	e.max_hp = hp
	e.intent_pattern = intents
	return e

func _make_intent(action_type: int, value: int, target: int) -> Resource:
	var i := IntentRes.new()
	i.action_type = action_type
	i.value = value
	i.target = target
	return i

func _make_card(owner_id: String, cost: int, effects: Array) -> Resource:
	var c := CardRes.new()
	c.owner_id = owner_id
	c.cost = cost
	c.effects = effects
	return c

func _make_effect(effect_type: int, value: int, target: String) -> Resource:
	var e := EffectRes.new()
	e.effect_type = effect_type
	e.value = value
	e.target = target
	return e

func test_setup_battle() -> void:
	print("[TestBattleManager] test_setup_battle")
	var bm := _make_bm()
	var enemy := _make_enemy(30, [])
	bm.setup_battle([enemy])
	_assert(bm.get_enemy_hp(0) == 30, "적 HP == max_hp(30)")
	_assert(bm.is_enemy_alive(0), "셋업 후 적 생존")
	_assert(bm.is_battle_active, "배틀 활성")
	_assert(bm.get_enemy_block(0) == 0, "초기 블록 0")
