# autoload/team_manager.gd
class_name TeamManagerClass
extends Node

var heroes: Array = []
var _hero_hp: Dictionary = {}
var _hero_alive: Dictionary = {}

signal hero_died(hero_id: String)
signal hero_revived(hero_id: String)
signal hero_healed(hero_id: String, amount: int)

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
	var prev_hp: int = _hero_hp[hero_id]
	_hero_hp[hero_id] = min(hero.max_hp, _hero_hp[hero_id] + amount)
	var actual: int = _hero_hp[hero_id] - prev_hp
	if actual > 0:
		hero_healed.emit(hero_id, actual)

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

func has_hero(hero_id: String) -> bool:
	return get_hero(hero_id) != null

func get_living_heroes() -> Array:
	var result: Array = []
	for hero in heroes:
		if _hero_alive.get(hero.hero_id, false):
			result.append(hero)
	return result

func to_dict() -> Dictionary:
	var hero_data := []
	for hero in heroes:
		hero_data.append({
			"hero_id": hero.hero_id,
			"hero_name": hero.hero_name,
			"max_hp": hero.max_hp,
			"current_hp": get_current_hp(hero.hero_id),
		})
	return {"heroes": hero_data}

func from_dict(data: Dictionary) -> void:
	clear()
	var HeroRes = load("res://resources/hero_resource.gd")
	for hd in data.get("heroes", []):
		var hero: Resource = HeroRes.new()
		hero.hero_id = hd["hero_id"]
		hero.hero_name = hd["hero_name"]
		hero.max_hp = hd["max_hp"]
		hero.character_scene = _get_hero_scene(hd["hero_id"])
		add_hero(hero)
		_hero_hp[hero.hero_id] = hd["current_hp"]

func _get_hero_scene(hero_id: String) -> PackedScene:
	match hero_id:
		"napoleon": return load("res://characters/heroes/napoleon/napoleon.tscn")
		"cleopatra": return load("res://characters/heroes/cleopatra/cleopatra.tscn")
		"yi_sun_sin": return load("res://characters/heroes/yi_sun_sin/yi_sun_sin.tscn")
	return null

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
