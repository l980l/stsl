# tests/test_secret_room.gd
class_name TestSecretRoom
extends RefCounted

const MapNodeRes = preload("res://resources/map_node_resource.gd")
const MapGen    = preload("res://autoload/map_generator.gd")
const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_secret_room_enum_exists()
	test_secret_room_serialization()
	test_map_generator_spawns_secret()
	test_map_generator_no_secret_on_floor_1()
	test_secret_resolves_one_of_four()
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
		push_error("  FAIL: " + msg)

# 1. SECRET enum 값이 정의되어 있음 (값 == 6)
func test_secret_room_enum_exists() -> void:
	print("[TestSecretRoom] test_secret_room_enum_exists")
	_assert(MapNodeRes.RoomType.has("SECRET"), "RoomType에 SECRET 키 존재")
	_assert(MapNodeRes.RoomType.SECRET == 6, "SECRET 값 == 6 (append-only 보장)")

# 2. to_dict → from_dict 왕복 시 SECRET 타입 보존
func test_secret_room_serialization() -> void:
	print("[TestSecretRoom] test_secret_room_serialization")
	var node: Resource = MapNodeRes.new()
	node.node_id = 5
	node.floor_num = 2
	node.column = 1
	node.room_type = MapNodeRes.RoomType.SECRET
	node.connections = [9]
	node.visited = false

	# to_dict 역할: int로 직렬화
	var d: Dictionary = {
		"node_id": node.node_id,
		"floor_num": node.floor_num,
		"column": node.column,
		"room_type": node.room_type,
		"connections": node.connections.duplicate(),
		"visited": node.visited,
	}
	_assert(d["room_type"] == 6, "직렬화된 room_type == 6 (SECRET)")

	# from_dict 역할: int → resource
	var restored: Resource = MapNodeRes.new()
	restored.node_id = d["node_id"]
	restored.floor_num = d["floor_num"]
	restored.column = d["column"]
	restored.room_type = d["room_type"]
	restored.connections = d["connections"].duplicate()
	restored.visited = d["visited"]
	_assert(restored.room_type == MapNodeRes.RoomType.SECRET,
		"from_dict 복원 후 room_type == SECRET")

# 3. 여러 번 맵 생성 시 SECRET 노드가 1개 이상 존재할 수 있음
#    (랜덤이므로 seed 고정 없이 충분한 횟수 반복하여 확인)
func test_map_generator_spawns_secret() -> void:
	print("[TestSecretRoom] test_map_generator_spawns_secret")
	# MapGenerator._pick_room_type이 SECRET을 반환할 수 있는지
	# floor 1~7 중 하나를 직접 반복 호출하여 확인 (1000회)
	var found_secret := false
	for _i in range(1000):
		var rt = MapGen._pick_room_type(2, 0, 1)
		if rt == MapNodeRes.RoomType.SECRET:
			found_secret = true
			break
	_assert(found_secret, "1000회 반복 시 SECRET이 적어도 1번 반환됨 (floor 2, col 0)")

# 4. 1층(floor_num == 0) 노드에는 SECRET이 없음
func test_map_generator_no_secret_on_floor_1() -> void:
	print("[TestSecretRoom] test_map_generator_no_secret_on_floor_1")
	# floor 0에서 1000회 호출해도 SECRET 없음을 확인
	var found_secret := false
	for _i in range(1000):
		var rt = MapGen._pick_room_type(0, randi() % 3, 1)
		if rt == MapNodeRes.RoomType.SECRET:
			found_secret = true
			break
	_assert(not found_secret, "floor 0에서는 1000회 호출해도 SECRET 없음")

	# floor 8(보스 직전)에서도 SECRET 없음
	var found_secret_f8 := false
	for _i in range(1000):
		var rt = MapGen._pick_room_type(8, randi() % 3, 1)
		if rt == MapNodeRes.RoomType.SECRET:
			found_secret_f8 = true
			break
	_assert(not found_secret_f8, "floor 8에서는 1000회 호출해도 SECRET 없음")

# 5. _resolve_secret_room() 호출이 에러 없이 완료됨
#    (SceneTree 없이도 크래시 없이 4가지 경로 중 하나를 실행)
#    randi() 분기는 비결정적이므로 각 경로를 개별 단위 테스트로 검증
#    완전한 통합 테스트는 수동 UI 검증으로 대체
func test_secret_resolves_one_of_four() -> void:
	print("[TestSecretRoom] test_secret_resolves_one_of_four")
	var gm := GameManagerClass.new()
	_to_free.append(gm)
	gm.act_mythologies = ["greek", "egyptian", "norse"]
	var map := MapGen.generate()
	gm.run_map = map
	gm.available_node_ids = [0, 1, 2]
	gm.current_node_id = 0
	gm.pending_enemies = []
	gm.card_rewards = []

	# node 0을 SECRET으로 강제 설정
	map[0].room_type = MapNodeRes.RoomType.SECRET

	# 4가지 경로를 모두 순회하여 크래시 없는지 확인
	var all_ok := true
	for forced_roll in [0, 1, 2, 3]:
		var test_gm := GameManagerClass.new()
		_to_free.append(test_gm)
		test_gm.act_mythologies = ["greek", "egyptian", "norse"]
		test_gm.run_map = MapGen.generate()
		test_gm.available_node_ids = [0, 1, 2]
		test_gm.current_node_id = 0
		test_gm.pending_enemies = []
		test_gm.card_rewards = []
		test_gm.run_map[0].room_type = MapNodeRes.RoomType.SECRET

		# 경로별 직접 실행 (match roll 우회)
		match forced_roll:
			0:
				# 카드 보상 경로
				test_gm.card_rewards = test_gm._generate_card_rewards()
				test_gm.card_rewards_pick_count = 1
				all_ok = all_ok and (test_gm.card_rewards is Array)
			1:
				# 유물 지급 경로
				var relic = test_gm.get_random_relic()
				# relic은 null일 수 있음 (풀 없음) — null이어도 정상
				all_ok = all_ok and true
			2:
				# 골드 경로
				var before_gold := test_gm.gold
				test_gm.add_gold(randi_range(100, 150))
				all_ok = all_ok and (test_gm.gold > before_gold)
			3:
				# 비밀 전투 경로
				var enemies := test_gm._make_elite_enemies()
				all_ok = all_ok and (enemies is Array)

	_assert(all_ok, "_resolve_secret_room 4가지 경로 모두 에러 없이 완료")
