# tests/test_card_effects_engine.gd
# 엔진 확장 효과 테스트 — ON_KILL_DRAW, PURGE_STATUS, PER_DRAW_DMG, CONDITIONAL 신규 조건, condition 필드
class_name TestCardEffectsEngine
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
var _to_free: Array = []

func run_all() -> Dictionary:
	test_on_kill_draw_single_kill()
	test_on_kill_draw_no_kill()
	test_purge_status_all()
	test_per_draw_dmg_zero_draws()
	test_per_draw_dmg_two_draws()
	test_conditional_dmg_enemy_hp_below_30()
	test_conditional_dmg_enemy_hp_below_30_false()
	test_conditional_dmg_dead_ally_count()
	test_effect_condition_skip_when_false()
	test_effect_condition_apply_when_true()
	# M6-5c 신규 10종
	test_damage_per_block_happy()
	test_damage_per_block_zero_block()
	test_damage_per_dead_ally_happy()
	test_damage_per_dead_ally_no_dead()
	test_double_next_damage_happy()
	test_double_next_damage_no_power()
	test_double_next_damage_cross_hero()
	test_double_next_damage_poison_tick()
	test_exhaust_draw_happy()
	test_exhaust_draw_empty_hand()
	test_morale_to_block_happy()
	test_morale_to_block_no_morale()
	test_damage_per_hand_size_happy()
	test_damage_per_hand_size_empty_hand()
	test_damage_per_token_happy()
	test_damage_per_token_no_tokens()
	test_heal_per_dead_ally_happy()
	test_heal_per_dead_ally_no_dead()
	test_energy_to_damage_happy()
	test_energy_to_damage_no_energy()
	test_status_double_happy()
	test_status_double_no_status()
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
		print("  FAIL: " + msg)

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

func _make_enemy(hp: int) -> Resource:
	var e := EnemyRes.new()
	e.enemy_name = "더미"
	e.max_hp = hp
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.BUFF
	intent.value = 0
	e.intent_pattern = [intent]
	return e

func _make_card(owner_id: String, effects: Array) -> Resource:
	var c := CardRes.new()
	c.card_name = "테스트 카드"
	c.owner_id = owner_id
	c.cost = 0
	c.effects = effects
	return c

# ─────────────────────────────────────────────────
# 1. ON_KILL_DRAW — 처치 시 드로우
# ─────────────────────────────────────────────────

func test_on_kill_draw_single_kill() -> void:
	print("[TestCardEffectsEngine] test_on_kill_draw_single_kill")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(100)])
	# 초기 핸드에 카드 2장 추가
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	bm.deck_mgr.hand.append(dummy_card)
	bm.deck_mgr.hand.append(dummy_card)
	var hand_before: int = bm.deck_mgr.hand.size()
	# DMG 200으로 HP 100 적 처치 + ON_KILL_DRAW 1
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.DAMAGE
	eff_dmg.value = 200; eff_dmg.base_value = 200; eff_dmg.target = "SINGLE"
	var eff_draw := EffectRes.new()
	eff_draw.effect_type = EffectRes.EffectType.ON_KILL_DRAW
	eff_draw.value = 1; eff_draw.base_value = 1
	# 덱에 드로우할 카드 채워두기
	for _i in range(5):
		bm.deck_mgr.draw_pile.append(dummy_card)
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dmg, eff_draw]), 0)
	var hand_after: int = bm.deck_mgr.hand.size()
	_assert(hand_after == hand_before + 1, "ON_KILL_DRAW: 처치 후 핸드 1장 증가 (%d → %d)" % [hand_before, hand_after])

