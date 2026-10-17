# 아키타입 시너지 개편의 데이터 전용 적용기.
# 카드의 정체성(희귀도, 아트, 보상/시작덱 풀)은 공장 정의를 그대로 사용한다.
class_name ArchetypeSynergyRevision
extends RefCounted

const CardRes = preload("res://resources/card_resource.gd")
const EffRes = preload("res://resources/effect_resource.gd")

static func apply_all(cards: Array) -> Array:
	for index in range(cards.size()):
		cards[index] = apply(cards[index])
	return cards

static func apply(card: Resource) -> Resource:
	if card == null or card.has_meta("archetype_synergy_revision"):
		return card
	match card.card_name:
		# 나폴레옹: 사기/토큰을 쌓아 그 턴의 선택지로 전환한다.
		"card.napoleon.cavalry_threat.name": _configure(card, 1, [_damage(60, 80), _rule("morale_if_survives", {"amount": 1})])
		"card.napoleon.arcole_breakthrough.name": _configure(card, 1, [_damage(70, 100), _rule("resource_to_block", {"resource": "morale", "consume_cap": 2, "per_resource": 40, "base": 0})])
		"card.napoleon.artillery_gather.name": _configure(card, 1, [_rule("recruit_or_draw", {"tokens": 1, "draw": 2}), _block(0, 30)])
		"card.napoleon.grand_armee_shield.name": _configure(card, 1, [_block(50, 80), _rule("resource_to_block", {"resource": "tokens", "consume_cap": 1, "per_resource": 80, "base": 0})])
		"card.napoleon.line_reform.name": _configure(card, 0, [_rule("discard_for_draw", {"draw": 2}, {"draw": 3})], true)
		"card.napoleon.charge_bugle.name": _configure(card, 1, [_rule("morale_attack_discount", {"consume": 1, "amount": 1}), _morale(1, 2)])

		# 클레오파트라: 독의 확산/즉발과 매혹의 반함 보상을 교차한다.
		"card.cleopatra.poison_seed.name": _configure(card, 1, [_damage(30, 50), _rule("poison_seed_spread", {"seed": 20, "spread": 10}, {}, "SINGLE")])
		"card.cleopatra.poison_party.name": _configure(card, 2, [_damage(50, 70, "ALL"), _rule_damage("poison_tick_now", 0, 0, 0, 0, {}, "ALL", "poison")])
		"card.cleopatra.snake_gaze.name": _configure(card, 1, [_rule("curse_weave", {"weak": 1, "vulnerable": 2, "draw": 1}, {"weak": 1, "vulnerable": 3, "draw": 1}, "SINGLE")])
		"card.cleopatra.pharaoh_fury.name": _configure(card, 2, [_rule_damage("debuff_cash_damage", 60, 80, 40, 40, {"statuses": ["weak", "vulnerable"], "consume_cap": 1}, "ALL")])
		"card.cleopatra.nile_whisper.name": _configure(card, 1, [_charm(20, 30, "ALL"), _draw_per_enthrall(1)])
		"card.cleopatra.charming_perfume.name": _configure(card, 3, [_charm(30, 40, "ALL"), _rule("charm_to_block", {"consume_cap": 20, "block_per_charm": 3, "block_cap": 180}, {}, "ALL")], true)

		# 이순신: 방어도를 보존하거나 넘겨서 공격/드로우로 바꾼다.
		"card.yi_sun_sin.consecutive_defense.name": _configure(card, 1, [_rule("guard_attack_discount", {"threshold": 50, "amount": 1}), _block(50, 70)])
		"card.yi_sun_sin.charge_stance.name": _configure(card, 1, [_rule_damage("consume_own_block", 50, 70, 2, 2, {"consume_cap": 60, "multiplier": 2}), _rule("block_if_target_survives", {"amount": 30})])
		"card.yi_sun_sin.formation_boost.name": _configure(card, 1, [_rule("block_transfer", {"consume_cap": 60, "base": 40}, {"consume_cap": 60, "base": 60}, "ALLY")])
		"card.yi_sun_sin.naval_training.name": _configure(card, 1, [_draw(1), _rule("formation_drill", {"block": 40}, {"block": 60})])
		"card.yi_sun_sin.all_in.name": _configure(card, 1, [_sacrifice(40), _damage(100, 130), _draw(1, -1, "low_hp")])
		"card.yi_sun_sin.crisis_breakthrough.name": _configure(card, 2, [_conditional(120, 150, 240, 280, "very_low_hp"), _heal(60, 70, "SELF", "very_low_hp")])

		# 잔다르크: 디버프 정산과 회복 과잉분의 방어 전환.
		"card.joan_of_arc.holy_bolt.name": _configure(card, 1, [_rule("heal_if_enemy_debuff", {"status": "vulnerable", "amount": 20}), _damage(60, 80), _status("vulnerable", 1)])
		"card.joan_of_arc.orleans_charge.name": _configure(card, 1, [_rule_damage("debuff_cash_damage", 80, 100, 40, 40, {"statuses": ["vulnerable"], "consume_cap": 2})])
		"card.joan_of_arc.holy_touch.name": _configure(card, 1, [_rule("overflow_heal", {"heal": 60, "block_cap": 40}, {"heal": 80, "block_cap": 50}, "ALLY")])
		"card.joan_of_arc.communion.name": _configure(card, 1, [_rule("block_to_heal", {"consume_cap": 40, "draw": 1}, {"consume_cap": 60, "draw": 1}, "ALLY")])
		"card.joan_of_arc.martyrdom_steps.name": _configure(card, 1, [_rule("bank_draw", {"consume_cap": 50, "draw": 1, "bonus_draw": 2}, {"consume_cap": 50, "draw": 1, "bonus_draw": 3})])
		"card.joan_of_arc.last_shield.name": _configure(card, 1, [_sacrifice(50), _rule("block_transfer", {"consume_cap": 100, "base": 50}, {"consume_cap": 140, "base": 70}, "ALLY")])

		# 칭기즈칸: 선제 디버프/드로우 콤보와 마킹 정산.
		"card.genghis_khan.swift_raid.name": _configure(card, 0, [_damage(20, 30), _rule("opening_status", {"status": "vulnerable", "amount": 1}, {}, "SINGLE")])
		"card.genghis_khan.cavalry_crossing.name": _configure(card, 2, [_draw(2, 3), _rule("combo_energy_once", {"threshold": 2, "normal": 1, "combo": 2})])
		"card.genghis_khan.arrow_volley.name": _configure(card, 1, [_rule_damage("consume_own_tokens_all", 30, 40, 40, 50, {"consume_cap": 1}, "ALL")])
		"card.genghis_khan.cavalry_retreat.name": _configure(card, 1, [_rule("resource_to_block", {"resource": "tokens", "consume_cap": 2, "base": 20, "per_resource": 30}, {"resource": "tokens", "consume_cap": 2, "base": 30, "per_resource": 30}, "ALL")])
		"card.genghis_khan.loot.name": _configure(card, 1, [_rule("marked_scout", {"draw": 1, "marked_draw": 2}, {"draw": 1, "marked_draw": 3}, "SINGLE")])
		"card.genghis_khan.war_tribute.name": _configure(card, 2, [_rule_damage("marked_cash_all", 60, 80, 40, 40, {"draw": 1}, "ALL")], false, CardRes.CardType.ATTACK)

		# 무사시: 다단 공격, 결투 상태, 빈 손패의 상호 전환.
		"card.musashi.niten_slash.name": _configure(card, 1, [_damage(40, 50, "SINGLE", 2), _rule("next_attack_first_hit_bonus", {"amount": 30}, {"amount": 40})])
		"card.musashi.whirlwind_cut.name": _configure(card, 1, [_rule_damage("block_multi_hit", 30, 40, 0, 0, {"consume_cap": 40}, "SINGLE", "slash", 2)])
		"card.musashi.courage.name": _configure(card, 1, [_block(60, 80), _rule("duel_preparation", {"amount": 30, "solo_amount": 50}, {"amount": 40, "solo_amount": 60})])
		"card.musashi.single_cut.name": _configure(card, 2, [_rule_damage("duel_status_damage", 160, 180, 280, 320, {"status": "weak", "consume": 1})])
		"card.musashi.empty_state.name": _configure(card, 1, [_rule("empty_reload", {"block": 70, "draw": 2, "fallback_draw": 1}, {"block": 90, "draw": 2, "fallback_draw": 1})])
		"card.musashi.empty_guard.name": _configure(card, 1, [_block(50, 70), _rule("discard_for_draw", {"draw": 0}), _status("weak", 1)])
		_: return card
	card.set_meta("archetype_synergy_revision", true)
	return card

