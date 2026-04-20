# tests/test_battle_manager.gd
class_name TestBattleManager
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")
const EnemyRes = preload("res://resources/enemy_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_setup_battle()
	test_play_card_damage()
	test_play_card_block()
	test_block_absorbs_damage()
	test_block_resets_on_player_turn()
	test_weak_reduces_damage()
	test_vulnerable_increases_damage()
	test_poison_tick_enemy()
	test_poison_tick_hero()
	test_enemy_turn_attacks_hero()
	test_enemy_intent_advances()
	test_win_condition()
	test_lose_condition()
	test_enemy_all_attack_hits_all_heroes()
	test_hero_damaged_emitted_with_zero_when_fully_blocked()
	test_enemy_damaged_emitted_with_zero_when_fully_blocked()
	test_harpy_special_removes_from_deck()
	test_charm_converts_to_enthrall_at_3()
	test_dead_hero_card_has_no_effect()
	test_get_hero_status_empty_by_default()
	test_get_enemy_status_after_apply()
	test_conditional_dmg_checks_owner_morale()
	test_morale_changed_signal_emitted()
	test_morale_changed_emitted_on_consume_success()
	test_morale_changed_not_emitted_on_consume_fail()
	test_cost_next_reduces_next_card_cost()
	test_enthrall_attacks_other_enemy()
	test_synergy_napoleon_yisunsin()
	test_synergy_yisunsin_cleopatra()
	test_synergy_napoleon_cleopatra()
	test_synergy_napoleon_cleopatra_no_morale()
	test_has_synergy_bonus()
	test_enemy_status_decrements_on_enemy_turn()
	test_hero_status_decrements_on_player_turn()
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
	return bm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_enemy(hp: int, intents: Array) -> Resource:
	var e := EnemyRes.new()
	e.max_hp = hp
	e.intent_pattern = intents
	return e

func _make_intent(action_type: int, value: int, target: int) -> Resource:
	var i := IntentRes.new()
	i.action_type = action_type
	i.value = value
	i.target = target
	return i

func _make_card(owner_id: String, cost: int, effects: Array) -> Resource:
	var c := CardRes.new()
	c.owner_id = owner_id
	c.cost = cost
	c.effects = effects
	return c

func _make_effect(effect_type: int, value: int, target: String) -> Resource:
	var e := EffectRes.new()
	e.effect_type = effect_type
	e.value = value
	e.target = target
	return e

func test_setup_battle() -> void:
	print("[TestBattleManager] test_setup_battle")
	var bm := _make_bm()
	var enemy := _make_enemy(30, [])
	bm.setup_battle([enemy])
	_assert(bm.get_enemy_hp(0) == 30, "적 HP == max_hp(30)")
	_assert(bm.is_enemy_alive(0), "셋업 후 적 생존")
	_assert(bm.is_battle_active, "배틀 활성")
	_assert(bm.get_enemy_block(0) == 0, "초기 블록 0")

func test_play_card_damage() -> void:
	print("[TestBattleManager] test_play_card_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])

	var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
	var card := _make_card("napoleon", 1, [effect])
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.is_player_turn = true

	var result := bm.play_card(card, 0)
	_assert(result, "카드 플레이 성공 반환")
	_assert(bm.get_enemy_hp(0) == 20, "피해 10 적용 → HP 30 → 20")

func test_play_card_block() -> void:
	print("[TestBattleManager] test_play_card_block")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])

	var effect := _make_effect(EffectRes.EffectType.BLOCK, 8, "SELF")
	var card := _make_card("napoleon", 1, [effect])
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.is_player_turn = true

	bm.play_card(card, 0)
	_assert(bm._hero_block.get("napoleon", 0) == 8, "블록 8 추가")

func test_block_absorbs_damage() -> void:
	print("[TestBattleManager] test_block_absorbs_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_block["napoleon"] = 10

	bm._deal_damage_to_hero("napoleon", 15)
	_assert(bm._hero_block.get("napoleon", -1) == 0, "블록 10 전부 소진")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 65, "HP 70 → 65 (블록 10 흡수, 나머지 5 피해)")

