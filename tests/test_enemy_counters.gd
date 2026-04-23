# tests/test_enemy_counters.gd
# 적 카드 타입 카운터 시스템 테스트 (Plan 27 Step 4)
class_name TestEnemyCounters
extends RefCounted

const BattleManagerClass = preload("res://autoload/battle_manager.gd")
const TeamManagerClass   = preload("res://autoload/team_manager.gd")
const DeckManagerClass   = preload("res://autoload/deck_manager.gd")
const HeroRes            = preload("res://resources/hero_resource.gd")
const CardRes            = preload("res://resources/card_resource.gd")
const EnemyRes           = preload("res://resources/enemy_resource.gd")
const IntentRes          = preload("res://resources/intent_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	print("[TestEnemyCounters] 적 카드 타입 카운터 테스트 시작")
	test_attack_counter_accumulates()
	test_skill_counter_does_not_count_attack()
	test_threshold_fires_intent_once()
	test_repeat_true_fires_multiple_times()
	test_repeat_false_fires_once_only()
	test_setup_battle_resets_counter()
	test_dead_enemy_does_not_count()
	test_kronos_skill_5_triggers_vulnerable()
	test_underworld_judge_attack_4_triggers_damage()
	test_pangu_power_1_triggers_weak()
	return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

# ────────────────────────────────────────────
# 헬퍼
# ────────────────────────────────────────────

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

func _make_card(card_type: int) -> Resource:
	var c := CardRes.new()
	c.card_name = "Test Card"
	c.owner_id = "test_hero"
	c.cost = 0
	c.card_type = card_type
	c.effects = []
	return c

func _make_enemy_with_trigger(card_type: int, threshold: int, repeat: bool) -> Resource:
	var e := EnemyRes.new()
	e.max_hp = 100
	var intent := IntentRes.new()
	intent.action_type = IntentRes.ActionType.BUFF
	intent.value = 1
	intent.target = IntentRes.TargetType.ALL
	e.card_count_trigger = {
		"card_type": card_type,
		"threshold": threshold,
		"intent": intent,
		"repeat": repeat,
	}
	return e

# _track_card_type_counters 직접 호출 헬퍼 (play_card는 deck_mgr/is_player_turn 의존)
func _track(bm: BattleManagerClass, card_type: int) -> void:
	var c := _make_card(card_type)
	bm._track_card_type_counters(c)

# ────────────────────────────────────────────
# 1. ATTACK 카드 3장 → count == 3
# ────────────────────────────────────────────
func test_attack_counter_accumulates() -> void:
	print("[TestEnemyCounters] test_attack_counter_accumulates")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 10, false)
	bm.setup_battle([enemy])

	for i in range(3):
		_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 3, "ATTACK 카드 3장 후 count == 3")

# ────────────────────────────────────────────
# 2. SKILL 트리거 적 — ATTACK 카드 3장 → count == 0
# ────────────────────────────────────────────
func test_skill_counter_does_not_count_attack() -> void:
	print("[TestEnemyCounters] test_skill_counter_does_not_count_attack")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.SKILL, 10, false)
	bm.setup_battle([enemy])

	for i in range(3):
		_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "SKILL 트리거 적은 ATTACK 카드를 세지 않음 (count == 0)")

# ────────────────────────────────────────────
# 3. 임계값 2, repeat=false → 2장에서 fired_count == 1
# ────────────────────────────────────────────
func test_threshold_fires_intent_once() -> void:
	print("[TestEnemyCounters] test_threshold_fires_intent_once")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 2, false)
	bm.setup_battle([enemy])

	_track(bm, CardRes.CardType.ATTACK)
	_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("fired_count", 0) == 1, "임계값 2 도달 시 fired_count == 1")

# ────────────────────────────────────────────
# 4. 임계값 2, repeat=true → 4장에서 fired_count == 2
# ────────────────────────────────────────────
func test_repeat_true_fires_multiple_times() -> void:
	print("[TestEnemyCounters] test_repeat_true_fires_multiple_times")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 2, true)
	bm.setup_battle([enemy])

	for i in range(4):
		_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("fired_count", 0) == 2, "repeat=true, 4장 후 fired_count == 2")

