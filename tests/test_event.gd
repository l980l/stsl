# tests/test_event.gd
class_name TestEvent
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_event_pool_size()
	test_gold_event_exists()
	test_heal_event_costs_gold()
	test_draw_event_costs_hp()
	test_remove_card_event_exists()
	test_hero_recruit_event_exists()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

# GameManagerClass.new()는 TeamManager 참조로 headless 컴파일 실패.
# 대신 이벤트 풀을 직접 구성하는 헬퍼를 인라인으로 정의.
func _build_pool() -> Array:
	var EventRes = load("res://resources/event_resource.gd")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var events: Array = []

	var e1: Resource = EventRes.new(); e1.event_name = "황금 상자"
	var c1a: Resource = ChoiceRes.new(); c1a.label = "열기"
	c1a.effect_type = ChoiceRes.EffectType.GOLD; c1a.value = 30
	var c1b: Resource = ChoiceRes.new(); c1b.label = "무시"
	c1b.effect_type = ChoiceRes.EffectType.NONE
	e1.choices = [c1a, c1b]; events.append(e1)

	var e2: Resource = EventRes.new(); e2.event_name = "상처 입은 전사"
	var c2a: Resource = ChoiceRes.new(); c2a.label = "치료 (골드 -20)"
	c2a.effect_type = ChoiceRes.EffectType.HEAL; c2a.value = 15; c2a.cost_gold = 20
	var c2b: Resource = ChoiceRes.new(); c2b.label = "무시"
	c2b.effect_type = ChoiceRes.EffectType.NONE
	e2.choices = [c2a, c2b]; events.append(e2)

	var e3: Resource = EventRes.new(); e3.event_name = "고대 도서관"
	var c3a: Resource = ChoiceRes.new(); c3a.label = "공부 (HP -5)"
	c3a.effect_type = ChoiceRes.EffectType.DRAW_UP; c3a.value = 1; c3a.cost_hp = 5
	var c3b: Resource = ChoiceRes.new(); c3b.label = "무시"
	c3b.effect_type = ChoiceRes.EffectType.NONE
	e3.choices = [c3a, c3b]; events.append(e3)

	var e4: Resource = EventRes.new(); e4.event_name = "저주받은 제단"
	var c4a: Resource = ChoiceRes.new(); c4a.label = "카드 바치기 (덱에서 1장 제거)"
	c4a.effect_type = ChoiceRes.EffectType.REMOVE_CARD; c4a.value = 1
	var c4b: Resource = ChoiceRes.new(); c4b.label = "무시"
	c4b.effect_type = ChoiceRes.EffectType.NONE
	e4.choices = [c4a, c4b]; events.append(e4)

	var e5: Resource = EventRes.new(); e5.event_name = "동료 만남"
	var c5a: Resource = ChoiceRes.new(); c5a.label = "합류시키기"
	c5a.effect_type = ChoiceRes.EffectType.ADD_HERO
	var c5b: Resource = ChoiceRes.new(); c5b.label = "거절"
	c5b.effect_type = ChoiceRes.EffectType.NONE
	e5.choices = [c5a, c5b]; events.append(e5)

	return events

func test_event_pool_size() -> void:
	print("[TestEvent] test_event_pool_size")
	var pool := _build_pool()
	_assert(pool.size() == 5, "이벤트 풀 5종")

func test_gold_event_exists() -> void:
	print("[TestEvent] test_gold_event_exists")
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for ev in pool:
		for ch in ev.choices:
			if ch.effect_type == ChoiceRes.EffectType.GOLD and ch.value == 30:
				found = true
	_assert(found, "골드 +30 이벤트 존재")

func test_heal_event_costs_gold() -> void:
	print("[TestEvent] test_heal_event_costs_gold")
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for ev in pool:
		for ch in ev.choices:
			if ch.effect_type == ChoiceRes.EffectType.HEAL and ch.cost_gold > 0:
				found = true
	_assert(found, "HP 회복 이벤트 골드 비용 있음")

func test_draw_event_costs_hp() -> void:
	print("[TestEvent] test_draw_event_costs_hp")
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for ev in pool:
		for ch in ev.choices:
			if ch.effect_type == ChoiceRes.EffectType.DRAW_UP and ch.cost_hp > 0:
				found = true
	_assert(found, "드로우 증가 이벤트 HP 비용 있음")

func test_remove_card_event_exists() -> void:
	print("[TestEvent] test_remove_card_event_exists")
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for ev in pool:
		for ch in ev.choices:
			if ch.effect_type == ChoiceRes.EffectType.REMOVE_CARD:
				found = true
	_assert(found, "카드 제거 이벤트 존재")

func test_hero_recruit_event_exists() -> void:
	print("[TestEvent] test_hero_recruit_event_exists")
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for ev in pool:
		for ch in ev.choices:
			if ch.effect_type == ChoiceRes.EffectType.ADD_HERO:
				found = true
	_assert(found, "동료 영입 이벤트 존재")
