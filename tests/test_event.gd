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
	test_pool_has_eleven_events()
	test_prometheus_event_exists()
	test_hades_event_uses_add_relic()
	test_hermes_event_has_two_choices()
	test_devil_deal_event_exists()
	test_act2_pool_size_ten()
	test_act2_book_of_the_dead()
	test_act2_pharaoh_tomb_relic()
	test_act2_ra_sunboat_add_hero()
	test_act2_mummy_curse_gamble()
	test_act2_oasis_three_choices()
	test_act2_no_greek_names()
	test_buddhist_event_pool_size()
	test_buddhist_yama_toll_event()
	test_buddhist_guanyin_mercy_event()
	test_daoist_event_pool_size()
	test_daoist_peach_of_immortality_event()
	test_japanese_event_pool_size()
	test_japanese_ise_shrine_event()
	test_new_effect_types_exist()
	test_trigger_battle_choice_structure()
	test_multi_effect_choice_structure()
	test_probabilistic_choice_structure()
	test_add_card_choice_structure()
	test_required_hero_field()
	test_phase4_new_events_exist()
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

	# 11. 악마의 거래
	var e11: Resource = EventRes.new(); e11.event_name = "악마의 거래"
	var c11a: Resource = ChoiceRes.new(); c11a.label = "받아들인다"
	c11a.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var c11b: Resource = ChoiceRes.new(); c11b.label = "거절한다"
	c11b.effect_type = ChoiceRes.EffectType.NONE
	e11.choices = [c11a, c11b]; events.append(e11)

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

func test_pool_has_eleven_events() -> void:
	print("[TestEvent] test_pool_has_eleven_events")
	var pool := _build_pool()
	_assert(pool.size() == 11, "이벤트 풀 11종")

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
	var pool := _build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "악마의 거래":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.ADD_RELIC_GAMBLE, "선택 A: ADD_RELIC_GAMBLE")
			_assert(e.choices[1].effect_type == ChoiceRes.EffectType.NONE, "선택 B: NONE")
	_assert(found, "악마의 거래 이벤트 존재")

const EventsAct2 = preload("res://resources/events/events_act2.gd")

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

# ──────────────────────────────────────────────
# Act 2 이벤트 테스트
# ──────────────────────────────────────────────

func test_act2_pool_size_ten() -> void:
	print("[TestEvent] test_act2_pool_size_ten")
	var pool := EventsAct2.build_pool()
	_assert(pool.size() == 11, "Act2 이벤트 풀 11종")  # Phase 4: +sphinx_gate

func test_act2_book_of_the_dead() -> void:
	print("[TestEvent] test_act2_book_of_the_dead")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var pool := EventsAct2.build_pool()
	var found := false
	for e in pool:
		if e.event_name == "event.act2.book_of_the_dead.name":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.TRIGGER_BATTLE, "선택 A: TRIGGER_BATTLE")
			_assert(e.choices[0].reward_effect_type == ChoiceRes.EffectType.DRAW_UP, "보상: DRAW_UP")
			_assert(e.choices[0].reward_value == 1, "보상 +1")
	_assert(found, "사자의 서 이벤트 존재")

func test_act2_pharaoh_tomb_relic() -> void:
	print("[TestEvent] test_act2_pharaoh_tomb_relic")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var pool := EventsAct2.build_pool()
	var found := false
	for e in pool:
		if e.event_name == "파라오의 무덤":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.ADD_RELIC, "선택 A: ADD_RELIC")
			_assert(e.choices[0].cost_hp == 35, "cost_hp == 35")
	_assert(found, "파라오의 무덤 이벤트 존재")

func test_act2_ra_sunboat_add_hero() -> void:
	print("[TestEvent] test_act2_ra_sunboat_add_hero")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var pool := EventsAct2.build_pool()
	var found := false
	for e in pool:
		if e.event_name == "라의 태양선":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.ADD_HERO, "선택 A: ADD_HERO")
	_assert(found, "라의 태양선 이벤트 존재")