static func _configure(card: Resource, cost: int, effects: Array, exhaust: bool = false, card_type: int = -1) -> void:
	card.cost = cost
	card.effects = effects
	card.is_exhaust = exhaust
	card.is_ethereal = false
	card.has_explicit_upgrade = true
	if card_type >= 0:
		card.card_type = card_type

static func _effect(type: int, value: int = 0, upgrade: int = -1, target: String = "SELF", condition: String = "") -> Resource:
	var effect := EffRes.new()
	effect.effect_type = type
	effect.value = value; effect.base_value = value; effect.upgrade_value = upgrade
	effect.target = target; effect.condition = condition
	return effect

static func _damage(value: int, upgrade: int = -1, target: String = "SINGLE", hits: int = 1) -> Resource:
	var effect := _effect(EffRes.EffectType.DAMAGE, value, upgrade, target)
	effect.hit_count = hits; effect.damage_type = "slash"
	return effect

static func _block(value: int, upgrade: int = -1, target: String = "SELF") -> Resource:
	return _effect(EffRes.EffectType.BLOCK, value, upgrade, target)

static func _draw(value: int, upgrade: int = -1, condition: String = "") -> Resource:
	return _effect(EffRes.EffectType.DRAW, value, upgrade, "SELF", condition)

static func _draw_per_enthrall(value: int) -> Resource:
	return _effect(EffRes.EffectType.DRAW_PER_ENTHRALL, value, -1, "ALL")

