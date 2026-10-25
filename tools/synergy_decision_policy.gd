extends RefCounted

# Visible-state heuristic, not a solver: never rolls targets, draws, or mutates BM.
# Scores use small-number HP units in both supported combat unit systems.
const E = preload("res://resources/effect_resource.gd")
const I = preload("res://resources/intent_resource.gd")
const Charm = preload("res://tools/charm_decision_policy.gd")

static func choose(bm: Object, hero_id: String, allowed: Callable = Callable()) -> Dictionary:
	if int(bm._hero_status.get(hero_id, {}).get("silence", 0)) > 0:
		return {}
	var best := {"card": null, "target": -1, "ally": "", "reason": "no_positive_action", "score": 0.0}
	for card in bm.deck_mgr.get_hand(hero_id):
		if not bm.deck_mgr.can_play_hero(hero_id, card):
			continue
		if allowed.is_valid() and not allowed.call(card):
			continue
		var targets: Array = []
		var lock: int = bm._get_taunt_lock_target(hero_id)
		for index in range(bm._enemy_alive.size()):
			if bm.is_enemy_alive(index) and (lock < 0 or not bm._card_has_single_target(card) or index == lock):
				targets.append(index)
		var allies: Array = [hero_id]
		for effect in card.effects:
			if effect.target == "ALLY":
				allies = bm.team_mgr.get_living_heroes().map(func(hero: Resource) -> String: return hero.hero_id)
				break
		for target in targets:
			for ally in allies:
				var value := evaluate(bm, card, target, ally)
				if value.score > best.score:
					best = {"card": card, "target": target, "ally": ally, "reason": value.reason, "score": value.score}
	return best

static func _unit(bm: Object, amount: float) -> float:
	return amount * float(bm.combat_unit_divisor) / 10.0

static func incoming(bm: Object, hero_id: String) -> float:
	# Expected share for random targets; do NOT call _pick_hero_target (RNG).
	var total := 0.0
	var living: Array = bm.team_mgr.get_living_heroes().filter(func(hero: Resource) -> bool: return int(bm._hero_status.get(hero.hero_id, {}).get("exiled", 0)) <= 0)
	if not living.any(func(hero: Resource) -> bool: return hero.hero_id == hero_id): return 0.0
	var lowest := ""
	var lowest_hp := 2147483647
	for hero in living:
		var hp: int = bm.team_mgr.get_current_hp(hero.hero_id)
		if hp < lowest_hp:
			lowest = hero.hero_id
			lowest_hp = hp
	for index in range(bm._enemy_alive.size()):
		if not bm.is_enemy_alive(index) or int(bm._enemy_status[index].get("enthrall", 0)) > 0:
			continue
		for intent in bm.get_enemy_current_intents(index):
			if intent.action_type != I.ActionType.ATTACK:
				continue
			var damage := _unit(bm, bm.get_intent_display_damage(index, intent))
			if int(bm._hero_status.get(hero_id, {}).get("vulnerable", 0)) > 0: damage *= 1.5
			var status: Dictionary = bm._enemy_status[index]
			var forced: String = str(status.get("taunt_source", "")) if int(status.get("taunt", 0)) > 0 and int(status.get("charm", 0)) <= 0 else ""
			if not bm.team_mgr.is_alive(forced): forced = ""
			if intent.target == I.TargetType.ALL:
				total += damage
			elif forced != "":
				total += damage if hero_id == forced else 0.0
			elif intent.target == I.TargetType.LOWEST_HP:
				total += damage if hero_id == lowest else 0.0
			elif intent.target == I.TargetType.LAST_ATTACKER and bm.team_mgr.is_alive(str(bm._last_attacker.get(index, ""))):
				total += damage if hero_id == str(bm._last_attacker[index]) else 0.0
			else:
				total += damage / maxi(1, living.size())
	return total