func test_block_resets_on_player_turn() -> void:
	print("[TestBattleManager] test_block_resets_on_player_turn")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_block["napoleon"] = 5
	bm.is_battle_active = true

	bm.start_player_turn()
	_assert(bm._hero_block.get("napoleon", -1) == 0, "턴 시작 시 블록 0으로 초기화")

func test_weak_reduces_damage() -> void:
	print("[TestBattleManager] test_weak_reduces_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_status["napoleon"] = {"weak": 1}

	var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
	var card := _make_card("napoleon", 1, [effect])
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.is_player_turn = true

	bm.play_card(card, 0)
	_assert(bm.get_enemy_hp(0) == 23, "약화 적용 → 피해 10 → 7 (HP 30 → 23)")

func test_vulnerable_increases_damage() -> void:
	print("[TestBattleManager] test_vulnerable_increases_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._enemy_status[0]["vulnerable"] = 1

	var effect := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
	var card := _make_card("napoleon", 1, [effect])
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.is_player_turn = true

	bm.play_card(card, 0)
	_assert(bm.get_enemy_hp(0) == 15, "취약 적용 → 피해 10 → 15 (HP 30 → 15)")

func test_poison_tick_enemy() -> void:
	print("[TestBattleManager] test_poison_tick_enemy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent := _make_intent(IntentRes.ActionType.BUFF, 5, IntentRes.TargetType.RANDOM)
	var enemy := _make_enemy(200, [intent])
	bm.setup_battle([enemy])
	bm._enemy_status[0]["poison"] = 3

	bm._execute_enemy_turn()
	_assert(bm.get_enemy_hp(0) == 170, "독 3 틱 → 3×10=30 피해 → HP 200 → 170")
	_assert(bm._enemy_status[0].get("poison", -1) == 2, "독 스택 3 → 2")

func test_poison_tick_hero() -> void:
	print("[TestBattleManager] test_poison_tick_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_status["napoleon"] = {"poison": 4}
	bm.is_battle_active = true

	bm.start_player_turn()
	_assert(bm.team_mgr.get_current_hp("napoleon") == 30, "독 4 틱 → 4×10=40 피해 → HP 70 → 30")
	_assert(bm._hero_status["napoleon"].get("poison", -1) == 3, "독 스택 4 → 3")

func test_enemy_turn_attacks_hero() -> void:
	print("[TestBattleManager] test_enemy_turn_attacks_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent := _make_intent(IntentRes.ActionType.ATTACK, 6, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(30, [intent])])

	bm._execute_enemy_turn()
	_assert(bm.team_mgr.get_current_hp("napoleon") == 64, "적 공격 6 → HP 70 → 64")

func test_enemy_intent_advances() -> void:
	print("[TestBattleManager] test_enemy_intent_advances")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent0 := _make_intent(IntentRes.ActionType.ATTACK, 5, IntentRes.TargetType.RANDOM)
	var intent1 := _make_intent(IntentRes.ActionType.BUFF, 8, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(30, [intent0, intent1])])

	_assert(bm._enemy_intent_index[0] == 0, "초기 인덱스 0")
	bm._execute_enemy_turn()
	_assert(bm._enemy_intent_index[0] == 1, "1회 후 인덱스 1")
	bm._execute_enemy_turn()
	_assert(bm._enemy_intent_index[0] == 0, "2회 후 인덱스 0 (순환)")

func test_win_condition() -> void:
	print("[TestBattleManager] test_win_condition")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(10, [])])

	var signal_received := {"won": false}
	bm.battle_won.connect(func():
		signal_received["won"] = true
	)

	bm._deal_damage_to_enemy(0, 10)
	_assert(signal_received["won"], "모든 적 처치 → battle_won 발동")
	_assert(not bm.is_battle_active, "배틀 비활성")

func test_lose_condition() -> void:
	print("[TestBattleManager] test_lose_condition")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 10))
	bm.setup_battle([_make_enemy(30, [])])

	var signal_received := {"lost": false}
	bm.battle_lost.connect(func():
		signal_received["lost"] = true
	)

	bm._deal_damage_to_hero("napoleon", 10)
	_assert(signal_received["lost"], "모든 영웅 사망 → battle_lost 발동")
	_assert(not bm.is_battle_active, "배틀 비활성")

