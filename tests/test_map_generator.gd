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

const MIN_NODES := 30  # FLOORS=15 확장 후 실측 최소값 ~45 — 여유 두고 30 하한
const MAX_NODES := 100

func test_node_count() -> void:
	print("[TestMapGenerator] test_node_count")
	var map := MapGen.generate()
	_assert(map.size() >= MIN_NODES and map.size() <= MAX_NODES,
		"노드 수 %d ∈ [%d, %d] (FLOORS=15)" % [map.size(), MIN_NODES, MAX_NODES])

func test_boss_node() -> void:
	print("[TestMapGenerator] test_boss_node")
	var map := MapGen.generate()
	_assert(map.size() >= MIN_NODES, "보스 테스트를 위해 노드 수 확인")
	if map.size() < MIN_NODES:
		return
	# 보스는 마지막 노드 (map_generator.gd Phase 3에서 마지막에 추가)
	var boss = map[-1]
	_assert(boss.room_type == MapNodeRes.RoomType.BOSS, "마지막 노드 = BOSS 타입")
	_assert(boss.floor_num == MapGen.FLOORS - 1, "보스 층 == %d" % (MapGen.FLOORS - 1))
	_assert(boss.connections.is_empty(), "보스는 연결 없음")

func test_connections_valid() -> void:
	print("[TestMapGenerator] test_connections_valid")
	var map := MapGen.generate()
	if map.size() < MIN_NODES:
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
	# Phase 1에서 시작 컬럼이 무작위 (distinct >= 2 보장). floor 0 노드들의 ID는 항상
	# 0부터 연속이지만 컬럼은 가변. floor_num 검증만 결정적.
	var floor0_count := 0
	for node in map:
		if node.floor_num == 0:
			floor0_count += 1
			_assert(node.column >= 0 and node.column < MapGen.COLS,
				"floor 0 노드 col %d ∈ [0, %d)" % [node.column, MapGen.COLS])
	_assert(floor0_count >= 2 and floor0_count <= MapGen.PATHS,
		"floor 0 노드 수 %d ∈ [2, %d] (distinct starts)" % [floor0_count, MapGen.PATHS])
	_assert(not map[0].connections.is_empty(), "floor 0 노드에 연결 있음")
