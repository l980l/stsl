extends RefCounted

# Versioned rollout: v1 remains frozen for reproduction and unsupported states.
const VERSION := "guard-v2"
const Base = preload("res://tools/synergy_decision_policy.gd")
const BM = preload("res://autoload/battle_manager.gd")
const E = preload("res://resources/effect_resource.gd")
const I = preload("res://resources/intent_resource.gd")

static func choose(bm: Object, hid: String, allowed: Callable = Callable()) -> Dictionary:
	var projection := forecast(bm)
	if not projection.supported: return Base.choose(bm, hid, allowed)
	if int(bm._hero_status.get(hid, {}).get("silence", 0)) > 0: return {}
	var best := {"card": null, "target": -1, "ally": "", "reason": "no_positive_action", "score": 0.0, "version": VERSION}
	for card in bm.deck_mgr.get_hand(hid):
		if not bm.deck_mgr.can_play_hero(hid, card) or (allowed.is_valid() and not allowed.call(card)): continue
		var allies: Array = [hid]
		for effect in card.effects:
			if effect.target == "ALLY":
				allies = bm.team_mgr.get_living_heroes().map(func(hero: Resource) -> String: return hero.hero_id)
				break
		var lock: int = bm._get_taunt_lock_target(hid)
		for target in range(bm._enemy_alive.size()):
			if not bm.is_enemy_alive(target) or (lock >= 0 and bm._card_has_single_target(card) and target != lock): continue
			for ally in allies:
				var value := evaluate(bm, card, target, ally, projection)
				if value.score > best.score:
					best = {"card": card, "target": target, "ally": ally, "reason": value.reason, "score": value.score, "version": VERSION}
	return best

static func _timeline(bm: Object, enemy: int, steps: int, debuffs: Dictionary) -> Dictionary:
	var counts := {}
	var vulnerable := {}
	for hero in bm.team_mgr.get_living_heroes():
		counts[hero.hero_id] = 0
		vulnerable[hero.hero_id] = int(bm._hero_status.get(hero.hero_id, {}).get("vulnerable", 0))
	var turns := 0
	for actor in bm.get_turn_queue_preview(64):
		if actor.begins_with("hero:"):
			var hid: String = actor.trim_prefix("hero:")
			counts[hid] = int(counts.get(hid, 0)) + 1
			vulnerable[hid] = maxi(0, int(vulnerable.get(hid, 0)) - 1)
		elif actor == "enemy:%d" % enemy:
			turns += 1
			if turns >= steps: return {"found": true, "hero_ends": counts, "vulnerable": vulnerable}
			if debuffs.has(turns):
				for hid in vulnerable: vulnerable[hid] += int(debuffs[turns])
	return {"found": false, "hero_ends": counts, "vulnerable": vulnerable}

static func _share(bm: Object, enemy: int, target: int, hid: String, steps: int) -> float:
	if target == I.TargetType.ALL: return 1.0
	var living: Array = bm.team_mgr.get_living_heroes()
	var pool: Array = living.filter(func(hero: Resource) -> bool: return int(bm._hero_status.get(hero.hero_id, {}).get("exiled", 0)) <= 0)
	if pool.is_empty(): return 0.0
	var status: Dictionary = bm._enemy_status[enemy]
	var taunter: String = str(status.get("taunt_source", ""))
	if int(status.get("taunt", 0)) >= steps and int(status.get("charm", 0)) <= 0 and bm.team_mgr.is_alive(taunter):
		return 1.0 if hid == taunter else 0.0
	var last: String = str(bm._last_attacker.get(enemy, ""))
	if target == I.TargetType.LAST_ATTACKER and bm.team_mgr.is_alive(last): return 1.0 if hid == last else 0.0
	if target == I.TargetType.LOWEST_HP:
		var lowest: String = pool[0].hero_id
		for hero in pool:
			if bm.team_mgr.get_current_hp(hero.hero_id) < bm.team_mgr.get_current_hp(lowest): lowest = hero.hero_id
		return 1.0 if hid == lowest else 0.0
	return 1.0 / pool.size() if pool.any(func(hero: Resource) -> bool: return hero.hero_id == hid) else 0.0