func test_enemy_all_attack_hits_all_heroes() -> void:
	print("[TestBattleManager] test_enemy_all_attack_hits_all_heroes")
	var bm := _make_bm()
	var hero1 := _make_hero("napoleon", 70)
	var hero2 := _make_hero("cleopatra", 60)
	bm.team_mgr.add_hero(hero1)
	bm.team_mgr.add_hero(hero2)
	# ALL 공격 인텐트 생성
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.ATTACK
	intent.value = 10
	intent.target = IntentRes.TargetType.ALL
	var enemy := _make_enemy(30, [intent])
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 실행
	_assert(bm.team_mgr.get_current_hp("napoleon") == 60, "ALL 공격 → napoleon HP 70→60")
	_assert(bm.team_mgr.get_current_hp("cleopatra") == 50, "ALL 공격 → cleopatra HP 60→50")

func test_hero_damaged_emitted_with_zero_when_fully_blocked() -> void:
	print("[TestBattleManager] test_hero_damaged_emitted_with_zero_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	bm._hero_block["napoleon"] = 10

	var damage_emitted: Array = []
	bm.hero_damaged.connect(func(id, amt): damage_emitted.append(amt))

	bm._deal_damage_to_hero("napoleon", 10)
	_assert(damage_emitted.size() == 1, "블록 완전 흡수 시에도 hero_damaged 발화")
	_assert(damage_emitted[0] == 0, "amount == 0 으로 발화")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 70, "HP 변화 없음")

func test_enemy_damaged_emitted_with_zero_when_fully_blocked() -> void:
	print("[TestBattleManager] test_enemy_damaged_emitted_with_zero_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	bm._enemy_block[0] = 10

	var damage_emitted: Array = []
	bm.enemy_damaged.connect(func(idx, amt): damage_emitted.append(amt))

	bm._deal_damage_to_enemy(0, 10)
	_assert(damage_emitted.size() == 1, "블록 완전 흡수 시에도 enemy_damaged 발화")
	_assert(damage_emitted[0] == 0, "amount == 0 으로 발화")
	_assert(bm.get_enemy_hp(0) == 30, "적 HP 변화 없음")

func test_harpy_special_removes_from_deck() -> void:
	print("[TestBattleManager] test_harpy_special_removes_from_deck")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	# 덱에 카드 3장 추가
	for i in range(3):
		var c := _make_card("napoleon", 1, [])
		bm.deck_mgr.draw_pile.append(c)
	var intent := _make_intent(IntentRes.ActionType.SPECIAL, 1, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(30, [intent])])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 실행
	_assert(bm.deck_mgr.get_full_deck().size() == 2, "SPECIAL → 덱에서 카드 1장 영구 제거 (3→2)")

func test_charm_converts_to_enthrall_at_3() -> void:
	print("[TestBattleManager] test_charm_converts_to_enthrall_at_3")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent := _make_intent(IntentRes.ActionType.ATTACK, 10, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(30, [intent])])
	bm._enemy_status[0]["charm"] = 3
	bm.start_player_turn()
	bm.end_player_turn()  # charm 3 → enthrall 전환, 다른 적 없어 공격 스킵
	_assert(bm.team_mgr.get_current_hp("napoleon") == 70, "홀림 턴: 다른 적 없어 영웅 HP 불변")
	_assert(bm._enemy_status[0].get("charm", -1) == 0, "charm 스택 → 0 초기화")

