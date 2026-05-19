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
	# Phase A2-1
	test_heal_block_prevents_heal()
	test_heal_block_zero_allows_heal()
	test_silence_blocks_card_play()
	test_silence_zero_allows_card_play()
	test_exiled_hero_not_targeted()
	# Phase A2-3
	test_defense_mode_halves_incoming_damage()
	test_offense_mode_boosts_outgoing_damage()
	test_no_modes_no_damage_modifier()
	test_change_affinity_overrides_damage_type()
	# Phase A2-2
	test_double_action_extra_intent()
	test_double_action_decrements_each_use()
	test_dynamic_resistance_reduces_mismatch_damage()
	test_dynamic_resistance_matching_full_damage()
	test_time_limit_enrage_strength()
	# Phase C1
	test_counter_charge_negates_when_window_active()
	test_counter_charge_fallback_damage_when_no_window()
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

# Phase A2-1 — heal_block / silence / exiled

# 11) heal_block — _heal_hero_safe 차단
func test_heal_block_prevents_heal() -> void:
	print("[TestEnemyPatternsV2] test_heal_block_prevents_heal")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.take_damage("napoleon", 50)
	bm._apply_status_to_hero("napoleon", "heal_block", 2)
	var applied: bool = bm._heal_hero_safe("napoleon", 30)
	_assert(not applied, "heal_block > 0 → 회복 차단 (false 반환)")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 50, "HP 변동 없음")

# 12) heal_block 0 — 정상 회복
func test_heal_block_zero_allows_heal() -> void:
	print("[TestEnemyPatternsV2] test_heal_block_zero_allows_heal")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.take_damage("napoleon", 50)
	var applied: bool = bm._heal_hero_safe("napoleon", 30)
	_assert(applied, "heal_block 미설정 → 회복 적용 (true)")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 80, "HP 50 + 30 = 80")

# 13) silence — 카드 사용 차단
func test_silence_blocks_card_play() -> void:
	print("[TestEnemyPatternsV2] test_silence_blocks_card_play")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	bm._apply_status_to_hero("napoleon", "silence", 1)
	bm.start_player_turn()
	# Card with owner_id = napoleon
	var c := preload("res://resources/card_resource.gd").new()
	c.owner_id = "napoleon"; c.cost = 0; c.effects = []
	bm.deck_mgr.hand.append(c)
	var ok: bool = bm.play_card(c, 0)
	_assert(not ok, "silence > 0 → play_card false")

# 14) silence 0 — 카드 사용 정상
func test_silence_zero_allows_card_play() -> void:
	print("[TestEnemyPatternsV2] test_silence_zero_allows_card_play")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	bm.start_player_turn()
	var c := preload("res://resources/card_resource.gd").new()
	c.owner_id = "napoleon"; c.cost = 0; c.effects = []
	bm.deck_mgr.hand.append(c)
	var ok: bool = bm.play_card(c, 0)
	_assert(ok, "silence 0 → play_card true")

# 15) exiled — 영웅이 target select 에서 제외
func test_exiled_hero_not_targeted() -> void:
	print("[TestEnemyPatternsV2] test_exiled_hero_not_targeted")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.add_hero(_make_hero("jeanne", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	bm._apply_status_to_hero("napoleon", "exiled", 1)
	# RANDOM 타겟 5회 — napoleon 절대 안 뽑혀야
	for _i in range(5):
		var pick: String = bm._pick_hero_target(IntentRes.TargetType.RANDOM, 0, IntentRes.ActionType.ATTACK)
		_assert(pick == "jeanne", "exiled napoleon 제외 → jeanne 만 선택")

# Phase A2-3 — FORM_SWITCH / CHANGE_AFFINITY 실효과

# 16) defense 모드 — 받는 damage 50%
func test_defense_mode_halves_incoming_damage() -> void:
	print("[TestEnemyPatternsV2] test_defense_mode_halves_incoming_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	enemy.turn_modes = ["defense", "offense"]
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 10)]
	bm.setup_battle([enemy])
	# current_mode_index 0 = defense (default)
	bm._deal_damage_to_enemy(0, 100)
	_assert(bm._enemy_hp[0] == 950, "defense 모드 → 100 dmg × 0.5 = 50, hp 1000→950")

# 17) offense 모드 — 주는 damage 1.5x
func test_offense_mode_boosts_outgoing_damage() -> void:
	print("[TestEnemyPatternsV2] test_offense_mode_boosts_outgoing_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.turn_modes = ["defense", "offense"]
	var atk := _make_intent(IntentRes.ActionType.ATTACK, 10)
	atk.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [atk]
	bm.setup_battle([enemy])
	# 강제로 offense 모드 (index 1)
	bm._enemy_status[0]["current_mode_index"] = 1
	bm.start_player_turn()
	bm.end_player_turn()
	# 10 × 1.5 = 15 → napoleon 200 - 15 = 185
	_assert(bm.team_mgr.get_current_hp("napoleon") == 185, "offense 모드 → 10 dmg × 1.5 = 15, hp 200→185")

# 18) turn_modes 없으면 modifier 미적용
func test_no_modes_no_damage_modifier() -> void:
	print("[TestEnemyPatternsV2] test_no_modes_no_damage_modifier")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 10)]
	bm.setup_battle([enemy])
	bm._deal_damage_to_enemy(0, 100)
	_assert(bm._enemy_hp[0] == 900, "turn_modes 없음 → damage 1.0× = 100, hp 1000→900")