func test_on_kill_draw_no_kill() -> void:
	print("[TestCardEffectsEngine] test_on_kill_draw_no_kill")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	bm.deck_mgr.hand.append(dummy_card)
	var hand_before: int = bm.deck_mgr.hand.size()
	# DMG 200, HP 500 → 처치 안됨
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.DAMAGE
	eff_dmg.value = 200; eff_dmg.base_value = 200; eff_dmg.target = "SINGLE"
	var eff_draw := EffectRes.new()
	eff_draw.effect_type = EffectRes.EffectType.ON_KILL_DRAW
	eff_draw.value = 1; eff_draw.base_value = 1
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dmg, eff_draw]), 0)
	_assert(bm.deck_mgr.hand.size() == hand_before, "ON_KILL_DRAW: 처치 없으면 핸드 변화 없음")

# ─────────────────────────────────────────────────
# 2. PURGE_STATUS
# ─────────────────────────────────────────────────

func test_purge_status_all() -> void:
	print("[TestCardEffectsEngine] test_purge_status_all")
	var bm := _make_bm()
	var hero := _make_hero("joan_of_arc", 1000)
	bm.team_mgr.add_hero(hero)
	bm.setup_battle([_make_enemy(100)])
	# 영웅에 디버프 수동 설정
	bm._hero_status["joan_of_arc"] = {"poison_dmg": 3, "weak": 2, "morale": 5}
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.PURGE_STATUS
	eff.target = "ALL"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), 0)
	var status_after: Dictionary = bm._hero_status.get("joan_of_arc", {})
	_assert(status_after.get("poison_dmg", 0) == 0 or not status_after.has("poison_dmg"), "PURGE_STATUS: poison_dmg 제거됨")
	_assert(status_after.get("weak", 0) == 0 or not status_after.has("weak"), "PURGE_STATUS: weak 제거됨")
	# morale은 디버프 목록에 없으므로 유지
	_assert(status_after.get("morale", 0) == 5, "PURGE_STATUS: morale은 유지됨")

# ─────────────────────────────────────────────────
# 3. PER_DRAW_DMG
# ─────────────────────────────────────────────────

func test_per_draw_dmg_zero_draws() -> void:
	print("[TestCardEffectsEngine] test_per_draw_dmg_zero_draws")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 드로우 카운터 0 (턴 시작 시 리셋 상태)
	bm._cards_drawn_this_turn = 0
	var hp_before: int = bm.get_enemy_hp(0)
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.PER_DRAW_DMG
	eff.value = 30; eff.base_value = 30; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == hp_before, "PER_DRAW_DMG: 드로우 0회 시 피해 없음")

func test_per_draw_dmg_two_draws() -> void:
	print("[TestCardEffectsEngine] test_per_draw_dmg_two_draws")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# DRAW 2 카드 먼저 실행
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	for _i in range(5):
		bm.deck_mgr.draw_pile.append(dummy_card)
	var eff_draw := EffectRes.new()
	eff_draw.effect_type = EffectRes.EffectType.DRAW
	eff_draw.value = 2; eff_draw.base_value = 2
	bm._apply_card_effects(_make_card("genghis_khan", [eff_draw]), -1)
	# 이제 PER_DRAW_DMG value=30 실행 → 2×30=60 피해
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.PER_DRAW_DMG
	eff_dmg.value = 30; eff_dmg.base_value = 30; eff_dmg.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dmg]), 0)
	_assert(bm.get_enemy_hp(0) == 440, "PER_DRAW_DMG: 드로우 2회 × 30 = 60 피해 (500→440)")

# ─────────────────────────────────────────────────
# 4. CONDITIONAL_DMG 신규 조건
# ─────────────────────────────────────────────────

func test_conditional_dmg_enemy_hp_below_30() -> void:
	print("[TestCardEffectsEngine] test_conditional_dmg_enemy_hp_below_30")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(1000)])
	# 적 HP를 max_hp의 20%로 설정 (200/1000 = 20% ≤ 30% 조건 충족)
	bm._enemy_hp[0] = 200
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONDITIONAL_DMG
	eff.value = 50; eff.base_value = 50
	eff.bonus_value = 150; eff.base_bonus_value = 150
	eff.status_type = "enemy_hp_below_30"; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	# bonus_value 150 적용 (200-150=50)
	_assert(bm.get_enemy_hp(0) == 50, "enemy_hp_below_30: 조건 충족(20%) → bonus_value 150 적용 (200→50)")