func test_dead_hero_card_has_no_effect() -> void:
	print("[TestBattleManager] test_dead_hero_card_has_no_effect")
	var bm := _make_bm()
	var napoleon := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(napoleon)
	var enemy := _make_enemy(30, [])
	bm.setup_battle([enemy])
	bm.start_player_turn()

	# 나폴레옹을 사망 처리
	bm.team_mgr._hero_hp["napoleon"] = 0
	bm.team_mgr._hero_alive["napoleon"] = false

	# 사망 영웅 카드로 공격 시도
	var dmg_eff := _make_effect(EffectRes.EffectType.DAMAGE, 10, "SINGLE")
	var card := _make_card("napoleon", 0, [dmg_eff])
	bm.deck_mgr.hand.append(card)
	bm.deck_mgr.current_energy = 3
	bm.play_card(card, 0)

	_assert(bm.get_enemy_hp(0) == 30, "사망 영웅 카드 사용 시 효과 없음 → 적 HP 불변")

func test_get_hero_status_empty_by_default() -> void:
	print("[TestBattleManager] test_get_hero_status_empty_by_default")
	var bm := BattleManagerClass.new()
	var status: Dictionary = bm.get_hero_status("napoleon")
	_assert(status.is_empty(), "영웅 상태 기본값 빈 딕셔너리")

func test_get_enemy_status_after_apply() -> void:
	print("[TestBattleManager] test_get_enemy_status_after_apply")
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var bm := BattleManagerClass.new()
	var enemy = EnemyRes.new()
	enemy.enemy_name = "테스트적"
	enemy.max_hp = 30
	bm.setup_battle([enemy])
	bm._apply_status_to_enemy(0, "poison", 3)
	var status: Dictionary = bm.get_enemy_status(0)
	_assert(status.get("poison", 0) == 3, "적 상태 poison 3 조회")
	var empty: Dictionary = bm.get_enemy_status(99)
	_assert(empty.is_empty(), "범위 밖 인덱스 빈 딕셔너리")

func test_conditional_dmg_checks_owner_morale() -> void:
	print("[TestBattleManager] test_conditional_dmg_checks_owner_morale")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	var enemy := _make_enemy(100, [])
	bm.setup_battle([enemy])
	bm.start_player_turn()

	var card_no_morale := CardRes.new()
	card_no_morale.card_name = "보로디노 포격"
	card_no_morale.owner_id = "napoleon"
	card_no_morale.cost = 0
	var eff_cond := EffectRes.new()
	eff_cond.effect_type = EffectRes.EffectType.CONDITIONAL_DMG
	eff_cond.value = 14
	eff_cond.bonus_value = 20
	eff_cond.status_type = "morale"
	eff_cond.target = "SINGLE"
	card_no_morale.effects = [eff_cond]
	bm._apply_card_effects(card_no_morale, 0)
	_assert(bm.get_enemy_hp(0) == 86, "사기 0 → 14 피해 (100-14=86)")

	bm._hero_status["napoleon"] = {"morale": 1}
	bm._apply_card_effects(card_no_morale, 0)
	_assert(bm.get_enemy_hp(0) == 66, "사기 1 → 20 피해 (86-20=66)")

func test_morale_changed_signal_emitted() -> void:
	print("[TestBattleManager] test_morale_changed_signal_emitted")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	var signals_received: Array = []
	bm.morale_changed.connect(func(hid, val): signals_received.append([hid, val]))

	var card := CardRes.new()
	card.card_name = "gain_morale_test"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.GAIN_MORALE
	eff.value = 2
	card.effects = [eff]
	bm._apply_card_effects(card, -1)

	_assert(signals_received.size() == 1, "morale_changed 시그널 1회 발화")
	_assert(signals_received[0][0] == "napoleon", "hero_id = napoleon")
	_assert(signals_received[0][1] == 2, "new morale value = 2")

