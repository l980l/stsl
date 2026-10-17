extends "res://autoload/battle_manager.gd"

# Evaluation-only ablation: both sides use production effects and small units.
# No gameplay setting or production balance rule is changed by this fixture.
var keep_block := false
var expired_block := 0
var attacked_actions := 0

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	var action_block: Dictionary = {}
	await _execute_intent_effects(enemy_index, intent, action_block)
	if not action_block.is_empty():
		attacked_actions += 1
	if not keep_block:
		for hero_id: String in action_block:
			expired_block += _spend_block(hero_id, int(action_block[hero_id]))
