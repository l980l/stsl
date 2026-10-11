# 카드 구성 개편 v3의 데이터 전용 적용기.
# 기존 카드 식별자·희귀도·풀 등록은 유지하며, 생성된 Resource의 효과만 교체한다.
class_name CardRevisionV3
extends RefCounted

const CardRes = preload("res://resources/card_resource.gd")
const EffRes = preload("res://resources/effect_resource.gd")

static func apply_all(cards: Array) -> Array:
	for card in cards:
		apply(card)
	return cards

static func apply(card: Resource) -> Resource:
	if card == null:
		return card
	var original_damage_type := ""
	for effect in card.effects:
		if effect.damage_type != "":
			original_damage_type = effect.damage_type
			break
	match card.card_name:
		# 공통 / 나폴레옹
		"card.counter.name": _counter(card)
		"card.napoleon.hussar_charge.name": _configure_card(card, 1, [_damage(70, 90), _morale(1)])
		"card.napoleon.war_bugle.name": _configure_card(card, 1, [_draw(1), _morale(1), _block(0, 30)])
		"card.napoleon.victory_proclamation.name": _configure_card(card, 1, [_rule_damage("morale_spend_damage", 100, 120, 180, 210, {"consume": 2})])
		"card.napoleon.emperors_power.name": _configure_card(card, 1, [_power("power.morale_per_turn", 1, 1, {"starts_next_turn": true, "immediate_morale": 0}, {"immediate_morale": 1})])
		"card.napoleon.emperors_spirit.name": _configure_card(card, 0, [_rule_damage("morale_spend_damage", 40, 60, 260, 310, {"consume": 3, "exhaust": true})], true)
		"card.napoleon.legion_charge.name": _configure_card(card, 2, [_rule_damage("consume_own_tokens", 100, 140, 100, -1, {"consume": 2, "multiplier": 100})])
		"card.napoleon.emperors_will.name": _configure_card(card, 2, [_draw(1), _power("power.draw_per_turn", 1, -1, {"starts_next_turn": true}), _block(0, 50)])
		"card.napoleon.allied_bombardment.name": _configure_card(card, 2, [_rule_damage("team_morale_damage", 120, 160, 20, -1, {"cap": 160})])
		"card.napoleon.blitz_advance.name": _configure_card(card, 1, [_block(40, 65), _rule("next_attack_cost_reduction", {"amount": 1, "count": 1})])

		# 클레오파트라
		"card.cleopatra.venom_needle.name": _configure_card(card, 1, [_damage(60, 80), _status("poison", 15)])
		"card.cleopatra.royal_guard.name": _configure_card(card, 1, [_block(80, 100), _status("poison", 10)])
		"card.cleopatra.poison_ritual.name": _configure_card(card, 1, [_damage(40, 60), _rule("poison_burst_multiplier", {"multiplier": 2})])
		"card.cleopatra.asp_fang.name": _configure_card(card, 1, [_status("poison", 30, 40)])
		"card.cleopatra.poison_throne.name": _configure_card(card, 2, [_rule_damage("damage_per_debuff_type", 60, 100, 70, -1, {"cap": 3, "statuses": ["weak", "vulnerable", "poison", "charm"]})])
		"card.cleopatra.cursed_gaze.name": _configure_card(card, 1, [_status("weak", 1, -1, "ALL"), _status("vulnerable", 1), _block(0, 30)])
		"card.cleopatra.temptation.name": _configure_card(card, 1, [_damage(30, 50), _charm(40)])
		"card.cleopatra.charm_execution.name": _configure_card(card, 2, [_rule_damage("consume_charm_damage", 80, 120, 4, -1, {"consume_cap": 60})])
		"card.cleopatra.isis_judgment.name": _configure_card(card, 1, [_rule("poison_existing_all_bonus", {"amount": 20}, {"amount": 30}), _rule("extend_enemy_debuffs", {"statuses": ["weak", "vulnerable"], "turns": 1})], true)

		# 이순신
		"card.yi_sun_sin.shield.name": _configure_card(card, 1, [_block(80, 100), _draw(1)])
		"card.yi_sun_sin.counter_strike.name": _configure_card(card, 1, [_block(50), _damage(60, 80)])
		"card.yi_sun_sin.counter.name": _configure_card(card, 1, [_rule_damage("consume_own_block", 60, 90, 1.5, -1, {"consume_cap": 80})])
		"card.yi_sun_sin.naval_muster.name": _configure_card(card, 1, [_token(1), _block(50, 80)])
		"card.yi_sun_sin.volley_fire.name": _configure_card(card, 2, [_rule_damage("team_token_damage", 100, 140, 20, -1, {"cap": 180})])
		"card.yi_sun_sin.turtle_ship_charge.name": _configure_card(card, 2, [_rule_damage("consume_own_block", 140, 180, 1.5, -1, {"consume_cap": 100})])
		"card.yi_sun_sin.formation_bond.name": _configure_card(card, 1, [_rule("formation_block", {"base": 75, "per_other_ally": 25}, {"base": 100}),], false, false, true)
		"card.yi_sun_sin.bloody_battle.name": _configure_card(card, 1, [_damage(80, 110), _rule("heal_ally_if_owner_hp_below", {"hp_percent": 50, "amount": 50})])
		"card.yi_sun_sin.united_bulwark.name": _configure_card(card, 2, [_rule("team_block_consume_morale", {"base": 70, "morale_per_hero": 1, "per_morale": 20}, {"base": 90})])

		# 잔다르크
		"card.joan_of_arc.holy_smite.name": _configure_card(card, 1, [_damage(90, 110), _heal(10)])
		"card.joan_of_arc.shield_prayer.name": _configure_card(card, 1, [_block(80, 100, "ALLY"), _heal(20, -1, "ALLY")])
		"card.joan_of_arc.altar_flame.name": _configure_card(card, 1, [_sacrifice(50), _rule("block_ally_if_owner_survives", {"amount": 140}, {"amount": 170})])
		"card.joan_of_arc.crusaders_faith.name": _configure_card(card, 1, [_power("power.strength_player", 12, 16), _heal(20)])
		"card.joan_of_arc.angel_wings.name": _configure_card(card, 2, [_heal_all(30, 40), _rule("delayed_team_heal", {"amount": 30, "turns": 3}, {"amount": 40})])
		"card.joan_of_arc.miracle_revive.name": _configure_card(card, 2, [_rule("revive_or_heal", {"revive_percent": 30, "heal": 120}, {"revive_percent": 40, "heal": 160})], true)
		"card.joan_of_arc.martyr_strength.name": _configure_card(card, 1, [_rule("sacrifice_then_power", {"sacrifice": 50, "power": "power.strength_player", "amount": 18}, {"amount": 23})])
		"card.joan_of_arc.saints_revelation.name": _configure_card(card, 2, [_rule_damage("sacrifice_bank_payoff", 70, 100, 1, -1, {"consume_cap": 150, "target": "ALL"})])
		"card.joan_of_arc.martyrs_light.name": _configure_card(card, 2, [_rule("sacrifice_bank_team_block", {"base": 60, "consume_cap": 150}, {"base": 90})], true)

		# 칭기즈칸
		"card.genghis_khan.horse_thrust.name": _configure_card(card, 1, [_rule_damage("other_card_this_turn_damage", 80, 100, 110, 130)])
		"card.genghis_khan.cavalry_summon.name": _configure_card(card, 1, [_token(1), _block(30, 50)])
		"card.genghis_khan.execution_ground.name": _configure_card(card, 1, [_conditional(90, 110, 170, 200, "enemy_hp_below_30")])
		"card.genghis_khan.horse_charge.name": _configure_card(card, 1, [_damage(60, 85), _rule("third_card_draw_once", {"threshold": 3, "draw": 1})])
		"card.genghis_khan.long_march.name": _configure_card(card, 1, [_rule("block_per_prior_card", {"per_card": 30, "cap": 120}, {"per_card": 40, "cap": 160})])
		"card.genghis_khan.great_khans_command.name": _configure_card(card, 2, [_rule("next_cards_cost_reduction", {"amount": 1, "count": 2}), _block(0, 50)], true)
		"card.genghis_khan.executioners_bounty.name": _configure_card(card, 1, [_power("power.on_kill_energy_once", 1, -1, {"per_turn_limit": 1, "direct_card_only": true}), _block(0, 40)])
		"card.genghis_khan.horde_volley.name": _configure_card(card, 2, [_rule_damage("consume_own_tokens_all", 40, 65, 50, -1, {"consume_cap": 3})])
		"card.genghis_khan.cavalry_charge_speed.name": _configure_card(card, 1, [_speed(10, 14, 2, {"exclude_current_turn_end": true})])

		# 무사시
		"card.musashi.niten_starter.name": _configure_card(card, 1, [_damage(50, 60, "SINGLE", 2)])
		"card.musashi.guard_stance.name": _configure_card(card, 1, [_block(75, 95), _rule("next_attack_first_hit_bonus", {"amount": 20, "count": 1})])
		"card.musashi.meditation.name": _configure_card(card, 0, [_rule("discard_up_to_one_for_block", {"max_discard": 1, "amount": 30}, {"amount": 50})], true)
		"card.musashi.void_sword.name": _configure_card(card, 1, [_conditional(80, 100, 170, 200, "hand_size_0")])
		"card.musashi.swordsmans_resolve.name": _configure_card(card, 1, [_power("power.strength_player", 10, 14)])
		"card.musashi.blood_path.name": _configure_card(card, 1, [_damage(100, 125), _rule("block_if_target_survives", {"amount": 30})])
		"card.musashi.flying_swallow.name": _configure_card(card, 1, [_damage(35, 45, "SINGLE", 2), _rule("hand_empty_energy_once", {"amount": 1})])
		"card.musashi.clear_wind.name": _configure_card(card, 2, [_conditional(140, 170, 260, 300, "hand_size_0"), _rule("cleanse_self_weak_vulnerable_if_hand_empty")])
		"card.musashi.swift_blade.name": _configure_card(card, 1, [_speed(6, 9, 999)])
	if card.card_name.ends_with(".strike.name") or card.card_name.ends_with(".defend.name"):
		card.has_explicit_upgrade = true
		card.effects[0].upgrade_value = 120 if card.card_name.ends_with(".strike.name") else 150
	if card.has_explicit_upgrade:
		for effect in card.effects:
			if effect.damage_type != "" and original_damage_type != "":
				effect.damage_type = original_damage_type
	return card

