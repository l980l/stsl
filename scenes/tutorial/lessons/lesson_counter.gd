# scenes/tutorial/lessons/lesson_counter.gd
# L2 카운터 & 차지 — 적이 강공(CHARGE_UP)을 준비할 때 빛나는 카운터 카드로 무효화한다.
class_name LessonCounter
extends RefCounted

const HERO_ID := "napoleon"
const CARD_COUNTER := "card.counter.name"
const CARD_STRIKE := "card.napoleon.strike.name"

static func lesson_id() -> String:
	return "counter"

# 카운터 카드(공용) + 마무리용 일격 2장. 전부 is_innate 로 첫 손패 보장.
static func build_deck() -> Array:
	var CommonCards = load("res://resources/cards/cards_common.gd")
	var NapoleonCards = load("res://resources/cards/cards_napoleon.gd")
	var deck: Array = [CommonCards.counter(HERO_ID), NapoleonCards._strike(), NapoleonCards._strike()]
	for c in deck:
		c.is_innate = true
	return deck

static func build_enemy() -> EnemyResource:
	var e := EnemyResource.new()
	# 실제 몬스터 일러스트 (사이클롭스 — 큰 한 방을 준비하는 느낌).
	e.enemy_name = "enemy.greek.cyclops"
	e.mythology = "greek"
	e.grade = EnemyResource.Grade.NORMAL
	# 카운터 후 기절 → 한 방으로 마무리되게 낮은 HP.
	e.max_hp = 90
	e.signatures_enabled = false
	e.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	# 카운터 윈도우 — CHARGE_UP 의도 표시 시점부터 카운터 카드로 무효 가능.
	e.counter_window_intent = {"enabled": true, "stun_on_counter": 1}
	# 첫 의도부터 강공 차지 — 첫 턴부터 카운터 카드가 빛난다.
	var charge := IntentResource.new()
	charge.action_type = IntentResource.ActionType.CHARGE_UP
	charge.charge_turns = 2
	var payoff := IntentResource.new()
	payoff.action_type = IntentResource.ActionType.ATTACK
	payoff.value = 45
	payoff.target = IntentResource.TargetType.RANDOM
	payoff.damage_type = "blunt"
	charge.payoff_intents = [payoff]
	e.intent_pattern = [charge]
	return e

# end_turn: "lock"=강제 / "highlight"=유도 / "free"=자유. complete_event 은 battle_scene 브리지가 notify.
static func steps() -> Array:
	return [
		{"text": "tutorial.counter.s_intent", "complete_event": "screen_clicked", "allowed_cards": [], "end_turn": "lock"},
		{"text": "tutorial.counter.s_counter", "complete_event": "counter_major", "allowed_cards": [CARD_COUNTER], "end_turn": "lock"},
		{"text": "tutorial.counter.s_win", "complete_event": "battle_won", "allowed_cards": [CARD_STRIKE], "end_turn": "free"},
	]