func test_conditional_dmg_enemy_hp_below_30_false() -> void:
	print("[TestCardEffectsEngine] test_conditional_dmg_enemy_hp_below_30_false")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(1000)])
	# 적 HP 60% (600/1000 — 조건 불충족)
	bm._enemy_hp[0] = 600
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONDITIONAL_DMG
	eff.value = 50; eff.base_value = 50
	eff.bonus_value = 150; eff.base_bonus_value = 150
	eff.status_type = "enemy_hp_below_30"; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	# value 50 적용 (600-50=550)
	_assert(bm.get_enemy_hp(0) == 550, "enemy_hp_below_30: 조건 불충족(60%) → value 50 적용 (600→550)")

func test_conditional_dmg_dead_ally_count() -> void:
	print("[TestCardEffectsEngine] test_conditional_dmg_dead_ally_count")
	var bm := _make_bm()
	var joan := _make_hero("joan_of_arc", 1000)
	var ally1 := _make_hero("napoleon", 1000)
	var ally2 := _make_hero("cleopatra", 1000)
	bm.team_mgr.add_hero(joan)
	bm.team_mgr.add_hero(ally1)
	bm.team_mgr.add_hero(ally2)
	bm.setup_battle([_make_enemy(2000)])
	# 아군 2명 사망
	bm.team_mgr.take_damage("napoleon", 1000)
	bm.team_mgr.take_damage("cleopatra", 1000)
	_assert(not bm.team_mgr.is_alive("napoleon"), "나폴레옹 사망 전제")
	_assert(not bm.team_mgr.is_alive("cleopatra"), "클레오파트라 사망 전제")
	# dead_ally_count: value=100, bonus_value=50 → 100 + 50×2 = 200 피해
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONDITIONAL_DMG
	eff.value = 100; eff.base_value = 100
	eff.bonus_value = 50; eff.base_bonus_value = 50
	eff.status_type = "dead_ally_count"; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 1800, "dead_ally_count: 100 + 50×2 = 200 피해 (2000→1800)")

# ─────────────────────────────────────────────────
# 5. condition 필드 테스트
# ─────────────────────────────────────────────────

func test_effect_condition_skip_when_false() -> void:
	print("[TestCardEffectsEngine] test_effect_condition_skip_when_false")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 핸드에 카드 1장 있음 → hand_size_0 조건 불충족 → BLOCK 미발동
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	bm.deck_mgr.hand.append(dummy_card)
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.BLOCK
	eff.value = 100; eff.base_value = 100
	eff.condition = "hand_size_0"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm._hero_block.get("musashi", 0) == 0, "condition=hand_size_0: 핸드 비어있지 않음 → BLOCK 미발동")

func test_effect_condition_apply_when_true() -> void:
	print("[TestCardEffectsEngine] test_effect_condition_apply_when_true")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 핸드 비어있음 → hand_size_0 조건 충족 → BLOCK 발동
	bm.deck_mgr.hand.clear()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.BLOCK
	eff.value = 100; eff.base_value = 100
	eff.condition = "hand_size_0"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm._hero_block.get("musashi", 0) == 100, "condition=hand_size_0: 핸드 비어있음 → BLOCK 100 발동")

# ─────────────────────────────────────────────────
# M6-5c 신규 10종
# ─────────────────────────────────────────────────

# 6. DAMAGE_PER_BLOCK
func test_damage_per_block_happy() -> void:
	print("[TestCardEffectsEngine] test_damage_per_block_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 블록 200, value=100 → 200 * 100 / 100 = 200 피해
	bm._hero_block["musashi"] = 200
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_BLOCK
	eff.value = 100; eff.base_value = 100; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 300, "DAMAGE_PER_BLOCK: 블록 200 × 100% = 200 피해 (500→300)")

