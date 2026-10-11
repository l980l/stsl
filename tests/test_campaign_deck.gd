extends SceneTree

const Deck := preload("res://autoload/deck_manager.gd")
const Card := preload("res://resources/card_resource.gd")

func _initialize() -> void:
	call_deferred("_run")

func _card(label: String, owner: String) -> Resource:
	var card := Card.new()
	card.card_name = label
	card.owner_id = owner
	return card

func _run() -> void:
	if not ProjectSettings.globalize_path("user://").get_base_dir().get_file().begins_with("STSL-campaign-bot-"):
		printerr("Use a fresh isolated campaign-bot project")
		quit(2)
		return
	var deck := Deck.new()
	var starter := _card("regression_starter", "napoleon")
	var reward := _card("regression_reward", "napoleon")
	var recruit := _card("regression_recruit", "yi_sun_sin")
	deck.add_card_to_deck(starter)
	deck.setup_for_battle(["napoleon"])
	deck.add_card_to_deck(reward)
	deck.add_card_to_deck(recruit)
	var ok := deck.get_full_deck().size() == 3
	var saved: Dictionary = deck.to_dict()
	var restored := Deck.new()
	restored.from_dict(saved)
	ok = ok and restored.get_full_deck().size() == 3
	deck.consolidate_for_battle()
	deck.setup_for_battle(["napoleon", "yi_sun_sin"])
	ok = ok and deck.get_full_deck().size() == 3 and deck.get_full_deck().has(reward)
	ok = ok and deck.get_draw_size("yi_sun_sin") == 1
	ok = deck.remove_from_deck(starter) and ok
	deck._heroes.napoleon.draw.erase(reward)
	deck._heroes.napoleon.exhaust.append(reward)
	deck.setup_for_battle(["napoleon", "yi_sun_sin"])
	ok = ok and deck.get_full_deck().size() == 2 and not deck.get_full_deck().has(starter)
	ok = ok and deck._heroes.napoleon.draw.has(reward)
	deck.setup_for_battle(["napoleon", "yi_sun_sin"])
	ok = ok and deck.get_full_deck().size() == 2
	print("Campaign deck persistence: ", "PASS" if ok else "FAIL")
	deck.free()
	restored.free()
	quit(0 if ok else 1)
