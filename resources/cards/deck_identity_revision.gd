# 덱 정체성 개편의 데이터 전용 적용기 (docs/game_design/deck_attractiveness_proposal.md).
# 아키타입 시너지 개편 뒤에 적용되며, 카드의 정체성(희귀도, 아트, 보상/시작덱 풀)은 그대로 둔다.
class_name DeckIdentityRevision
extends RefCounted

const EffRes = preload("res://resources/effect_resource.gd")
const Synergy = preload("res://resources/cards/archetype_synergy_revision.gd")

static func apply(card: Resource) -> Resource:
	if card == null or card.has_meta("deck_identity_revision"):
		return card
	match card.card_name:
		# 1단계 나폴레옹 자원 정리: 사기 보상은 사기를 실제로 소비하고(승리의 포고와 같은
		# '소비 시 대신' 규칙), 군단 카드는 사기 대신 병사를 만들고 병사 수로 강해진다.
		"card.napoleon.one_man_army.name": Synergy._configure(card, 1, [Synergy._rule_damage("morale_spend_damage", 60, 70, 160, 190, {"consume": 1})])
		"card.napoleon.emperors_assault.name": Synergy._configure(card, 2, [Synergy._rule_damage("morale_spend_damage", 160, 180, 340, 380, {"consume": 2}), Synergy._block(100, 110)])
		"card.napoleon.borodino_bombardment.name": Synergy._configure(card, 2, [Synergy._rule_damage("morale_spend_damage", 140, 160, 300, 340, {"consume": 1})])
		"card.napoleon.trench_construction.name": Synergy._configure(card, 1, [Synergy._block(50, 70), Synergy._effect(EffRes.EffectType.SUMMON_TOKEN, 1)])
		"card.napoleon.imperial_artillery.name": Synergy._configure(card, 1, [Synergy._damage(50, 60), Synergy._effect(EffRes.EffectType.DAMAGE_PER_TOKEN, 10, -1, "SINGLE"), Synergy._status("vulnerable", 1, 2)])
		# 2단계 칭기즈칸 질주: 병사는 칭기즈칸 차례마다 공격하므로 속도가 곧 화력이다.
		# 병사를 소비하지 않고 즉시 쏘게 하고, 모든 적보다 빠를 때 보상한다.
		"card.genghis_khan.horde_volley.name": Synergy._configure(card, 2, [Synergy._rule_damage("soldier_volley", 40, 60, 0, -1, {}, "ALL")])
		"card.genghis_khan.khans_banner.name": Synergy._configure(card, 1, [Synergy._status("power.token_bonus_dmg", 10, 20, "SELF")])
		"card.genghis_khan.war_horse_power.name": Synergy._configure(card, 2, [Synergy._status("power.summon_per_turn", 1, 2, "SELF"), _permanent_speed(8, 10), Synergy._sacrifice(5)])
		# 3단계 이순신 거북선/함대 분리: 병사 카드(수군 소집·일제 사격·함포 일제사)는 학익진 태그로 옮겼다.
		# 거북선 이정표 철갑 충각은 방어를 소비하지 않고 현재 방어만큼 모든 적을 친다.
		"card.yi_sun_sin.iron_ram.name": Synergy._configure(card, 2, [Synergy._rule_damage("block_damage_all", 0, 50, 0, -1, {}, "ALL", "explosive")], true)
		# 4단계 잔다르크 삼각 순환: 태그를 순교/축복/성전 3개로 합치고(번역 값·태그 배열),
		# 성전 공격은 아군이 실제로 회복한 양을 피해로 바꾼다.
		"card.joan_of_arc.archangels_wrath.name": Synergy._configure(card, 2, [Synergy._effect(EffRes.EffectType.HEAL_ALL, 20, 30), Synergy._rule_damage("heal_turn_damage", 60, 80, 0, -1, {"percent": 50}, "ALL")])
		"card.joan_of_arc.holy_fury.name": Synergy._configure(card, 2, [Synergy._rule_damage("heal_battle_damage", 80, 100, 0, -1, {"percent": 30, "cap": 150}, "ALL")])
		# 5단계 클레오파트라 저주 보상: 쌓은 약화·취약을 거두는 카드. 람세스의 방패는 아군이 취약한 적을
		# 칠 때마다 클레오파트라 방어(차례당 3회) — 팀 안에서 저주를 고를 이유가 보인다.
		"card.cleopatra.desert_recipe.name": Synergy._configure(card, 1, [Synergy._rule("weak_enemy_draw", {"draw": 1, "cap": 2}, {"draw": 2, "cap": 2})])
		"card.cleopatra.ramesses_shield.name": Synergy._configure(card, 1, [Synergy._status("power.block_per_turn", 45, 60, "SELF"), Synergy._status("power.vulnerable_hit_block", 20, 30, "SELF")])
		_: return card
	card.set_meta("deck_identity_revision", true)
	return card

static func _permanent_speed(value: int, upgrade: int) -> Resource:
	var effect: Resource = Synergy._effect(EffRes.EffectType.BUFF_SPEED, value, upgrade)
	effect.bonus_value = 999; effect.base_bonus_value = 999
	return effect