func test_damage_per_block_zero_block() -> void:
	print("[TestCardEffectsEngine] test_damage_per_block_zero_block")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 블록 0 → 피해 없음
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_BLOCK
	eff.value = 100; eff.base_value = 100; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 500, "DAMAGE_PER_BLOCK: 블록 0 → 피해 없음")

# 7. DAMAGE_PER_DEAD_ALLY
func test_damage_per_dead_ally_happy() -> void:
	print("[TestCardEffectsEngine] test_damage_per_dead_ally_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 1000))
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.team_mgr.add_hero(_make_hero("musashi", 100))
	bm.setup_battle([_make_enemy(500)])
	# 아군 2명 사망
	bm.team_mgr.take_damage("napoleon", 100)
	bm.team_mgr.take_damage("musashi", 100)
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY
	eff.value = 12; eff.base_value = 12; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), 0)
	# 사망 2 × 12 = 24 피해
	_assert(bm.get_enemy_hp(0) == 476, "DAMAGE_PER_DEAD_ALLY: 사망 2 × 12 = 24 피해 (500→476)")

func test_damage_per_dead_ally_no_dead() -> void:
	print("[TestCardEffectsEngine] test_damage_per_dead_ally_no_dead")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 1000))
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 모두 생존 → 피해 없음
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY
	eff.value = 12; eff.base_value = 12; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 500, "DAMAGE_PER_DEAD_ALLY: 사망 아군 없음 → 피해 없음")

# 8. DOUBLE_NEXT_DAMAGE
func test_double_next_damage_happy() -> void:
	print("[TestCardEffectsEngine] test_double_next_damage_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# DOUBLE_NEXT_DAMAGE 등록
	var eff_dnd := EffectRes.new()
	eff_dnd.effect_type = EffectRes.EffectType.DOUBLE_NEXT_DAMAGE
	eff_dnd.value = 0
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dnd]), -1)
	# 파워 등록 확인
	_assert(bm._active_powers.has("power.double_next_damage:__global__"), "DOUBLE_NEXT_DAMAGE: 글로벌 파워 슬롯 등록됨")
	# 다음 DAMAGE 50 → ×2 = 100 피해
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.DAMAGE
	eff_dmg.value = 50; eff_dmg.base_value = 50; eff_dmg.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dmg]), 0)
	_assert(bm.get_enemy_hp(0) == 400, "DOUBLE_NEXT_DAMAGE: 50 × 2 = 100 피해 (500→400)")
	# 파워 소비 후 사라졌는지 확인
	_assert(not bm._active_powers.has("power.double_next_damage:__global__"), "DOUBLE_NEXT_DAMAGE: 파워 1회 소비 후 제거됨")

func test_double_next_damage_no_power() -> void:
	print("[TestCardEffectsEngine] test_double_next_damage_no_power")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 파워 없이 DAMAGE → 배율 없음
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.DAMAGE
	eff_dmg.value = 50; eff_dmg.base_value = 50; eff_dmg.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dmg]), 0)
	_assert(bm.get_enemy_hp(0) == 450, "DOUBLE_NEXT_DAMAGE: 파워 없으면 배율 미적용 (500→450)")

func test_double_next_damage_cross_hero() -> void:
	print("[TestCardEffectsEngine] test_double_next_damage_cross_hero")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 징기스칸이 DOUBLE_NEXT_DAMAGE 등록
	var eff_dnd := EffectRes.new()
	eff_dnd.effect_type = EffectRes.EffectType.DOUBLE_NEXT_DAMAGE
	eff_dnd.value = 0
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dnd]), -1)
	# 잔다르크 카드의 DAMAGE 50 → 글로벌 파워로 ×2 = 100
	var eff_dmg := EffectRes.new()
	eff_dmg.effect_type = EffectRes.EffectType.DAMAGE
	eff_dmg.value = 50; eff_dmg.base_value = 50; eff_dmg.target = "SINGLE"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff_dmg]), 0)
	_assert(bm.get_enemy_hp(0) == 400, "DOUBLE_NEXT_DAMAGE: cross-hero — 잔다르크 50 × 2 = 100 피해 (500→400)")
	_assert(not bm._active_powers.has("power.double_next_damage:__global__"), "DOUBLE_NEXT_DAMAGE: cross-hero 소비 후 파워 제거됨")

