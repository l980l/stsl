# autoload/icon_utils.gd
extends Node

const STATUS_DIR := "res://assets/art/ui/status/"
const SYNERGY_DIR := "res://assets/art/ui/synergy/"
const RELIC_DIR := "res://assets/art/ui/relic/"

const STATUS_FILE_ALIAS := {
	"poison_dmg": "poison",
}

var _cache: Dictionary = {}

func get_status_icon(key: String) -> Texture2D:
	var fname: String = STATUS_FILE_ALIAS.get(key, key)
	return _load(STATUS_DIR + fname + ".png")

func get_synergy_icon(name_key: String) -> Texture2D:
	return _load(SYNERGY_DIR + _strip(name_key) + ".png")

func get_relic_icon(name_key: String) -> Texture2D:
	return _load(RELIC_DIR + _strip(name_key) + ".png")

func _strip(key: String) -> String:
	var parts := key.split(".")
	return parts[1] if parts.size() >= 2 else key

func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = tex
	return tex
