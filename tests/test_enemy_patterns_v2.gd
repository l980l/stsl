# tests/test_enemy_patterns_v2.gd
# Phase A — 신규 ActionType (DISPEL/FORM_SWITCH/CHANGE_AFFINITY/INFLICT_WEAKNESS) +
# 신규 EnemyResource 필드 (turn_modes/counter_window_intent/dynamic_affinity_pool) 검증
class_name TestEnemyPatternsV2
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_action_type_enum_extended()
	test_enemy_resource_new_fields_default()
	test_dispel_clears_hero_strength()
	test_dispel_all_targets()
	test_dispel_custom_status_type()
	test_form_switch_cycles_turn_modes()
	test_form_switch_no_modes_no_op()
	test_change_affinity_picks_from_pool()
	test_change_affinity_empty_pool_uses_default()
	test_inflict_weakness_applies_to_hero()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

func _make_bm() -> BattleManagerClass:
	var bm := BattleManagerClass.new()
	bm._test_disable_crit = true
	bm.team_mgr = TeamManagerClass.new()
	bm.deck_mgr = DeckManagerClass.new()
	_to_free.append(bm)
	_to_free.append(bm.team_mgr)
	_to_free.append(bm.deck_mgr)
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_intent(action_type: int, value: int = 0, target: int = IntentRes.TargetType.RANDOM) -> Resource:
	var i := IntentRes.new()
	i.action_type = action_type
	i.value = value
	i.target = target
	return i

# 1) ActionType enum 4 신규 정의 검증
func test_action_type_enum_extended() -> void:
	print("[TestEnemyPatternsV2] test_action_type_enum_extended")
	_assert(IntentRes.ActionType.DISPEL >= 0, "DISPEL ActionType 정의됨")
	_assert(IntentRes.ActionType.FORM_SWITCH >= 0, "FORM_SWITCH ActionType 정의됨")
	_assert(IntentRes.ActionType.CHANGE_AFFINITY >= 0, "CHANGE_AFFINITY ActionType 정의됨")
	_assert(IntentRes.ActionType.INFLICT_WEAKNESS >= 0, "INFLICT_WEAKNESS ActionType 정의됨")

# 2) EnemyResource 신규 필드 default 확인
func test_enemy_resource_new_fields_default() -> void:
	print("[TestEnemyPatternsV2] test_enemy_resource_new_fields_default")
	var e := EnemyRes.new()
	_assert(e.turn_modes is Array and e.turn_modes.is_empty(), "turn_modes default = []")
	_assert(e.counter_window_intent is Dictionary and e.counter_window_intent.is_empty(), "counter_window_intent default = {}")
	_assert(e.dynamic_affinity_pool is Array and e.dynamic_affinity_pool.is_empty(), "dynamic_affinity_pool default = []")

# 3) DISPEL — 영웅 단일 strength 제거 (default = strength + block)
func test_dispel_clears_hero_strength() -> void:
	print("[TestEnemyPatternsV2] test_dispel_clears_hero_strength")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm._apply_status_to_hero("napoleon", "strength", 5)
	bm._apply_status_to_hero("napoleon", "block", 10)
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.DISPEL)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._hero_status["napoleon"].get("strength", 0) == 0, "DISPEL 후 strength 0")
	_assert(bm._hero_status["napoleon"].get("block", 0) == 0, "DISPEL 후 block 0")

# 4) DISPEL ALL — 모든 영웅 buff 제거
func test_dispel_all_targets() -> void:
	print("[TestEnemyPatternsV2] test_dispel_all_targets")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.add_hero(_make_hero("jeanne", 100))
	bm._apply_status_to_hero("napoleon", "strength", 3)
	bm._apply_status_to_hero("jeanne", "strength", 4)
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	var intent := _make_intent(IntentRes.ActionType.DISPEL, 0, IntentRes.TargetType.ALL)
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._hero_status["napoleon"].get("strength", 0) == 0, "ALL DISPEL → napoleon strength 0")
	_assert(bm._hero_status["jeanne"].get("strength", 0) == 0, "ALL DISPEL → jeanne strength 0")

# 5) DISPEL custom status_type — 명시한 키만 제거
func test_dispel_custom_status_type() -> void:
	print("[TestEnemyPatternsV2] test_dispel_custom_status_type")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm._apply_status_to_hero("napoleon", "strength", 5)
	bm._apply_status_to_hero("napoleon", "block", 10)
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	var intent := _make_intent(IntentRes.ActionType.DISPEL)
	intent.status_type = "strength"  # strength 만 제거, block 유지
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._hero_status["napoleon"].get("strength", 0) == 0, "custom DISPEL strength → 0")
	_assert(bm._hero_status["napoleon"].get("block", 0) == 10, "custom DISPEL strength 만 → block 유지")

# 6) FORM_SWITCH — turn_modes 순환
func test_form_switch_cycles_turn_modes() -> void:
	print("[TestEnemyPatternsV2] test_form_switch_cycles_turn_modes")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.turn_modes = ["offense", "defense", "offense"]
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.FORM_SWITCH)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_status[0].get("current_mode_index", -1) == 1, "FORM_SWITCH 1회 → index 1")
	_assert(bm._enemy_status[0].get("current_mode", "") == "defense", "current_mode = defense")
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_status[0].get("current_mode_index", -1) == 2, "FORM_SWITCH 2회 → index 2")

# 7) FORM_SWITCH — turn_modes 빈 배열이면 no-op
func test_form_switch_no_modes_no_op() -> void:
	print("[TestEnemyPatternsV2] test_form_switch_no_modes_no_op")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.FORM_SWITCH)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(not bm._enemy_status[0].has("current_mode_index"), "빈 turn_modes → current_mode_index 미설정")

# 8) CHANGE_AFFINITY — dynamic_affinity_pool 에서 픽
func test_change_affinity_picks_from_pool() -> void:
	print("[TestEnemyPatternsV2] test_change_affinity_picks_from_pool")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.dynamic_affinity_pool = ["holy_fire"]
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.CHANGE_AFFINITY)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_status[0].get("current_affinity", "") == "holy_fire", "단일 풀 → holy_fire 선택")

# 9) CHANGE_AFFINITY — 빈 풀이면 기본 4 속성에서
func test_change_affinity_empty_pool_uses_default() -> void:
	print("[TestEnemyPatternsV2] test_change_affinity_empty_pool_uses_default")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.CHANGE_AFFINITY)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	var chosen: String = bm._enemy_status[0].get("current_affinity", "")
	_assert(chosen in ["holy_fire", "holy_strike", "holy_arrow", "holy_slash"], "빈 풀 → 기본 4 속성 중 하나")

# 10) INFLICT_WEAKNESS — 영웅에 status 부여
func test_inflict_weakness_applies_to_hero() -> void:
	print("[TestEnemyPatternsV2] test_inflict_weakness_applies_to_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	var intent := _make_intent(IntentRes.ActionType.INFLICT_WEAKNESS, 2)
	intent.status_type = "weakness_fire"
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._hero_status.get("napoleon", {}).get("weakness_fire", 0) == 2, "INFLICT_WEAKNESS → weakness_fire stack 2")