func test_double_next_damage_poison_tick() -> void:
	print("[TestCardEffectsEngine] test_double_next_damage_poison_tick")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# poison 2스택 (POISON_DMG_PER_STACK=5이므로 tick_dmg=10)
	bm._enemy_status[0]["poison_dmg"] = 2
	bm._enemy_status[0]["poison_dur"] = 3
	# DOUBLE_NEXT_DAMAGE 등록
	var eff_dnd := EffectRes.new()
	eff_dnd.effect_type = EffectRes.EffectType.DOUBLE_NEXT_DAMAGE
	eff_dnd.value = 0
	bm._apply_card_effects(_make_card("genghis_khan", [eff_dnd]), -1)
	# poison tick → 2스택 × 10 = 20, ×2 = 40 피해
	bm._tick_enemy_poison(0)
	_assert(bm.get_enemy_hp(0) == 460, "DOUBLE_NEXT_DAMAGE: poison tick 20 × 2 = 40 피해 (500→460)")
	_assert(not bm._active_powers.has("power.double_next_damage:__global__"), "DOUBLE_NEXT_DAMAGE: poison tick 소비 후 파워 제거됨")

# 9. DISCARD_PICK_DRAW
func test_exhaust_draw_happy() -> void:
	print("[TestCardEffectsEngine] test_discard_pick_draw_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 1000))
	bm.setup_battle([_make_enemy(500)])
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	# 핸드 3장, 드로우 파일 3장
	for _i in range(3):
		bm.deck_mgr.hand.append(dummy_card)
		bm.deck_mgr.draw_pile.append(dummy_card)
	# DISCARD_PICK_DRAW value=2 → 시그널 emit 후 _pending_discard_pick 등록
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DISCARD_PICK_DRAW
	eff.value = 2; eff.base_value = 2
	bm._apply_card_effects(_make_card("yi_sun_sin", [eff]), -1)
	_assert(not bm._pending_discard_pick.is_empty(), "DISCARD_PICK_DRAW: 모달 대기 상태 등록됨")
	# resolve_pending_discard_pick 호출 시뮬레이션 (버리기 버튼 클릭)
	var picked := bm.deck_mgr.hand[0]
	var hand_before: int = bm.deck_mgr.hand.size()
	var energy_before: int = bm.deck_mgr.current_energy
	bm.resolve_pending_discard_pick(picked)
	# 핸드: hand_before - 1(버림) + 2(드로우) = hand_before + 1
	_assert(bm.deck_mgr.hand.size() == hand_before + 1, "DISCARD_PICK_DRAW: 1장 버리고 2장 드로우 (핸드 +1)")
	_assert(bm.deck_mgr.discard_pile.has(picked), "DISCARD_PICK_DRAW: 선택 카드 discard_pile에 이동됨")
	_assert(bm.deck_mgr.current_energy == energy_before + 1, "DISCARD_PICK_DRAW: 에너지 +1")
	_assert(bm._pending_discard_pick.is_empty(), "DISCARD_PICK_DRAW: resolve 후 pending 초기화됨")

func test_exhaust_draw_empty_hand() -> void:
	print("[TestCardEffectsEngine] test_discard_pick_draw_empty_hand")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 핸드 비어있음 → 모달 미표시 (pending 등록 안 됨)
	bm.deck_mgr.hand.clear()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DISCARD_PICK_DRAW
	eff.value = 2; eff.base_value = 2
	bm._apply_card_effects(_make_card("yi_sun_sin", [eff]), -1)
	_assert(bm._pending_discard_pick.is_empty(), "DISCARD_PICK_DRAW: 핸드 비어있으면 pending 등록 안 됨")

# 10. MORALE_TO_BLOCK
func test_morale_to_block_happy() -> void:
	print("[TestCardEffectsEngine] test_morale_to_block_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 사기 5, value=1 → 블록 5
	bm._hero_status["napoleon"] = {"morale": 5}
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.MORALE_TO_BLOCK
	eff.value = 1; eff.base_value = 1; eff.target = "SELF"
	bm._apply_card_effects(_make_card("napoleon", [eff]), -1)
	_assert(bm._hero_block.get("napoleon", 0) == 5, "MORALE_TO_BLOCK: 사기 5 × 1 = 블록 5")

func test_morale_to_block_no_morale() -> void:
	print("[TestCardEffectsEngine] test_morale_to_block_no_morale")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 사기 0 → 블록 없음
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.MORALE_TO_BLOCK
	eff.value = 1; eff.base_value = 1; eff.target = "SELF"
	bm._apply_card_effects(_make_card("napoleon", [eff]), -1)
	_assert(bm._hero_block.get("napoleon", 0) == 0, "MORALE_TO_BLOCK: 사기 0 → 블록 없음")

# 11. DAMAGE_PER_HAND_SIZE
func test_damage_per_hand_size_happy() -> void:
	print("[TestCardEffectsEngine] test_damage_per_hand_size_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 핸드 3장, value=4 → 12 피해
	var dummy_card := CardRes.new(); dummy_card.card_name = "dummy"; dummy_card.cost = 0; dummy_card.effects = []
	for _i in range(3):
		bm.deck_mgr.hand.append(dummy_card)
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_HAND_SIZE
	eff.value = 4; eff.base_value = 4; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 488, "DAMAGE_PER_HAND_SIZE: 핸드 3 × 4 = 12 피해 (500→488)")

func test_damage_per_hand_size_empty_hand() -> void:
	print("[TestCardEffectsEngine] test_damage_per_hand_size_empty_hand")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("musashi", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 핸드 비어있음 → 피해 없음
	bm.deck_mgr.hand.clear()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_HAND_SIZE
	eff.value = 4; eff.base_value = 4; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("musashi", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 500, "DAMAGE_PER_HAND_SIZE: 핸드 0 → 피해 없음")

# 12. DAMAGE_PER_TOKEN
func test_damage_per_token_happy() -> void:
	print("[TestCardEffectsEngine] test_damage_per_token_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 토큰 3, value=5 → 15 피해
	bm._hero_status["napoleon"] = {"tokens": 3}
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_TOKEN
	eff.value = 5; eff.base_value = 5; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("napoleon", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 485, "DAMAGE_PER_TOKEN: 토큰 3 × 5 = 15 피해 (500→485)")

func test_damage_per_token_no_tokens() -> void:
	print("[TestCardEffectsEngine] test_damage_per_token_no_tokens")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 토큰 0 → 피해 없음
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.DAMAGE_PER_TOKEN
	eff.value = 5; eff.base_value = 5; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("napoleon", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 500, "DAMAGE_PER_TOKEN: 토큰 0 → 피해 없음")

# 13. HEAL_PER_DEAD_ALLY
func test_heal_per_dead_ally_happy() -> void:
	print("[TestCardEffectsEngine] test_heal_per_dead_ally_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 1000))
	bm.team_mgr.add_hero(_make_hero("napoleon", 100))
	bm.setup_battle([_make_enemy(500)])
	# 나폴레옹 사망, 잔다르크 HP 감소
	bm.team_mgr.take_damage("napoleon", 100)
	bm.team_mgr.take_damage("joan_of_arc", 200)
	var joan_hp_before: int = bm.team_mgr.get_current_hp("joan_of_arc")
	# HEAL_PER_DEAD_ALLY value=8, 사망 1 → 회복 8
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.HEAL_PER_DEAD_ALLY
	eff.value = 8; eff.base_value = 8; eff.target = "SELF"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), -1)
	_assert(bm.team_mgr.get_current_hp("joan_of_arc") == joan_hp_before + 8, "HEAL_PER_DEAD_ALLY: 사망 1 × 8 = 8 회복")

func test_heal_per_dead_ally_no_dead() -> void:
	print("[TestCardEffectsEngine] test_heal_per_dead_ally_no_dead")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("joan_of_arc", 1000))
	bm.team_mgr.add_hero(_make_hero("napoleon", 1000))
	bm.setup_battle([_make_enemy(500)])
	bm.team_mgr.take_damage("joan_of_arc", 200)
	var joan_hp_before: int = bm.team_mgr.get_current_hp("joan_of_arc")
	# 사망 아군 없음 → 회복 없음
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.HEAL_PER_DEAD_ALLY
	eff.value = 8; eff.base_value = 8; eff.target = "SELF"
	bm._apply_card_effects(_make_card("joan_of_arc", [eff]), -1)
	_assert(bm.team_mgr.get_current_hp("joan_of_arc") == joan_hp_before, "HEAL_PER_DEAD_ALLY: 사망 아군 없음 → 회복 없음")

# 14. ENERGY_TO_DAMAGE
func test_energy_to_damage_happy() -> void:
	print("[TestCardEffectsEngine] test_energy_to_damage_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 에너지 3, value=6 → 18 피해, 에너지 0
	bm.deck_mgr.current_energy = 3
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.ENERGY_TO_DAMAGE
	eff.value = 6; eff.base_value = 6; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 482, "ENERGY_TO_DAMAGE: 에너지 3 × 6 = 18 피해 (500→482)")
	_assert(bm.deck_mgr.current_energy == 0, "ENERGY_TO_DAMAGE: 사용 후 에너지 0")

func test_energy_to_damage_no_energy() -> void:
	print("[TestCardEffectsEngine] test_energy_to_damage_no_energy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("genghis_khan", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 에너지 0 → 피해 없음
	bm.deck_mgr.current_energy = 0
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.ENERGY_TO_DAMAGE
	eff.value = 6; eff.base_value = 6; eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("genghis_khan", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 500, "ENERGY_TO_DAMAGE: 에너지 0 → 피해 없음")

# 15. STATUS_DOUBLE
func test_status_double_happy() -> void:
	print("[TestCardEffectsEngine] test_status_double_happy")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 적에게 상태이상 설정
	bm._enemy_status[0] = {"poison_dmg": 4, "weak": 2, "vulnerable": 0, "charm": 0}
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.STATUS_DOUBLE
	eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("cleopatra", [eff]), 0)
	_assert(bm._enemy_status[0].get("poison_dmg", 0) == 8, "STATUS_DOUBLE: poison_dmg 4 → 8")
	_assert(bm._enemy_status[0].get("weak", 0) == 4, "STATUS_DOUBLE: weak 2 → 4")
	_assert(bm._enemy_status[0].get("vulnerable", 0) == 0, "STATUS_DOUBLE: vulnerable 0은 변화 없음")

func test_status_double_no_status() -> void:
	print("[TestCardEffectsEngine] test_status_double_no_status")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 1000))
	bm.setup_battle([_make_enemy(500)])
	# 상태이상 없음 → 크래시 없이 통과
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.STATUS_DOUBLE
	eff.target = "SINGLE"
	bm._apply_card_effects(_make_card("cleopatra", [eff]), 0)
	_assert(bm._enemy_status[0].get("poison_dmg", 0) == 0, "STATUS_DOUBLE: 상태이상 없으면 크래시 없이 0 유지")
