extends RefCounted

# Narrow current-hand ordering wrapper. v1..v4/defaults remain frozen.
const VERSION := "tempo-v5"
const Prior = preload("res://tools/tempo_decision_policy.gd")
const Base = preload("res://tools/synergy_decision_policy.gd")
const E = preload("res://resources/effect_resource.gd")
const I = preload("res://resources/intent_resource.gd")

static func _legal(bm: Object, hid: String, card: Resource, allowed: Callable) -> bool:
	return bm.deck_mgr.can_play_hero(hid, card) and (not allowed.is_valid() or allowed.call(card))

static func _plain_damage(bm: Object, card: Resource, target: int, conditional: bool = false) -> int:
	var total := 0
	for effect in card.effects:
		if effect.rule_id != "" or effect.condition != "": return -1
		if effect.damage_type != "":
			if effect.target != "SINGLE" or effect.effect_type not in ([E.EffectType.DAMAGE, E.EffectType.CONDITIONAL_DMG] if conditional else [E.EffectType.DAMAGE]): return -1
			total += bm.estimate_effect_damage(effect, card.owner_id, target) * maxi(1, effect.hit_count)
		elif effect.effect_type not in [E.EffectType.HEAL, E.EffectType.BLOCK] or effect.target not in ["SELF", "ALLY"]:
			return -1
	return total

static func _joint_affordable(bm: Object, setup: Resource, attack: Resource) -> bool:
	return bm.deck_mgr.get_effective_cost(setup.owner_id, setup) + Prior._followup_cost(bm, setup, attack) <= bm.deck_mgr.get_energy(setup.owner_id)

static func _before(choice: Dictionary, setup: Resource, hid: String, reason: String) -> Dictionary:
	return {"card": setup, "target": choice.target, "ally": hid, "score": choice.score, "version": VERSION, "reason": reason, "followup_preview": choice.card.card_name}

static func _refund_setup(bm: Object, hid: String, choice: Dictionary, allowed: Callable) -> Resource:
	if bm._active_powers.has("power.on_kill_energy_once:" + hid) or bm._turn_effect_uses.get(hid, {}).get("kill_energy", false): return null
	var enemy: Resource = bm._enemies[choice.target]
	if enemy.death_trigger != null or not enemy.phase_heal_ratios.is_empty(): return null
	var damage := _plain_damage(bm, choice.card, choice.target, true)
	if damage < bm.get_enemy_hp(choice.target) + bm._enemy_block[choice.target]: return null
	for card in bm.deck_mgr.get_hand(hid):
		if card == choice.card or not _legal(bm, hid, card, allowed) or not _joint_affordable(bm, card, choice.card): continue
		var refund := 0
		var supported := true
		for effect in card.effects:
			if effect.condition != "" or effect.rule_id != "": supported = false; break
			if effect.effect_type == E.EffectType.APPLY_STATUS and effect.status_type == "power.on_kill_energy_once" and effect.target == "SELF": refund += effect.value
			elif effect.effect_type != E.EffectType.BLOCK or effect.value != 0: supported = false; break
		if supported and refund > 0 and refund >= bm.deck_mgr.get_effective_cost(hid, card): return card
	return null

static func _exposed_attackers(bm: Object, hid: String) -> int:
	var preview: Array = bm.get_turn_queue_preview(32)
	if preview.is_empty() or preview[0] != "hero:" + hid: return 0
	var seen := {}
	var visited := {}
	for actor in preview.slice(1):
		if actor == "hero:" + hid:
			return seen.size()
		if not actor.begins_with("enemy:"): continue
		var index: int = actor.trim_prefix("enemy:").to_int()
		if visited.has(index): return 0 # a later intent would require forecasting
		visited[index] = true
		if not bm.is_enemy_alive(index): continue
		var state: Dictionary = bm._enemy_status[index]
		if int(state.get("stun", 0)) > 0 or int(state.get("enthrall", 0)) > 0: continue
		for intent in bm.get_enemy_current_intents(index):
			if intent.action_type == I.ActionType.ATTACK and bm.get_intent_display_damage(index, intent) > 0: seen[index] = true
	return 0 # no next-owner boundary in the bounded preview

static func _potential_removal(bm: Object, hid: String, allowed: Callable) -> bool:
	var hand: Array = bm.deck_mgr.get_hand(hid)
	if hand.size() > 10: return true # bounded search; uncertainty retains v3
	var budget: int = bm.deck_mgr.get_energy(hid)
	for target in range(bm._enemy_alive.size()):
		if not bm.is_enemy_alive(target): continue
		var frontier := {0: 0}
		for card in hand:
			if not bm.deck_mgr.can_play_hero(hid, card): continue
			var damage := _plain_damage(bm, card, target)
			if damage < 0: return true # conditions/resources/unknown rules not projected
			if damage == 0: continue
			if allowed.is_valid() and not allowed.call(card): return true
			var cost: int = bm.deck_mgr.get_effective_cost(hid, card)
			var previous := frontier.duplicate()
			for spent in previous:
				if int(spent) + cost <= budget:
					frontier[int(spent) + cost] = maxi(frontier.get(int(spent) + cost, 0), int(previous[spent]) + damage)
		for damage in frontier.values():
			if int(damage) >= bm.get_enemy_hp(target) + bm._enemy_block[target]: return true
	return false

static func _restorative_guard(bm: Object, hid: String, choice: Dictionary, allowed: Callable) -> Resource:
	if bm.get_hero_block(hid) > 0 or not bm._active_powers.is_empty() or _exposed_attackers(bm, hid) < 2: return null
	if _plain_damage(bm, choice.card, choice.target) <= 0 or _potential_removal(bm, hid, allowed): return null
	var missing: int = bm.team_mgr.get_hero(hid).max_hp - bm.team_mgr.get_current_hp(hid)
	if missing <= 0: return null
	for card in bm.deck_mgr.get_hand(hid):
		if card == choice.card or not _legal(bm, hid, card, allowed) or not _joint_affordable(bm, card, choice.card): continue
		var block := 0
		var heal := 0
		var supported := true
		for effect in card.effects:
			if effect.rule_id != "" or effect.condition != "" or effect.target not in ["SELF", "ALLY"]: supported = false; break
			if effect.effect_type == E.EffectType.BLOCK: block += effect.value
			elif effect.effect_type == E.EffectType.HEAL: heal += effect.value
			else: supported = false; break
		if supported and block > 0 and heal > 0: return card
	return null

static func choose(bm: Object, hid: String, allowed: Callable = Callable()) -> Dictionary:
	var choice := Prior.choose(bm, hid, allowed)
	if choice.get("card") == null or bm._get_living_enemy_count() <= 1 or bm.team_mgr.heroes.size() != 1 or bm.team_mgr.get_living_heroes().size() != 1: return choice
	# Buddhist signatures and exile require their existing specialized path.
	if int(bm._hero_status.get(hid, {}).get("exiled", 0)) > 0: return choice
	for index in range(bm._enemy_alive.size()):
		if bm.is_enemy_alive(index) and bm._enemies[index].mythology == "buddhist": return choice
	var setup := _refund_setup(bm, hid, choice, allowed)
	if setup != null: return _before(choice, setup, hid, VERSION + ":refund_before_visible_finisher")
	setup = _restorative_guard(bm, hid, choice, allowed)
	if setup != null: return _before(choice, setup, hid, VERSION + ":restorative_guard_before_affordable_attack")
	return choice

static func discard_choice(bm: Object, hid: String) -> Resource:
	return Prior.discard_choice(bm, hid)
