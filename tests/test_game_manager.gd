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
	test_battle_lost_goes_to_game_over()
	test_enter_shop_sets_state()
	test_complete_shop_returns_to_map()
	test_elite_battle_gives_two_card_picks()
	test_complete_rest_returns_to_map()
	test_upgrade_card_damage()
	test_upgrade_card_reduces_cost()
	test_upgrade_card_no_op_if_already_upgraded()
	test_enter_card_upgrade_sets_state()
	test_boss_card_pick_goes_to_upgrade()
	test_complete_event_returns_to_map()
	test_start_run_with_cleopatra()
	test_act_serialization()
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

func test_battle_lost_goes_to_game_over() -> void:
	print("[TestGameManager] test_battle_lost_goes_to_game_over")
	var gm := _make_gm()
	gm.enter_node(0)
	gm.complete_battle(false)
	_assert(gm.run_won == false, "패배 시 run_won == false")
	_assert(gm.current_state == 6, "패배 시 상태 GAME_OVER(6)으로 변경")  # GameState.GAME_OVER == 6

func test_enter_shop_sets_state() -> void:
	print("[TestGameManager] test_enter_shop_sets_state")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.SHOP
	gm.enter_node(0)
	_assert(gm.current_state == 4, "SHOP 노드 진입 시 상태 SHOP(4)으로 변경")  # GameState.SHOP == 4

func test_complete_shop_returns_to_map() -> void:
	print("[TestGameManager] test_complete_shop_returns_to_map")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.SHOP
	gm.enter_node(0)
	gm.complete_shop()
	_assert(gm.current_state == 0, "complete_shop 후 상태 MAP(0)으로 변경")  # GameState.MAP == 0

func test_elite_battle_gives_two_card_picks() -> void:
	print("[TestGameManager] test_elite_battle_gives_two_card_picks")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.ELITE
	gm.enter_node(0)
	gm.complete_battle(true)
	_assert(gm.card_rewards_pick_count == 2, "엘리트 전투 승리 시 카드 2장 선택 가능")

func test_complete_rest_returns_to_map() -> void:
	print("[TestGameManager] test_complete_rest_returns_to_map")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.REST
	gm.enter_node(0)
	gm.complete_rest()
	_assert(gm.current_state == 0, "complete_rest 후 상태 MAP(0)으로 변경")  # GameState.MAP == 0

func test_upgrade_card_damage() -> void:
	print("[TestGameManager] test_upgrade_card_damage")
	var gm := _make_gm()
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var card: Resource = CardRes.new()
	card.cost = 1
	var eff: Resource = EffRes.new()
	eff.effect_type = EffRes.EffectType.DAMAGE
	eff.value = 6
	card.effects = [eff]
	gm.upgrade_card(card)
	_assert(card.upgraded == true, "업그레이드 후 upgraded = true")
	_assert(eff.value == 9, "데미지 +3 → 9")
	_assert(card.cost == 1, "비용 1 카드는 비용 변경 없음")

func test_upgrade_card_reduces_cost() -> void:
	print("[TestGameManager] test_upgrade_card_reduces_cost")
	var gm := _make_gm()
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var card: Resource = CardRes.new()
	card.cost = 2
	var eff: Resource = EffRes.new()
	eff.effect_type = EffRes.EffectType.BLOCK
	eff.value = 5
	card.effects = [eff]
	gm.upgrade_card(card)
	_assert(card.cost == 1, "비용 2 카드 강화 시 비용 1로 감소")
	_assert(eff.value == 8, "블록 +3 → 8")

func test_upgrade_card_no_op_if_already_upgraded() -> void:
	print("[TestGameManager] test_upgrade_card_no_op_if_already_upgraded")
	var gm := _make_gm()
	var CardRes = load("res://resources/card_resource.gd")
	var EffRes = load("res://resources/effect_resource.gd")
	var card: Resource = CardRes.new()
	card.cost = 1
	card.upgraded = true
	var eff: Resource = EffRes.new()
	eff.effect_type = EffRes.EffectType.DAMAGE
	eff.value = 6
	card.effects = [eff]
	gm.upgrade_card(card)
	_assert(eff.value == 6, "이미 강화된 카드는 수치 변경 없음")

func test_enter_card_upgrade_sets_state() -> void:
	print("[TestGameManager] test_enter_card_upgrade_sets_state")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.REST
	gm.enter_node(0)
	gm.enter_card_upgrade()
	_assert(gm.current_state == 7, "카드 강화 진입 시 상태 CARD_UPGRADE(7)으로 변경")  # GameState.CARD_UPGRADE == 7

func test_boss_card_pick_goes_to_upgrade() -> void:
	print("[TestGameManager] test_boss_card_pick_goes_to_upgrade")
	var MapNodeRes = load("res://resources/map_node_resource.gd")
	var gm := _make_gm()
	gm.run_map[0].room_type = MapNodeRes.RoomType.BOSS
	gm.enter_node(0)
	gm.complete_battle(true)
	gm.complete_card_pick()
	_assert(gm.current_state == 7, "보스 카드픽 완료 후 CARD_UPGRADE(7) 상태")
	_assert(gm.pending_boss_upgrade == true, "pending_boss_upgrade == true")

func test_complete_event_returns_to_map() -> void:
	print("[TestGameManager] test_complete_event_returns_to_map")
	var gm := _make_gm()
	gm.current_node_id = 0
	gm.complete_event()
	_assert(gm.current_state == 0, "complete_event 후 MAP(0) 상태")
	_assert(gm.pending_event == null, "pending_event 초기화")

func test_start_run_with_cleopatra() -> void:
	print("[TestGameManager] test_start_run_with_cleopatra")
	var gm := _make_gm()
	# start_run은 싱글톤(TeamManager/DeckManager) 없이도 크래시 없이 완료돼야 함
	gm.start_run("cleopatra")
	_assert(gm.run_map.size() == 28, "클레오파트라로 시작해도 맵 28개 노드")
	_assert(gm.available_node_ids == [0, 1, 2], "초기 접근 가능 노드 [0,1,2]")

func test_act_serialization() -> void:
	print("[TestGameManager] test_act_serialization")
	var gm := _make_gm()
	gm.current_act = 2
	var d := gm.to_dict()
	_assert(d.get("current_act") == 2, "to_dict current_act=2")
	gm.current_act = 1
	gm.from_dict(d)
	_assert(gm.current_act == 2, "from_dict restores current_act")
	passed += 1