func test_morale_changed_emitted_on_consume_success() -> void:
	print("[TestBattleManager] test_morale_changed_emitted_on_consume_success")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()
	bm._hero_status["napoleon"] = {"morale": 3}

	var signals_received: Array = []
	bm.morale_changed.connect(func(hid, val): signals_received.append([hid, val]))

	var card := CardRes.new()
	card.card_name = "consume_test"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 3
	eff.bonus_value = 10
	card.effects = [eff]
	bm._apply_card_effects(card, 0)

	_assert(signals_received.size() == 1, "소비 성공 시 morale_changed 1회 발화")
	_assert(signals_received[0][1] == 0, "소비 후 사기 = 0")

func test_morale_changed_not_emitted_on_consume_fail() -> void:
	print("[TestBattleManager] test_morale_changed_not_emitted_on_consume_fail")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()
	bm._hero_status["napoleon"] = {"morale": 1}

	var signals_received: Array = []
	bm.morale_changed.connect(func(hid, val): signals_received.append([hid, val]))

	var card := CardRes.new()
	card.card_name = "consume_fail_test"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 3
	eff.bonus_value = 10
	card.effects = [eff]
	bm._apply_card_effects(card, 0)

	_assert(signals_received.is_empty(), "사기 부족 시 morale_changed 미발화")

func test_cost_next_reduces_next_card_cost() -> void:
	print("[TestBattleManager] test_cost_next_reduces_next_card_cost")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	var card_cn := CardRes.new()
	card_cn.card_name = "cost_next_card"
	card_cn.owner_id = "napoleon"
	card_cn.cost = 0
	var eff_cn := EffectRes.new()
	eff_cn.effect_type = EffectRes.EffectType.COST_NEXT
	eff_cn.value = 1
	card_cn.effects = [eff_cn]
	bm.deck_mgr.hand.append(card_cn)
	bm.play_card(card_cn, -1)
	_assert(bm.deck_mgr.pending_cost_reduction == 1, "COST_NEXT 사용 후 pending_cost_reduction == 1")

func test_enthrall_attacks_other_enemy() -> void:
	print("[TestBattleManager] test_enthrall_attacks_other_enemy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent := _make_intent(IntentRes.ActionType.ATTACK, 10, IntentRes.TargetType.RANDOM)
	var enemy0 := _make_enemy(50, [intent])
	var enemy1 := _make_enemy(50, [intent])
	bm.setup_battle([enemy0, enemy1])
	bm._enemy_status[0]["enthrall"] = 1  # 홀림 1턴 직접 부여
	bm.start_player_turn()
	bm.end_player_turn()

	var napoleon_hp: int = bm.team_mgr.get_current_hp("napoleon")
	var enemy1_hp: int = bm.get_enemy_hp(1)
	_assert(napoleon_hp == 60, "enemy1이 napoleon 공격 → HP 70-10=60")
	_assert(enemy1_hp == 40, "홀림된 enemy0가 enemy1 공격 → enemy1 HP 50-10=40")
	_assert(bm._enemy_status[0].get("enthrall", -1) == 0, "홀림 스택 1→0 소모")


func test_synergy_napoleon_yisunsin() -> void:
	print("[TestBattleManager] test_synergy_napoleon_yisunsin")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 50))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 50))
	bm.setup_battle([_make_enemy(50, [])])
	bm.start_player_turn()

	var card = CardRes.new()
	card.card_name = "사기_부여_테스트"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.GAIN_MORALE
	eff.value = 1
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)

	bm.play_card(card, -1)
	_assert(bm.get_hero_block("yi_sun_sin") == 3,
		"철벽 진군: 나폴레옹 GAIN_MORALE → 이순신 BLOCK +3")