# 19) CHANGE_AFFINITY — current_affinity 가 다음 ATTACK 의 damage_type override
func test_change_affinity_overrides_damage_type() -> void:
	print("[TestEnemyPatternsV2] test_change_affinity_overrides_damage_type")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 10)]
	bm.setup_battle([enemy])
	bm._enemy_status[0]["current_affinity"] = "holy_fire"
	var resolved: String = bm._resolve_enemy_damage_type(0, "blunt")
	_assert(resolved == "holy_fire", "current_affinity 설정 → override")
	# 미설정 시 intent damage_type
	bm._enemy_status[0].erase("current_affinity")
	resolved = bm._resolve_enemy_damage_type(0, "blunt")
	_assert(resolved == "blunt", "current_affinity 미설정 → intent damage_type 사용")

# Phase A2-2 — double_action

# 20) double_action — 적이 한 turn 안에 intent 2번 실행
func test_double_action_extra_intent() -> void:
	print("[TestEnemyPatternsV2] test_double_action_extra_intent")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	var atk := _make_intent(IntentRes.ActionType.ATTACK, 20)
	atk.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [atk]
	bm.setup_battle([enemy])
	bm._apply_status_to_enemy(0, "double_action", 1)
	bm.start_player_turn()
	bm.end_player_turn()
	# 20 + 20 = 40 → napoleon 1000 - 40 = 960
	_assert(bm.team_mgr.get_current_hp("napoleon") == 960, "double_action 1 → intent 2번 (20+20=40 dmg)")

# 21) double_action decrement — 매 사용마다 -1
func test_double_action_decrements_each_use() -> void:
	print("[TestEnemyPatternsV2] test_double_action_decrements_each_use")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	var atk := _make_intent(IntentRes.ActionType.ATTACK, 10)
	atk.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [atk]
	bm.setup_battle([enemy])
	bm._apply_status_to_enemy(0, "double_action", 2)
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_status[0].get("double_action", 0) == 1, "double_action 2 → 사용 후 1")

# 22) dynamic_resistance — current_weakness 불일치 시 0.2배
func test_dynamic_resistance_reduces_mismatch_damage() -> void:
	print("[TestEnemyPatternsV2] test_dynamic_resistance_reduces_mismatch_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	enemy.dynamic_resistance_pool = ["holy_fire"]
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	bm._enemy_status[0]["current_weakness"] = "holy_fire"
	bm._deal_damage_to_enemy(0, 100, "blunt")  # 불일치
	_assert(bm._enemy_hp[0] == 980, "blunt vs holy_fire (불일치) → 100 × 0.2 = 20, hp 1000→980")

# 23) dynamic_resistance — current_weakness 일치 시 정상 damage
func test_dynamic_resistance_matching_full_damage() -> void:
	print("[TestEnemyPatternsV2] test_dynamic_resistance_matching_full_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	enemy.dynamic_resistance_pool = ["holy_fire"]
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	bm._enemy_status[0]["current_weakness"] = "holy_fire"
	bm._deal_damage_to_enemy(0, 100, "holy_fire")  # 일치
	_assert(bm._enemy_hp[0] == 900, "holy_fire vs holy_fire (일치) → 100 정상, hp 1000→900")

# 24) time_limit — turn_count >= 임계 시 자기 strength +5/turn
func test_time_limit_enrage_strength() -> void:
	print("[TestEnemyPatternsV2] test_time_limit_enrage_strength")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.time_limit_turns = 3
	var atk := _make_intent(IntentRes.ActionType.ATTACK, 5)
	atk.target = IntentRes.TargetType.RANDOM
	enemy.intent_pattern = [atk]
	bm.setup_battle([enemy])
	bm.turn_count = 3  # 임계 도달
	bm.start_player_turn()
	bm.end_player_turn()
	# enemy turn 시작 시 광폭화 strength +5
	_assert(bm._enemy_status[0].get("strength", 0) == 5, "time_limit 도달 → 자기 strength +5")

const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")

# 25) COUNTER_CHARGE — counter_window 활성 + charge 중 시 charge 무효 + stun
func test_counter_charge_negates_when_window_active() -> void:
	print("[TestEnemyPatternsV2] test_counter_charge_negates_when_window_active")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	enemy.counter_window_intent = {"enabled": true}
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	# 보스가 charge 중 시뮬레이션
	bm._enemy_status[0]["charge_remaining"] = 2
	# 영웅 카드 — COUNTER_CHARGE effect
	var card := CardRes.new()
	card.owner_id = "napoleon"; card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.COUNTER_CHARGE
	eff.value = 50  # fallback
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)
	bm.start_player_turn()
	bm.play_card(card, 0)
	_assert(not bm._enemy_status[0].has("charge_remaining"), "charge_remaining 무효 (키 제거)")
	_assert(bm._enemy_status[0].get("stun", 0) == 1, "stun 1 부여")
	_assert(bm._enemy_hp[0] == 1000, "fallback damage X (charge 가 무효됨)")

# 26) COUNTER_CHARGE — counter_window 미활성 시 fallback damage
func test_counter_charge_fallback_damage_when_no_window() -> void:
	print("[TestEnemyPatternsV2] test_counter_charge_fallback_damage_when_no_window")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var enemy := EnemyRes.new()
	enemy.max_hp = 1000
	# counter_window_intent 미설정
	enemy.intent_pattern = [_make_intent(IntentRes.ActionType.ATTACK, 5)]
	bm.setup_battle([enemy])
	var card := CardRes.new()
	card.owner_id = "napoleon"; card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.COUNTER_CHARGE
	eff.value = 50
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)
	bm.start_player_turn()
	bm.play_card(card, 0)
	_assert(bm._enemy_hp[0] == 950, "counter_window 미활성 → fallback 50 dmg, hp 1000→950")

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
