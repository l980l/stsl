# v3 개편 전제 조건: 막별 적 난이도와 명시 강화 회귀 테스트.
class_name TestRevisionDifficulty
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_shared_phase_intent_scales_once()
	test_charge_payoff_scales_once()
	test_elite_uses_elite_grade_speed()
	test_all_elite_definitions()
	test_explicit_upgrade_only_changes_declared_values()
	test_legacy_upgrade_stays_available_for_unmigrated_cards()
	return {"passed": passed, "failed": failed}

func _assert(condition: bool, message: String) -> void:
	if condition:
		passed += 1
		print("  PASS: " + message)
	else:
		failed += 1
		push_error("  FAIL: " + message)

func test_shared_phase_intent_scales_once() -> void:
	print("[TestRevisionDifficulty] test_shared_phase_intent_scales_once")
	var gm := GameManagerClass.new()
	var enemy := EnemyRes.new()
	var attack := IntentRes.new()
	attack.action_type = IntentRes.ActionType.ATTACK
	attack.value = 160
	enemy.intent_pattern = [attack]
	enemy.phase_patterns = [[attack]]
	gm._apply_act_difficulty([enemy], 3)
	_assert(attack.value == 224, "공유된 기본/페이즈 공격은 Act 3 배율을 한 번만 적용")
	gm._apply_act_difficulty([enemy], 3)
	_assert(attack.value == 224, "같은 적에 난이도를 다시 적용해도 누적되지 않음")
	gm.free()

func test_charge_payoff_scales_once() -> void:
	print("[TestRevisionDifficulty] test_charge_payoff_scales_once")
	var gm := GameManagerClass.new()
	var enemy := EnemyRes.new()
	var payoff := IntentRes.new()
	payoff.action_type = IntentRes.ActionType.ATTACK
	payoff.value = 100
	var charge := IntentRes.new()
	charge.action_type = IntentRes.ActionType.CHARGE_UP
	charge.payoff_intents = [payoff]
	enemy.intent_pattern = [charge]
	enemy.phase_patterns = [[charge]]
	gm._apply_act_difficulty([enemy], 3)
	_assert(payoff.value == 140, "공유된 차지 보상 공격도 Act 3 배율을 한 번 적용")
	gm.free()

func test_elite_uses_elite_grade_speed() -> void:
	print("[TestRevisionDifficulty] test_elite_uses_elite_grade_speed")
	var gm := GameManagerClass.new()
	gm.current_act = 1
	gm.act_mythologies = ["greek"]
	var enemies := gm._make_elite_enemies()
	_assert(enemies.size() == 1 and enemies[0].grade == EnemyRes.Grade.ELITE,
		"엘리트 방의 적은 ELITE 등급으로 생성")
	var bm := BattleManagerClass.new()
	bm._enemies = enemies
	_assert(bm._enemy_effective_speed(0) == 53, "등급 기본 속도로 엘리트는 53을 사용")
	bm.free()
	gm.free()

func test_all_elite_definitions() -> void:
	var catalog = load("res://resources/monster_catalog.gd")
	var count := 0
	for mythology in catalog.MYTH_ORDER:
		for act in catalog._ACTS[mythology]:
			for factory in act.elites():
				var enemy = act.call(factory, null)
				_assert(enemy.grade == EnemyRes.Grade.ELITE, mythology + " " + factory + " authored elite grade")
				count += 1
	_assert(count == 55, "all 55 authored elite factories checked")

func test_explicit_upgrade_only_changes_declared_values() -> void:
	print("[TestRevisionDifficulty] test_explicit_upgrade_only_changes_declared_values")
	var gm := GameManagerClass.new()
	var card := CardRes.new()
	card.cost = 2
	card.upgrade_cost = 1
	card.has_explicit_upgrade = true
	var changed := EffRes.new()
	changed.effect_type = EffRes.EffectType.DAMAGE
	changed.value = 80
	changed.base_value = 80
	changed.upgrade_value = 110
	var unchanged := EffRes.new()
	unchanged.effect_type = EffRes.EffectType.DRAW
	unchanged.value = 1
	unchanged.base_value = 1
	card.effects = [changed, unchanged]
	gm.upgrade_card(card)
	_assert(card.upgrade_level == 1 and card.cost == 1, "명시 강화는 지정 비용을 적용")
	_assert(changed.value == 110, "명시한 효과만 지정 수치로 변경")
	_assert(unchanged.value == 1, "명시하지 않은 보조 효과는 유지")
	gm.free()

func test_legacy_upgrade_stays_available_for_unmigrated_cards() -> void:
	print("[TestRevisionDifficulty] test_legacy_upgrade_stays_available_for_unmigrated_cards")
	var gm := GameManagerClass.new()
	var card := CardRes.new()
	card.rarity = CardRes.Rarity.COMMON
	var effect := EffRes.new()
	effect.effect_type = EffRes.EffectType.DAMAGE
	effect.value = 100
	effect.base_value = 100
	card.effects = [effect]
	gm.upgrade_card(card)
	_assert(effect.value == 108, "개편 대상이 아닌 카드는 기존 강화 규칙을 유지")
	gm.free()
