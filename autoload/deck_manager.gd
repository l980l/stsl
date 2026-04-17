# autoload/deck_manager.gd
class_name DeckManagerClass
extends Node

var base_draw_count: int = 5
const MAX_ENERGY: int = 3

var draw_pile: Array = []
var hand: Array = []
var discard_pile: Array = []
var exhaust_pile: Array = []
var current_energy: int = 0
var pending_cost_reduction: int = 0

signal card_drawn(card: Resource)
signal card_played(card: Resource)
signal hand_changed()
signal energy_changed(new_energy: int)

func start_turn() -> void:
	current_energy = MAX_ENERGY
	pending_cost_reduction = 0
	energy_changed.emit(current_energy)
	draw_cards(base_draw_count)

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
	var effective_cost: int = max(0, card.cost - pending_cost_reduction)
	return hand.has(card) and current_energy >= effective_cost

func play_card(card: Resource) -> bool:
	if not can_play(card):
		return false
	var effective_cost: int = max(0, card.cost - pending_cost_reduction)
	pending_cost_reduction = 0
	current_energy -= effective_cost
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

func discard_random(n: int) -> void:
	for _i in range(min(n, hand.size())):
		var idx := randi() % hand.size()
		discard_pile.append(hand[idx])
		hand.remove_at(idx)
	hand_changed.emit()

func to_dict() -> Dictionary:
	var full := draw_pile.duplicate()
	full.append_array(discard_pile)
	full.append_array(exhaust_pile)
	# hand는 맵 저장 시점에 비어있음 — 무시
	var card_data := []
	for card in full:
		var effects_data := []
		for eff in card.effects:
			effects_data.append({
				"effect_type": eff.effect_type,
				"value": eff.value,
				"target": eff.target,
				"status_type": eff.status_type,
				"bonus_value": eff.bonus_value,
			})
		card_data.append({
			"card_name": card.card_name,
			"owner_id": card.owner_id,
			"cost": card.cost,
			"play_animation": card.play_animation,
			"upgraded": card.get("upgraded") if card.get("upgraded") != null else false,
			"effects": effects_data,
		})
	return {"base_draw_count": base_draw_count, "full_deck": card_data}

func from_dict(data: Dictionary) -> void:
	clear()
	base_draw_count = data.get("base_draw_count", 5)
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	for cd in data.get("full_deck", []):
		var card: Resource = CardRes.new()
		card.card_name = cd["card_name"]
		card.owner_id = cd["owner_id"]
		card.cost = cd["cost"]
		card.play_animation = cd.get("play_animation", "idle")
		card.upgraded = cd.get("upgraded", false)
		var effects := []
		for ed in cd.get("effects", []):
			var eff: Resource = EffRes.new()
			eff.effect_type = ed["effect_type"]
			eff.value = ed["value"]
			eff.target = ed.get("target", "SINGLE")
			eff.status_type = ed.get("status_type", "")
			eff.bonus_value = ed.get("bonus_value", 0)
			effects.append(eff)
		card.effects = effects
		draw_pile.append(card)
	draw_pile.shuffle()

func remove_from_deck(card: Resource) -> bool:
	if draw_pile.has(card):
		draw_pile.erase(card)
		return true
	if discard_pile.has(card):
		discard_pile.erase(card)
		return true
	return false

func clear() -> void:
	draw_pile.clear()
	hand.clear()
	discard_pile.clear()
	exhaust_pile.clear()
	current_energy = 0
	pending_cost_reduction = 0
