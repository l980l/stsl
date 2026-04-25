# autoload/map_generator.gd
# NOTE: Autoload에 등록하지 않음 — RefCounted 유틸 클래스
class_name MapGenerator
extends RefCounted

const MapNodeRes = preload("res://resources/map_node_resource.gd")

const FLOORS := 15   # 총 15층 (floor 0~14, floor 14 = 보스)
const COLS := 7      # 7열 (col 0~6)
const PATHS := 6     # 동시 진행 경로 수

static func generate(act: int = 1, seed_value: int = -1) -> Array:
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	return _generate_with_rng(act, rng)

static func _generate_with_rng(act: int, rng: RandomNumberGenerator) -> Array:
	# grid[floor][col] = node_id, -1이면 노드 없음
	var grid: Array = []
	for _f in range(FLOORS):
		var row: Array = []
		for _c in range(COLS):
			row.append(-1)
		grid.append(row)

	var nodes: Array = []
	var edges_set: Dictionary = {}   # 교차 검출용: _edge_key(from,to) → true

	# Phase 1: 시작 컬럼 6개 선정 (최소 2 distinct 보장)
	var starts: Array = []
	for _i in range(PATHS):
		starts.append(rng.randi_range(0, COLS - 1))
	while _distinct_count(starts) < 2:
		starts[rng.randi_range(0, PATHS - 1)] = rng.randi_range(0, COLS - 1)

	# Phase 2: 경로 생성 (floor 0 → 13)
	for s in starts:
		var col := int(s)
		_ensure(grid, nodes, 0, col)
		for f in range(FLOORS - 2):  # 0..12 → 연결 대상: 1..13
			var nc := _step(col, f, rng, edges_set, grid)
			_ensure(grid, nodes, f + 1, nc)
			_add_edge(edges_set, nodes, grid[f][col], grid[f + 1][nc])
			col = nc

	# Phase 3: 보스 노드 (floor 14, 중앙 컬럼)
	var boss_col := COLS / 2
	var boss_id := _ensure(grid, nodes, FLOORS - 1, boss_col)
	nodes[boss_id].room_type = MapNodeRes.RoomType.BOSS
	for c in range(COLS):
		if grid[FLOORS - 2][c] != -1:
			_add_edge(edges_set, nodes, grid[FLOORS - 2][c], boss_id)

	# Phase 4: 룸 타입 배정
	_assign_room_types(grid, nodes, rng, act)

	return nodes

# 노드 생성 또는 기존 노드 ID 반환 (node_id == nodes 배열 인덱스 invariant 유지)
static func _ensure(grid: Array, nodes: Array, floor: int, col: int) -> int:
	if grid[floor][col] != -1:
		return grid[floor][col]
	var node := MapNodeRes.new()
	node.node_id = nodes.size()
	node.floor_num = floor
	node.column = col
	nodes.append(node)
	grid[floor][col] = node.node_id
	return node.node_id

# 엣지 추가 (중복 방지, connections/parents 동시 설정)
static func _add_edge(edges_set: Dictionary, nodes: Array, from_id: int, to_id: int) -> void:
	var key := _edge_key(from_id, to_id)
	if edges_set.has(key):
		return
	edges_set[key] = true
	if to_id not in nodes[from_id].connections:
		nodes[from_id].connections.append(to_id)
	if from_id not in nodes[to_id].parents:
		nodes[to_id].parents.append(from_id)

# 다음 컬럼 선택 (교차 금지 적용)
static func _step(col: int, floor: int, rng: RandomNumberGenerator, edges_set: Dictionary, grid: Array) -> int:
	var candidates: Array = []
	for delta: int in [-1, 0, 1]:
		var nc: int = col + delta
		if nc < 0 or nc >= COLS:
			continue
		if delta != 0 and _would_cross(grid, edges_set, floor, col, nc):
			continue
		candidates.append(nc)
	if candidates.is_empty():
		return col  # fallback: 제자리
	return candidates[rng.randi_range(0, candidates.size() - 1)]

