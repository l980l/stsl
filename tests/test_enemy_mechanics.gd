# tests/test_enemy_mechanics.gd
# Phase 1 — phase_buffs 자동 적용 + SPECIAL 일반화 + 그리스 신화 tier 0/1 검증
class_name TestEnemyMechanics
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")

const GreekNormals = preload("res://resources/enemies/greek/greek_normals.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_phase_buffs_applied()
	test_special_remove_card_default_variant()
	test_special_unknown_variant_no_crash()
	test_ares_soldier_berserk_strength_on_phase()
	test_dryad_phase_transforms_pattern()
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

func _make_card(owner_id: String) -> Resource:
	var c := CardRes.new()
	c.owner_id = owner_id
	c.cost = 1
	c.effects = []
	return c

func _make_intent(action_type: int, value: int, target: int = IntentRes.TargetType.RANDOM) -> Resource:
	var i := IntentRes.new()
	i.action_type = action_type
	i.value = value
	i.target = target
	return i

# 1) phase_buffs — phase 전환 시 자동 status 부여
func test_phase_buffs_applied() -> void:
	print("[TestEnemyMechanics] test_phase_buffs_applied")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var intent := _make_intent(IntentRes.ActionType.ATTACK, 10)

	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.intent_pattern = [intent]
	enemy.phase_thresholds = [0.5]
	enemy.phase_buffs = [[{"status": "strength", "value": 3}]]

	bm.setup_battle([enemy])
	bm.start_player_turn()
	# HP 100 → 40 (50% 이하) 으로 깎기
	bm._deal_damage_to_enemy(0, 60)
	_assert(bm._enemy_phase[0] == 1, "HP 50% 이하 도달 시 phase 0 → 1 전환")
	_assert(bm._enemy_status[0].get("strength", 0) == 3, "phase 전환 시 strength +3 자동 부여")

# 2) SPECIAL status_type 미지정 시 remove_card 동작 (하위 호환)
func test_special_remove_card_default_variant() -> void:
	print("[TestEnemyMechanics] test_special_remove_card_default_variant")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	for _i in range(3):
		bm.deck_mgr.draw_pile.append(_make_card("napoleon"))
	# status_type 미지정 — 기본 remove_card 분기로 빠져야 함
	var intent := _make_intent(IntentRes.ActionType.SPECIAL, 1)
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm.deck_mgr.get_full_deck().size() == 2, "SPECIAL status_type 빈 값 → remove_card (3→2)")

# 3) SPECIAL 알 수 없는 variant 입력 시 크래시 없이 경고만
func test_special_unknown_variant_no_crash() -> void:
	print("[TestEnemyMechanics] test_special_unknown_variant_no_crash")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.deck_mgr.draw_pile.append(_make_card("napoleon"))
	var intent := _make_intent(IntentRes.ActionType.SPECIAL, 1)
	intent.status_type = "unknown_variant_xyz"
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 크래시 없이 통과해야
	_assert(bm.deck_mgr.get_full_deck().size() == 1, "알 수 없는 variant → 덱 변동 없음 + 크래시 없음")

# 4) 그리스 ares_soldier — T1-BERSERK
func test_ares_soldier_berserk_strength_on_phase() -> void:
	print("[TestEnemyMechanics] test_ares_soldier_berserk_strength_on_phase")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var ares: Resource = GreekNormals.ares_soldier(null)
	bm.setup_battle([ares])
	bm.start_player_turn()
	# HP 380 → 180 (50% 이하 = 190) 도달 위해 200 데미지
	bm._deal_damage_to_enemy(0, 200)
	_assert(bm._enemy_phase[0] == 1, "ares_soldier HP 50% 이하 → phase 1")
	_assert(bm._enemy_status[0].get("strength", 0) == 3, "광폭화 — strength +3 자동")

# 5) 그리스 dryad — T1-PHASE 패턴 교체 검증
func test_dryad_phase_transforms_pattern() -> void:
	print("[TestEnemyMechanics] test_dryad_phase_transforms_pattern")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var dryad: Resource = GreekNormals.dryad(null)
	bm.setup_battle([dryad])
	bm.start_player_turn()
	var p0_pattern: Array = bm._get_active_pattern(0)
	_assert(p0_pattern.size() == 3, "dryad 페이즈 0 패턴 길이 3")
	_assert(p0_pattern[0].action_type == IntentRes.ActionType.DEBUFF, "dryad 페이즈 0 첫 액션 = DEBUFF")
	# HP 270 → 130 (50% 이하 = 135) 도달 위해 140 데미지
	bm._deal_damage_to_enemy(0, 140)
	_assert(bm._enemy_phase[0] == 1, "dryad HP 50% 이하 → phase 1")
	var p1_pattern: Array = bm._get_active_pattern(0)
	_assert(p1_pattern[0].action_type == IntentRes.ActionType.ATTACK, "dryad 페이즈 1 첫 액션 = ATTACK (광기 ALL)")
	_assert(p1_pattern[0].target == IntentRes.TargetType.ALL, "dryad 페이즈 1 첫 액션 ALL 타겟")