static func _configure_card(card: Resource, cost: int, effects: Array, exhaust: bool = false, retain: bool = false, innate: bool = false) -> void:
	card.cost = cost
	card.effects = effects
	card.is_exhaust = exhaust
	card.is_retain = retain
	card.is_innate = innate
	card.is_ethereal = false
	card.has_explicit_upgrade = true

static func _counter(card: Resource) -> void:
	card.cost = 2
	card.upgrade_cost = 2
	card.is_exhaust = true
	card.is_retain = true
	card.has_explicit_upgrade = true
	var counter_effect := _rule("counter_reflect")
	counter_effect.effect_type = EffRes.EffectType.COUNTER_REFLECT
	card.effects = [_block(40, 80), counter_effect]

static func _effect(type: int, value: int = 0, upgrade: int = -1, target: String = "SELF") -> Resource:
	var e := EffRes.new()
	e.effect_type = type; e.value = value; e.base_value = value; e.upgrade_value = upgrade; e.target = target
	return e

static func _damage(value: int, upgrade: int = -1, target: String = "SINGLE", hits: int = 1) -> Resource:
	var e := _effect(EffRes.EffectType.DAMAGE, value, upgrade, target)
	e.hit_count = hits; e.damage_type = "slash"
	return e

static func _block(value: int, upgrade: int = -1, target: String = "SELF") -> Resource:
	return _effect(EffRes.EffectType.BLOCK, value, upgrade, target)

