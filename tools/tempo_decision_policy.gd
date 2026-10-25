extends RefCounted

# Multi-enemy staged rollout. No fixture IDs, future draws or simulated writes.
const VERSION := "tempo-v3"
const Guard = preload("res://tools/guard_decision_policy.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const E = preload("res://resources/effect_resource.gd")

static func choose(bm: Object, hid: String, allowed: Callable = Callable()) -> Dictionary:
	if bm._get_living_enemy_count() <= 1: return Guard.choose(bm, hid, allowed)
	if int(bm._hero_status.get(hid, {}).get("silence", 0)) > 0: return {}
	var context := tempo_context(bm, hid)
	var best := {"card": null, "target": -1, "ally": "", "score": 0.0, "reason": "no_positive_action", "version": VERSION}
	var lock: int = bm._get_taunt_lock_target(hid)
	for card in bm.deck_mgr.get_hand(hid):
		if not bm.deck_mgr.can_play_hero(hid, card) or (allowed.is_valid() and not allowed.call(card)): continue
		var allies: Array = [hid]
		for effect in card.effects:
			if effect.target == "ALLY":
				allies = bm.team_mgr.get_living_heroes().map(func(hero: Resource) -> String: return hero.hero_id)
				break
		for target in range(bm._enemy_alive.size()):
			if not bm.is_enemy_alive(target) or (lock >= 0 and bm._card_has_single_target(card) and target != lock): continue
			for ally in allies:
				var value := evaluate(bm, card, target, ally, context)
				if value.score > best.score:
					best = {"card": card, "target": target, "ally": ally, "score": value.score, "reason": value.reason, "version": VERSION}
	return best

static func _damage(bm: Object, card: Resource, target: int) -> float:
	var amount := 0.0
	for effect in card.effects:
		if effect.damage_type == "" or (effect.condition != "" and not bm._evaluate_condition(effect.condition, card)): continue
		var block: int = 0 if effect.rule_id == "poison_tick_now" else bm._enemy_block[target]
		amount += Base._unit(bm, maxi(0, bm.estimate_effect_damage(effect, card.owner_id, target) * maxi(1, effect.hit_count) - block))
	return amount # bounded preview, not a speculative play or exact multi-hit ledger

static func tempo_context(bm: Object, hid: String) -> Dictionary:
	var hp := Base._unit(bm, bm.team_mgr.get_current_hp(hid))
	var status: Dictionary = bm._hero_status.get(hid, {})
	var poison := Base._unit(bm, status.get("poison_dmg", 0)) if int(status.get("poison_dur", 0)) > 0 else 0.0
	var pressure := maxf(0.0, Base.incoming(bm, hid) - Base._unit(bm, bm.get_hero_block(hid))) + poison
	var enemy_hp := 0.0
	var lowest := INF
	for i in range(bm._enemy_alive.size()):
		if bm.is_enemy_alive(i):
			var health := Base._unit(bm, bm.get_enemy_hp(i))
			enemy_hp += health
			lowest = minf(lowest, health)
	var visible_damage := 0.0
	var hits := 0
	var attack_cards := 0
	# Aggregate composition only: never use pile membership/order to infer draws.
	var known_cards := 0
	for card in bm.deck_mgr.get_full_deck():
		if card.owner_id != hid: continue
		known_cards += 1
		var card_hits := 0
		for effect in card.effects:
			if effect.damage_type != "": card_hits += maxi(1, effect.hit_count)
		if card_hits > 0:
			hits += card_hits
			attack_cards += 1
	for card in bm.deck_mgr.get_hand(hid):
		if not bm.deck_mgr.can_play_hero(hid, card): continue
		var best := 0.0
		for i in range(bm._enemy_alive.size()):
			if bm.is_enemy_alive(i): best = maxf(best, _damage(bm, card, i))
		visible_damage = maxf(visible_damage, best)
	# Two owner turns maximum; a rough opportunity horizon, not a win prediction.
	var horizon := 0.0 if pressure >= hp else (0.5 if enemy_hp <= visible_damage * 2.0 else 2.0)
	return {"pressure": pressure, "hp": hp, "horizon": horizon, "lowest_hp": lowest,
		"mean_attack_hits": float(hits) / maxi(1, attack_cards),
		"attack_density": float(attack_cards) / maxi(1, known_cards)}

static func _followup_cost(bm: Object, setup: Resource, other: Resource) -> int:
	var entry: Dictionary = bm.deck_mgr._heroes.get(setup.owner_id, {})
	if entry.get("pending_all_cost_zero", false): return 0
	var general: int = entry.get("pending_cost_reduction", 0)
	if int(entry.get("cost_reduction_count", 1)) <= 1: general = 0
	var attack: int = entry.get("attack_cost_reduction", 0)
	if int(setup.card_type) == 0 and int(entry.get("attack_cost_reduction_count", 1)) <= 1: attack = 0
	return maxi(0, other.cost - maxi(general, attack if int(other.card_type) == 0 else 0))

static func _power_value(bm: Object, card: Resource, effect: Resource, ctx: Dictionary) -> float:
	var v := Base._unit(bm, effect.value)
	var horizon: float = ctx.horizon
	var affordable_hits := 0
	var remaining: int = bm.deck_mgr.get_energy(card.owner_id) - bm.deck_mgr.get_effective_cost(card.owner_id, card)
	for other in bm.deck_mgr.get_hand(card.owner_id):
		if other == card or _followup_cost(bm, card, other) > remaining: continue
		var hits := 0
		for attack in other.effects:
			if attack.damage_type != "" and attack.condition == "": hits += maxi(1, attack.hit_count)
		affordable_hits = maxi(affordable_hits, hits) # one visible follow-up, not all unaffordable attacks
	var future_hits: float = ctx.mean_attack_hits * ctx.attack_density * horizon
	match effect.status_type:
		"power.bonus_per_hit", "power.strength_player": return v * (affordable_hits + future_hits) * 1.8
		"power.poison_per_turn": return v * bm._get_living_enemy_count() * horizon * 2.0
		"power.block_per_turn": return v * horizon * 1.5
		"power.draw_per_turn": return effect.value * horizon * 3.0
		"power.morale_per_turn", "power.summon_per_turn": return effect.value * horizon * 4.0
		_: return 12.0 # unsupported effects preserve v1 rather than inventing ROI

static func evaluate(bm: Object, card: Resource, target: int, ally: String, context: Dictionary = {}) -> Dictionary:
	if bm._get_living_enemy_count() <= 1: return Guard.evaluate(bm, card, target, ally)
	var value := Base.evaluate(bm, card, target, ally)
	if value.score <= -999.0: return value
	var ctx := tempo_context(bm, card.owner_id) if context.is_empty() else context
	var cost: int = bm.deck_mgr.get_effective_cost(card.owner_id, card)
	var adjustment := 0.0
	var reason: String = "focus_and_setup:" + value.reason
	var damage := _damage(bm, card, target)
	var hp := Base._unit(bm, bm.get_enemy_hp(target))
	var single_poison := false
	for effect in card.effects:
		if effect.target == "SINGLE" and effect.status_type == "poison" and (effect.condition == "" or bm._evaluate_condition(effect.condition, card)):
			single_poison = true
	if bm._card_has_single_target(card) and damage > 0.0:
		# Progress/removal, not maximum raw damage into the first living slot.
		adjustment += 12.0 * minf(1.0, damage / maxf(1.0, hp)) + 3.0 * ctx.lowest_hp / maxf(1.0, hp)
		if damage >= hp: adjustment += 20.0
	elif single_poison:
		# Status-only defense/poison cards should not seed slot0 merely on a tie.
		var status: Dictionary = bm._enemy_status[target]
		var pending := Base._unit(bm, status.get("poison_dmg", 0)) if int(status.get("poison_dur", 0)) > 0 else 0.0
		adjustment += 3.0 * ctx.lowest_hp / maxf(1.0, hp) if pending < hp else -3.0
	for effect in card.effects:
		if effect.condition != "" and not bm._evaluate_condition(effect.condition, card): continue
		if effect.status_type == "power.spend_all_energy_poison_double":
			var energy: int = bm.deck_mgr.get_energy(card.owner_id) - cost
			if energy <= 0: return {"score": -1000.0, "reason": "no_energy_for_poison_amplification"}
			var extra := 0.0
			for i in range(bm._enemy_alive.size()):
				if not bm.is_enemy_alive(i): continue
				var st: Dictionary = bm._enemy_status[i]
				if int(st.get("poison_dur", 0)) <= 0: continue
				var tick := Base._unit(bm, st.get("poison_dmg", 0))
				var health := Base._unit(bm, bm.get_enemy_hp(i))
				extra += maxf(0.0, minf(tick * (energy * 2 - 1), health - tick))
			if extra <= 0.0: return {"score": -1000.0, "reason": "seed_before_energy_poison_payoff"}
			# A genuine all-energy spend, not a free persistent-power activation.
			return {"score": extra * 1.8 / maxi(1, energy), "reason": "visible_poison_payoff_per_energy"}
		if effect.effect_type == E.EffectType.APPLY_STATUS and effect.status_type.begins_with("power."):
			adjustment += _power_value(bm, card, effect, ctx) - 12.0
	return {"score": value.score + adjustment / maxf(1.0, cost), "reason": VERSION + ":" + reason}

static func discard_choice(bm: Object, hid: String) -> Resource:
	return Guard.discard_choice(bm, hid) # rollout isolates play/target changes
