extends RefCounted

# Bounded evaluator policy, not a replacement combat model or optimal solver.
const Effect = preload("res://resources/effect_resource.gd")

static func is_consumer(card: Resource) -> bool:
	for effect in card.effects:
		if effect.rule_id == "consume_charm_damage":
			return true
	return false

static func target_for(bm: Object, card: Resource) -> int:
	var lock: int = bm._get_taunt_lock_target(card.owner_id)
	if lock >= 0 and bm._card_has_single_target(card):
		return lock
	for i in range(bm._enemy_alive.size()):
		if bm._enemy_alive[i]:
			return i
	return -1

static func would_enthrall(bm: Object, card: Resource, target: int) -> bool:
	var effective_target := target_for(bm, card)
	for effect in card.effects:
		if effect.effect_type != Effect.EffectType.CHARM:
			continue
		if effect.target != "ALL" and effective_target != target:
			continue
		if effect.condition == "enemy_hp_below_50" and bm.get_enemy_hp(target) * 2 > bm._enemies[target].max_hp:
			continue
		var multiplier: int = 1 + int(bm._active_powers.get("power.charm_double_apply:" + card.owner_id, {}).get("value", 0))
		if bm.will_enthrall_enemy(target, effect.value * multiplier):
			return true
	return false

static func choose(bm: Object, hero_id: String, policy: String) -> Dictionary:
	var available: Array = []
	for card in bm.deck_mgr.get_hand(hero_id):
		if bm.deck_mgr.can_play_hero(hero_id, card):
			available.append(card)
	if available.is_empty():
		return {}
	var held: Array = []
	for card in available:
		if not is_consumer(card) or policy == "hand_order":
			continue
		var target := target_for(bm, card)
		if target < 0 or int(bm._enemy_status[target].get("charm", 0)) <= 0:
			continue
		if policy == "consume_first":
			return {"card": card, "target": target, "reason": "consume_existing_charm", "held": 0}
		if int(bm._enemy_status[target].get("enthrall", 0)) > 0:
			continue
		if bm.will_enthrall_enemy(target, 0):
			held.append(card)
			continue
		for setup_card in available:
			if would_enthrall(bm, setup_card, target):
				return {"card": setup_card, "target": target_for(bm, setup_card), "reason": "complete_enthrall_before_consuming", "held": 1}
	for card in available:
		if card not in held:
			return {"card": card, "target": target_for(bm, card), "reason": "preserve_pending_enthrall" if not held.is_empty() else "hand_order", "held": held.size()}
	return {"card": null, "target": -1, "reason": "wait_for_pending_enthrall", "held": held.size()}
