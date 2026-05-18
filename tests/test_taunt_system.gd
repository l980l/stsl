# tests/test_taunt_system.gd
# 도발(taunt) 시스템 — 영웅 자기 부여 (어그로) + 적 부여 (SINGLE 카드 lock) 양면 동작 검증
class_name TestTauntSystem
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const EffRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_self_taunt_collects_as_taunter()
	test_enemy_taunt_does_not_aggro()
	test_taunt_source_recorded()
	test_taunt_lock_overrides_single_target()
	test_taunt_lock_does_not_affect_all_target()
	test_taunt_cleanup_on_enemy_death()
	test_taunt_decays_each_turn_and_clears_source()
	test_marked_by_cleanup_on_enemy_death()
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

func _make_dummy_enemy(hp: int = 100) -> Resource:
	var e := EnemyRes.new()
	e.max_hp = hp
	# intent_pattern 비울 수 없음 — 더미 ATTACK 1개
	var i := IntentRes.new()
	i.action_type = IntentRes.ActionType.ATTACK
	i.value = 1
	i.target = IntentRes.TargetType.RANDOM
	e.intent_pattern = [i]
	return e

func _make_single_card(owner_id: String) -> Resource:
	var c := CardRes.new()
	c.owner_id = owner_id
	c.cost = 0
	var ef := EffRes.new()
	ef.effect_type = EffRes.EffectType.DAMAGE
	ef.value = 10; ef.base_value = 10
	ef.target = "SINGLE"
	c.effects = [ef]
	return c

func _make_all_card(owner_id: String) -> Resource:
	var c := CardRes.new()
	c.owner_id = owner_id
	c.cost = 0
	var ef := EffRes.new()
	ef.effect_type = EffRes.EffectType.DAMAGE
	ef.value = 10; ef.base_value = 10
	ef.target = "ALL"
	c.effects = [ef]
	return c

# 1) 영웅 자기 부여 도발 → _get_taunting_heroes 에 포함 (어그로)
func test_self_taunt_collects_as_taunter() -> void:
	print("[TestTauntSystem] test_self_taunt_collects_as_taunter")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy()])
	# 영웅 자기 부여 (source 없음)
	bm._hero_status["napoleon"] = {"taunt": 2}
	var taunters: Array = bm._get_taunting_heroes()
	_assert(taunters.has("napoleon"), "자기 부여 도발 영웅이 어그로 목록에 포함")

# 2) 적 부여 도발 → _get_taunting_heroes 에 X (어그로 안 함)
func test_enemy_taunt_does_not_aggro() -> void:
	print("[TestTauntSystem] test_enemy_taunt_does_not_aggro")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy()])
	# 적 부여 (source=0)
	bm._hero_status["napoleon"] = {"taunt": 2, "taunt_source": 0}
	var taunters: Array = bm._get_taunting_heroes()
	_assert(not taunters.has("napoleon"), "적 부여 도발 영웅은 어그로 목록에서 제외 (lock 의미만)")

# 3) 적 DEBUFF taunt intent → 영웅 status.taunt + taunt_source 기록
func test_taunt_source_recorded() -> void:
	print("[TestTauntSystem] test_taunt_source_recorded")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var taunt_intent := IntentRes.new()
	taunt_intent.action_type = IntentRes.ActionType.DEBUFF
	taunt_intent.status_type = "taunt"
	taunt_intent.value = 3
	taunt_intent.target = IntentRes.TargetType.RANDOM
	var enemy := EnemyRes.new()
	enemy.max_hp = 50
	enemy.intent_pattern = [taunt_intent]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 → taunt 부여
	var st: Dictionary = bm._hero_status.get("napoleon", {})
	_assert(st.get("taunt", 0) == 3, "적 DEBUFF taunt → 영웅 taunt=3")
	_assert(st.get("taunt_source", -1) == 0, "taunt_source = 부여 적 index (0)")

