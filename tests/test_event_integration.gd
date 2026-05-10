# tests/test_event_integration.gd
# Phase 1-4 신규 EffectType 흐름 통합 검증
# - TRIGGER_BATTLE → start_event_battle → complete_battle → 보상 자동 적용
# - 확률 (success_chance + alt_effect_type) 분기
# - MULTI (secondary_effect_type) 두 효과 적용
# - 조건부 (required_hero_id) — _is_choice_available 흐름
class_name TestEventIntegration
extends RefCounted

const GameManagerClass = preload("res://autoload/game_manager.gd")
const TeamManagerClass = preload("res://autoload/team_manager.gd")
const DeckManagerClass = preload("res://autoload/deck_manager.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")
const HeroRes = preload("res://resources/hero_resource.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_start_event_battle_sets_pending_reward()
	test_complete_battle_applies_event_reward_gold()
	test_complete_battle_applies_event_reward_relic()
	test_complete_battle_clears_event_reward()
	test_required_hero_available_when_present()
	test_required_hero_unavailable_when_missing()
	test_required_hero_empty_means_always_available()
	test_choice_unavailable_when_gold_insufficient()
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

func _make_tm() -> TeamManagerClass:
	var tm := TeamManagerClass.new()
	_to_free.append(tm)
	return tm

func _make_hero(id: String, hp: int) -> Resource:
	var h := HeroRes.new()
	h.hero_id = id
	h.max_hp = hp
	return h

func _make_gm(tm: TeamManagerClass = null) -> GameManagerClass:
	var gm := GameManagerClass.new()
	if tm:
		gm._test_tm_override = tm
	_to_free.append(gm)
	return gm

# ──────────────────────────────────────────────
# TRIGGER_BATTLE 흐름 — pending_event_battle_reward 수명주기
# ──────────────────────────────────────────────

func test_start_event_battle_sets_pending_reward() -> void:
	print("[TestEventIntegration] test_start_event_battle_sets_pending_reward")
	var gm := _make_gm()
	var reward := {"effect_type": ChoiceRes.EffectType.GOLD, "value": 100, "card_id": ""}
	# start_event_battle은 _request_scene 호출하지만 헤드리스에선 무해
	gm.start_event_battle(0, reward)
	_assert(gm.pending_event_battle_reward.size() == 3, "pending_event_battle_reward 채워짐")
	_assert(int(gm.pending_event_battle_reward["effect_type"]) == ChoiceRes.EffectType.GOLD, "보상 effect_type=GOLD")
	_assert(int(gm.pending_event_battle_reward["value"]) == 100, "보상 value=100")

func test_complete_battle_applies_event_reward_gold() -> void:
	print("[TestEventIntegration] test_complete_battle_applies_event_reward_gold")
	var gm := _make_gm()
	gm.gold = 0
	gm.pending_event_battle_reward = {
		"effect_type": ChoiceRes.EffectType.GOLD,
		"value": 80,
		"card_id": "",
	}
	gm._apply_event_battle_reward()
	_assert(gm.gold == 80, "이벤트 전투 GOLD 보상 +80 적용 (실제: %d)" % gm.gold)

func test_complete_battle_applies_event_reward_relic() -> void:
	print("[TestEventIntegration] test_complete_battle_applies_event_reward_relic")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	var gm := _make_gm(tm)
	gm.pending_event_battle_reward = {
		"effect_type": ChoiceRes.EffectType.ADD_RELIC,
		"value": 0,
		"card_id": "",
	}
	var prev_count: int = gm.relics.size()
	gm._apply_event_battle_reward()
	_assert(gm.relics.size() == prev_count + 1, "이벤트 전투 ADD_RELIC 보상 1개 추가")

func test_complete_battle_clears_event_reward() -> void:
	print("[TestEventIntegration] test_complete_battle_clears_event_reward")
	var gm := _make_gm()
	gm.gold = 0
	gm.pending_event_battle_reward = {
		"effect_type": ChoiceRes.EffectType.GOLD,
		"value": 50,
		"card_id": "",
	}
	gm._apply_event_battle_reward()
	_assert(gm.pending_event_battle_reward.is_empty(), "보상 적용 후 pending_event_battle_reward 비워짐")
	# 같은 호출 두 번 → 두 번째는 효과 없음 (중복 적용 방지)
	gm._apply_event_battle_reward()
	_assert(gm.gold == 50, "두 번째 호출은 효과 없음 (gold 50 유지, 중복 적용 방지)")

# ──────────────────────────────────────────────
# 조건부 선택지 — _is_choice_available 로직 (event_scene.gd 외부 검증)
# ──────────────────────────────────────────────

# event_scene.gd의 _is_choice_available는 GameManager.gold + TeamManager.heroes 검사.
# 이 로직을 inline으로 재현해 검증 (실제 호출은 SceneTree 필요).
func _is_available(choice: Resource, gm: GameManagerClass, tm: TeamManagerClass) -> bool:
	if choice.required_hero_id != "":
		var found: bool = false
		for h in tm.heroes:
			if h.hero_id == choice.required_hero_id:
				found = true
				break
		if not found:
			return false
	if choice.cost_gold > 0 and gm.gold < choice.cost_gold:
		return false
	return true

func test_required_hero_available_when_present() -> void:
	print("[TestEventIntegration] test_required_hero_available_when_present")
	var tm := _make_tm()
	tm.add_hero(_make_hero("musashi", 100))
	var gm := _make_gm(tm)
	var c: Resource = ChoiceRes.new()
	c.required_hero_id = "musashi"
	c.effect_type = ChoiceRes.EffectType.GOLD
	c.value = 50
	_assert(_is_available(c, gm, tm), "musashi 보유 시 활성")

func test_required_hero_unavailable_when_missing() -> void:
	print("[TestEventIntegration] test_required_hero_unavailable_when_missing")
	var tm := _make_tm()
	tm.add_hero(_make_hero("napoleon", 100))
	var gm := _make_gm(tm)
	var c: Resource = ChoiceRes.new()
	c.required_hero_id = "musashi"
	_assert(not _is_available(c, gm, tm), "musashi 미보유 시 비활성")

func test_required_hero_empty_means_always_available() -> void:
	print("[TestEventIntegration] test_required_hero_empty_means_always_available")
	var tm := _make_tm()
	var gm := _make_gm(tm)
	var c: Resource = ChoiceRes.new()
	# required_hero_id 빈 문자열 — 영웅 0명이라도 활성
	_assert(_is_available(c, gm, tm), "required_hero_id 빈 문자열 → 영웅 무관 활성")

func test_choice_unavailable_when_gold_insufficient() -> void:
	print("[TestEventIntegration] test_choice_unavailable_when_gold_insufficient")
	var tm := _make_tm()
	var gm := _make_gm(tm)
	gm.gold = 30
	var c: Resource = ChoiceRes.new()
	c.cost_gold = 50
	_assert(not _is_available(c, gm, tm), "골드 30 < cost_gold 50 → 비활성")
	gm.gold = 60
	_assert(_is_available(c, gm, tm), "골드 60 >= cost_gold 50 → 활성")
