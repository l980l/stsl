# Authored, legal 16-card owner decks for archetype balance fixtures.
# This is data for evaluators, not a runtime deck or a reward recommendation.
extends SceneTree

const Catalog = preload("res://resources/card_catalog.gd")
const CardRes = preload("res://resources/card_resource.gd")

# Every entry is its hero's actual 10-card starter deck plus these six distinct
# reward slugs.  The evaluator resolves a slug as card.<hero>.<slug>.name.
const DECKS: Array[Dictionary] = [
	{"id": "napoleon_charge", "hero": "napoleon", "archetype": "charge", "cards": ["cavalry_threat", "arcole_breakthrough", "austerlitz_maneuver", "emperors_power", "emperors_assault", "blitz_advance"], "plan": "Build morale with threat and early attacks, then choose between spending it for breakthrough damage or retaining it for the next payoff."},
	{"id": "napoleon_legion", "hero": "napoleon", "archetype": "legion", "cards": ["artillery_gather", "grand_armee_shield", "imperial_artillery", "guard_charge", "imperial_infantry_call", "eagle_standard"], "plan": "Recruit soldiers, turn part of that stock into a timely guard, then cash the remaining formation into artillery and legion payoffs."},
	{"id": "napoleon_command", "hero": "napoleon", "archetype": "command", "cards": ["line_reform", "charge_bugle", "emperors_command", "glory_shout", "emperors_will", "reconnaissance"], "plan": "Use discard and draw to find a compact sequence; bank morale before Bugle so the attack discount is a real ordering decision."},

	{"id": "cleopatra_poison", "hero": "cleopatra", "archetype": "poison", "cards": ["poison_seed", "poison_party", "asp_fang", "nile_mist", "serpent_power", "poison_feast"], "plan": "Seed poison on the priority target, spread it once it is established, and decide whether to accelerate a tick now or preserve duration for later turns."},
	{"id": "cleopatra_curse", "hero": "cleopatra", "archetype": "curse", "cards": ["snake_gaze", "pharaoh_fury", "cursed_gaze", "sandstorm", "desert_recipe", "ramesses_shield"], "plan": "Layer weak and vulnerable, then decide when to consume those debuffs for Pharaoh's Fury instead of keeping their defensive and damage amplification."},
	{"id": "cleopatra_charm", "hero": "cleopatra", "archetype": "charm", "cards": ["nile_whisper", "charming_perfume", "cursed_gaze", "serpent_ritual", "seductive_stillness", "charm_execution"], "plan": "Build charm toward enthrall; Perfume can convert remaining charm to block, competing with Charm Execution's damage conversion."},

	{"id": "yi_turtle_ship", "hero": "yi_sun_sin", "archetype": "turtle_ship", "cards": ["consecutive_defense", "charge_stance", "turtle_shield", "turtle_power", "turtle_ship_charge", "iron_ram"], "plan": "Create block before the enemy's next attack, reserve it for protection or spend it for Charge Stance and counter-pressure."},
	{"id": "yi_formation", "hero": "yi_sun_sin", "archetype": "formation", "cards": ["formation_boost", "naval_training", "regroup", "naval_muster", "fleet_command", "fleet_fire"], "plan": "Fleet admiral: recruit soldiers and protect the party, then cash every ally's soldiers with Fleet Broadside while moving block where it is needed."},
	{"id": "yi_desperate", "hero": "yi_sun_sin", "archetype": "desperate", "cards": ["turtle_ship_charge", "crisis_breakthrough", "miraculous_recovery", "phoenix", "death_resolve", "fighting_spirit"], "plan": "Accept controlled low health for the stronger crisis branch, while recovery cards prevent the payoff from becoming an accidental death spiral."},

	{"id": "joan_holy", "hero": "joan_of_arc", "archetype": "holy", "cards": ["holy_bolt", "orleans_charge", "holy_wave", "holy_fury", "crusaders_faith", "archangels_wrath"], "plan": "Crusade: heal the party first, then turn this turn's and this battle's healing into area damage with Archangel's Wrath and Holy Fury."},
	{"id": "joan_restoration", "hero": "joan_of_arc", "archetype": "restoration", "cards": ["holy_touch", "communion", "hymn", "guardian_angel", "angel_wings", "joan_return"], "plan": "Keep a damaged team alive through targeted and team healing; overheal-to-block and block-to-heal are deliberately conditional rather than free value."},
	{"id": "joan_martyr", "hero": "joan_of_arc", "archetype": "martyr", "cards": ["martyrdom_steps", "last_shield", "martyrs_will", "martyr_strength", "saints_revelation", "martyrs_light"], "plan": "Convert deliberate self-sacrifice into a bank, then choose draw, team block, transfer, or a consumed-bank payoff before the next enemy pressure."},

	{"id": "genghis_mobility", "hero": "genghis_khan", "archetype": "mobility", "cards": ["swift_raid", "cavalry_crossing", "khans_fury", "mobility_power", "horse_charge", "desert_cavalry"], "plan": "Open with Raid for vulnerable, reach Crossing after prior cards for its larger refund, and use draw/speed to sustain a long turn."},
	{"id": "genghis_horde", "hero": "genghis_khan", "archetype": "horde", "cards": ["cavalry_charge_speed", "arrow_volley", "cavalry_encirclement", "horde_advance", "horde_volley", "khans_banner"], "plan": "Gallop: soldiers fire on every Genghis turn, so raise speed to act more often, keep soldiers alive, and fire Horde Volley when faster than every enemy."},
	{"id": "genghis_plunder", "hero": "genghis_khan", "archetype": "plunder", "cards": ["loot", "war_tribute", "massacre_khan", "spoils_distribution", "executioners_bounty", "khans_treasury"], "plan": "Mark targets and draw through the hunt, then cash only Genghis's own marks into War Tribute without stealing another owner's setup."},

	{"id": "musashi_dual_blades", "hero": "musashi", "archetype": "dual_blades", "cards": ["niten_slash", "whirlwind_cut", "twin_blades_basic", "twin_sword_power", "rhythm_of_strikes", "flying_swallow"], "plan": "Stack multi-hit support and strike rhythm; Whirlwind's block consumption makes the two-hit payoff compete with defense."},
	{"id": "musashi_duel", "hero": "musashi", "archetype": "duel", "cards": ["courage", "single_cut", "blood_path", "peak_aim", "swordsmans_resolve", "blade_polish"], "plan": "Prepare a single-enemy duel with block and strength, then consume weak only when Single Cut's isolated target payoff is available."},
	{"id": "musashi_empty_mind", "hero": "musashi", "archetype": "empty_mind", "cards": ["empty_state", "empty_guard", "mushin_power", "five_rings_realm", "void_guard", "mushin_burst"], "plan": "Deliberately exhaust or discard down to an empty hand, then choose between the empty-hand refill/guard and its stronger attack payoffs."},
]

