# tests/test_deck_manager.gd
class_name TestDeckManager
extends RefCounted

var CardResource = preload("res://resources/card_resource.gd")
var DeckManagerClass = preload("res://autoload/deck_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_draw_cards()
	test_energy_cost()
	test_reshuffle_on_empty()
	test_discard_hand()
	test_remove_from_deck()
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
	return card

func test_draw_cards() -> void:
	print("[TestDeckManager] test_draw_cards")
	var dm = DeckManagerClass.new()
	for i in range(10):
		dm.draw_pile.append(_make_card("card_%d" % i))
	dm.draw_cards(5)
	_assert(dm.hand.size() == 5, "5장 드로우 후 손패 5장")
	_assert(dm.draw_pile.size() == 5, "드로우 후 드로우 파일 5장")

func test_energy_cost() -> void:
	print("[TestDeckManager] test_energy_cost")
	var dm = DeckManagerClass.new()
	dm.current_energy = 3
	var card = _make_card("attack", 2)
	dm.hand.append(card)
	var result = dm.play_card(card)
	_assert(result == true, "에너지 충분 시 카드 사용 성공")
	_assert(dm.current_energy == 1, "2 비용 카드 후 에너지 == 1")
	_assert(dm.hand.size() == 0, "플레이 후 손패에서 제거됨")
	_assert(dm.discard_pile.size() == 1, "플레이 후 버림 더미에 추가됨")

func test_reshuffle_on_empty() -> void:
	print("[TestDeckManager] test_reshuffle_on_empty")
	var dm = DeckManagerClass.new()
	for i in range(3):
		dm.discard_pile.append(_make_card("card_%d" % i))
	dm.draw_cards(5)
	_assert(dm.hand.size() == 3, "버림 더미 3장 → 손패 3장 드로우")
	_assert(dm.discard_pile.size() == 0, "셔플 후 버림 더미 비어있음")

func test_discard_hand() -> void:
	print("[TestDeckManager] test_discard_hand")
	var dm = DeckManagerClass.new()
	for i in range(5):
		dm.hand.append(_make_card("card_%d" % i))
	dm.discard_hand()
	_assert(dm.hand.size() == 0, "턴 종료 후 손패 비어있음")
	_assert(dm.discard_pile.size() == 5, "턴 종료 후 버림 더미 5장")

func test_remove_from_deck() -> void:
	print("[TestDeckManager] test_remove_from_deck")
	var dm = DeckManagerClass.new()
	var card1 = _make_card("strike")
	var card2 = _make_card("defend")
	dm.draw_pile.append(card1)
	dm.discard_pile.append(card2)

	var r1 := dm.remove_from_deck(card1)
	_assert(r1 == true, "draw_pile 카드 제거 성공")
	_assert(dm.draw_pile.size() == 0, "draw_pile에서 제거됨")

	var r2 := dm.remove_from_deck(card2)
	_assert(r2 == true, "discard_pile 카드 제거 성공")
	_assert(dm.discard_pile.size() == 0, "discard_pile에서 제거됨")

	var r3 := dm.remove_from_deck(card1)
	_assert(r3 == false, "없는 카드 제거 시 false 반환")
