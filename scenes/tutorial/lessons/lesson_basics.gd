# scenes/tutorial/lessons/lesson_basics.gd
# L1 기초 전투 — 영웅/덱/적 빌더 + 스텝 정의.
class_name LessonBasics
extends RefCounted

const HERO_ID := "napoleon"

# 실제 napoleon 기본 카드 이름 — 일러스트/효과/번역이 실제 게임과 동일하게 표시되도록 사용.
const CARD_STRIKE := "card.napoleon.strike.name"
const CARD_DEFEND := "card.napoleon.defend.name"
const CARD_POWER := "card.napoleon.conquest_decree.name"

static func lesson_id() -> String:
	return "basics"

# 실제 napoleon 카드를 사용 — 일러스트가 있고 효과/번역이 일관됨. is_innate 로 첫 손패 보장.
static func build_deck() -> Array:
	var CN = load("res://resources/cards/cards_napoleon.gd")
	var deck: Array = [CN._strike(), CN._defend(), CN._conquest_decree()]
	for c in deck:
		c.is_innate = true
	return deck

static func build_enemy() -> EnemyResource:
	var e := EnemyResource.new()
	# 실제 일반 몬스터 일러스트 사용 (assets/art/enemies/greek_satyr.png).
	# character_scene = enemy_placeholder 가 enemy_name 으로 일러스트를 로드한다 (실제 전투와 동일 경로).
	e.enemy_name = "enemy.greek.satyr"
	e.mythology = "greek"
	e.grade = EnemyResource.Grade.NORMAL
	# 튜토리얼 진행에 맞춘 HP — strike 100 → 치명타 200 → strike 100 (3타) 로 처치되게 튜닝.
	e.max_hp = 350
	e.signatures_enabled = false
	e.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	var atk := IntentResource.new()
	atk.action_type = IntentResource.ActionType.ATTACK
	atk.value = 8  # 약하게 — 방어(BLOCK 125)로 충분히 막히고, 안 막아도 치명적이지 않게
	atk.target = IntentResource.TargetType.RANDOM
	atk.damage_type = "blunt"
	e.intent_pattern = [atk]
	return e

# 스텝: text(i18n) + 완료 이벤트 + allowed_cards(이 스텝에 사용 가능한 카드 이름).
# allowed_cards 가 비어있으면 모든 카드 비활성(턴 종료 유도). force_crit=true 면 그 스텝에서 치명타 확정.
static func steps() -> Array:
	return [
		{"text": "tutorial.basics.s1_intro", "complete_event": "card_played", "allowed_cards": [CARD_STRIKE]},
		{"text": "tutorial.basics.s2_block", "complete_event": "card_played", "allowed_cards": [CARD_DEFEND]},
		{"text": "tutorial.basics.s_power", "complete_event": "card_played", "allowed_cards": [CARD_POWER]},
		{"text": "tutorial.basics.s3_endturn", "complete_event": "turn_ended", "allowed_cards": []},
		{"text": "tutorial.basics.s4_crit", "complete_event": "crit_landed", "allowed_cards": [CARD_STRIKE], "force_crit": true},
		{"text": "tutorial.basics.s5_win", "complete_event": "battle_won", "allowed_cards": [CARD_STRIKE]},
	]