func test_synergy_yisunsin_cleopatra() -> void:
	print("[TestBattleManager] test_synergy_yisunsin_cleopatra")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 50))
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(50, [])])
	bm.start_player_turn()
	bm._enemy_status[0]["poison"] = 3

	var card = CardRes.new()
	card.card_name = "공격_테스트"
	card.owner_id = "yi_sun_sin"
	card.cost = 0
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE
	eff.value = 5
	eff.target = "SINGLE"
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)

	bm.play_card(card, 0)
	_assert(bm.get_enemy_hp(0) == 41,
		"독침 반격: 이순신 DAMAGE 5 + 시너지 4 = 9 피해 → 적 HP 50-9=41")


func test_synergy_napoleon_cleopatra() -> void:
	print("[TestBattleManager] test_synergy_napoleon_cleopatra")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 50))
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(50, [])])
	bm.start_player_turn()
	if not bm._hero_status.has("napoleon"):
		bm._hero_status["napoleon"] = {}
	bm._hero_status["napoleon"]["morale"] = 3

	var card = CardRes.new()
	card.card_name = "사기소모_테스트"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 1
	eff.bonus_value = 5
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)

	bm.play_card(card, 0)
	_assert(bm._enemy_status[0].get("charm", 0) == 1,
		"혼란의 돌격: 나폴레옹 CONSUME_MORALE → 적 charm +1")


func test_synergy_napoleon_cleopatra_no_morale() -> void:
	print("[TestBattleManager] test_synergy_napoleon_cleopatra_no_morale")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 50))
	bm.team_mgr.add_hero(_make_hero("cleopatra", 50))
	bm.setup_battle([_make_enemy(50, [])])
	bm.start_player_turn()
	# morale = 0, so CONSUME_MORALE fails → no charm
	var card = CardRes.new()
	card.card_name = "사기소모_실패_테스트"
	card.owner_id = "napoleon"
	card.cost = 0
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 1
	eff.bonus_value = 5
	card.effects = [eff]
	bm.deck_mgr.hand.append(card)
	bm.play_card(card, 0)
	_assert(bm._enemy_status[0].get("charm", 0) == 0,
		"혼란의 돌격: 사기 부족 시 charm 미부여")


func test_has_synergy_bonus() -> void:
	print("[TestBattleManager] test_has_synergy_bonus")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 50))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 50))
	bm.setup_battle([_make_enemy(30, [])])

	var card = CardRes.new()
	card.owner_id = "napoleon"
	card.cost = 0
	var eff = EffectRes.new()
	eff.effect_type = EffectRes.EffectType.GAIN_MORALE
	eff.value = 2
	card.effects = [eff]
	_assert(bm.has_synergy_bonus(card) == true,
		"napoleon GAIN_MORALE + yi_sun_sin 생존 → true")

	bm.team_mgr.clear()
	bm.team_mgr.add_hero(_make_hero("napoleon", 50))
	_assert(bm.has_synergy_bonus(card) == false,
		"napoleon GAIN_MORALE 혼자 → false")

func test_enemy_status_decrements_on_enemy_turn() -> void:
	print("[TestBattleManager] test_enemy_status_decrements_on_enemy_turn")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	var intent := _make_intent(IntentRes.ActionType.BUFF, 0, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(500, [intent])])
	bm._enemy_status[0]["weak"] = 2
	bm._enemy_status[0]["vulnerable"] = 3
	bm._execute_enemy_turn()
	_assert(bm._enemy_status[0].get("weak", -1) == 1, "적 weak 2 → 1 (적 턴마다 감소)")
	_assert(bm._enemy_status[0].get("vulnerable", -1) == 2, "적 vulnerable 3 → 2 (적 턴마다 감소)")

func test_hero_status_decrements_on_player_turn() -> void:
	print("[TestBattleManager] test_hero_status_decrements_on_player_turn")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_status["napoleon"] = {"weak": 2, "vulnerable": 1}
	bm.is_battle_active = true
	bm.start_player_turn()
	_assert(bm._hero_status["napoleon"].get("weak", -1) == 1, "영웅 weak 2 → 1 (플레이어 턴마다 감소)")
	_assert(bm._hero_status["napoleon"].get("vulnerable", -1) == 0, "영웅 vulnerable 1 → 0")