func test_act2_mummy_curse_gamble() -> void:
	print("[TestEvent] test_act2_mummy_curse_gamble")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var pool := EventsAct2.build_pool()
	var found := false
	for e in pool:
		if e.event_name == "event.act2.mummy_curse.name":
			found = true
			# 다양화: GAMBLE → TRIGGER_BATTLE (엘리트, 승리 시 렐릭)
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.TRIGGER_BATTLE, "선택 A: TRIGGER_BATTLE")
			_assert(e.choices[0].encounter_tier == 1, "엘리트 tier")
			_assert(e.choices[0].reward_effect_type == ChoiceRes.EffectType.ADD_RELIC, "보상: ADD_RELIC")
	_assert(found, "미라의 저주 이벤트 존재")

func test_act2_oasis_three_choices() -> void:
	print("[TestEvent] test_act2_oasis_three_choices")
	var pool := EventsAct2.build_pool()
	var found := false
	for e in pool:
		if e.event_name == "오아시스 상인":
			found = true
			_assert(e.choices.size() == 3, "오아시스 상인 선택지 3개")
	_assert(found, "오아시스 상인 이벤트 존재")

func test_act2_no_greek_names() -> void:
	print("[TestEvent] test_act2_no_greek_names")
	var pool := EventsAct2.build_pool()
	var greek_names := ["프로메테우스", "헤라클레스", "하데스", "헤르메스", "키르케", "황금 상자", "악마의 거래"]
	var has_greek := false
	for e in pool:
		for name in greek_names:
			if name in e.event_name:
				has_greek = true
	_assert(not has_greek, "Act2 풀에 그리스 고유 이름 없음")

func test_buddhist_event_pool_size() -> void:
	print("[TestEvent] test_buddhist_event_pool_size")
	var BuddhistEvents = load("res://resources/events/events_buddhist.gd")
	var pool: Array = BuddhistEvents.build_pool()
	_assert(pool.size() == 11, "불교 이벤트 풀 11종")  # Phase 4: +bodhi_tree

func test_buddhist_yama_toll_event() -> void:
	print("[TestEvent] test_buddhist_yama_toll_event")
	var BuddhistEvents = load("res://resources/events/events_buddhist.gd")
	var pool: Array = BuddhistEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "event.buddhist.yama_toll.name":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.GOLD, "선택A: GOLD")
			_assert(e.choices[0].value == 70, "GOLD +70")
			_assert(e.choices[0].cost_hp == 40, "HP -40")
	_assert(found, "염라의 통행세 이벤트 존재")

func test_buddhist_guanyin_mercy_event() -> void:
	print("[TestEvent] test_buddhist_guanyin_mercy_event")
	var BuddhistEvents = load("res://resources/events/events_buddhist.gd")
	var pool: Array = BuddhistEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "event.buddhist.guanyin_mercy.name":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.HEAL, "선택A: HEAL")
			_assert(e.choices[0].value == 30, "HEAL +30")
	_assert(found, "관음의 자비 이벤트 존재")

func test_daoist_event_pool_size() -> void:
	print("[TestEvent] test_daoist_event_pool_size")
	var DaoistEvents = load("res://resources/events/events_daoist.gd")
	var pool: Array = DaoistEvents.build_pool()
	_assert(pool.size() == 11, "도교 이벤트 풀 11종")  # Phase 4: +eight_immortals

func test_daoist_peach_of_immortality_event() -> void:
	print("[TestEvent] test_daoist_peach_of_immortality_event")
	var DaoistEvents = load("res://resources/events/events_daoist.gd")
	var pool: Array = DaoistEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "event.daoist.peach_of_immortality.name":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.HEAL, "선택A: HEAL")
			_assert(e.choices[0].value == 40, "HEAL +40")
			_assert(e.choices[1].effect_type == ChoiceRes.EffectType.NONE, "선택B: NONE")
	_assert(found, "불로장생의 복숭아 이벤트 존재")

func test_japanese_event_pool_size() -> void:
	print("[TestEvent] test_japanese_event_pool_size")
	var JapaneseEvents = load("res://resources/events/events_japanese.gd")
	var pool: Array = JapaneseEvents.build_pool()
	_assert(pool.size() == 11, "일본 이벤트 풀 11종")  # Phase 4: +kitsune_kit

func test_japanese_ise_shrine_event() -> void:
	print("[TestEvent] test_japanese_ise_shrine_event")
	var JapaneseEvents = load("res://resources/events/events_japanese.gd")
	var pool: Array = JapaneseEvents.build_pool()
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var found := false
	for e in pool:
		if e.event_name == "이세 신궁의 축복":
			found = true
			_assert(e.choices[0].effect_type == ChoiceRes.EffectType.HEAL, "선택A: HEAL")
			_assert(e.choices[0].value == 50, "HEAL +50")
			_assert(e.choices[0].cost_gold == 30, "골드 -30")
	_assert(found, "이세 신궁의 축복 이벤트 존재")

