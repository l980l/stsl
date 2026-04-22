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
