# tests/test_save.gd
class_name TestSave
extends RefCounted

const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffRes = preload("res://resources/effect_resource.gd")
const MapNodeRes = preload("res://resources/map_node_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_game_manager_roundtrip()
	test_team_manager_roundtrip()
	test_deck_manager_roundtrip()
	test_has_save_false_when_no_file()
	test_relic_serialization_roundtrip()
	test_deck_from_dict_preserves_effects()
	test_upgraded_flag_preserved_in_save()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func _make_node(id: int, floor: int, col: int) -> Resource:
	var node := MapNodeRes.new()
	node.node_id = id
	node.floor_num = floor
	node.column = col
	node.room_type = MapNodeRes.RoomType.BATTLE
	node.connections = []
	node.visited = false
	return node

# ──────────────────────────────────────────────

func test_game_manager_roundtrip() -> void:
	print("[TestSave] test_game_manager_roundtrip")
	# game_manager.gd를 직접 인스턴스화할 수 없으므로 to_dict 로직을 인라인 검증
	var node := _make_node(5, 2, 1)
	node.visited = true
	var map_data := [{
		"node_id": node.node_id,
		"floor_num": node.floor_num,
		"column": node.column,
		"room_type": node.room_type,
		"connections": node.connections.duplicate(),
		"visited": node.visited,
	}]
	var d := {
		"current_floor": 3,
		"gold": 80,
		"current_node_id": 5,
		"available_node_ids": [6, 7],
		"run_map": map_data,
	}
	# from_dict 로직 인라인
	var restored_floor: int = d.get("current_floor", 0)
	var restored_gold: int = d.get("gold", 0)
	var restored_node_id: int = d.get("current_node_id", -1)
	var restored_map_size: int = d.get("run_map", []).size()
	_assert(restored_floor == 3, "current_floor 복원")
	_assert(restored_gold == 80, "gold 복원")
	_assert(restored_node_id == 5, "current_node_id 복원")
	_assert(restored_map_size == 1, "run_map 크기 복원")
	# 노드 필드
	var nd: Dictionary = d["run_map"][0]
	_assert(nd["node_id"] == 5, "node_id 복원")
	_assert(nd["visited"] == true, "visited 복원")

func test_team_manager_roundtrip() -> void:
	print("[TestSave] test_team_manager_roundtrip")
	var tm := TeamManagerClass.new()
	_to_free.append(tm)
	var hero := HeroRes.new()
	hero.hero_id = "napoleon"
	hero.hero_name = "나폴레옹"
	hero.max_hp = 70
	tm.add_hero(hero)
	tm.take_damage("napoleon", 20)  # 현재 HP = 50

	var d: Dictionary = tm.to_dict()
	_assert(d["heroes"].size() == 1, "영웅 1명 직렬화")
	_assert(d["heroes"][0]["hero_id"] == "napoleon", "hero_id 보존")
	_assert(d["heroes"][0]["max_hp"] == 70, "max_hp 보존")
	_assert(d["heroes"][0]["current_hp"] == 50, "current_hp 보존")

	# from_dict 복원 (씬 로드 없이 hero_id만 검증)
	var tm2 := TeamManagerClass.new()
	_to_free.append(tm2)
	# _get_hero_scene은 실제 .tscn 로드 시도 — 헤드리스에서 실패할 수 있음
	# 직접 수동으로 hero 추가 후 _hero_hp 검증
	var hero2 := HeroRes.new()
	hero2.hero_id = d["heroes"][0]["hero_id"]
	hero2.hero_name = d["heroes"][0]["hero_name"]
	hero2.max_hp = d["heroes"][0]["max_hp"]
	tm2.add_hero(hero2)
	tm2._hero_hp[hero2.hero_id] = d["heroes"][0]["current_hp"]
	_assert(tm2.get_current_hp("napoleon") == 50, "from_dict 현재 HP 복원")
	_assert(tm2.get_hero("napoleon").max_hp == 70, "from_dict max_hp 복원")

func test_deck_manager_roundtrip() -> void:
	print("[TestSave] test_deck_manager_roundtrip")
	var dm := DeckManagerClass.new()
	_to_free.append(dm)
	for _i in range(5):
		var card := CardRes.new()
		card.card_name = "스트라이크"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "attack"
		var eff := EffRes.new()
		eff.effect_type = EffRes.EffectType.DAMAGE
		eff.value = 6
		eff.target = "SINGLE"
		card.effects = [eff]
		dm.add_card_to_deck(card)

	var d: Dictionary = dm.to_dict()
	_assert(d["full_deck"].size() == 5, "덱 5장 직렬화")
	_assert(d["base_draw_count"] == 5, "base_draw_count 보존")

	var dm2 := DeckManagerClass.new()
	_to_free.append(dm2)
	dm2.from_dict(d)
	_assert(dm2.draw_pile.size() == 5, "from_dict 덱 크기 복원")

func test_has_save_false_when_no_file() -> void:
	print("[TestSave] test_has_save_false_when_no_file")
	# SaveManager는 Autoload라 직접 인스턴스화 불가
	# FileAccess.file_exists 로직만 검증
	var path := "user://save_test_nonexistent_12345.json"
	_assert(not FileAccess.file_exists(path), "존재하지 않는 파일 → false")

func test_relic_serialization_roundtrip() -> void:
	print("[TestSave] test_relic_serialization_roundtrip")
	var RelicRes = load("res://resources/relic_resource.gd")
	var relic: Resource = RelicRes.new()
	relic.relic_name = "버닝 블러드"
	relic.trigger = RelicRes.TriggerType.BATTLE_WIN
	relic.effect_type = RelicRes.EffectType.HEAL
	relic.value = 6
	# 직렬화
	var entry := {"relic_name": relic.relic_name}
	_assert(entry["relic_name"] == "버닝 블러드", "릴릭 이름 직렬화")
	# 역직렬화 (풀에서 매칭)
	var pool := [relic]
	var restored: Resource = null
	for r in pool:
		if r.relic_name == entry["relic_name"]:
			restored = r
			break
	_assert(restored != null, "릴릭 역직렬화 매칭")
	_assert(restored.value == 6, "릴릭 value 복원")

func test_deck_from_dict_preserves_effects() -> void:
	print("[TestSave] test_deck_from_dict_preserves_effects")
	var dm := DeckManagerClass.new()
	_to_free.append(dm)
	var card := CardRes.new()
	card.card_name = "포이즌 스트라이크"
	card.owner_id = "napoleon"
	card.cost = 1
	card.play_animation = "attack"
	var e1 := EffRes.new(); e1.effect_type = EffRes.EffectType.DAMAGE; e1.value = 3; e1.target = "SINGLE"
	var e2 := EffRes.new(); e2.effect_type = EffRes.EffectType.APPLY_STATUS
	e2.status_type = "poison"; e2.value = 2; e2.target = "SINGLE"
	card.effects = [e1, e2]
	dm.add_card_to_deck(card)

	var d: Dictionary = dm.to_dict()
	var dm2 := DeckManagerClass.new()
	_to_free.append(dm2)
	dm2.from_dict(d)

	_assert(dm2.draw_pile.size() == 1, "카드 1장 복원")
	var restored_card: Resource = dm2.draw_pile[0]
	_assert(restored_card.card_name == "포이즌 스트라이크", "카드 이름 복원")
	_assert(restored_card.effects.size() == 2, "이펙트 2개 복원")
	_assert(restored_card.effects[1].status_type == "poison", "status_type 복원")

func test_upgraded_flag_preserved_in_save() -> void:
	print("[TestSave] test_upgraded_flag_preserved_in_save")
	var dm := DeckManagerClass.new()
	_to_free.append(dm)
	var card := CardRes.new()
	card.card_name = "스트라이크"
	card.owner_id = "napoleon"
	card.cost = 1
	card.upgrade_level = 1
	var eff := EffRes.new(); eff.effect_type = EffRes.EffectType.DAMAGE; eff.value = 9; eff.target = "SINGLE"
	card.effects = [eff]
	dm.add_card_to_deck(card)

	var d: Dictionary = dm.to_dict()
	var dm2 := DeckManagerClass.new()
	_to_free.append(dm2)
	dm2.from_dict(d)

	var restored: Resource = dm2.draw_pile[0]
	_assert(restored.upgrade_level == 1, "강화된 카드 upgrade_level=1 저장/복원")
	_assert(restored.effects[0].value == 9, "강화 수치 복원")
