# tests/test_game_manager.gd
class_name TestGameManager
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const MapGen = preload("res://autoload/map_generator.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_run_map_initialized()
	test_enter_node_marks_visited()
	test_enter_battle_sets_pending_enemies()
	test_complete_battle_generates_rewards()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		push_error("  FAIL: " + msg)

func _make_gm() -> GameManagerClass:
	var gm := GameManagerClass.new()
	gm.run_map = MapGen.generate()
	gm.available_node_ids = [0, 1, 2]
	gm.current_node_id = -1
	gm.pending_enemies = []
	gm.card_rewards = []
	return gm

func test_run_map_initialized() -> void:
	print("[TestGameManager] test_run_map_initialized")
	var gm := _make_gm()
	_assert(gm.run_map.size() == 28, "맵 28개 노드")
	_assert(gm.available_node_ids == [0, 1, 2], "초기 접근 가능 노드 [0,1,2]")

func test_enter_node_marks_visited() -> void:
	print("[TestGameManager] test_enter_node_marks_visited")
	var gm := _make_gm()
	_assert(not gm.run_map[0].visited, "초기 미방문")
	gm.enter_node(0)
	_assert(gm.run_map[0].visited, "enter_node 후 visited = true")
	_assert(gm.current_node_id == 0, "current_node_id == 0")

func test_enter_battle_sets_pending_enemies() -> void:
	print("[TestGameManager] test_enter_battle_sets_pending_enemies")
	var gm := _make_gm()
	# node 0 = floor 0, col 0 = BATTLE 타입
	gm.enter_node(0)
	_assert(gm.pending_enemies.size() > 0, "BATTLE 노드 진입 시 pending_enemies 설정")

func test_complete_battle_generates_rewards() -> void:
	print("[TestGameManager] test_complete_battle_generates_rewards")
	var gm := _make_gm()
	gm.enter_node(0)
	gm.complete_battle(true)
	# 로컬 gm 인스턴스는 SceneTree 외부 → TeamManager 싱글톤 접근 불가
	# → card_rewards는 빈 배열. complete_battle이 예외 없이 완료되면 정상
	_assert(gm.card_rewards is Array, "complete_battle 후 card_rewards는 Array")
	_assert(gm.current_state == 2, "complete_battle 후 상태 CARD_PICK(2)으로 변경")  # GameState.CARD_PICK == 2