# (floor, from_col)→(floor+1, to_col) 엣지가 (floor, to_col)→(floor+1, from_col)와 교차하는지 검사
static func _would_cross(grid: Array, edges_set: Dictionary, floor: int, from_col: int, to_col: int) -> bool:
	var mirror_from: int = grid[floor][to_col]
	var mirror_to: int = grid[floor + 1][from_col]
	if mirror_from == -1 or mirror_to == -1:
		return false
	return edges_set.has(_edge_key(mirror_from, mirror_to))

static func _edge_key(from_id: int, to_id: int) -> int:
	return from_id * 1000 + to_id  # 최대 노드 수 << 1000 이므로 충돌 없음

static func _distinct_count(arr: Array) -> int:
	var seen := {}
	for v in arr:
		seen[v] = true
	return seen.size()

static func _assign_room_types(grid: Array, nodes: Array, rng: RandomNumberGenerator, _act: int) -> void:
	for f in range(FLOORS - 1):  # 0..13 (floor 14 = 보스, Phase 3에서 이미 설정)
		for c in range(COLS):
			var nid: int = grid[f][c]
			if nid == -1:
				continue
			var node: Resource = nodes[nid]
			if f == 0:
				node.room_type = MapNodeRes.RoomType.BATTLE
			elif f == FLOORS - 2:  # floor 13 = 보스 직전 → 항상 휴식
				node.room_type = MapNodeRes.RoomType.REST
			else:
				node.room_type = _weighted_room_type(node, nodes, f, c, grid, rng)

static func _weighted_room_type(node: Resource, nodes: Array, floor: int, col: int, grid: Array, rng: RandomNumberGenerator) -> MapNodeRes.RoomType:
	var weights := {
		MapNodeRes.RoomType.BATTLE: 50,
		MapNodeRes.RoomType.EVENT:  18,
		MapNodeRes.RoomType.ELITE:  14,
		MapNodeRes.RoomType.REST:   10,
		MapNodeRes.RoomType.SHOP:    6,
		MapNodeRes.RoomType.SECRET:  2,
	}

	# 층 기반 제한
	if floor < 5:
		weights[MapNodeRes.RoomType.ELITE] = 0
	if floor < 2:
		weights[MapNodeRes.RoomType.SHOP] = 0
		weights[MapNodeRes.RoomType.REST] = 0

	# 부모가 ELITE/REST/SHOP이면 동일 타입 연속 금지
	var restricted: Array = []
	for parent_id in node.parents:
		var pt: int = nodes[parent_id].room_type
		if pt in [MapNodeRes.RoomType.ELITE, MapNodeRes.RoomType.REST, MapNodeRes.RoomType.SHOP]:
			if pt not in restricted:
				restricted.append(pt)

	# 같은 층 좌측 노드와 동일 타입 금지 (ELITE/REST/SHOP)
	if col > 0 and grid[floor][col - 1] != -1:
		var lt: int = nodes[grid[floor][col - 1]].room_type
		if lt in [MapNodeRes.RoomType.ELITE, MapNodeRes.RoomType.REST, MapNodeRes.RoomType.SHOP]:
			if lt not in restricted:
				restricted.append(lt)

	for rt in restricted:
		weights[rt] = 0

	return _pick_weighted(weights, rng)

static func _pick_weighted(weights: Dictionary, rng: RandomNumberGenerator) -> MapNodeRes.RoomType:
	var total := 0
	for w in weights.values():
		total += w
	if total == 0:
		return MapNodeRes.RoomType.BATTLE
	var roll := rng.randi_range(0, total - 1)
	var cumulative := 0
	for type in weights.keys():
		cumulative += weights[type]
		if roll < cumulative:
			return type
	return MapNodeRes.RoomType.BATTLE