static func _guard_value(bm: Object, hero_id: String, amount: float) -> float:
	var block := _unit(bm, bm.get_hero_block(hero_id))
	var needed := maxf(0.0, incoming(bm, hero_id) - block)
	var hp := _unit(bm, bm.team_mgr.get_current_hp(hero_id))
	return minf(amount, needed) * (4.0 if hp <= needed else 2.2) + maxf(0.0, amount - needed) * 0.12

static func _heal_value(bm: Object, hero_id: String, amount: float) -> float:
	var hero: Resource = bm.team_mgr.get_hero(hero_id)
	var hp: int = bm.team_mgr.get_current_hp(hero_id)
	return minf(amount, _unit(bm, hero.max_hp - hp)) * (5.0 if hp * 3 < hero.max_hp else 2.5)

static func _followup(bm: Object, card: Resource, rules: Array = [], attack: bool = false, discount: int = 0) -> bool:
	var energy: int = bm.deck_mgr.get_energy(card.owner_id) - bm.deck_mgr.get_effective_cost(card.owner_id, card)
	for other in bm.deck_mgr.get_hand(card.owner_id):
		var projected_cost: int = bm.deck_mgr.get_effective_cost(card.owner_id, other)
		if attack and int(other.card_type) == 0: projected_cost = maxi(0, projected_cost - discount)
		if other == card or projected_cost > energy:
			continue
		for effect in other.effects:
			if (rules.is_empty() and not attack) or effect.rule_id in rules or (attack and int(other.card_type) == 0 and effect.damage_type != ""):
				return true
	return false

