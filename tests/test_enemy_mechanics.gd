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
const InteractionSys = preload("res://autoload/enemy_interaction_system.gd")

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
	# Phase 2 — 적간 상호작용
	test_heal_ally_recovers_hp()
	test_buff_ally_strength_on_ally()
	test_interaction_no_op_when_alone()
	test_pick_lowest_hp_ally_excludes_self()
	# Phase 2 — DEATH-RATTLE
	test_death_trigger_fires_on_death()
	test_death_trigger_buff_ally_to_remaining()
	# Phase 3 — 신화 시그니처 6종
	test_signature_greek_hubris()
	test_signature_norse_ragnarok()
	test_signature_egyptian_curse_stack()
	test_signature_buddhist_karma()
	test_signature_daoist_yin_yang()
	test_signature_japanese_ward()
	test_signatures_disabled_for_easy_encounter()
	# Phase 3-3 — T3-COUNTER + T3-MARK
	test_counter_prepare_accumulates_and_consumes()
	test_counter_pool_clears_on_attack()
	test_mark_target_increases_attack_damage()
	test_mark_target_does_not_affect_unmarked_hero()
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

# ─────────────── Phase 2: 적간 상호작용 ───────────────

# HEAL_ALLY 인텐트 → 살아있는 동료 HP 회복
func test_heal_ally_recovers_hp() -> void:
	print("[TestEnemyMechanics] test_heal_ally_recovers_hp")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	# 적 0: 힐러 (HEAL_ALLY 30, LOWEST_HP 동료)
	var heal_intent := _make_intent(IntentRes.ActionType.HEAL_ALLY, 30, IntentRes.TargetType.LOWEST_HP)
	var healer := EnemyRes.new()
	healer.max_hp = 100
	healer.intent_pattern = [heal_intent]
	# 적 1: 평범 (HP 손상 상태)
	var ally_intent := _make_intent(IntentRes.ActionType.ATTACK, 5)
	var ally := EnemyRes.new()
	ally.max_hp = 100
	ally.intent_pattern = [ally_intent]
	bm.setup_battle([healer, ally])
	bm._enemy_hp[1] = 40  # 동료를 HP 40으로 손상시켜둠
	bm.start_player_turn()
	bm.end_player_turn()  # healer 턴 — HEAL_ALLY 발동
	_assert(bm._enemy_hp[1] == 70, "HEAL_ALLY 30 → 동료 HP 40 → 70 회복")

# BUFF_ALLY 인텐트 → 동료에게 strength 부여
func test_buff_ally_strength_on_ally() -> void:
	print("[TestEnemyMechanics] test_buff_ally_strength_on_ally")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var buff_intent := _make_intent(IntentRes.ActionType.BUFF_ALLY, 2)
	buff_intent.status_type = "strength"
	var buffer := EnemyRes.new()
	buffer.max_hp = 100
	buffer.intent_pattern = [buff_intent]
	var atk_intent := _make_intent(IntentRes.ActionType.ATTACK, 5)
	var ally := EnemyRes.new()
	ally.max_hp = 100
	ally.intent_pattern = [atk_intent]
	bm.setup_battle([buffer, ally])
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_status[1].get("strength", 0) == 2, "BUFF_ALLY strength 2 → 동료 strength = 2")
	_assert(bm._enemy_status[0].get("strength", 0) == 0, "buffer 자기 자신엔 부여 안 됨")

# 동료 0명일 때 HEAL_ALLY/BUFF_ALLY no-op
func test_interaction_no_op_when_alone() -> void:
	print("[TestEnemyMechanics] test_interaction_no_op_when_alone")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var heal_intent := _make_intent(IntentRes.ActionType.HEAL_ALLY, 50, IntentRes.TargetType.LOWEST_HP)
	var solo := EnemyRes.new()
	solo.max_hp = 100
	solo.intent_pattern = [heal_intent]
	bm.setup_battle([solo])
	bm._enemy_hp[0] = 30  # 자기 자신 HP 깎아둠
	bm.start_player_turn()
	bm.end_player_turn()
	_assert(bm._enemy_hp[0] == 30, "동료 없을 때 HEAL_ALLY no-op — 자기 자신 회복 X")

# pick_lowest_hp_ally가 자기 자신 제외하는지
func test_pick_lowest_hp_ally_excludes_self() -> void:
	print("[TestEnemyMechanics] test_pick_lowest_hp_ally_excludes_self")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var dummy := _make_intent(IntentRes.ActionType.ATTACK, 5)
	var e0 := EnemyRes.new(); e0.max_hp = 100; e0.intent_pattern = [dummy]
	var e1 := EnemyRes.new(); e1.max_hp = 100; e1.intent_pattern = [dummy]
	var e2 := EnemyRes.new(); e2.max_hp = 100; e2.intent_pattern = [dummy]
	bm.setup_battle([e0, e1, e2])
	bm._enemy_hp[0] = 10  # 가장 낮은 HP는 자기 자신
	bm._enemy_hp[1] = 50
	bm._enemy_hp[2] = 80
	var picked: int = InteractionSys.pick_lowest_hp_ally(bm, 0)
	_assert(picked == 1, "자기(idx 0, HP 10) 제외 → 동료 중 LOWEST_HP는 idx 1 (HP 50)")

