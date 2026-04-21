# autoload/progress_manager.gd
class_name ProgressManagerClass
extends Node

const PROGRESS_PATH := "user://progress.json"
const _DEFAULT_HEROES := ["napoleon", "cleopatra", "yi_sun_sin"]

var chapters_cleared: Array = []
var unlocked_heroes: Array = []
var unlock_flags: Dictionary = {}

func _ready() -> void:
	load_progress()

func reset_progress() -> void:
	chapters_cleared.clear()
	unlocked_heroes = _DEFAULT_HEROES.duplicate()
	unlock_flags.clear()

func mark_chapter_cleared(chapter: int) -> void:
	if chapter not in chapters_cleared:
		chapters_cleared.append(chapter)
	save_progress()

func is_chapter_unlocked(chapter: int) -> bool:
	if chapter <= 1:
		return true
	return (chapter - 1) in chapters_cleared

func is_hero_unlocked(hero_id: String) -> bool:
	return hero_id in unlocked_heroes

func unlock_hero(hero_id: String) -> bool:
	if hero_id in unlocked_heroes:
		return false
	unlocked_heroes.append(hero_id)
	save_progress()
	return true

func set_flag(flag_key: String) -> void:
	unlock_flags[flag_key] = true
	save_progress()

func has_flag(flag_key: String) -> bool:
	return unlock_flags.get(flag_key, false)

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"chapters_cleared": chapters_cleared.duplicate(),
		"unlocked_heroes": unlocked_heroes.duplicate(),
		"unlock_flags": unlock_flags.duplicate(),
	}

func from_dict(data: Dictionary) -> void:
	chapters_cleared = data.get("chapters_cleared", []).duplicate()
	var heroes = data.get("unlocked_heroes", [])
	if heroes.is_empty():
		heroes = _DEFAULT_HEROES.duplicate()
	unlocked_heroes = heroes.duplicate()
	unlock_flags = data.get("unlock_flags", {}).duplicate()

func save_progress() -> void:
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(to_dict()))
		file.close()

func load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		reset_progress()
		return
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if not file:
		reset_progress()
		return
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		reset_progress()
		return
	from_dict(data)

func clear_progress_file() -> void:
	if FileAccess.file_exists(PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PROGRESS_PATH))
	reset_progress()
