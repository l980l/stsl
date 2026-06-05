# autoload/progress_manager.gd
class_name ProgressManagerClass
extends Node

signal hero_unlocked(hero_id: String)

const PROGRESS_PATH := "user://progress.json"
const _DEFAULT_HEROES := ["napoleon", "cleopatra", "yi_sun_sin"]

var chapters_cleared: Array = []
var unlocked_heroes: Array = []
var unlock_flags: Dictionary = {}
var run_count: int = 0  # 누적 런(각성) 횟수 — 스토리 변주("전에도 왔다")용. 영구 저장.

func _ready() -> void:
	load_progress()

func reset_progress() -> void:
	chapters_cleared.clear()
	unlocked_heroes = _DEFAULT_HEROES.duplicate()
	unlock_flags.clear()
	run_count = 0

# 런 시작 시 1회 호출 — 스토리 각성 라인 변주 기준.
func increment_run_count() -> void:
	run_count += 1
	save_progress()

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

func increment_flag(flag_key: String, amount: int = 1) -> int:
	var cur = unlock_flags.get(flag_key, 0)
	if typeof(cur) != TYPE_INT:
		cur = 0
	cur += amount
	unlock_flags[flag_key] = cur
	save_progress()
	return cur

func get_flag_int(flag_key: String) -> int:
	var v = unlock_flags.get(flag_key, 0)
	return v if typeof(v) == TYPE_INT else 0

func check_unlock_conditions() -> Array:
	var newly: Array = []
	var HR = load("res://resources/heroes/hero_registry.gd")
	for hid in HR.all_hero_ids():
		if is_hero_unlocked(hid):
			continue
		var hero = HR.make_hero(hid)
		if _evaluate_condition(hero.unlock_condition):
			unlock_hero(hid)
			newly.append(hid)
			hero_unlocked.emit(hid)
	return newly

func _evaluate_condition(cond: String) -> bool:
	if cond == "default" or cond == "":
		return true
	if cond == "clear_chapter_1":
		return 1 in chapters_cleared
	if cond == "clear_chapter_2":
		return 2 in chapters_cleared
	if cond.begins_with("flag:"):
		return has_flag(cond.substr(5))
	if ">=" in cond:
		var parts := cond.split(">=")
		if parts.size() == 2:
			return get_flag_int(parts[0]) >= int(parts[1])
	return false

func to_dict() -> Dictionary:
	return {
		"version": 1,
		"chapters_cleared": chapters_cleared.duplicate(),
		"unlocked_heroes": unlocked_heroes.duplicate(),
		"unlock_flags": unlock_flags.duplicate(),
		"run_count": run_count,
	}

func from_dict(data: Dictionary) -> void:
	chapters_cleared = data.get("chapters_cleared", []).duplicate()
	var heroes = data.get("unlocked_heroes", [])
	if heroes.is_empty():
		heroes = _DEFAULT_HEROES.duplicate()
	unlocked_heroes = heroes.duplicate()
	unlock_flags = data.get("unlock_flags", {}).duplicate()
	run_count = int(data.get("run_count", 0))

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
