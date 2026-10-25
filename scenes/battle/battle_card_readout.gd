extends RefCounted
## Read-only, deliberately bounded pre-play information. Not a combat simulator.
const Effect = preload("res://resources/effect_resource.gd")

static func _t(key: String) -> String:
	return TranslationServer.translate("battle.readout." + key)

static func describe(card: Resource, bm: Node, dm: Node, target: int = -1) -> Dictionary:
	var cost: int = dm.get_effective_cost(card.owner_id, card)
	var energy: int = dm.get_energy(card.owner_id)
	var result := {"cost": cost, "energy": energy, "lines": []}
	var lines: Array = result.lines
	lines.append(_t("cost") % [cost, energy])
	if energy < cost:
		lines.append(_t("insufficient"))
	if card.effects.is_empty():
		return result
	# Only the first effect is inspected: later effects can change resources,
	# targets or conditions. Never pretend their current-state values are final.
	var effect: Resource = card.effects[0]
	var needs_enemy: bool = effect.target == "SINGLE"
	var valid_target: bool = target >= 0 and bm.is_enemy_alive(target)
	if needs_enemy and not valid_target:
		lines.append(_t("select_target"))
	var condition_known := true
	var enabled := true
	if effect.condition != "":
		match effect.condition:
			"hand_size_0":
				# The engine removes this card from hand before resolving effects.
				enabled = dm.get_hand(card.owner_id).size() == 1 and dm.get_hand(card.owner_id).has(card)
			"owner_hp_below_50", "low_hp", "very_low_hp", "team_count_3", "enemy_count_1", "not_enemy_count_1", "team_hp_below_30", "dead_ally_any":
				enabled = bm._evaluate_condition(effect.condition, card)
			_:
				condition_known = false
		lines.append(_t("gate_on" if enabled else "gate_off") if condition_known else _t("gate_later"))
	if not enabled or not condition_known:
		return result
	var status: Dictionary = bm.get_hero_status(card.owner_id)
	var amount := 0
	var resource := ""
	match effect.rule_id:
		"consume_own_block", "block_multi_hit":
			amount = mini(bm.get_hero_block(card.owner_id), int(effect.rule_params.consume_cap))
			resource = TranslationServer.translate("keyword.block")
		"consume_own_tokens", "consume_own_tokens_all":
			amount = mini(int(status.get("tokens", 0)), int(effect.rule_params.get("consume_cap", effect.rule_params.get("consume", 0))))
			resource = TranslationServer.translate("status.tokens.name")
		"morale_spend_damage":
			var required := int(effect.rule_params.consume)
			amount = required if int(status.get("morale", 0)) >= required else 0
			resource = TranslationServer.translate("status.morale.name")
		"sacrifice_bank_payoff", "sacrifice_bank_team_block":
			amount = mini(int(status.get("sacrifice_bank", 0)), int(effect.rule_params.consume_cap))
			resource = _t("sacrifice")
		"consume_charm_damage":
			if valid_target:
				amount = mini(int(bm.get_enemy_status(target).get("charm", 0)), int(effect.rule_params.consume_cap))
				resource = TranslationServer.translate("status.charm.name")
	if resource != "":
		# 'Up to' includes conditional follow-ups (e.g. charm after base hit).
		lines.append(_t("consume") % [resource, amount])
	# Existing damage estimator excludes some mitigation, one-shot bonuses and
	# random effects. Limit this readout to ordinary first DAMAGE effects; never
	# label it final HP loss, guaranteed lethality or a complete card total.
	if effect.effect_type == Effect.EffectType.DAMAGE and effect.rule_id == "" and (effect.target == "ALL" or valid_target):
		var per_hit: int = bm.estimate_effect_damage(effect, card.owner_id, target)
		lines.append(_t("damage") % [per_hit, effect.hit_count, per_hit * effect.hit_count])
		lines.append(_t("damage_note"))
	elif effect.effect_type == Effect.EffectType.BLOCK and effect.rule_id == "":
		lines.append(_t("block") % effect.value)
		lines.append(_t("block_note"))
	elif effect.effect_type in [Effect.EffectType.CONDITIONAL_DMG, Effect.EffectType.CHARM] or effect.rule_id != "":
		lines.append(_t("state_note"))
	return result
