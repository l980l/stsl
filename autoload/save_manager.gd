# autoload/save_manager.gd
class_name SaveManagerClass
extends Node

const SAVE_PATH := "user://save.json"

func save() -> void:
	# autoload는 Engine 싱글톤이 아니라 /root 아래 노드 — get_node_or_null로 접근
	var _gm = get_node_or_null("/root/GameManager")
	var _tm = get_node_or_null("/root/TeamManager")
	var _dm = get_node_or_null("/root/DeckManager")
	if _gm == null or _tm == null or _dm == null:
		return
	var data := {
		"version": 2,
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
		push_warning("[SaveManager] 세이브 버전 %s 미지원 — 초기화합니다." % data["version"])
		clear_save()
		return false
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
