extends RefCounted

# Freeze v3 for reproduction. Focus ranks equally useful targets of one card;
# it must not make a partial hit outrank a better guard, setup or area attack.
const VERSION := "tempo-v4"
const Tempo = preload("res://tools/tempo_decision_policy.gd")
const Guard = preload("res://tools/guard_decision_policy.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const E = preload("res://resources/effect_resource.gd")

static func _focus_adjustment(bm: Object, card: Resource, target: int, context: Dictionary) -> float:
	var damage := Tempo._damage(bm, card, target)
	var hp := Base._unit(bm, bm.get_enemy_hp(target))
	var bonus := 0.0
	if bm._card_has_single_target(card) and damage > 0.0:
		bonus = 12.0 * minf(1.0, damage / maxf(1.0, hp)) + 3.0 * context.lowest_hp / maxf(1.0, hp)
		if damage >= hp: bonus += 20.0
	else:
		for effect in card.effects:
			if effect.target != "SINGLE" or effect.status_type != "poison" or (effect.condition != "" and not bm._evaluate_condition(effect.condition, card)): continue
			var state: Dictionary = bm._enemy_status[target]
			var pending := Base._unit(bm, state.get("poison_dmg", 0)) if int(state.get("poison_dur", 0)) > 0 else 0.0
			bonus = 3.0 * context.lowest_hp / maxf(1.0, hp) if pending < hp else -3.0
			break
	return bonus / maxf(1.0, bm.deck_mgr.get_effective_cost(card.owner_id, card))

static func evaluate(bm: Object, card: Resource, target: int, ally: String, context: Dictionary = {}) -> Dictionary:
	if bm._get_living_enemy_count() <= 1: return Guard.evaluate(bm, card, target, ally)
	var ctx := Tempo.tempo_context(bm, card.owner_id) if context.is_empty() else context
	var value := Tempo.evaluate(bm, card, target, ally, ctx)
	if value.score <= -999.0: return value
	# These early-return energy-conversion estimates have no v3 focus term.
	var special: bool = value.reason == "visible_poison_payoff_per_energy"
	var core: float = value.score - (0.0 if special else _focus_adjustment(bm, card, target, ctx))
	var deterministic_single := false
	for effect in card.effects:
		if effect.damage_type == "": continue
		if effect.effect_type != E.EffectType.DAMAGE or effect.target != "SINGLE" or effect.condition != "":
			deterministic_single = false
			break
		deterministic_single = true
	return {"score": core, "focus_score": value.score if deterministic_single else core, "reason": VERSION + ":core_then_target:" + value.reason}

static func choose(bm: Object, hid: String, allowed: Callable = Callable()) -> Dictionary:
	if bm._get_living_enemy_count() <= 1: return Guard.choose(bm, hid, allowed)
	if int(bm._hero_status.get(hid, {}).get("silence", 0)) > 0: return {}
	var context := Tempo.tempo_context(bm, hid)
	var best := {"card": null, "target": -1, "ally": "", "score": 0.0, "reason": "no_positive_action", "version": VERSION}
	var lock: int = bm._get_taunt_lock_target(hid)
	for card in bm.deck_mgr.get_hand(hid):
		if not bm.deck_mgr.can_play_hero(hid, card) or (allowed.is_valid() and not allowed.call(card)): continue
		var allies: Array = [hid]
		for effect in card.effects:
			if effect.target == "ALLY":
				allies = bm.team_mgr.get_living_heroes().map(func(hero: Resource) -> String: return hero.hero_id)
				break
		var card_best := {"score": -INF, "focus_score": -INF}
		for target in range(bm._enemy_alive.size()):
			if not bm.is_enemy_alive(target) or (lock >= 0 and bm._card_has_single_target(card) and target != lock): continue
			for ally in allies:
				var value := evaluate(bm, card, target, ally, context)
				if value.score <= 0.0: continue
				# Subtraction can introduce round-off; focus only resolves numerical ties.
				if value.score > card_best.score and not is_equal_approx(value.score, card_best.score) or (is_equal_approx(value.score, card_best.score) and value.focus_score > card_best.focus_score):
					card_best = {"card": card, "target": target, "ally": ally, "score": value.score, "focus_score": value.focus_score, "reason": value.reason, "version": VERSION}
		if card_best.score > best.score and not is_equal_approx(card_best.score, best.score): best = card_best
	return best

static func discard_choice(bm: Object, hid: String) -> Resource:
	return Guard.discard_choice(bm, hid)
