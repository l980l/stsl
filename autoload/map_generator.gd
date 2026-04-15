# autoload/map_generator.gd
# NOTE: Autoload에 등록하지 않음 — RefCounted 유틸 클래스
class_name MapGenerator
extends RefCounted

const MapNodeRes = preload("res://resources/map_node_resource.gd")

const FLOORS := 10
const COLS := 3

static func generate() -> Array:  # -> Array[MapNodeResource]
	var nodes: Array = []

	# Floor 0~8: 각 3개 노드 (총 27개)
	for f in range(FLOORS - 1):
		for c in range(COLS):
			var node := MapNodeRes.new()
			node.node_id = f * COLS + c
			node.floor_num = f
			node.column = c
			node.room_type = _pick_room_type(f, c)
			nodes.append(node)

	# Floor 9: 보스 노드 (ID 27)
	var boss := MapNodeRes.new()
	boss.node_id = 27
	boss.floor_num = 9
	boss.column = 1
	boss.room_type = MapNodeRes.RoomType.BOSS
	boss.connections = []
	nodes.append(boss)

	# 연결 생성: floor 0~7 → 다음 floor
	for f in range(FLOORS - 2):  # 0~7
		for c in range(COLS):
			nodes[f * COLS + c].connections = _make_connections(f, c)

	# Floor 8 → 보스 (ID 27)
	for c in range(COLS):
		nodes[8 * COLS + c].connections = [27]

	return nodes

static func _pick_room_type(floor_num: int, col: int) -> MapNodeRes.RoomType:
	if floor_num == 3 and col == 1: return MapNodeRes.RoomType.REST
	if floor_num == 3 and col == 2: return MapNodeRes.RoomType.SHOP
	if floor_num == 4 and col == 1: return MapNodeRes.RoomType.ELITE
	if floor_num == 6 and col == 0: return MapNodeRes.RoomType.ELITE
	if floor_num == 6 and col == 2: return MapNodeRes.RoomType.SHOP
	if floor_num == 7 and col == 1: return MapNodeRes.RoomType.SHOP
	if floor_num == 7 and col == 2: return MapNodeRes.RoomType.REST
	# floor 8 전체 ELITE — 보스 직전 층 난이도 상승 (스펙 의도)
	if floor_num == 8:               return MapNodeRes.RoomType.ELITE
	return MapNodeRes.RoomType.BATTLE

# col 0 → 다음 floor col 0~1
# col 1 → 다음 floor col 0~2
# col 2 → 다음 floor col 1~2
static func _make_connections(floor_num: int, col: int) -> Array:
	var base := (floor_num + 1) * COLS
	match col:
		0: return [base + 0, base + 1]
		1: return [base + 0, base + 1, base + 2]
		2: return [base + 1, base + 2]
		_: return [base + 1]