# ────────────────────────────────────────────
# 5. 임계값 2, repeat=false → 4장에도 fired_count == 1 (1회만 발동)
# ────────────────────────────────────────────
func test_repeat_false_fires_once_only() -> void:
	print("[TestEnemyCounters] test_repeat_false_fires_once_only")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 2, false)
	bm.setup_battle([enemy])

	for i in range(4):
		_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("fired_count", 0) == 1, "repeat=false, 4장 후에도 fired_count == 1")

# ────────────────────────────────────────────
# 6. setup_battle 재호출 → 카운터 리셋
# ────────────────────────────────────────────
func test_setup_battle_resets_counter() -> void:
	print("[TestEnemyCounters] test_setup_battle_resets_counter")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 10, false)
	bm.setup_battle([enemy])

	for i in range(3):
		_track(bm, CardRes.CardType.ATTACK)

	# 새 전투 시작
	var enemy2 := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 10, false)
	bm.setup_battle([enemy2])

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "setup_battle 재호출 후 count == 0")

# ────────────────────────────────────────────
# 7. 사망한 적은 카운트 안 함
# ────────────────────────────────────────────
func test_dead_enemy_does_not_count() -> void:
	print("[TestEnemyCounters] test_dead_enemy_does_not_count")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var enemy := _make_enemy_with_trigger(CardRes.CardType.ATTACK, 10, false)
	bm.setup_battle([enemy])

	# 적 사망 처리
	bm._enemy_alive[0] = false

	_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "사망한 적은 count 증가 없음 (count == 0)")

# ────────────────────────────────────────────
# 8. 크로노스 — SKILL 5장 → fired_count == 1
# ────────────────────────────────────────────
func test_kronos_skill_5_triggers_vulnerable() -> void:
	print("[TestEnemyCounters] test_kronos_skill_5_triggers_vulnerable")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var M = load("res://resources/enemies/greek/greek_act3.gd")
	var kronos = M.kronos(null)
	bm.setup_battle([kronos])

	for i in range(5):
		_track(bm, CardRes.CardType.SKILL)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "크로노스: SKILL 5장 후 발동 → count 리셋 == 0")
	_assert(ctr.get("fired_count", 0) == 1, "크로노스: SKILL 5장 후 fired_count == 1")

# ────────────────────────────────────────────
# 9. 저승 판관 — ATTACK 4장 → fired_count == 1
# ────────────────────────────────────────────
func test_underworld_judge_attack_4_triggers_damage() -> void:
	print("[TestEnemyCounters] test_underworld_judge_attack_4_triggers_damage")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var M = load("res://resources/enemies/korean/korean_act3.gd")
	var judge = M.underworld_judge(null)
	bm.setup_battle([judge])

	for i in range(4):
		_track(bm, CardRes.CardType.ATTACK)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "저승 판관: ATTACK 4장 후 발동 → count 리셋 == 0")
	_assert(ctr.get("fired_count", 0) == 1, "저승 판관: ATTACK 4장 후 fired_count == 1")

# ────────────────────────────────────────────
# 10. 반고 — POWER 1장 → fired_count == 1
# ────────────────────────────────────────────
func test_pangu_power_1_triggers_weak() -> void:
	print("[TestEnemyCounters] test_pangu_power_1_triggers_weak")
	var bm := _make_bm()
	bm.team_mgr.add_hero(_make_hero("test_hero", 50))
	var M = load("res://resources/enemies/chinese/chinese_act3.gd")
	var pangu_enemy = M.pangu(null)
	bm.setup_battle([pangu_enemy])

	_track(bm, CardRes.CardType.POWER)

	var ctr: Dictionary = bm._enemy_card_counters.get(0, {})
	_assert(ctr.get("count", -1) == 0, "반고: POWER 1장 후 발동 → count 리셋 == 0")
	_assert(ctr.get("fired_count", 0) == 1, "반고: POWER 1장 후 fired_count == 1 (threshold=1)")