static func _draw(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.DRAW, value, upgrade)

static func _heal(value: int, upgrade: int = -1, target: String = "SELF") -> Resource:
	return _effect(EffRes.EffectType.HEAL, value, upgrade, target)

static func _heal_all(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.HEAL_ALL, value, upgrade, "ALL")

static func _morale(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.GAIN_MORALE, value, upgrade)

static func _token(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.SUMMON_TOKEN, value, upgrade)

static func _status(status: String, value: int, upgrade: int = -1, target: String = "SINGLE") -> Resource:
	var e := _effect(EffRes.EffectType.APPLY_STATUS, value, upgrade, target); e.status_type = status
	return e

static func _charm(value: int, upgrade: int = -1) -> Resource:
	return _effect(EffRes.EffectType.CHARM, value, upgrade, "SINGLE")

static func _sacrifice(value: int) -> Resource:
	return _effect(EffRes.EffectType.SACRIFICE_HP, value)

static func _conditional(value: int, upgrade_value: int, bonus: int, upgrade_bonus: int, condition: String) -> Resource:
	var e := _effect(EffRes.EffectType.CONDITIONAL_DMG, value, upgrade_value, "SINGLE")
	e.bonus_value = bonus; e.base_bonus_value = bonus; e.upgrade_bonus_value = upgrade_bonus; e.status_type = condition; e.damage_type = "slash"
	return e

static func _power(status: String, value: int, upgrade: int = -1, params: Dictionary = {}, upgrade_params: Dictionary = {}) -> Resource:
	var e := _status(status, value, upgrade, "SELF"); e.rule_params = params; e.upgrade_rule_params = upgrade_params
	return e

static func _speed(value: int, upgrade: int, turns: int, params: Dictionary = {}) -> Resource:
	var e := _effect(EffRes.EffectType.BUFF_SPEED, value, upgrade, "SELF")
	e.bonus_value = turns; e.base_bonus_value = turns; e.rule_params = params
	return e

static func _rule(rule_id: String, params: Dictionary = {}, upgrade_params: Dictionary = {}) -> Resource:
	var e := _effect(EffRes.EffectType.APPLY_STATUS)
	e.rule_id = rule_id; e.rule_params = params; e.upgrade_rule_params = upgrade_params
	if rule_id == "poison_burst_multiplier":
		e.target = "SINGLE"; e.damage_type = "poison"
	return e

static func _rule_damage(rule_id: String, value: int, upgrade_value: int, bonus: float, upgrade_bonus: int, params: Dictionary = {}) -> Resource:
	var e := _effect(EffRes.EffectType.DAMAGE, value, upgrade_value, "SINGLE")
	e.damage_type = "slash"
	e.rule_id = rule_id; e.bonus_value = int(bonus) if bonus == floor(bonus) else 0
	e.base_bonus_value = e.bonus_value; e.upgrade_bonus_value = upgrade_bonus; e.rule_params = params
	if bonus != floor(bonus):
		e.rule_params = params.duplicate(); e.rule_params["multiplier"] = bonus
	if rule_id == "consume_own_tokens_all" or params.get("target", "") == "ALL":
		e.target = "ALL"
	return e