# ─────────────── Phase 2: DEATH-RATTLE ───────────────

# 사망 시 death_trigger DEBUFF ALL 발동 → 영웅 모두 weak 부여
func test_death_trigger_fires_on_death() -> void:
	print("[TestEnemyMechanics] test_death_trigger_fires_on_death")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 100))
	var dummy := _make_intent(IntentRes.ActionType.ATTACK, 5)
	var dt := _make_intent(IntentRes.ActionType.DEBUFF, 2, IntentRes.TargetType.ALL)
	dt.status_type = "weak"
	var enemy := EnemyRes.new()
	enemy.max_hp = 30
	enemy.intent_pattern = [dummy]
	enemy.death_trigger = dt
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm._deal_damage_to_enemy(0, 30)  # 즉사
	_assert(not bm._enemy_alive[0], "적 사망")
	_assert(bm._hero_status["napoleon"].get("weak", 0) == 2, "death_trigger DEBUFF ALL → napoleon weak 2")
	_assert(bm._hero_status["yi_sun_sin"].get("weak", 0) == 2, "death_trigger DEBUFF ALL → yi_sun_sin weak 2")

# DEATH-RATTLE 의 BUFF_ALLY 가 자기 자신은 제외하고 동료에만 부여
func test_death_trigger_buff_ally_to_remaining() -> void:
	print("[TestEnemyMechanics] test_death_trigger_buff_ally_to_remaining")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var dummy := _make_intent(IntentRes.ActionType.ATTACK, 5)
	# 적 0: 죽으면 동료 strength +3
	var dt := _make_intent(IntentRes.ActionType.BUFF_ALLY, 3)
	dt.status_type = "strength"
	var dying := EnemyRes.new()
	dying.max_hp = 30
	dying.intent_pattern = [dummy]
	dying.death_trigger = dt
	# 적 1: 살아남는 동료
	var ally := EnemyRes.new()
	ally.max_hp = 100
	ally.intent_pattern = [dummy]
	bm.setup_battle([dying, ally])
	bm.start_player_turn()
	bm._deal_damage_to_enemy(0, 30)
	_assert(not bm._enemy_alive[0], "적 0 사망")
	_assert(bm._enemy_status[1].get("strength", 0) == 3, "death_trigger BUFF_ALLY → 동료 strength +3")
	_assert(bm._enemy_status[0].get("strength", 0) == 0, "사망한 자기 자신엔 부여 안 됨")

# ─────────────── Phase 3: 신화 시그니처 6종 ───────────────

func _make_signature_enemy(myth: String, hp: int = 100) -> Resource:
	var dummy := _make_intent(IntentRes.ActionType.ATTACK, 5)
	var e := EnemyRes.new()
	e.max_hp = hp
	e.mythology = myth
	e.intent_pattern = [dummy]
	e.signatures_enabled = true
	return e

# 그리스 휴브리스 — 단일 25+ 피해 받음 → 다음 턴 strength +2
func test_signature_greek_hubris() -> void:
	print("[TestEnemyMechanics] test_signature_greek_hubris")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var greek_enemy := _make_signature_enemy("greek", 200)
	bm.setup_battle([greek_enemy])
	bm.start_player_turn()
	bm._deal_damage_to_enemy(0, 30)  # 25+ 임계 충족
	_assert(bm._enemy_status[0].get("greek_hubris_pending", false), "휴브리스 pending 설정")
	bm.end_player_turn()  # 적 턴 시작 → 시그니처 발동
	_assert(bm._enemy_status[0].get("strength", 0) == 2, "다음 턴 strength +2 자동")
	_assert(not bm._enemy_status[0].get("greek_hubris_pending", false), "pending 플래그 해제")

# 북유럽 라그나로크 — HP 30% 미만 → 모든 적 strength +1 (1회)
func test_signature_norse_ragnarok() -> void:
	print("[TestEnemyMechanics] test_signature_norse_ragnarok")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var e0 := _make_signature_enemy("norse", 100)
	var e1 := _make_signature_enemy("norse", 100)
	bm.setup_battle([e0, e1])
	bm.start_player_turn()
	# e0 HP 100 → 25 (25%, < 30%)
	bm._deal_damage_to_enemy(0, 75)
	_assert(bm._enemy_status[0].get("strength", 0) == 1, "라그나로크 발동 → 자기 strength +1")
	_assert(bm._enemy_status[1].get("strength", 0) == 1, "라그나로크 발동 → 동료 strength +1")
	# 다시 한번 데미지 — 1회 제한
	bm._deal_damage_to_enemy(0, 5)
	_assert(bm._enemy_status[0].get("strength", 0) == 1, "두 번째 발동 차단 (1회 제한)")