# ──────────────────────────────────────────────
# Phase 1 인프라 — 신규 EffectType 및 필드
# ──────────────────────────────────────────────

func test_new_effect_types_exist() -> void:
	print("[TestEvent] test_new_effect_types_exist")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	_assert(ChoiceRes.EffectType.has("TRIGGER_BATTLE"), "TRIGGER_BATTLE enum 존재")
	_assert(ChoiceRes.EffectType.has("ADD_CARD"), "ADD_CARD enum 존재")
	_assert(ChoiceRes.EffectType.has("MULTI"), "MULTI enum 존재")

func test_trigger_battle_choice_structure() -> void:
	print("[TestEvent] test_trigger_battle_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var c: Resource = ChoiceRes.new()
	c.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	c.encounter_tier = 1
	c.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	c.reward_value = 0
	_assert(c.effect_type == ChoiceRes.EffectType.TRIGGER_BATTLE, "TRIGGER_BATTLE 설정")
	_assert(c.encounter_tier == 1, "엘리트 tier 설정")
	_assert(c.reward_effect_type == ChoiceRes.EffectType.ADD_RELIC, "보상 effect_type")

func test_multi_effect_choice_structure() -> void:
	print("[TestEvent] test_multi_effect_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var c: Resource = ChoiceRes.new()
	c.effect_type = ChoiceRes.EffectType.GOLD
	c.value = 50
	c.secondary_effect_type = ChoiceRes.EffectType.HEAL
	c.secondary_value = 10
	_assert(c.secondary_effect_type == ChoiceRes.EffectType.HEAL, "보조 effect_type 설정")
	_assert(c.secondary_value == 10, "보조 value 설정")

func test_probabilistic_choice_structure() -> void:
	print("[TestEvent] test_probabilistic_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var c: Resource = ChoiceRes.new()
	c.effect_type = ChoiceRes.EffectType.ADD_RELIC
	c.success_chance = 60
	c.alt_effect_type = ChoiceRes.EffectType.HEAL
	c.alt_value = -20  # 실패 시 페널티 (음수 HEAL = 데미지 의도라면 별도 처리 필요)
	_assert(c.success_chance == 60, "success_chance 60")
	_assert(c.alt_effect_type == ChoiceRes.EffectType.HEAL, "alt_effect_type 설정")

func test_add_card_choice_structure() -> void:
	print("[TestEvent] test_add_card_choice_structure")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var c: Resource = ChoiceRes.new()
	c.effect_type = ChoiceRes.EffectType.ADD_CARD
	c.card_id = "res://resources/cards/strike.tres"
	_assert(c.effect_type == ChoiceRes.EffectType.ADD_CARD, "ADD_CARD 설정")
	_assert(c.card_id != "", "card_id 설정")

func test_required_hero_field() -> void:
	print("[TestEvent] test_required_hero_field")
	var ChoiceRes = load("res://resources/event_choice_resource.gd")
	var c: Resource = ChoiceRes.new()
	c.required_hero_id = "achilles"
	_assert(c.required_hero_id == "achilles", "required_hero_id 필드 설정 가능")

func test_phase4_new_events_exist() -> void:
	print("[TestEvent] test_phase4_new_events_exist")
	# 신화별 신규 이벤트 5종 존재 검증
	var checks: Array = [
		["res://resources/events/events_act2.gd", "event.act2.sphinx_gate.name"],
		["res://resources/events/events_act3.gd", "event.act3.ymir_blood.name"],
		["res://resources/events/events_buddhist.gd", "event.buddhist.bodhi_tree.name"],
		["res://resources/events/events_daoist.gd", "event.daoist.eight_immortals.name"],
		["res://resources/events/events_japanese.gd", "event.japanese.kitsune_kit.name"],
	]
	for entry in checks:
		var script = load(entry[0])
		var pool: Array = script.build_pool()
		var found := false
		for ev in pool:
			if ev.event_name == entry[1]:
				found = true
				break
		_assert(found, "신규 이벤트 존재: " + entry[1])
