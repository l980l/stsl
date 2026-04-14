# tests/test_map_generator.gd
class_name TestMapGenerator
extends RefCounted

const MapGen = preload("res://autoload/map_generator.gd")
const MapNodeRes = preload("res://resources/map_node_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_node_count()
	test_boss_node()
	test_connections_valid()
	test_floor0_nodes()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func test_node_count() -> void:
	print("[TestMapGenerator] test_node_count")
	var map := MapGen.generate()
	_assert(map.size() == 28, "노드 수 == 28 (floor 0~8 × 3 + 보스 1)")

func test_boss_node() -> void:
	print("[TestMapGenerator] test_boss_node")
	var map := MapGen.generate()
	_assert(map.size() == 28, "보스 테스트를 위해 노드 수 확인")
	if map.size() < 28:
		return
	var boss = map[27]
	_assert(boss.room_type == MapNodeRes.RoomType.BOSS, "ID 27 = BOSS 타입")
	_assert(boss.floor_num == 9, "보스 층 == 9")
	_assert(boss.connections.is_empty(), "보스는 연결 없음")

func test_connections_valid() -> void:
	print("[TestMapGenerator] test_connections_valid")
	var map := MapGen.generate()
	if map.size() < 28:
		_assert(false, "노드 부족으로 건너뜀")
		return
	for node in map:
		for conn_id in node.connections:
			_assert(conn_id >= 0 and conn_id < map.size(),
				"연결 ID %d 범위 유효" % conn_id)
			_assert(map[conn_id].floor_num == node.floor_num + 1,
				"연결 노드는 다음 층")

func test_floor0_nodes() -> void:
	print("[TestMapGenerator] test_floor0_nodes")
	var map := MapGen.generate()
	if map.size() < 3:
		_assert(false, "노드 부족")
		return
	_assert(map[0].floor_num == 0 and map[0].column == 0, "ID 0: floor 0, col 0")
	_assert(map[1].floor_num == 0 and map[1].column == 1, "ID 1: floor 0, col 1")
	_assert(map[2].floor_num == 0 and map[2].column == 2, "ID 2: floor 0, col 2")
	_assert(not map[0].connections.is_empty(), "floor 0 노드에 연결 있음")
