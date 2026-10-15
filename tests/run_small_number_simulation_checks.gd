extends SceneTree

const Sim = preload("res://tools/simulate_small_number_battles.gd")
const Fixture = preload("res://tests/test_card_revision_runtime.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var fixture = Fixture.new()
	var bm = fixture._battle(["napoleon"])
	var first = fixture._card("napoleon", 0, 10)
	first.card_name = "test.first"
	var second = fixture._card("napoleon", 0, 20)
	second.card_name = "test.second"
	bm.deck_mgr._heroes.napoleon.hand.assign([first, second])
	bm.deck_mgr._heroes.napoleon.energy = 2
	bm._hero_status.napoleon = {"strength": 2, "speed_bonus": [{"value": 4, "dur": 3}]}
	var before: Dictionary = Sim._snapshot(bm, "test", "napoleon", 0)
	bm._hero_status.napoleon.strength = 99
	bm._hero_status.napoleon.speed_bonus[0].dur = 1
	bm.deck_mgr._heroes.napoleon.hand.reverse()
	bm.deck_mgr._heroes.napoleon.energy = 0
	var after: Dictionary = Sim._snapshot(bm, "test", "napoleon", 0)
	var checks := [
		before.heroes.napoleon.status.strength == 2,
		before.heroes.napoleon.status.speed_bonus[0].dur == 3,
		before.heroes.napoleon.deck.hand[0].name == "test.first" and after.heroes.napoleon.deck.hand[0].name == "test.second",
		before.heroes.napoleon.deck.energy == 2 and after.heroes.napoleon.deck.energy == 0,
		before != after,
	]
	var failed := checks.count(false)
	fixture._free(bm)
	print("Simulation snapshot checks: %d passed, %d failed" % [checks.size() - failed, failed])
	quit(1 if failed > 0 else 0)
