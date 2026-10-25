extends RefCounted

# Diagnostic interventions only. The frozen shared/campaign policy is untouched.
const Base = preload("res://tools/synergy_decision_policy.gd")
const BM = preload("res://autoload/battle_manager.gd")
const E = preload("res://resources/effect_resource.gd")
const I = preload("res://resources/intent_resource.gd")
const MODES := ["synergy", "no_block_spend", "legacy_ally", "random_risk", "prepare_guard", "marginal_guard"]

static func choose(bm: Object, hid: String, mode: String) -> Dictionary:
	if mode == "synergy": return Base.choose(bm, hid)
	if int(bm._hero_status.get(hid, {}).get("silence", 0)) > 0: return {}
	var best := {"card": null, "target": -1, "ally": "", "reason": "no_positive_action", "score": 0.0}
	for card in bm.deck_mgr.get_hand(hid):
		if not bm.deck_mgr.can_play_hero(hid, card): continue
		var allies: Array = [hid]
		for effect in card.effects:
			if effect.target == "ALLY":
				allies = [_legacy_ally(bm, card)] if mode == "legacy_ally" else bm.team_mgr.get_living_heroes().map(func(hero: Resource) -> String: return hero.hero_id)
				break
		var lock: int = bm._get_taunt_lock_target(hid)
		for target in range(bm._enemy_alive.size()):
			if not bm.is_enemy_alive(target) or (lock >= 0 and bm._card_has_single_target(card) and target != lock): continue
			for ally in allies:
				var value := Base.evaluate(bm, card, target, ally)
				if value.score <= -999.0: continue # preserve hard safety gates, not ordinary negative valuations
				if mode == "no_block_spend":
					var consumes := false
					for effect in card.effects:
						if effect.rule_id in ["consume_own_block", "block_multi_hit"] and bm.get_hero_block(hid) > 0: consumes = true
						if effect.rule_id == "block_transfer" and ally != hid and bm.get_hero_block(hid) > 0: consumes = true
						if effect.rule_id == "block_to_heal" and bm.get_hero_block(ally) > 0: consumes = true
					if consumes: continue
				var adjustment := _adjustment(bm, card, ally, mode)
				var score: float = value.score + adjustment / maxf(1.0, bm.deck_mgr.get_effective_cost(hid, card))
				if score > best.score:
					best = {"card": card, "target": target, "ally": ally, "reason": mode + ":" + value.reason, "score": score}
	return best

static func _legacy_ally(bm: Object, card: Resource) -> String:
	var transfer: bool = card.effects.any(func(effect: Resource) -> bool: return effect.rule_id == "block_transfer")
	var best: String = card.owner_id
	var hp := 2147483647
	for hero in bm.team_mgr.get_living_heroes():
		if transfer and hero.hero_id == card.owner_id: continue
		if bm.team_mgr.get_current_hp(hero.hero_id) < hp:
			best = hero.hero_id
			hp = bm.team_mgr.get_current_hp(best)
	return best

static func demand(bm: Object, hid: String, mode: String) -> float:
	var ordinary := Base.incoming(bm, hid)
	if mode == "random_risk":
		var n: int = bm.team_mgr.get_living_heroes().size()
		for i in range(bm._enemy_alive.size()):
			if not bm.is_enemy_alive(i) or int(bm._enemy_status[i].get("enthrall", 0)) > 0: continue
			var status: Dictionary = bm._enemy_status[i]
			if int(status.get("taunt", 0)) > 0 and int(status.get("charm", 0)) <= 0 and bm.team_mgr.is_alive(str(status.get("taunt_source", ""))): continue
			for intent in bm.get_enemy_current_intents(i):
				if intent.action_type == I.ActionType.ATTACK and intent.target == I.TargetType.RANDOM:
					var damage := Base._unit(bm, bm.get_intent_display_damage(i, intent))
					if int(bm._hero_status.get(hid, {}).get("vulnerable", 0)) > 0: damage *= 1.5
					ordinary += damage * (1.0 - 1.0 / maxi(1, n))
		return ordinary
	if mode != "prepare_guard": return ordinary
	# Bounded authored-pattern lookahead: no target RNG, no future draws. This
	# values a reserve for the first attack, not the sum of all future attacks.
	var future := 0.0
	for i in range(bm._enemy_alive.size()):
		if not bm.is_enemy_alive(i) or int(bm._enemy_status[i].get("enthrall", 0)) > 0: continue
		var enemy: Resource = bm._enemies[i]
		var pattern: Array = bm._get_active_pattern(i)
		if pattern.is_empty(): continue
		var strength: int = bm._enemy_status[i].get("strength", 0)
		var form: int = bm._enemy_status[i].get("current_mode_index", 0)
		var steps := 0
		for offset in range(mini(8, pattern.size())):
			var intent: Resource = pattern[(int(bm._enemy_intent_index[i]) + offset) % pattern.size()]
			steps += 1
			if intent.action_type == I.ActionType.BUFF and intent.status_type == "strength": strength += intent.value
			if intent.action_type == I.ActionType.FORM_SWITCH and not enemy.turn_modes.is_empty(): form = (form + 1) % enemy.turn_modes.size()
			if intent.action_type == I.ActionType.CHARGE_UP:
				steps += maxi(0, int(bm._enemy_status[i].get("charge_remaining", intent.charge_turns)) - 1)
				for payoff in intent.payoff_intents:
					if payoff.action_type == I.ActionType.ATTACK:
						intent = payoff
						break
			if intent.action_type != I.ActionType.ATTACK: continue
			var ctx := BM.DamageContext.new()
			ctx.base = intent.value
			ctx.flat = strength + int(bm._enemy_status[i].get("counter_pool", 0))
			if int(bm._enemy_status[i].get("weak", 0)) > 0: ctx.out_pct -= 0.25
			if not enemy.turn_modes.is_empty() and form > 0: ctx.out_pct += 0.5
			var damage := Base._unit(bm, BM.compute_damage(ctx))
			if int(bm._hero_status.get(hid, {}).get("vulnerable", 0)) > 0: damage *= 1.5
			var share := 1.0 if intent.target == I.TargetType.ALL else 1.0 / maxi(1, bm.team_mgr.get_living_heroes().size())
			if intent.target == I.TargetType.LOWEST_HP:
				var lowest := ""
				var hp := 2147483647
				for hero in bm.team_mgr.get_living_heroes():
					if bm.team_mgr.get_current_hp(hero.hero_id) < hp:
						lowest = hero.hero_id
						hp = bm.team_mgr.get_current_hp(lowest)
				share = 1.0 if hid == lowest else 0.0
			# Existing ATB preview is copied. Discount reserve when this hero can
			# act again before the forecast hit; do not assume future card plays.
			var enemy_turns := 0
			var skipped_current := false
			for actor in bm.get_turn_queue_preview(32):
				if not skipped_current and actor == bm.get_current_actor_id():
					skipped_current = true
					continue
				if actor == "hero:" + hid: break
				if actor == "enemy:%d" % i: enemy_turns += 1
			future += damage * share * (1.0 if enemy_turns >= steps else 0.5)
			break
	return maxf(ordinary, future)