static func forecast(bm: Object) -> Dictionary:
	var unsupported := {"supported": false, "reason": "unsupported_forecast", "threat": {}}
	var enemies: Array = []
	for i in range(bm._enemy_alive.size()):
		if bm.is_enemy_alive(i): enemies.append(i)
	# One block pool cannot cover multiple attacked actions. Preserve v1 rather
	# than summing different enemies into a fictitious absorbable damage pool.
	if enemies.size() != 1: return unsupported
	var index: int = enemies[0]
	var enemy: Resource = bm._enemies[index]
	var status: Dictionary = bm._enemy_status[index]
	if enemy.time_limit_turns > 0: return unsupported
	if enemy.mythology == "buddhist" or bm.will_enthrall_enemy(index, 0): return unsupported
	for key in ["enthrall", "stun", "double_action"]:
		if int(status.get(key, 0)) > 0: return unsupported
	var pattern: Array = bm._get_active_pattern(index)
	if pattern.is_empty(): return unsupported
	var strength: int = status.get("strength", 0)
	var form: int = status.get("current_mode_index", 0)
	var steps := 0
	var attacks: Array = []
	var debuffs := {}
	for offset in range(mini(8, pattern.size())):
		var intent: Resource = pattern[(int(bm._enemy_intent_index[index]) + offset) % pattern.size()]
		steps += 1
		match intent.action_type:
			I.ActionType.ATTACK: attacks = [intent]
			I.ActionType.BUFF:
				if intent.status_type == "strength": strength += intent.value
				elif intent.status_type not in ["", "block"]: return unsupported
			I.ActionType.FORM_SWITCH:
				if not enemy.turn_modes.is_empty(): form = (form + 1) % enemy.turn_modes.size()
			I.ActionType.CHARGE_UP:
				steps += maxi(0, int(status.get("charge_remaining", intent.charge_turns)) - 1)
				var saw_debuff := false
				for payoff in intent.payoff_intents:
					if payoff.action_type == I.ActionType.ATTACK:
						if saw_debuff or payoff.target != I.TargetType.ALL: return unsupported
						attacks.append(payoff)
					elif payoff.action_type == I.ActionType.DEBUFF: saw_debuff = true
					else: return unsupported
			I.ActionType.DEBUFF:
				if intent.status_type == "vulnerable":
					if intent.target != I.TargetType.ALL: return unsupported
					debuffs[steps] = intent.value
				elif intent.status_type not in ["weak", "poison"]: return unsupported
			I.ActionType.PREPARE, I.ActionType.INFLICT_WEAKNESS:
				pass # no predicted block absorption or future damage type effects
			_: return unsupported
		if not attacks.is_empty(): break
	if attacks.is_empty(): return unsupported
	var timeline := _timeline(bm, index, steps, debuffs)
	if not timeline.found: return unsupported
	var threats := {}
	for hero in bm.team_mgr.get_living_heroes():
		var hid: String = hero.hero_id
		var total := 0.0
		var first_hit := true
		for intent in attacks:
			var ctx := BM.DamageContext.new()
			ctx.base = intent.value
			ctx.flat = strength + (int(status.get("counter_pool", 0)) if first_hit else 0)
			if int(status.get("weak", 0)) >= steps: ctx.out_pct -= 0.25
			if not enemy.turn_modes.is_empty() and form > 0: ctx.out_pct += 0.5
			var incoming_ctx := BM.DamageContext.new()
			incoming_ctx.base = BM._outgoing_damage(ctx)
			if int(timeline.vulnerable.get(hid, 0)) > 0: incoming_ctx.in_pct += 0.5
			if int(status.get("duel_lock", 0)) >= steps and str(status.get("duel_lock_owner", "")) == hid: incoming_ctx.in_pct += 0.5
			if first_hit and int(bm._hero_status.get(hid, {}).get("counter_pending", 0)) > 0: incoming_ctx.mitigation.append(0.5)
			var share := _share(bm, index, intent.target, hid, steps)
			total += Base._unit(bm, BM.compute_damage(incoming_ctx)) * share
			if share > 0: first_hit = false
		# Discount a reserve, not the actual HP cost, if another hero opportunity
		# precedes the hit. Current hero ending its active turn is not an extra one.
		var opportunities: int = int(timeline.hero_ends.get(hid, 0)) - int(bm.get_current_hero_id() == hid)
		threats[hid] = total * (0.5 if opportunities > 0 else 1.0)
	return {"supported": true, "reason": "first_attacked_action", "threat": threats, "attack_step": steps, "enemy": index}

