# tests/test_deck_manager.gd
class_name TestDeckManager
extends RefCounted

var CardResource = preload("res://resources/card_resource.gd")
var DeckManagerClass = preload("res://autoload/deck_manager.gd")

const HID := "test_hero"

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_draw_cards()
	test_energy_cost()
	test_reshuffle_on_empty()
	test_discard_hand()
	test_remove_from_deck()
	test_cost_reduction_applies_to_next_card()
	test_cost_reduction_resets_after_one_card()
	test_cost_reduction_cannot_go_below_zero()
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

func _make_card(card_name: String, cost: int = 1) -> Resource:
	var card = CardResource.new()
	card.card_name = card_name
	card.cost = cost
	card.owner_id = HID
	return card

# 영웅 1명 전투 세팅 — 빈 덱으로 시작
func _new_dm() -> Object:
	var dm = DeckManagerClass.new()
	_to_free.append(dm)
	dm.setup_for_battle([HID])
	return dm

func test_draw_cards() -> void:
	print("[TestDeckManager] test_draw_cards")
	var dm = _new_dm()
	for i in range(10):
		dm._heroes[HID]["draw"].append(_make_card("card_%d" % i))
	dm.draw_cards_h(HID, 5)
	_assert(dm.get_hand(HID).size() == 5, "5장 드로우 후 손패 5장")
	_assert(dm.get_draw_size(HID) == 5, "드로우 후 드로우 파일 5장")

func test_energy_cost() -> void:
	print("[TestDeckManager] test_energy_cost")
	var dm = _new_dm()
	dm.set_energy_h(HID, 3)
	var card = _make_card("attack", 2)
	dm._heroes[HID]["hand"].append(card)
	var result = dm.play_card_hero(HID, card)
	_assert(result == true, "에너지 충분 시 카드 사용 성공")
	_assert(dm.get_energy(HID) == 1, "2 비용 카드 후 에너지 == 1")
	_assert(dm.get_hand(HID).size() == 0, "플레이 후 손패에서 제거됨")
	_assert(dm.get_discard_size(HID) == 1, "플레이 후 버림 더미에 추가됨")

func test_reshuffle_on_empty() -> void:
	print("[TestDeckManager] test_reshuffle_on_empty")
	var dm = _new_dm()
	for i in range(3):
		dm._heroes[HID]["discard"].append(_make_card("card_%d" % i))
	dm.draw_cards_h(HID, 5)
	_assert(dm.get_hand(HID).size() == 3, "버림 더미 3장 → 손패 3장 드로우")
	_assert(dm.get_discard_size(HID) == 0, "셔플 후 버림 더미 비어있음")

func test_discard_hand() -> void:
	print("[TestDeckManager] test_discard_hand")
	var dm = _new_dm()
	for i in range(5):
		dm._heroes[HID]["hand"].append(_make_card("card_%d" % i))
	dm.end_hero_turn(HID)
	_assert(dm.get_hand(HID).size() == 0, "턴 종료 후 손패 비어있음")
	_assert(dm.get_discard_size(HID) == 5, "턴 종료 후 버림 더미 5장")

func test_remove_from_deck() -> void:
	print("[TestDeckManager] test_remove_from_deck")
	var dm = _new_dm()
	var card1 = _make_card("strike")
	var card2 = _make_card("defend")
	dm._heroes[HID]["draw"].append(card1)
	dm._heroes[HID]["discard"].append(card2)

	var r1: bool = dm.remove_from_deck(card1)
	_assert(r1 == true, "draw_pile 카드 제거 성공")
	_assert(dm.get_draw_size(HID) == 0, "draw_pile에서 제거됨")

	var r2: bool = dm.remove_from_deck(card2)
	_assert(r2 == true, "discard_pile 카드 제거 성공")
	_assert(dm.get_discard_size(HID) == 0, "discard_pile에서 제거됨")

	var r3: bool = dm.remove_from_deck(card1)
	_assert(r3 == false, "없는 카드 제거 시 false 반환")

func test_cost_reduction_applies_to_next_card() -> void:
	print("[TestDeckManager] test_cost_reduction_applies_to_next_card")
	var dm = _new_dm()
	dm.set_energy_h(HID, 3)
	dm.set_pending_cost_reduction(HID, 1)
	var card = _make_card("test_card", 2)
	dm._heroes[HID]["hand"].append(card)
	_assert(dm.can_play_hero(HID, card), "reduction 1이면 cost 2 카드를 energy 3으로 사용 가능")
	dm.play_card_hero(HID, card)
	_assert(dm.get_energy(HID) == 2, "실제 차감 에너지 = 2-1 = 1 → 남은 energy = 2")

func test_cost_reduction_resets_after_one_card() -> void:
	print("[TestDeckManager] test_cost_reduction_resets_after_one_card")
	var dm = _new_dm()
	dm.set_energy_h(HID, 3)
	dm.set_pending_cost_reduction(HID, 2)
	var card1 = _make_card("c1", 1)
	var card2 = _make_card("c2", 1)
	dm._heroes[HID]["hand"].append(card1)
	dm._heroes[HID]["hand"].append(card2)
	dm.play_card_hero(HID, card1)
	_assert(dm.get_pending_cost_reduction(HID) == 0, "카드 1장 사용 후 pending_cost_reduction 초기화")
	dm.play_card_hero(HID, card2)
	_assert(dm.get_energy(HID) == 2, "두 번째 카드는 reduction 없이 cost 1 차감 → energy 2")

func test_cost_reduction_cannot_go_below_zero() -> void:
	print("[TestDeckManager] test_cost_reduction_cannot_go_below_zero")
	var dm = _new_dm()
	dm.set_energy_h(HID, 3)
	dm.set_pending_cost_reduction(HID, 5)
	var card = _make_card("c", 1)
	dm._heroes[HID]["hand"].append(card)
	_assert(dm.can_play_hero(HID, card), "reduction > cost여도 사용 가능")
	dm.play_card_hero(HID, card)
	_assert(dm.get_energy(HID) == 3, "max(0, 1-5) = 0 차감 → energy 그대로")
