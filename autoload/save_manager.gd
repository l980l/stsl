# autoload/save_manager.gd
class_name SaveManagerClass
extends Node

const SAVE_PATH := "user://save.json"
const CombatScale = preload("res://resources/balance/combat_scale.gd")

# Keep the container version stable: this is a units migration inside the
# established v2 format.  A legacy v2 file has no combat_unit_version.
const COMBAT_UNIT_VERSION := 2

func save() -> void:
	# autoload는 Engine 싱글톤이 아니라 /root 아래 노드 — get_node_or_null로 접근
	var _gm = get_node_or_null("/root/GameManager")
	var _tm = get_node_or_null("/root/TeamManager")
	var _dm = get_node_or_null("/root/DeckManager")
	if _gm == null or _tm == null or _dm == null:
		return
	# Practice battles must never overwrite the player's resumable run.
	if _gm.tutorial_lesson_id != "":
		return
	var data := {
		"version": 2,
		"combat_unit_version": COMBAT_UNIT_VERSION if CombatScale.enabled() else 1,
		"game_manager": _gm.to_dict(),
		"team_manager": _tm.to_dict(),
		"deck_manager": _dm.to_dict(),
		"relics": _serialize_relics(_gm),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var text := file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null or not data.has("version"):
		return false
	if int(data["version"]) != 2:
		push_warning("[SaveManager] 세이브 버전 %s 미지원 — 원본을 보존합니다." % data["version"])
		return false
	# A file written by a newer combat-unit migration must not be interpreted
	# with older rules or removed. This branch deliberately fails closed.
	if int(data.get("combat_unit_version", 1)) > COMBAT_UNIT_VERSION:
		push_warning("[SaveManager] 전투 단위 버전 %s 미지원 — 원본을 보존합니다." % data["combat_unit_version"])
		return false
	data = prepare_for_load(data)
	var _gm = get_node_or_null("/root/GameManager")
	var _tm = get_node_or_null("/root/TeamManager")
	var _dm = get_node_or_null("/root/DeckManager")
	if _gm == null or _tm == null or _dm == null:
		return false
	_gm.from_dict(data["game_manager"])
	_tm.from_dict(data["team_manager"])
	_dm.from_dict(data["deck_manager"])
	_deserialize_relics(_gm, data.get("relics", []))
	return true

# Load-time only conversion for historical v2 saves.  The source file is left
# untouched; the next normal save writes the explicit small-unit marker.  This
# keeps a failed/aborted load from destructively rewriting user data.
static func prepare_for_load(data: Dictionary) -> Dictionary:
	var prepared: Dictionary = data.duplicate(true)
	if not CombatScale.enabled() or int(prepared.get("combat_unit_version", 1)) >= COMBAT_UNIT_VERSION:
		return prepared
	var team_data: Dictionary = prepared.get("team_manager", {})
	for hero_data in team_data.get("heroes", []):
		if not (hero_data is Dictionary):
			continue
		hero_data["max_hp"] = CombatScale.amount(int(hero_data.get("max_hp", 0)))
		hero_data["current_hp"] = CombatScale.amount(int(hero_data.get("current_hp", 0)))
	prepared["team_manager"] = team_data
	prepared["combat_unit_version"] = COMBAT_UNIT_VERSION
	return prepared

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(
			ProjectSettings.globalize_path(SAVE_PATH))

func _serialize_relics(_gm: Object) -> Array:
	var result := []
	for relic in _gm.relics:
		result.append({"relic_name": relic.relic_name})
	return result

func _deserialize_relics(_gm: Object, data: Array) -> void:
	_gm.relics.clear()
	var pool: Array = _gm._build_relic_pool()
	var RelicData = load("res://resources/relics/relics.gd")
	for entry in data:
		var rname: String = entry["relic_name"]
		# 성스러운 두루마리는 이벤트 전용이라 build_pool에 없음 — 팩토리로 복원
		if rname.begins_with("relic.sacred_scroll_"):
			var n: int = rname.trim_prefix("relic.sacred_scroll_").trim_suffix(".name").to_int()
			if n >= 1 and n <= 3:
				_gm.relics.append(RelicData._make_sacred_scroll(n))
			continue
		for r in pool:
			if r.relic_name == rname:
				_gm.relics.append(r)
				break
