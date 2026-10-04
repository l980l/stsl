# scenes/tutorial/lessons/lesson_status.gd
# L3 상태이상 & 독 — 취약(받는 피해 증가)과 독(매 턴 피해·3턴 지속·재부여 갱신)을 가르친다.
class_name LessonStatus
extends RefCounted

const HERO_ID := "cleopatra"
const CARD_VULN := "card.cleopatra.snake_gaze.name"      # 취약 3 부여 (피해 없음)
const CARD_POISON := "card.cleopatra.venom_needle.name"  # 피해 60 + 독 10

static func lesson_id() -> String:
	return "status"

static func build_deck() -> Array:
	var CleoCards = load("res://resources/cards/cards_cleopatra.gd")
	var deck: Array = [CleoCards._snake_gaze(), CleoCards._venom_needle(), CleoCards._venom_needle()]
	for c in deck:
		c.is_innate = true
	return deck

static func build_enemy() -> EnemyResource:
	var e := EnemyResource.new()
	# 독 테마 몬스터 일러스트 (사막 전갈).
	e.enemy_name = "enemy.egyptian.desert_scorpion"
	e.mythology = "egyptian"
	e.grade = EnemyResource.Grade.NORMAL
	# 취약(×1.5) 독침 두 번 + 독 틱(10 → 20)을 모두 보여 준 뒤 마지막 독 틱으로 처치.
	e.max_hp = 220
	e.signatures_enabled = false
	e.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	var atk := IntentResource.new()
	atk.action_type = IntentResource.ActionType.ATTACK
	atk.value = 8  # 약하게 — 학습에 집중
	atk.target = IntentResource.TargetType.RANDOM
	atk.damage_type = "blunt"
	e.intent_pattern = [atk]
	return e

# end_turn: "lock"=강제 / "highlight"=유도 / "free"=자유.
static func steps() -> Array:
	return [
		{"text": "tutorial.status.s_intro", "complete_event": "screen_clicked", "allowed_cards": [], "end_turn": "lock"},
		{"text": "tutorial.status.s_vuln", "complete_event": "card_played", "allowed_cards": [CARD_VULN], "end_turn": "lock"},
		{"text": "tutorial.status.s_poison", "complete_event": "card_played", "allowed_cards": [CARD_POISON], "end_turn": "lock"},
		{"text": "tutorial.status.s_tick", "complete_event": "enemy_poison_ticked", "allowed_cards": [], "end_turn": "highlight"},
		{"text": "tutorial.status.s_refresh", "complete_event": "card_played", "allowed_cards": [CARD_POISON], "end_turn": "lock"},
		{"text": "tutorial.status.s_finish", "complete_event": "battle_won", "allowed_cards": [], "end_turn": "highlight"},
	]
