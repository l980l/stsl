# scenes/event/event_scene.gd
extends Node2D

@onready var name_label: Label = $VBoxContainer/EventNameLabel
@onready var desc_label: Label = $VBoxContainer/EventDescLabel
@onready var choices_container: HBoxContainer = $VBoxContainer/ChoicesContainer

func _ready() -> void:
	var event: Resource = GameManager.pending_event
	if event == null:
		GameManager._request_scene("res://scenes/map/map_scene.tscn")
		return
	name_label.text = event.event_name
	desc_label.text = event.description
	for choice in event.choices:
		var btn := Button.new()
		btn.text = choice.label
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choices_container.add_child(btn)

func _on_choice_selected(choice: Resource) -> void:
	_apply_choice(choice)
	GameManager.pending_event = null
	GameManager._advance_nodes_from(GameManager.current_node_id)
	GameManager.change_state(GameManager.GameState.MAP)
	GameManager._request_scene("res://scenes/map/map_scene.tscn")

func _apply_choice(choice: Resource) -> void:
	match choice.effect_type:
		choice.EffectType.GOLD:
			GameManager.add_gold(choice.value)
		choice.EffectType.HEAL:
			if GameManager.spend_gold(choice.cost_gold):
				for hero in TeamManager.heroes:
					TeamManager.heal(hero.hero_id, choice.value)
		choice.EffectType.DRAW_UP:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			DeckManager.base_draw_count += choice.value
		choice.EffectType.REMOVE_CARD:
			if not DeckManager.draw_pile.is_empty():
				DeckManager.draw_pile.remove_at(
					randi() % DeckManager.draw_pile.size())
		choice.EffectType.ADD_HERO:
			var pool := GameManager._recruit_hero_pool()
			if pool.is_empty():
				return
			var hero: Resource = pool[randi() % pool.size()]
			TeamManager.add_hero(hero)
			GameManager._add_initial_deck_for(hero)
		choice.EffectType.NONE:
			pass
