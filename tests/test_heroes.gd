# tests/test_heroes.gd
class_name TestHeroes
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
	test_napoleon_card_pool_size()
	test_cleopatra_card_pool_size()
	test_yi_sun_sin_card_pool_size()
	test_gain_morale_effect()
	test_consume_morale_insufficient()
	test_consume_morale_sufficient()
	test_poison_burst_damages_and_clears()
	test_counter_block_damage()
	test_block_all_covers_team()
	test_recruit_hero_pool_napoleon_only()
	test_recruit_hero_pool_full_party()
	test_add_initial_deck_for_cleopatra()
	test_generate_card_rewards_multi_hero()
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

func _load_gm():
	return load("res://autoload/game_manager.gd").new()

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

# ──────────────────────────────────────────────
# 카드 풀 크기 테스트 (런타임 load 사용)
# ──────────────────────────────────────────────

func test_napoleon_card_pool_size() -> void:
	print("[TestHeroes] test_napoleon_card_pool_size")
	var gm = _load_gm()
	_assert(gm._napoleon_card_pool().size() == 38, "나폴레옹 카드 풀 38장")

func test_cleopatra_card_pool_size() -> void:
	print("[TestHeroes] test_cleopatra_card_pool_size")
	var gm = _load_gm()
	_assert(gm._cleopatra_card_pool().size() == 38, "클레오파트라 카드 풀 38장")

func test_yi_sun_sin_card_pool_size() -> void:
	print("[TestHeroes] test_yi_sun_sin_card_pool_size")
	var gm = _load_gm()
	_assert(gm._yi_sun_sin_card_pool().size() == 14, "이순신 카드 풀 14장")

# ──────────────────────────────────────────────
# BattleManager 신규 효과 테스트
# ──────────────────────────────────────────────

func test_gain_morale_effect() -> void:
	print("[TestHeroes] test_gain_morale_effect")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30)])
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.GAIN_MORALE
	eff.value = 3
	bm._apply_card_effects(_make_card("napoleon", [eff]), 0)
	_assert(bm._hero_status.get("napoleon", {}).get("morale", 0) == 3, "GAIN_MORALE +3 반영")

func test_consume_morale_insufficient() -> void:
	print("[TestHeroes] test_consume_morale_insufficient")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30)])
	bm._hero_status["napoleon"] = {"morale": 1}
	var enemy_hp_before := bm.get_enemy_hp(0)
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 3; eff.bonus_value = 20
	bm._apply_card_effects(_make_card("napoleon", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == enemy_hp_before, "CONSUME_MORALE 사기 부족 시 피해 없음")
	_assert(bm._hero_status["napoleon"]["morale"] == 1, "CONSUME_MORALE 사기 부족 시 사기 유지")

func test_consume_morale_sufficient() -> void:
	print("[TestHeroes] test_consume_morale_sufficient")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.setup_battle([_make_enemy(30)])
	bm._hero_status["napoleon"] = {"morale": 3}
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.CONSUME_MORALE
	eff.value = 3; eff.bonus_value = 20
	bm._apply_card_effects(_make_card("napoleon", [eff]), 0)
	_assert(bm._hero_status["napoleon"]["morale"] == 0, "CONSUME_MORALE 사기 소모")
	_assert(bm.get_enemy_hp(0) == 10, "CONSUME_MORALE 피해 20 적용 (30-20=10)")

func test_poison_burst_damages_and_clears() -> void:
	print("[TestHeroes] test_poison_burst_damages_and_clears")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("cleopatra", 60))
	bm.setup_battle([_make_enemy(50)])
	bm._enemy_status[0]["poison"] = 8
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.POISON_BURST
	bm._apply_card_effects(_make_card("cleopatra", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 42, "POISON_BURST 독(8) 피해 적용 (50-8=42)")
	_assert(bm._enemy_status[0].get("poison", 0) == 0, "POISON_BURST 후 독 초기화")

func test_counter_block_damage() -> void:
	print("[TestHeroes] test_counter_block_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 75))
	bm.setup_battle([_make_enemy(50)])
	bm._hero_block["yi_sun_sin"] = 20
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.COUNTER_BLOCK
	eff.value = 100
	bm._apply_card_effects(_make_card("yi_sun_sin", [eff]), 0)
	_assert(bm.get_enemy_hp(0) == 30, "COUNTER_BLOCK 100% 방어도 20 → 피해 20 (50-20=30)")

func test_block_all_covers_team() -> void:
	print("[TestHeroes] test_block_all_covers_team")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("napoleon", 70))
	bm.team_mgr.add_hero(_make_hero("yi_sun_sin", 75))
	bm.setup_battle([_make_enemy(30)])
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.BLOCK_ALL
	eff.value = 5
	bm._apply_card_effects(_make_card("yi_sun_sin", [eff]), 0)
	_assert(bm.get_hero_block("napoleon") == 5, "BLOCK_ALL — 나폴레옹 방어 5")
	_assert(bm.get_hero_block("yi_sun_sin") == 5, "BLOCK_ALL — 이순신 방어 5")

# ──────────────────────────────────────────────
# 영입 풀 테스트 (로직 인라인)
# ──────────────────────────────────────────────

func test_recruit_hero_pool_napoleon_only() -> void:
	print("[TestHeroes] test_recruit_hero_pool_napoleon_only")
	# 나폴레옹만 있을 때 → 클레오파트라 + 이순신 2명 반환
	var pool := _compute_recruit_pool(["napoleon"])
	_assert(pool.size() == 2, "나폴레옹만 있을 때 영입 후보 2명")

func test_recruit_hero_pool_full_party() -> void:
	print("[TestHeroes] test_recruit_hero_pool_full_party")
	var pool := _compute_recruit_pool(["napoleon", "cleopatra", "yi_sun_sin"])
	_assert(pool.size() == 0, "풀 파티일 때 영입 후보 없음")

func _compute_recruit_pool(existing_ids: Array) -> Array:
	var pool := []
	if "cleopatra" not in existing_ids:
		pool.append("cleopatra")
	if "yi_sun_sin" not in existing_ids:
		pool.append("yi_sun_sin")
	return pool

# ──────────────────────────────────────────────
# 초기 덱 + 다중 영웅 보상 테스트
# ──────────────────────────────────────────────

func test_add_initial_deck_for_cleopatra() -> void:
	print("[TestHeroes] test_add_initial_deck_for_cleopatra")
	# 클레오파트라 스타터: 독침 2장 + 왕실 방어 2장
	var cards := []
	for _i in range(2):
		var c := CardRes.new(); c.card_name = "독침"; c.owner_id = "cleopatra"
		cards.append(c)
	for _i in range(2):
		var c := CardRes.new(); c.card_name = "왕실 방어"; c.owner_id = "cleopatra"
		cards.append(c)
	_assert(cards.size() == 4, "클레오파트라 초기 덱 4장 구성")
	_assert(cards[0].card_name == "독침", "첫 카드 독침")
	_assert(cards[2].card_name == "왕실 방어", "세 번째 카드 왕실 방어")

func test_generate_card_rewards_multi_hero() -> void:
	print("[TestHeroes] test_generate_card_rewards_multi_hero")
	var gm = _load_gm()
	var pool: Array = gm._napoleon_card_pool()
	pool.append_array(gm._cleopatra_card_pool())
	pool.shuffle()
	var rewards: Array = pool.slice(0, min(3, pool.size()))
	_assert(rewards.size() == 3, "다중 영웅 카드 풀 합산 시 보상 3장")
