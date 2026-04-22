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
	LabelUtils.fit_text(name_label, 36, 20)
	LabelUtils.fit_text(desc_label, 20, 12)
	for choice in event.choices:
		var btn := Button.new()
		btn.text = choice.label
		btn.pressed.connect(_on_choice_selected.bind(choice))
		choices_container.add_child(btn)

func _on_choice_selected(choice: Resource) -> void:
	_apply_choice(choice)
	GameManager.complete_event()

func _apply_choice(choice: Resource) -> void:
	match choice.effect_type:
		choice.EffectType.GOLD:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
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
		choice.EffectType.ADD_RELIC:
			if choice.cost_hp > 0:
				for hero in TeamManager.heroes:
					TeamManager.take_damage(hero.hero_id, choice.cost_hp)
			var relic: Resource = GameManager.get_random_relic()
			if relic:
				GameManager.add_relic(relic)
		choice.EffectType.ADD_RELIC_GAMBLE:
			var relic: Resource
			if randf() < 0.5:
				relic = GameManager.get_random_relic()
			else:
				relic = GameManager.get_random_cursed_relic()
			if relic:
				GameManager.add_relic(relic)
		choice.EffectType.ADD_HERO:
			GameManager.recruit_random_hero()
		choice.EffectType.NONE:
			pass
