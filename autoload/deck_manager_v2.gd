# autoload/deck_manager_v2.gd
# 개체별 턴 시스템 프로토타입용 — 영웅별 덱/핸드/discard/exhaust/에너지 분리.
# 기존 DeckManager 와 별개. 영웅 ID 기준 Dictionary 로 관리.
class_name DeckManagerV2Class
extends Node

const MAX_ENERGY: int = 3
const DRAW_PER_TURN: int = 4

# hero_id → {draw: Array, hand: Array, discard: Array, exhaust: Array, energy: int}
var _heroes: Dictionary = {}

signal card_drawn(hero_id: String, card: Resource)
signal card_played(hero_id: String, card: Resource)
signal hand_changed(hero_id: String)
signal energy_changed(hero_id: String, new_energy: int)

func setup(hero_cards: Dictionary) -> void:
	# hero_cards: {hero_id: [CardResource, ...]} — 영웅별 시작 덱
	_heroes.clear()
	for hero_id in hero_cards:
		var cards: Array = (hero_cards[hero_id] as Array).duplicate()
		cards.shuffle()
		_heroes[hero_id] = {
			"draw": cards,
			"hand": [],
			"discard": [],
			"exhaust": [],
			"energy": 0,
		}

func get_hand(hero_id: String) -> Array:
	if not _heroes.has(hero_id):
		return []
	return _heroes[hero_id]["hand"]

func get_energy(hero_id: String) -> int:
	if not _heroes.has(hero_id):
		return 0
	return _heroes[hero_id]["energy"]

func get_draw_size(hero_id: String) -> int:
	return (_heroes[hero_id]["draw"] as Array).size() if _heroes.has(hero_id) else 0

func get_discard_size(hero_id: String) -> int:
	return (_heroes[hero_id]["discard"] as Array).size() if _heroes.has(hero_id) else 0

# 본인 차례 시작 — 에너지 3 충전 (남으면 리셋), 4장 드로우.
func start_hero_turn(hero_id: String) -> void:
	if not _heroes.has(hero_id):
		return
	var entry: Dictionary = _heroes[hero_id]
	entry["energy"] = MAX_ENERGY
	energy_changed.emit(hero_id, entry["energy"])
	_draw_cards(hero_id, DRAW_PER_TURN)

func _draw_cards(hero_id: String, count: int) -> void:
	var entry: Dictionary = _heroes[hero_id]
	for i in range(count):
		if (entry["draw"] as Array).is_empty():
			_reshuffle(hero_id)
		if (entry["draw"] as Array).is_empty():
			break
		var card: Resource = (entry["draw"] as Array).pop_back()
		(entry["hand"] as Array).append(card)
		card_drawn.emit(hero_id, card)
	hand_changed.emit(hero_id)

func _reshuffle(hero_id: String) -> void:
	var entry: Dictionary = _heroes[hero_id]
	entry["draw"] = (entry["discard"] as Array).duplicate()
	(entry["draw"] as Array).shuffle()
	(entry["discard"] as Array).clear()

func can_play(hero_id: String, card: Resource) -> bool:
	if not _heroes.has(hero_id):
		return false
	var entry: Dictionary = _heroes[hero_id]
	return (entry["hand"] as Array).has(card) and entry["energy"] >= card.cost

func play_card(hero_id: String, card: Resource) -> bool:
	if not can_play(hero_id, card):
		return false
	var entry: Dictionary = _heroes[hero_id]
	entry["energy"] -= card.cost
	energy_changed.emit(hero_id, entry["energy"])
	(entry["hand"] as Array).erase(card)
	if card.get("card_type") == 2 or card.get("is_exhaust") == true:
		(entry["exhaust"] as Array).append(card)
	else:
		(entry["discard"] as Array).append(card)
	card_played.emit(hero_id, card)
	hand_changed.emit(hero_id)
	return true

# 본인 차례 종료 — 핸드 모두 discard (retain/ethereal 구분).
func end_hero_turn(hero_id: String) -> void:
	if not _heroes.has(hero_id):
		return
	var entry: Dictionary = _heroes[hero_id]
	var retained: Array = []
	for card in entry["hand"]:
		if card.get("is_retain") == true:
			retained.append(card)
		elif card.get("is_ethereal") == true:
			(entry["exhaust"] as Array).append(card)
		else:
			(entry["discard"] as Array).append(card)
	entry["hand"] = retained
	hand_changed.emit(hero_id)

func clear() -> void:
	_heroes.clear()
