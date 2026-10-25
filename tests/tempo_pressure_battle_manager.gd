extends "res://tests/block_balance_battle_manager.gd"

# Observation only: preserve the real inherited intent/expiry path exactly.
var pressure_events: Array = []

func _hero_state() -> Dictionary:
	var state := {}
	for hero in team_mgr.heroes:
		state[hero.hero_id] = {"hp": team_mgr.get_current_hp(hero.hero_id), "block": get_hero_block(hero.hero_id), "alive": team_mgr.is_alive(hero.hero_id)}
	return state

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	var before := _hero_state()
	var expired_before := expired_block
	var actions_before := attacked_actions
	await super._execute_intent(enemy_index, intent)
	pressure_events.append({"enemy": enemy_index, "intent_type": intent.action_type, "intent_target": intent.target, "owner_input_boundary": get_meta("observed_owner_input", 0), "before": before, "after": _hero_state(), "expired_old_block": expired_block - expired_before, "attacked_actions": attacked_actions - actions_before})
