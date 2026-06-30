# scenes/tutorial/lessons/lesson_basics.gd
# L1 기초 전투 — 영웅/덱/적 빌더 + 스텝 정의.
class_name LessonBasics
extends RefCounted

const HERO_ID := "napoleon"

static func lesson_id() -> String:
	return "basics"

static func _make_effect(etype: int, value: int, target: String = "SINGLE", status_type: String = "") -> EffectResource:
	var e := EffectResource.new()
	e.effect_type = etype
	e.value = value
	e.base_value = value
	e.target = target
	e.status_type = status_type
	return e

static func _make_card(name_key: String, cost: int, ctype: int, effect: EffectResource) -> CardResource:
	var c := CardResource.new()
	c.card_name = name_key
	c.owner_id = HERO_ID
	c.cost = cost
	c.card_type = ctype
	c.effects = [effect]
	c.is_innate = true
	return c

static func build_deck() -> Array:
	var atk := _make_card("tutorial.card.strike.name", 1, CardResource.CardType.ATTACK,
		_make_effect(EffectResource.EffectType.DAMAGE, 6))
	var blk := _make_card("tutorial.card.guard.name", 1, CardResource.CardType.SKILL,
		_make_effect(EffectResource.EffectType.BLOCK, 5))
	var pwr := _make_card("tutorial.card.resolve.name", 1, CardResource.CardType.POWER,
		_make_effect(EffectResource.EffectType.APPLY_STATUS, 2, "SELF", "strength"))
	return [atk, blk, pwr]

static func build_enemy() -> EnemyResource:
	var e := EnemyResource.new()
	e.enemy_name = "tutorial.enemy.dummy.name"
	e.mythology = "greek"
	e.grade = EnemyResource.Grade.NORMAL
	e.max_hp = 40
	e.signatures_enabled = false
	# character_scene 없으면 battle_scene 이 ColorRect placeholder 를 만들어 _play_hit_flash(Node2D) 에서 크래시.
	# 테스트 전투와 동일한 Node2D placeholder 씬을 사용해 피격 피드백이 정상 동작하게 한다.
	e.character_scene = load("res://characters/enemies/enemy_placeholder.tscn")
	var atk := IntentResource.new()
	atk.action_type = IntentResource.ActionType.ATTACK
	atk.value = 6
	atk.target = IntentResource.TargetType.RANDOM
	atk.damage_type = "slash"
	e.intent_pattern = [atk]
	return e

# 스텝: text(i18n) + 완료 이벤트 + allowed_cards(이 스텝에 사용 가능한 카드 이름).
# allowed_cards 가 비어있으면 이 스텝에선 모든 카드 비활성(예: 턴 종료 유도).
# 이벤트는 battle_scene 브리지가 notify.
static func steps() -> Array:
	return [
		{"text": "tutorial.basics.s1_intro", "complete_event": "card_played", "allowed_cards": ["tutorial.card.strike.name"]},
		{"text": "tutorial.basics.s2_block", "complete_event": "card_played", "allowed_cards": ["tutorial.card.guard.name"]},
		{"text": "tutorial.basics.s3_endturn", "complete_event": "turn_ended", "allowed_cards": []},
		{"text": "tutorial.basics.s4_crit", "complete_event": "crit_landed", "allowed_cards": ["tutorial.card.strike.name"]},
		{"text": "tutorial.basics.s5_win", "complete_event": "battle_won", "allowed_cards": ["tutorial.card.strike.name"]},
	]