# 이집트 저주 누적 — ATTACK 시 타겟에 vulnerable +1 자동
func test_signature_egyptian_curse_stack() -> void:
	print("[TestEnemyMechanics] test_signature_egyptian_curse_stack")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var atk := _make_intent(IntentRes.ActionType.ATTACK, 10, IntentRes.TargetType.RANDOM)
	var enemy := EnemyRes.new()
	enemy.max_hp = 100
	enemy.mythology = "egyptian"
	enemy.intent_pattern = [atk]
	enemy.signatures_enabled = true
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 ATTACK 발동
	_assert(bm._hero_status["napoleon"].get("vulnerable", 0) >= 1, "이집트 ATTACK → vulnerable 자동 부여")

# 불교 인과응보 — 사망 시 받은 누적 피해 25%를 ALL 영웅에 반환
func test_signature_buddhist_karma() -> void:
	print("[TestEnemyMechanics] test_signature_buddhist_karma")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var buddhist_enemy := _make_signature_enemy("buddhist", 100)
	bm.setup_battle([buddhist_enemy])
	bm.start_player_turn()
	bm._deal_damage_to_enemy(0, 100)  # 즉사 — damage_taken = 100
	_assert(not bm._enemy_alive[0], "불교 적 사망")
	# 25% 반환 = 25
	_assert(bm.team_mgr.get_current_hp("napoleon") == 175, "인과응보 → napoleon HP 200 - 25 = 175")

# 도교 음양 — 매 턴 공격형(strength +1) ↔ 방어형(block +15) 자동 교대
func test_signature_daoist_yin_yang() -> void:
	print("[TestEnemyMechanics] test_signature_daoist_yin_yang")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var daoist := _make_signature_enemy("daoist", 200)
	bm.setup_battle([daoist])
	bm.start_player_turn()
	bm.end_player_turn()  # 1번째 적 턴 — 공격형
	_assert(bm._enemy_status[0].get("strength", 0) == 1, "1턴 공격형 → strength +1")
	_assert(bm._enemy_status[0].get("daoist_stance", -1) == 1, "다음 자세 = 방어형")
	bm.end_player_turn()  # 2번째 적 턴 — 방어형
	_assert(bm._enemy_block[0] >= 15, "2턴 방어형 → block +15")
	_assert(bm._enemy_status[0].get("daoist_stance", -1) == 0, "다음 자세 = 공격형")

# 일본 결계 — 매 5턴마다 자기 block +20
func test_signature_japanese_ward() -> void:
	print("[TestEnemyMechanics] test_signature_japanese_ward")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var japanese := _make_signature_enemy("japanese", 300)
	bm.setup_battle([japanese])
	bm.start_player_turn()
	# 4턴 진행 — 결계 미발동
	for _t in range(4):
		bm.end_player_turn()
		bm.start_player_turn()
	_assert(bm._enemy_status[0].get("japanese_turn_count", 0) == 4, "4턴 카운트")
	_assert(bm._enemy_block[0] < 20, "5턴 전엔 결계 미발동")
	bm.end_player_turn()  # 5턴째 — 결계 발동
	_assert(bm._enemy_status[0].get("japanese_turn_count", 0) == 5, "5턴 카운트")
	_assert(bm._enemy_block[0] >= 20, "5턴마다 결계 → block +20")

# signatures_enabled = false 인 적은 모든 시그니처 미발동
func test_signatures_disabled_for_easy_encounter() -> void:
	print("[TestEnemyMechanics] test_signatures_disabled_for_easy_encounter")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	var greek_easy := _make_signature_enemy("greek", 200)
	greek_easy.signatures_enabled = false
	bm.setup_battle([greek_easy])
	bm.start_player_turn()
	bm._deal_damage_to_enemy(0, 50)
	bm.end_player_turn()
	_assert(bm._enemy_status[0].get("strength", 0) == 0, "signatures_enabled=false → 휴브리스 미발동")
	_assert(not bm._enemy_status[0].get("greek_hubris_pending", false), "pending 플래그도 미설정")

# ─────────────── Phase 3-3: T3-COUNTER + T3-MARK ───────────────