static func _guard(bm: Object, hid: String, amount: float, threat: float, block: float) -> float:
	var needed := maxf(0.0, threat - block)
	return minf(amount, needed) * (4.0 if Base._unit(bm, bm.team_mgr.get_current_hp(hid)) <= needed else 2.2) + maxf(0.0, amount - needed) * 0.12

static func evaluate(bm: Object, card: Resource, target: int, ally: String, projection: Dictionary = {}) -> Dictionary:
	var value := Base.evaluate(bm, card, target, ally)
	if value.score <= -999.0: return value
	var projected := forecast(bm) if projection.is_empty() else projection
	if not projected.supported: return value
	var hid: String = card.owner_id
	var state: Dictionary = bm._hero_status.get(hid, {})
	var ledger := {}
	for hero in bm.team_mgr.get_living_heroes(): ledger[hero.hero_id] = float(bm.get_hero_block(hero.hero_id))
	var delta := 0.0
	for effect in card.effects:
		if effect.condition != "" and not bm._evaluate_condition(effect.condition, card): continue
		var p: Dictionary = effect.rule_params
		var old_grants := {}
		var grants := {}
		var caps := {}
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
					if ledger[hero.hero_id] <= 0: grants[hero.hero_id] = p.block
			"overflow_heal":
				var missing: int = bm.team_mgr.get_hero(ally).max_hp - bm.team_mgr.get_current_hp(ally)
				grants[ally] = mini(p.block_cap, maxi(0, bm._holy_war_amplify(int(p.heal)) - missing))
			"empty_reload":
				if bm.deck_mgr.get_hand(hid).size() == 1: grants[hid] = p.block
			"consume_own_block", "block_multi_hit": caps[hid] = p.consume_cap
			"block_transfer":
				var moved := minf(float(ledger[hid]), p.consume_cap) if ally != hid else 0.0
				grants[ally] = int(p.base) + moved
				if ally != hid: caps[hid] = p.consume_cap
			"block_to_heal": caps[ally] = p.consume_cap
		old_grants = grants.duplicate()
		if effect.rule_id == "overflow_heal":
			var missing: int = bm.team_mgr.get_hero(ally).max_hp - bm.team_mgr.get_current_hp(ally)
			old_grants[ally] = mini(p.block_cap, maxi(0, int(p.heal) - missing))
		if effect.rule_id == "block_transfer": old_grants[ally] = int(p.base) + (mini(bm.get_hero_block(hid), p.consume_cap) if ally != hid else 0)
		for recipient in caps:
			var initial := Base._unit(bm, bm.get_hero_block(recipient))
			var old_spent := minf(initial, Base._unit(bm, caps[recipient]))
			var old_penalty := minf(old_spent, Base.incoming(bm, recipient)) * 2.2
			var block := Base._unit(bm, ledger[recipient])
			var spent := minf(block, Base._unit(bm, caps[recipient]))
			var threat: float = projected.threat.get(recipient, 0.0)
			var marginal := minf(block, threat) - minf(maxf(0.0, block - spent), threat)
			delta += old_penalty - marginal * 2.2 # refund v1 once, replace once
			ledger[recipient] -= minf(ledger[recipient], caps[recipient])
		for recipient in grants:
			var amount := Base._unit(bm, grants[recipient])
			var old_amount := Base._unit(bm, old_grants[recipient])
			delta += _guard(bm, recipient, amount, projected.threat.get(recipient, 0.0), Base._unit(bm, ledger[recipient])) - Base._guard_value(bm, recipient, old_amount)
			ledger[recipient] += grants[recipient]
	return {"score": value.score + delta / maxf(1.0, bm.deck_mgr.get_effective_cost(hid, card)), "reason": VERSION + ":" + value.reason}

static func discard_choice(bm: Object, hid: String) -> Resource:
	return Base.discard_choice(bm, hid) # isolate play/guard policy, not draw policy
