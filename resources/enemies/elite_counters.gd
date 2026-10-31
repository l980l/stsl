# 엘리트 상성 기믹 도우미 (docs/game_design/elite_counter_design.md).
# 엘리트마다 한 아키타입의 엔진을 늦추거나 비용을 매긴다. 수치는 기존 단위(×10)로 쓴다.
extends RefCounted

const IntentRes = preload("res://resources/intent_resource.gd")
const CardRes = preload("res://resources/card_resource.gd")

# 영웅 상태 지우기 — morale(돌격)·tokens(병사)·block(거북선). value > 0 이면 그만큼만 줄인다.
static func dispel(key: String, value: int = 0, target: int = IntentRes.TargetType.ALL) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.DISPEL
	it.status_type = key
	it.value = value
	it.target = target
	it.play_animation = "debuff"
	return it

# 자기 정화 — cleanse_poison(독살)·cleanse_debuff(저주)·cleanse_marks(약탈).
static func cleanse(variant: String) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.SPECIAL
	it.status_type = variant
	it.play_animation = "buff"
	return it

# 회복 차단 — 신성은 한 명, 회복은 전체.
static func heal_block(turns: int, target: int) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.DEBUFF
	it.status_type = "heal_block"
	it.value = turns
	it.target = target
	return it

# 속도 감소(기동) — 영웅 전체.
static func slow(value: int, turns: int) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.DEBUFF
	it.status_type = "speed_penalty"
	it.value = value
	it.duration = turns
	it.target = IntentRes.TargetType.ALL
	return it

# 가시(이도류) — 공격 카드로 맞을 때마다 때린 영웅에게 value 피해. 패턴이 돌 때마다 쌓인다.
static func thorns(value: int) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.BUFF
	it.status_type = "thorns"
	it.value = value
	return it

# 졸개 소환(결투) — 같은 신화 일반 몬스터 팩토리.
static func summon(factory: String, count: int) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.SUMMON
	it.status_type = factory
	it.value = count
	return it

# 처형(필사즉생·순교) — 체력이 가장 낮은 영웅을 마킹하면 이 적의 공격이 그 영웅에게 +50%.
static func execute_mark() -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.MARK_TARGET
	it.target = IntentRes.TargetType.LOWEST_HP
	return it

# 큰 피해 되갚기(무심) — 다음 공격까지 받은 피해의 pct% 를 모아 더한다.
static func counter_prepare(pct: int) -> Resource:
	var it := IntentRes.new()
	it.action_type = IntentRes.ActionType.COUNTER_PREPARE
	it.value = pct
	return it

# 스킬 반격(지휘) — 스킬 카드 threshold 장마다 무작위 영웅에게 value 피해.
static func skill_counter(e: Resource, threshold: int, value: int, damage_type: String) -> void:
	var hit := IntentRes.new()
	hit.action_type = IntentRes.ActionType.ATTACK
	hit.value = value
	hit.target = IntentRes.TargetType.RANDOM
	hit.damage_type = damage_type
	hit.play_animation = "attack"
	e.card_count_trigger = {"card_type": CardRes.CardType.SKILL, "threshold": threshold, "intent": hit, "repeat": true}

# 패턴의 at 위치에 의도를 끼운다. 페이즈 패턴이 있으면 모든 페이즈에 같은 위치로 넣는다.
static func insert(e: Resource, intent: Resource, at: int) -> void:
	if e.phase_patterns.is_empty():
		e.intent_pattern.insert(mini(at, e.intent_pattern.size()), intent)
		return
	for pattern in e.phase_patterns:
		pattern.insert(mini(at, pattern.size()), intent.duplicate(true))
	e.intent_pattern = e.phase_patterns[0]

# 한 페이즈에만 의도를 끼운다(다른 페이즈에 이미 같은 기믹이 있을 때).
static func insert_phase(e: Resource, phase: int, intent: Resource, at: int) -> void:
	var pattern: Array = e.phase_patterns[phase]
	pattern.insert(mini(at, pattern.size()), intent)
	e.intent_pattern = e.phase_patterns[0]

# 난이도(사용자 결정: 견제와 함께 엘리트를 더 단단하게). 막별 체력·공격 배율.
# 목표: 체력 100%로 들어가 엘리트전 1회에 파티 체력 20~35% 손실(사용자 결정 2026-10-31).
# 1막 시뮬레이션: 체력 2배·공격 3.5배에서 평균 손실이 이 범위에 든다. 2·3막은 측정 후 정한다.
const HP_MUL := {1: 2.0, 2: 2.0, 3: 2.0}
const ATTACK_MUL := {1: 3.5, 2: 3.5, 3: 3.5}

static func harden(e: Resource, act: int) -> void:
	e.max_hp = int(round(e.max_hp * HP_MUL[act]))
	var seen := {}
	var intents: Array = e.intent_pattern.duplicate()
	for pattern in e.phase_patterns:
		intents.append_array(pattern)
	while not intents.is_empty():
		var it: Resource = intents.pop_back()
		if it == null or seen.has(it.get_instance_id()):
			continue
		seen[it.get_instance_id()] = true
		if it.action_type == IntentRes.ActionType.ATTACK:
			it.value = int(round(it.value * ATTACK_MUL[act]))
		intents.append_array(it.payoff_intents)