# COUNTER_PREPARE 후 받은 데미지 누적, 다음 ATTACK에 가산
func test_counter_prepare_accumulates_and_consumes() -> void:
	print("[TestEnemyMechanics] test_counter_prepare_accumulates_and_consumes")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	# 적 패턴: COUNTER_PREPARE(50%) → ATTACK(20)
	var i_counter := _make_intent(IntentRes.ActionType.COUNTER_PREPARE, 50)
	var i_atk := _make_intent(IntentRes.ActionType.ATTACK, 20)
	var enemy := EnemyRes.new()
	enemy.max_hp = 200
	enemy.intent_pattern = [i_counter, i_atk]
	enemy.signatures_enabled = false  # 시그니처 영향 배제
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # 적 턴 1: COUNTER_PREPARE 발동 (counter_ratio=0.5)
	_assert(abs(bm._enemy_status[0].get("counter_ratio", 0.0) - 0.5) < 0.001, "counter_ratio 0.5 설정")
	# 플레이어 턴: 40 데미지 → counter_pool += 20
	bm._deal_damage_to_enemy(0, 40)
	_assert(bm._enemy_status[0].get("counter_pool", 0) == 20, "counter_pool = 20 (40 × 0.5)")
	bm.end_player_turn()  # 적 턴 2: ATTACK 20 + counter 20 = 40 데미지
	_assert(bm.team_mgr.get_current_hp("napoleon") == 160, "ATTACK 20 + counter 20 = 40 데미지 (200 → 160)")

# counter_pool 소진 후 다음 ATTACK은 정상
func test_counter_pool_clears_on_attack() -> void:
	print("[TestEnemyMechanics] test_counter_pool_clears_on_attack")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var i_counter := _make_intent(IntentRes.ActionType.COUNTER_PREPARE, 100)
	var i_atk := _make_intent(IntentRes.ActionType.ATTACK, 10)
	var enemy := EnemyRes.new()
	enemy.max_hp = 200
	enemy.intent_pattern = [i_counter, i_atk, i_atk]
	enemy.signatures_enabled = false
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # COUNTER_PREPARE
	bm._deal_damage_to_enemy(0, 30)  # counter_pool += 30
	bm.end_player_turn()  # ATTACK 10 + counter 30 = 40 → napoleon HP 200-40=160
	bm.end_player_turn()  # ATTACK 10 (counter_pool 소진됨) → napoleon HP 160-10=150
	_assert(bm.team_mgr.get_current_hp("napoleon") == 150, "두 번째 ATTACK은 counter 없이 10 데미지만")
	_assert(bm._enemy_status[0].get("counter_pool", 0) == 0, "counter_pool 0 유지")

# MARK_TARGET → 마킹된 영웅 공격 시 +50%
func test_mark_target_increases_attack_damage() -> void:
	print("[TestEnemyMechanics] test_mark_target_increases_attack_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	var i_mark := _make_intent(IntentRes.ActionType.MARK_TARGET, 0, IntentRes.TargetType.LOWEST_HP)
	var i_atk := _make_intent(IntentRes.ActionType.ATTACK, 40, IntentRes.TargetType.LOWEST_HP)
	var enemy := EnemyRes.new()
	enemy.max_hp = 200
	enemy.intent_pattern = [i_mark, i_atk]
	enemy.signatures_enabled = false
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # MARK 발동
	_assert(bm._hero_status.get("napoleon", {}).get("marked_by", []).has(0), "napoleon에 marked_by[0] 추가")
	bm.end_player_turn()  # ATTACK 40 × 1.5 = 60 → napoleon HP 140
	_assert(bm.team_mgr.get_current_hp("napoleon") == 140, "마킹된 영웅 공격 → 40 × 1.5 = 60 데미지")

# 마킹 안 된 영웅엔 보너스 미적용
func test_mark_target_does_not_affect_unmarked_hero() -> void:
	print("[TestEnemyMechanics] test_mark_target_does_not_affect_unmarked_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 200))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 50))  # LOWEST_HP — 마킹 대상
	var i_mark := _make_intent(IntentRes.ActionType.MARK_TARGET, 0, IntentRes.TargetType.LOWEST_HP)
	# napoleon 타겟 ATTACK (마킹 안 됨)
	var i_atk_napoleon := IntentRes.new()
	i_atk_napoleon.action_type = IntentRes.ActionType.ATTACK
	i_atk_napoleon.value = 40
	i_atk_napoleon.target = IntentRes.TargetType.LAST_ATTACKER  # 가짜 타겟 — 첫 사이클엔 random fallback
	var enemy := EnemyRes.new()
	enemy.max_hp = 200
	enemy.intent_pattern = [i_mark]
	enemy.signatures_enabled = false
	bm.setup_battle([enemy])
	bm.start_player_turn()
	bm.end_player_turn()  # MARK yi_sun_sin
	_assert(bm._hero_status.get("yi_sun_sin", {}).get("marked_by", []).has(0), "yi_sun_sin 마킹됨")
	_assert(not bm._hero_status.get("napoleon", {}).get("marked_by", []).has(0), "napoleon은 미마킹")
