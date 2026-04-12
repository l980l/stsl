# autoload/game_manager.gd
class_name GameManagerClass
extends Node

enum GameState { MAP, BATTLE, CARD_PICK, EVENT, SHOP, REST }

var current_state: GameState = GameState.MAP
var current_floor: int = 0
var current_chapter: int = 1
var gold: int = 0
var relics: Array = []

signal state_changed(new_state: GameState)
signal gold_changed(new_gold: int)
signal relic_added(relic: Resource)

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	gold_changed.emit(gold)
	return true

func add_relic(relic: Resource) -> void:
	relics.append(relic)
	relic_added.emit(relic)

func has_relic(relic_name: String) -> bool:
	for r in relics:
		if r.relic_name == relic_name:
			return true
	return false

func reset() -> void:
	current_state = GameState.MAP
	current_floor = 0
	current_chapter = 1
	gold = 0
	relics.clear()