static func evaluate(bm: Object, card: Resource, target: int, ally: String) -> Dictionary:
	var hid: String = card.owner_id
	var state: Dictionary = bm._hero_status.get(hid, {})
	var enemy_state: Dictionary = bm._enemy_status[target]
	var score := 0.0
	var reason := "immediate_value"
	var damage_total := 0.0
	var sacrifice := 0
	var cost: int = bm.deck_mgr.get_effective_cost(hid, card)
	var energy: int = bm.deck_mgr.get_energy(hid)
	var before: int = bm.deck_mgr.get_cards_played_this_turn(hid)
	for effect in card.effects:
		var p: Dictionary = effect.rule_params
		if effect.condition != "" and not bm._evaluate_condition(effect.condition, card): continue
		if effect.rule_id == "sacrifice_then_power": sacrifice += int(p.get("sacrifice", 0))
		var targets: Array = range(bm._enemy_alive.size()) if effect.target == "ALL" else [target]
		if effect.damage_type != "":
			for index in targets:
				if not bm.is_enemy_alive(index): continue
				var blocked: int = 0 if effect.rule_id == "poison_tick_now" else int(bm._enemy_block[index])
				var damage: int = maxi(0, bm.estimate_effect_damage(effect, hid, index) * maxi(1, effect.hit_count) - blocked)
				damage_total += _unit(bm, damage)
				score += _unit(bm, mini(damage, bm.get_enemy_hp(index))) * 1.8
				if damage >= bm.get_enemy_hp(index): score += 12.0
		match effect.effect_type:
			E.EffectType.SACRIFICE_HP:
				sacrifice += effect.value
				score -= _unit(bm, effect.value) * (4.0 if bm.team_mgr.get_current_hp(hid) * 3 < bm.team_mgr.get_hero(hid).max_hp else 1.2)
			E.EffectType.BLOCK, E.EffectType.BLOCK_ALL:
				for hero in bm.team_mgr.get_living_heroes():
					if effect.effect_type == E.EffectType.BLOCK_ALL or hero.hero_id == (ally if effect.target == "ALLY" else hid):
						score += _guard_value(bm, hero.hero_id, _unit(bm, effect.value))
			E.EffectType.HEAL, E.EffectType.HEAL_ALL:
				for hero in bm.team_mgr.get_living_heroes():
					if effect.effect_type == E.EffectType.HEAL_ALL or hero.hero_id == (ally if effect.target == "ALLY" else hid):
						score += _heal_value(bm, hero.hero_id, _unit(bm, effect.value))
			E.EffectType.DRAW: score += effect.value * 3.0 if energy > cost else 0.3
			E.EffectType.ENERGY: score += effect.value * 8.0
			E.EffectType.PURGE_STATUS:
				for hero in bm.team_mgr.get_living_heroes():
					if effect.target != "ALL" and hero.hero_id != hid: continue
					var status: Dictionary = bm._hero_status.get(hero.hero_id, {})
					score += _unit(bm, int(status.get("poison_dmg", 0)) * int(status.get("poison_dur", 0))) * 3.0
					score += 5.0 * (int(status.get("weak", 0)) + int(status.get("vulnerable", 0)))
			E.EffectType.GAIN_MORALE, E.EffectType.SUMMON_TOKEN: score += effect.value * 4.0
			E.EffectType.CHARM: score += _unit(bm, effect.value) * 1.5
			E.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					if bm._active_powers.has(effect.status_type + ":" + hid): return {"score": -1000.0, "reason": "already_active_power"}
					score += 12.0
				elif effect.status_type == "poison": score += _unit(bm, effect.value) * 2.5
				elif effect.status_type in ["weak", "vulnerable"]: score += 5.0
			E.EffectType.COUNTER_REFLECT:
				if bm.is_counter_window_active(target): score += 25.0
				elif int(state.get("counter_pending", 0)) <= 0: score += incoming(bm, hid) * 2.0
		match effect.rule_id:
			"consume_charm_damage":
				if int(enemy_state.get("enthrall", 0)) <= 0 and bm.will_enthrall_enemy(target, 0):
					return {"score": -1000.0, "reason": "preserve_pending_enthrall"}
				for other in bm.deck_mgr.get_hand(hid):
					if other != card and bm.deck_mgr.get_effective_cost(hid, other) + cost <= energy and Charm.would_enthrall(bm, other, target):
						score -= 40.0
						reason = "enthrall_setup_before_consumption"
			"sacrifice_then_power":
				var active: Dictionary = bm._active_powers.get(str(p.power) + ":" + hid, {})
				if int(active.get("params", {}).get("sources", {}).get(card.card_name, 0)) >= int(p.amount):
					return {"score": -1000.0, "reason": "already_active_sacrifice_power"}
				score += 12.0 - _unit(bm, int(p.sacrifice)) * 2.5
			"formation_drill":
				for hero in bm.team_mgr.get_living_heroes():
					score += _guard_value(bm, hero.hero_id, _unit(bm, p.block)) if bm.get_hero_block(hero.hero_id) <= 0 else 3.0
			"resource_to_block":
				var spent: int = mini(state.get(p.resource, 0), p.consume_cap)
				var amount := _unit(bm, int(p.get("base", 0)) + spent * int(p.per_resource))
				for hero in bm.team_mgr.get_living_heroes():
					if effect.target == "ALL" or hero.hero_id == hid: score += _guard_value(bm, hero.hero_id, amount)
				score -= spent * (4.0 if p.resource == "tokens" else 2.0)
				reason = "guard_vs_resource_income"
			"consume_own_tokens", "consume_own_tokens_all":
				score -= mini(state.get("tokens", 0), p.get("consume_cap", p.get("consume", 0))) * 4.0
				reason = "token_damage_vs_income"
			"consume_own_block", "block_multi_hit":
				var spent := _unit(bm, mini(bm.get_hero_block(hid), p.consume_cap))
				score -= minf(spent, incoming(bm, hid)) * 2.2
				reason = "block_damage_vs_survival"
			"block_transfer":
				var moved: int = mini(bm.get_hero_block(hid), p.consume_cap) if ally != hid else 0
				score += _guard_value(bm, ally, _unit(bm, int(p.base) + moved))
				score -= minf(_unit(bm, moved), incoming(bm, hid)) * 2.2
				reason = "protect_threatened_ally"
			"overflow_heal":
				score += _heal_value(bm, ally, _unit(bm, p.heal))
				var missing: int = bm.team_mgr.get_hero(ally).max_hp - bm.team_mgr.get_current_hp(ally)
				score += _guard_value(bm, ally, _unit(bm, mini(p.block_cap, maxi(0, int(p.heal) - missing))))
			"block_to_heal":
				var spent := _unit(bm, mini(bm.get_hero_block(ally), p.consume_cap))
				score += _heal_value(bm, ally, spent) - minf(spent, incoming(bm, ally)) * 2.2 + 3.0
			"bank_draw":
				score += 3.0 * (int(p.draw) + (int(p.bonus_draw) if int(state.get("sacrifice_bank", 0)) >= int(p.consume_cap) else 0))
				if _followup(bm, card, ["sacrifice_bank_payoff", "sacrifice_bank_team_block"]): score -= 8.0
				reason = "bank_draw_vs_payoff"
			"sacrifice_bank_team_block":
				var amount := _unit(bm, int(p.base) + mini(state.get("sacrifice_bank", 0), p.consume_cap))
				for hero in bm.team_mgr.get_living_heroes(): score += _guard_value(bm, hero.hero_id, amount)
			"opening_status":
				if before == 0: score += 18.0; reason = "opening_before_other_cards"
			"next_attack_first_hit_bonus", "duel_preparation":
				if _followup(bm, card, [], true): score += 16.0; reason = "prepare_affordable_attack"
			"guard_attack_discount", "morale_attack_discount":
				var ready: bool = bm.get_hero_block(hid) >= int(p.get("threshold", 0)) if effect.rule_id == "guard_attack_discount" else int(state.get("morale", 0)) >= int(p.consume)
				if ready and _followup(bm, card, [], true, int(p.amount)): score += 15.0; reason = "discount_before_attack"
			"poison_seed_spread":
				score += _unit(bm, p.seed) * 2.0 if int(enemy_state.get("poison_dur", 0)) <= 0 else _unit(bm, p.spread) * maxi(0, bm._get_living_enemy_count() - 1) * 2.0
				if _followup(bm, card, ["poison_tick_now"]): score += 12.0; reason = "seed_before_poison_payoff"
			"curse_weave":
				score += 6.0
				if _followup(bm, card, ["debuff_cash_damage", "duel_status_damage"]): score += 12.0; reason = "debuff_before_cashout"
			"heal_if_enemy_debuff":
				if int(enemy_state.get(p.status, 0)) > 0: score += _heal_value(bm, hid, _unit(bm, p.amount))
			"empty_reload":
				score += 4.0
				if bm.deck_mgr.get_hand(hid).size() == 1:
					score += _guard_value(bm, hid, _unit(bm, p.block)) + 8.0
				elif _followup(bm, card): score -= 4.0
			"recruit_or_draw": score += 6.0
			"marked_scout": score += 8.0
			"combo_energy_once": score += 8.0 if before >= int(p.threshold) else 4.0
			"discard_for_draw": score += 4.0 if bm.deck_mgr.get_hand(hid).size() > 1 and int(p.draw) > 0 else 0.0
	# Safety gate uses total printed self-cost: no deliberately fatal sacrifice.
	if sacrifice >= bm.team_mgr.get_current_hp(hid): return {"score": -1000.0, "reason": "avoid_fatal_sacrifice"}
	if damage_total >= _unit(bm, bm.get_enemy_hp(target)) and bm._get_living_enemy_count() == 1:
		score += 25.0
	return {"score": score / maxf(1.0, float(cost)), "reason": reason}

static func discard_choice(bm: Object, hero_id: String) -> Resource:
	if bm.is_discard_pick_optional() and int(bm._pending_discard_pick.get("draw_count", 0)) <= 0:
		# Do not throw a useful card away merely because a choice was offered.
		return null
	var worst: Resource = null
	var score := INF
	for card in bm.deck_mgr.get_hand(hero_id):
		var target := 0
		while target < bm._enemy_alive.size() and not bm.is_enemy_alive(target): target += 1
		if target >= bm._enemy_alive.size(): return null
		var value: float = evaluate(bm, card, target, hero_id).score
		if value < score:
			worst = card
			score = value
	return worst
