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
	test_hero_damaged_not_emitted_when_fully_blocked()
	test_enemy_damaged_not_emitted_when_fully_blocked()
	test_harpy_special_removes_from_deck()
	test_charm_skips_enemy_turn()
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
	var enemy := _make_enemy(30, [intent])
	bm.setup_battle([enemy])
	bm._enemy_status[0]["poison"] = 3

	bm._execute_enemy_turn()
	_assert(bm.get_enemy_hp(0) == 27, "독 3 틱 → HP 30 → 27")
	_assert(bm._enemy_status[0].get("poison", -1) == 2, "독 스택 3 → 2")

func test_poison_tick_hero() -> void:
	print("[TestBattleManager] test_poison_tick_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30, [])])
	bm._hero_status["napoleon"] = {"poison": 4}
	bm.is_battle_active = true

	bm.start_player_turn()
	_assert(bm.team_mgr.get_current_hp("napoleon") == 66, "독 4 틱 → HP 70 → 66")
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

func test_hero_damaged_not_emitted_when_fully_blocked() -> void:
	print("[TestBattleManager] test_hero_damaged_not_emitted_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	# 블록 10 부여
	bm._hero_block["napoleon"] = 10

	var damage_emitted: Array = []
	bm.hero_damaged.connect(func(id, amt): damage_emitted.append(amt))

	# 피해 10 → 블록 10이 전부 흡수 → amount == 0
	bm._deal_damage_to_hero("napoleon", 10)
	_assert(damage_emitted.is_empty(), "블록 완전 흡수 시 hero_damaged 발화 없음")
	_assert(bm.team_mgr.get_current_hp("napoleon") == 70, "HP 변화 없음")

func test_enemy_damaged_not_emitted_when_fully_blocked() -> void:
	print("[TestBattleManager] test_enemy_damaged_not_emitted_when_fully_blocked")
	var bm := _make_bm()
	var hero := _make_hero("napoleon", 70)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(30, [])])
	bm.start_player_turn()

	# 적 블록 10 부여
	bm._enemy_block[0] = 10

	var damage_emitted: Array = []
	bm.enemy_damaged.connect(func(idx, amt): damage_emitted.append(amt))

	# 피해 10 → 블록 10이 전부 흡수
	bm._deal_damage_to_enemy(0, 10)
	_assert(damage_emitted.is_empty(), "블록 완전 흡수 시 enemy_damaged 발화 없음")
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

func test_charm_skips_enemy_turn() -> void:
	print("[TestBattleManager] test_charm_skips_enemy_turn")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	var intent := _make_intent(IntentRes.ActionType.ATTACK, 10, IntentRes.TargetType.RANDOM)
	bm.setup_battle([_make_enemy(30, [intent])])
	bm._enemy_status[0]["charm"] = 1
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 — charm 있으므로 공격 스킵
	_assert(bm.team_mgr.get_current_hp("napoleon") == 70, "charm 상태 시 적 공격 스킵 → HP 불변")
	_assert(bm._enemy_status[0].get("charm", -1) == 0, "charm 스택 1→0 감소")
