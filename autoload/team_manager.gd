# autoload/team_manager.gd
class_name TeamManagerClass
extends Node

var heroes: Array = []
var _hero_hp: Dictionary = {}
var _hero_alive: Dictionary = {}

signal hero_died(hero_id: String)
signal hero_revived(hero_id: String)

func add_hero(hero: Resource) -> void:
	heroes.append(hero)
	_hero_hp[hero.hero_id] = hero.max_hp
	_hero_alive[hero.hero_id] = true

func take_damage(hero_id: String, amount: int) -> void:
	if not _hero_alive.get(hero_id, false):
		return
	_hero_hp[hero_id] = max(0, _hero_hp[hero_id] - amount)
	if _hero_hp[hero_id] == 0:
		_hero_alive[hero_id] = false
		hero_died.emit(hero_id)

func heal(hero_id: String, amount: int) -> void:
	if not _hero_alive.get(hero_id, false):
		return
	var hero: Resource = get_hero(hero_id)
	if hero == null:
		return
	_hero_hp[hero_id] = min(hero.max_hp, _hero_hp[hero_id] + amount)

func revive(hero_id: String, hp: int) -> void:
	if not _hero_hp.has(hero_id):
		return
	_hero_alive[hero_id] = true
	_hero_hp[hero_id] = hp
	hero_revived.emit(hero_id)

func get_current_hp(hero_id: String) -> int:
	return _hero_hp.get(hero_id, 0)

func is_alive(hero_id: String) -> bool:
	return _hero_alive.get(hero_id, false)

func get_hero(hero_id: String) -> Resource:
	for hero in heroes:
		if hero.hero_id == hero_id:
			return hero
	return null

func get_living_heroes() -> Array:
	var result: Array = []
	for hero in heroes:
		if _hero_alive.get(hero.hero_id, false):
			result.append(hero)
	return result

func increase_max_hp(hero_id: String, amount: int) -> void:
	for hero in heroes:
		if hero.hero_id == hero_id:
			hero.max_hp += amount
			_hero_hp[hero_id] = _hero_hp.get(hero_id, hero.max_hp) + amount
			return

func clear() -> void:
	heroes.clear()
	_hero_hp.clear()
	_hero_alive.clear()
