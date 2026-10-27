extends SceneTree

# The card upgrade screen previews each card's upgrade on a copy. The preview
# must match what clicking the card actually does, and must not touch the deck.

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: " + message)

func _texts(card: Resource) -> Array:
	var out: Array = [card.cost]
	for effect in card.effects:
		out.append(effect.display_text())
	return out

func _run() -> void:
	# Loaded after autoloads exist; the scene script refers to them by name.
	var UpgradeScene: GDScript = load("res://scenes/card_upgrade/card_upgrade_scene.gd")
	var gm: Node = root.get_node("GameManager")
	gm.start_run("napoleon", 1)
	var deck: Array = root.get_node("DeckManager").draw_pile.duplicate()
	var cards: Array = deck + load("res://resources/card_catalog.gd").get_all_cards()
	var with_diff := 0
	for card: Resource in cards:
		if not card.can_upgrade():
			continue
		var before := _texts(card)
		var level: int = card.upgrade_level
		var preview: Resource = UpgradeScene.upgraded_copy(card)
		_check(_texts(card) == before and card.upgrade_level == level, "%s: preview leaves the deck card unchanged" % card.card_name)
		var actual: Resource = card.duplicate(true)
		gm.upgrade_card(actual)
		_check(_texts(preview) == _texts(actual), "%s: preview matches the real upgrade" % card.card_name)
		if not UpgradeScene.upgrade_diff_lines(card, preview).is_empty():
			with_diff += 1
	_check(with_diff > 0, "some upgrades produce visible change lines")
	# The preview showed "피해 12을"; Korean particles must follow the number's reading.
	var fix := func(t: String) -> String: return EffectResource.fix_korean_number_particles(t)
	_check(fix.call("피해 12을 입힙니다.") == "피해 12를 입힙니다.", "12 takes 를")
	_check(fix.call("피해 10을 입힙니다.") == "피해 10을 입힙니다.", "10 keeps 을")
	_check(fix.call("방어도 5을 얻고 독 3를 부여") == "방어도 5를 얻고 독 3을 부여", "pairs swap both ways")
	_check(fix.call("사기 2이상") == "사기 2이상", "particle-like word starts are left alone")
	print("Card upgrade preview: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)