var _passed := 0
var _failed := 0

func _init() -> void:
	_validate()
	print("Archetype deck definitions: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _validate() -> void:
	var catalog: Dictionary = {}
	for card in Catalog.get_all_cards():
		catalog[card.owner_id + "|" + card.card_name] = card
	_check(DECKS.size() == 18, "exactly 18 hero/archetype decks")
	var ids: Dictionary = {}
	var hero_archetypes: Dictionary = {}
	for deck in DECKS:
		var id: String = deck.get("id", "")
		var hero: String = deck.get("hero", "")
		var archetype: String = deck.get("archetype", "")
		_check(not ids.has(id), id + " has a unique id")
		ids[id] = true
		hero_archetypes[hero] = int(hero_archetypes.get(hero, 0)) + 1
		var starter: Dictionary = {}
		var source = Catalog._HERO_CARDS.get(hero)
		_check(source != null, id + " references a production hero")
		if source == null:
			continue
		for card in source.starter_deck():
			starter[card.card_name] = true
		var slugs: Array = deck.get("cards", [])
		_check(slugs.size() == 6, id + " has exactly six reward cards")
		var seen: Dictionary = {}
		var rares := 0
		var legendary := 0
		for slug_value in slugs:
			var slug: String = slug_value
			var key := "card.%s.%s.name" % [hero, slug]
			var card = catalog.get(hero + "|" + key)
			_check(card != null, id + " resolves " + key)
			if card == null:
				continue
			_check(not starter.has(key), id + " excludes actual starter " + slug)
			_check(not seen.has(key), id + " has distinct reward " + slug)
			seen[key] = true
			rares += 1 if card.rarity == CardRes.Rarity.RARE else 0
			legendary += 1 if card.rarity == CardRes.Rarity.LEGENDARY else 0
			_check(card.rarity != CardRes.Rarity.DIVINE, id + " excludes divine " + slug)
		_check(rares <= 2, id + " has at most two rare rewards (%d)" % rares)
		_check(legendary <= 1, id + " has at most one legendary reward (%d)" % legendary)
		_check(str(deck.get("plan", "")).length() > 20, id + " records an actionable plan")
	for hero in Catalog.HERO_ORDER:
		_check(hero_archetypes.get(hero, 0) == 3, hero + " has three archetype decks")

func _check(condition: bool, label: String) -> void:
	if condition:
		_passed += 1
	else:
		_failed += 1
		push_error("FAIL: " + label)