static func _guard(bm: Object, hid: String, amount: float, threat: float) -> float:
	var needed := maxf(0.0, threat - Base._unit(bm, bm.get_hero_block(hid)))
	return minf(amount, needed) * (4.0 if Base._unit(bm, bm.team_mgr.get_current_hp(hid)) <= needed else 2.2) + maxf(0.0, amount - needed) * 0.12

static func _adjustment(bm: Object, card: Resource, ally: String, mode: String) -> float:
	var hid: String = card.owner_id
	var delta := 0.0
	var state: Dictionary = bm._hero_status.get(hid, {})
	for effect in card.effects:
		if effect.condition != "" and not bm._evaluate_condition(effect.condition, card): continue
		var p: Dictionary = effect.rule_params
		var grants := {}
		var spends := {}
		if effect.effect_type in [E.EffectType.BLOCK, E.EffectType.BLOCK_ALL]:
			for hero in bm.team_mgr.get_living_heroes():
				if effect.effect_type == E.EffectType.BLOCK_ALL or hero.hero_id == (ally if effect.target == "ALLY" else hid): grants[hero.hero_id] = effect.value
		match effect.rule_id:
			"resource_to_block", "sacrifice_bank_team_block":
				var amount: int = int(p.get("base", 0)) + (mini(state.get(p.resource, 0), p.consume_cap) * int(p.per_resource) if effect.rule_id == "resource_to_block" else mini(state.get("sacrifice_bank", 0), p.consume_cap))
				for hero in bm.team_mgr.get_living_heroes():
					if effect.rule_id == "sacrifice_bank_team_block" or effect.target == "ALL" or hero.hero_id == hid: grants[hero.hero_id] = amount
			"formation_drill":
				for hero in bm.team_mgr.get_living_heroes():
					if bm.get_hero_block(hero.hero_id) <= 0: grants[hero.hero_id] = p.block
			"overflow_heal":
				var missing: int = bm.team_mgr.get_hero(ally).max_hp - bm.team_mgr.get_current_hp(ally)
				grants[ally] = mini(p.block_cap, maxi(0, int(p.heal) - missing))
			"consume_own_block", "block_multi_hit": spends[hid] = mini(bm.get_hero_block(hid), p.consume_cap)
			"block_transfer":
				var moved: int = mini(bm.get_hero_block(hid), p.consume_cap) if ally != hid else 0
				grants[ally] = int(p.base) + moved
				spends[hid] = moved
			"block_to_heal": spends[ally] = mini(bm.get_hero_block(ally), p.consume_cap)
		for target in grants:
			if mode in ["random_risk", "prepare_guard"]:
				var amount := Base._unit(bm, grants[target])
				delta += _guard(bm, target, amount, demand(bm, target, mode)) - _guard(bm, target, amount, Base.incoming(bm, target))
		for target in spends:
			var spent := Base._unit(bm, spends[target])
			var old := minf(spent, Base.incoming(bm, target)) * 2.2
			var threat := demand(bm, target, mode)
			var penalty := minf(spent, threat) * 2.2
			if mode == "marginal_guard":
				var block := Base._unit(bm, bm.get_hero_block(target))
				penalty = (minf(block, threat) - minf(maxf(0.0, block - spent), threat)) * 2.2
			delta += old - penalty
	return delta