# 4) 적 부여 도발 + SINGLE 카드 → _get_taunt_lock_target 이 lock 적 index 반환
func test_taunt_lock_overrides_single_target() -> void:
	print("[TestTauntSystem] test_taunt_lock_overrides_single_target")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy(100), _make_dummy_enemy(100)])
	bm._hero_status["napoleon"] = {"taunt": 2, "taunt_source": 1}
	# lock 함수 직접 검증 — play_card 가 이 결과로 target_enemy_index override
	_assert(bm._get_taunt_lock_target("napoleon") == 1, "적 부여 도발 시 lock 적 index 반환")
	# SINGLE 카드 _card_has_single_target → true
	var single := _make_single_card("napoleon")
	_assert(bm._card_has_single_target(single), "SINGLE 효과 카드 → has_single_target true")

# 5) 적 부여 도발 + ALL 카드 → ALL 카드는 has_single_target false → lock override 안 됨
func test_taunt_lock_does_not_affect_all_target() -> void:
	print("[TestTauntSystem] test_taunt_lock_does_not_affect_all_target")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy(100), _make_dummy_enemy(100)])
	bm._hero_status["napoleon"] = {"taunt": 2, "taunt_source": 1}
	# lock 대상은 있지만, ALL 카드는 single_target false → override 안 됨
	_assert(bm._get_taunt_lock_target("napoleon") == 1, "lock 대상 존재")
	var all_card := _make_all_card("napoleon")
	_assert(not bm._card_has_single_target(all_card), "ALL 효과 카드 → has_single_target false (lock 영향 X)")

# 6) 도발 부여 적 사망 → taunt + source 즉시 해제
func test_taunt_cleanup_on_enemy_death() -> void:
	print("[TestTauntSystem] test_taunt_cleanup_on_enemy_death")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy(10), _make_dummy_enemy(100)])
	bm.start_player_turn()
	bm._hero_status["napoleon"] = {"taunt": 5, "taunt_source": 0}
	# 적 0 죽이기
	bm._deal_damage_to_enemy(0, 20)
	var st: Dictionary = bm._hero_status.get("napoleon", {})
	_assert(st.get("taunt", -1) == 0, "도발 부여 적 사망 → taunt 0 으로")
	_assert(not st.has("taunt_source"), "도발 부여 적 사망 → taunt_source 제거")

# 7) 매 턴 -1 → 0 도달 시 taunt_source 도 정리
func test_taunt_decays_each_turn_and_clears_source() -> void:
	print("[TestTauntSystem] test_taunt_decays_each_turn_and_clears_source")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy()])
	bm._hero_status["napoleon"] = {"taunt": 1, "taunt_source": 0}
	# _phase_hero_post 한 번 → taunt 1 -> 0, source erase
	bm._phase_hero_post("napoleon")
	var st: Dictionary = bm._hero_status.get("napoleon", {})
	_assert(st.get("taunt", -1) == 0, "_phase_hero_post → taunt -1 → 0")
	_assert(not st.has("taunt_source"), "_phase_hero_post taunt=0 도달 → source 제거")

# 8) marked_by cleanup (bonus): 마킹한 적 사망 → marked_by 배열에서 제거
func test_marked_by_cleanup_on_enemy_death() -> void:
	print("[TestTauntSystem] test_marked_by_cleanup_on_enemy_death")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_dummy_enemy(10), _make_dummy_enemy(100)])
	bm.start_player_turn()
	# 적 0 과 적 1 둘 다 napoleon 마킹
	bm._hero_status["napoleon"] = {"marked_by": [0, 1]}
	bm._deal_damage_to_enemy(0, 20)  # 적 0 사망
	var marked: Array = bm._hero_status["napoleon"].get("marked_by", [])
	_assert(not marked.has(0), "사망한 적 0 은 marked_by 에서 제거")
	_assert(marked.has(1), "살아있는 적 1 의 마킹은 유지")