static func _heal(value: int, upgrade: int = -1, target: String = "SELF", condition: String = "") -> Resource:
	return _effect(EffRes.EffectType.HEAL, value, upgrade, target, condition)

static func _morale(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.GAIN_MORALE, value, upgrade)

static func _sacrifice(value: int) -> Resource:
	return _effect(EffRes.EffectType.SACRIFICE_HP, value)

static func _status(status: String, value: int, upgrade: int = -1, target: String = "SINGLE") -> Resource:
	var effect := _effect(EffRes.EffectType.APPLY_STATUS, value, upgrade, target)
	effect.status_type = status
	return effect

static func _charm(value: int, upgrade: int = -1, target: String = "SINGLE") -> Resource:
	return _effect(EffRes.EffectType.CHARM, value, upgrade, target)

static func _conditional(value: int, upgrade_value: int, bonus: int, upgrade_bonus: int, condition: String) -> Resource:
	var effect := _effect(EffRes.EffectType.CONDITIONAL_DMG, value, upgrade_value, "SINGLE")
	effect.bonus_value = bonus; effect.base_bonus_value = bonus; effect.upgrade_bonus_value = upgrade_bonus
	effect.status_type = condition; effect.damage_type = "slash"
	return effect

static func _rule(rule_id: String, params: Dictionary = {}, upgrade_params: Dictionary = {}, target: String = "SELF") -> Resource:
	var effect := _effect(EffRes.EffectType.APPLY_STATUS, 0, -1, target)
	effect.rule_id = rule_id; effect.rule_params = params; effect.upgrade_rule_params = upgrade_params
	return effect

static func _rule_damage(rule_id: String, value: int, upgrade: int, bonus: int, upgrade_bonus: int, params: Dictionary = {}, target: String = "SINGLE", damage_type: String = "slash", hits: int = 1) -> Resource:
	var effect := _damage(value, upgrade, target, hits)
	effect.rule_id = rule_id; effect.damage_type = damage_type
	effect.bonus_value = bonus; effect.base_bonus_value = bonus; effect.upgrade_bonus_value = upgrade_bonus
	effect.rule_params = params
	return effect
