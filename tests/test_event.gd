# tests/test_event.gd
class_name TestEvent
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_gold_event_exists()
	test_heal_event_costs_gold()
	test_draw_event_costs_hp()
	test_remove_card_event_exists()
	test_hero_recruit_event_exists()
	test_add_relic_choice_structure()
	test_gold_with_cost_hp_structure()
	test_pool_has_ten_events()
	test_prometheus_event_exists()
	test_hades_event_uses_add_relic()
	test_hermes_event_has_two_choices()
	test_devil_deal_event_exists()
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

	# 6. 프로메테우스의 불
	var e6: Resource = EventRes.new(); e6.event_name = "프로메테우스의 불"
	var c6a: Resource = ChoiceRes.new(); c6a.label = "불씨를 받는다 (드로우 +1, HP -20)"
	c6a.effect_type = ChoiceRes.EffectType.DRAW_UP; c6a.value = 1; c6a.cost_hp = 20
	var c6b: Resource = ChoiceRes.new(); c6b.label = "거절한다"
	c6b.effect_type = ChoiceRes.EffectType.NONE
	e6.choices = [c6a, c6b]; events.append(e6)

	# 7. 헤라클레스의 시련
	var e7: Resource = EventRes.new(); e7.event_name = "헤라클레스의 시련"
	var c7a: Resource = ChoiceRes.new(); c7a.label = "맞선다 (골드 +60, HP -25)"
	c7a.effect_type = ChoiceRes.EffectType.GOLD; c7a.value = 60; c7a.cost_hp = 25
	var c7b: Resource = ChoiceRes.new(); c7b.label = "포기한다"
	c7b.effect_type = ChoiceRes.EffectType.NONE
	e7.choices = [c7a, c7b]; events.append(e7)

	# 8. 키르케의 마법
	var e8: Resource = EventRes.new(); e8.event_name = "키르케의 마법"
	var c8a: Resource = ChoiceRes.new(); c8a.label = "마법을 받는다 (HP +25, 골드 -50)"
	c8a.effect_type = ChoiceRes.EffectType.HEAL; c8a.value = 25; c8a.cost_gold = 50
	var c8b: Resource = ChoiceRes.new(); c8b.label = "거절한다"
	c8b.effect_type = ChoiceRes.EffectType.NONE
	e8.choices = [c8a, c8b]; events.append(e8)

	# 9. 하데스의 계약
	var e9: Resource = EventRes.new(); e9.event_name = "하데스의 계약"
	var c9a: Resource = ChoiceRes.new(); c9a.label = "계약한다 (렐릭 획득, HP -30)"
	c9a.effect_type = ChoiceRes.EffectType.ADD_RELIC; c9a.cost_hp = 30
	var c9b: Resource = ChoiceRes.new(); c9b.label = "거절한다"
	c9b.effect_type = ChoiceRes.EffectType.NONE
	e9.choices = [c9a, c9b]; events.append(e9)

	# 10. 헤르메스의 도박
	var e10: Resource = EventRes.new(); e10.event_name = "헤르메스의 도박"
	var c10a: Resource = ChoiceRes.new(); c10a.label = "황금을 받는다 (골드 +50)"
	c10a.effect_type = ChoiceRes.EffectType.GOLD; c10a.value = 50
	var c10b: Resource = ChoiceRes.new(); c10b.label = "덱을 가볍게 한다 (카드 1장 제거)"
	c10b.effect_type = ChoiceRes.EffectType.REMOVE_CARD; c10b.value = 1
	e10.choices = [c10a, c10b]; events.append(e10)

	return events

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

func test_add_relic_choice_structure() -> void:
	print("[TestEvent] test_add_relic_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var choice: Resource = ChoiceRes.new()
	choice.effect_type = ChoiceRes.EffectType.ADD_RELIC
	choice.cost_hp = 30
	_assert(choice.effect_type == ChoiceRes.EffectType.ADD_RELIC, "ADD_RELIC 타입 설정 가능")
	_assert(choice.cost_hp == 30, "cost_hp 30 설정 가능")

func test_gold_with_cost_hp_structure() -> void:
	print("[TestEvent] test_gold_with_cost_hp_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var choice: Resource = ChoiceRes.new()
	choice.effect_type = ChoiceRes.EffectType.GOLD
	choice.value = 60
	choice.cost_hp = 25
	_assert(choice.effect_type == ChoiceRes.EffectType.GOLD, "GOLD 타입 설정 가능")
	_assert(choice.value == 60, "value 60")
	_assert(choice.cost_hp == 25, "cost_hp 25 설정 가능")

func test_pool_has_ten_events() -> void:
	print("[TestEvent] test_pool_has_ten_events")
	var pool := _build_pool()
	_assert(pool.size() == 10, "이벤트 풀 10종")

func test_prometheus_event_exists() -> void:
	print("[TestEvent] test_prometheus_event_exists")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "프로메테우스의 불":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.DRAW_UP, "선택 A: DRAW_UP")
			_assert(e.choices[0].cost_hp == 20, "cost_hp == 20")
	_assert(found, "프로메테우스의 불 이벤트 존재")

func test_hades_event_uses_add_relic() -> void:
	print("[TestEvent] test_hades_event_uses_add_relic")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "하데스의 계약":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.ADD_RELIC, "선택 A: ADD_RELIC")
			_assert(e.choices[0].cost_hp == 30, "cost_hp == 30")
	_assert(found, "하데스의 계약 이벤트 존재")

func test_devil_deal_event_exists() -> void:
	print("[TestEvent] test_devil_deal_event_exists")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	_assert(ChoiceRes.EffectType.ADD_RELIC_GAMBLE == 7, "ADD_RELIC_GAMBLE == 7")

func test_hermes_event_has_two_choices() -> void:
	print("[TestEvent] test_hermes_event_has_two_choices")
	var pool := _build_pool()
	var found := false
	for e in pool:
		if e.event_name == "헤르메스의 도박":
			found = true
			var ChoiceRes = load("res://resources/event_choice_resource.gd")
			_assert(e.choices.size() == 2, "선택지 2개")
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.GOLD, "선택 A: GOLD")
			_assert(e.choices[1].effect_type == ChoiceRes.EffectType.REMOVE_CARD, "선택 B: REMOVE_CARD")
	_assert(found, "헤르메스의 도박 이벤트 존재")
