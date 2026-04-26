# autoload/icon_utils.gd
extends Node

const STATUS_DIR := "res://assets/art/ui/status/"
const SYNERGY_DIR := "res://assets/art/ui/synergy/"
const RELIC_DIR := "res://assets/art/ui/relic/"
const MAP_DIR := "res://assets/art/ui/map/"
const INTENT_DIR := "res://assets/art/ui/intent/"
const HUD_DIR := "res://assets/art/ui/hud/"

const _ROOM_ICON_FILES := {
	0: "icon_room_battle",
	1: "icon_room_elite",
	2: "icon_room_rest",
	3: "icon_room_shop",
	4: "icon_room_boss",
	5: "icon_room_event",
	6: "icon_room_secret",
}

const STATUS_FILE_ALIAS := {
	"poison_dmg": "poison",
}

var _cache: Dictionary = {}

func get_status_icon(key: String) -> Texture2D:
	var fname: String = STATUS_FILE_ALIAS.get(key, key)
	var svg_path := STATUS_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(STATUS_DIR + fname + ".png")

func get_synergy_icon(name_key: String) -> Texture2D:
	var fname := _strip(name_key)
	var svg_path := SYNERGY_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(SYNERGY_DIR + fname + ".png")

func get_room_icon(room_type: int) -> Texture2D:
	var fname: String = _ROOM_ICON_FILES.get(room_type, "")
	if fname == "":
		return null
	var svg_path := MAP_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(MAP_DIR + fname + ".png")

func get_relic_icon(name_key: String) -> Texture2D:
	var fname := _strip(name_key)
	var svg_path := RELIC_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(RELIC_DIR + fname + ".png")

const _INTENT_ICON_FILES := {
	0: "attack",
	1: "buff",
	2: "debuff",
	3: "power",
	4: "prepare",
}

const _CARD_TYPE_ICON_FILES := {
	0: "attack",
	1: "skill",
	2: "power",
}

func get_intent_icon(action_type: int) -> Texture2D:
	var fname: String = _INTENT_ICON_FILES.get(action_type, "")
	if fname == "":
		return null
	return _load(INTENT_DIR + fname + ".svg")

func get_card_type_icon(card_type: int) -> Texture2D:
	var fname: String = _CARD_TYPE_ICON_FILES.get(card_type, "")
	if fname == "":
		return null
	return _load(INTENT_DIR + fname + ".svg")

func get_energy_icon() -> Texture2D:
	return _load(HUD_DIR + "energy.svg")

func get_counter_icon() -> Texture2D:
	return _load("res://assets/art/ui/clock.svg")

func get_power_icon(base_key: String) -> Texture2D:
	var fname := base_key.replace(".", "_")
	return _load(STATUS_DIR + fname + ".svg")

func _strip(key: String) -> String:
	var parts := key.split(".")
	return parts[1] if parts.size() >= 2 else key

func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = tex
	return tex
