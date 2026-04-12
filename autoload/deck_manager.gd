# autoload/deck_manager.gd
class_name DeckManagerClass
extends Node

const HAND_SIZE: int = 5
const MAX_ENERGY: int = 3

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var current_energy: int = 0

signal card_drawn(card: Resource)
signal card_played(card: Resource)
signal hand_changed()
signal energy_changed(new_energy: int)

func start_turn() -> void:
	current_energy = MAX_ENERGY
	energy_changed.emit(current_energy)
	draw_cards(HAND_SIZE)

func draw_cards(count: int) -> void:
	for i in range(count):
		if draw_pile.is_empty():
			_reshuffle()
		if draw_pile.is_empty():
			break
		var card: Resource = draw_pile.pop_back()
		hand.append(card)
		card_drawn.emit(card)
	hand_changed.emit()

func _reshuffle() -> void:
	draw_pile = discard_pile.duplicate()
	draw_pile.shuffle()
	discard_pile.clear()

func can_play(card: Resource) -> bool:
	return hand.has(card) and current_energy >= card.cost

func play_card(card: Resource) -> bool:
	if not can_play(card):
		return false
	current_energy -= card.cost
	energy_changed.emit(current_energy)
	hand.erase(card)
	discard_pile.append(card)
	card_played.emit(card)
	hand_changed.emit()
	return true

func exhaust_card(card: Resource) -> void:
	hand.erase(card)
	exhaust_pile.append(card)
	hand_changed.emit()

func discard_hand() -> void:
	for card in hand:
		discard_pile.append(card)
	hand.clear()
	hand_changed.emit()

func add_card_to_deck(card: Resource) -> void:
	discard_pile.append(card)

func get_full_deck() -> Array:
	var full: Array = []
	full.append_array(draw_pile)
	full.append_array(hand)
	full.append_array(discard_pile)
	return full

func clear() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	current_energy = 0
