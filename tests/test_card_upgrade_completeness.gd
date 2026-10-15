class_name TestCardUpgradeCompleteness
extends RefCounted

const Catalog = preload("res://resources/card_catalog.gd")
const GameManagerClass = preload("res://autoload/game_manager.gd")

var passed := 0
var failed := 0

func run_all() -> Dictionary:
	var gm = GameManagerClass.new()
	var cards: Array = Catalog.get_all_cards()
	var seen: Dictionary = {}
	for card in cards:
		var key := Catalog.card_key(card)
		_check(not seen.has(key), "unique catalog key " + key)
		seen[key] = true
		_check(card.cost >= 0, "non-negative base cost " + key)
	_check(cards.size() == 216, "all 216 owner/name card definitions are registered")
	# 강화 레벨 표지만 바뀌는 새 카드를 등록하면 전체 목록 검사에서 차단한다.
	for card in cards:
		var upgraded = card.duplicate(true)
		gm.upgrade_card(upgraded)
		_check(upgraded.upgrade_level == 1 and upgraded.cost >= 0, "catalog upgrade is valid " + Catalog.card_key(card))
		_check(_gameplay_signature(card) != _gameplay_signature(upgraded), "catalog upgrade changes gameplay data " + Catalog.card_key(card))
		if card.card_name == "card.cleopatra.pharaoh_venom.name":
			_check(upgraded.effects[0].value == 0 and upgraded.effects[1].value == 20, "독력의 무효 +1 대신 본인 방어 20 강화")
	# 이 목록은 기존 GameManager 강화식이 해당 효과 유형을 건너뛰어, 강화 전후
	# 데이터 자체가 완전히 같았던 카드다. 효과 소비자는 별도 전투 테스트가 담당하고,
	# 여기서는 명시값이 실제 GameManager 경로로 적용되는지를 고정한다.
	var expected := {
		"cleopatra|card.cleopatra.desert_recipe.name": [[3, -1]],
		"cleopatra|card.cleopatra.seductive_stillness.name": [[7, 4]],
		"yi_sun_sin|card.yi_sun_sin.fleet_fire.name": [[55, -1]],
		"yi_sun_sin|card.yi_sun_sin.fighting_spirit.name": [[60, -1]],
		"yi_sun_sin|card.yi_sun_sin.turtleship_drill.name": [[6, 5]],
		"joan_of_arc|card.joan_of_arc.grace_of_spirit.name": [[6, 4]],
		"genghis_khan|card.genghis_khan.plunderers_instinct.name": [[50, -1]],
		"musashi|card.musashi.steel_strike.name": [[140, -1]],
		"musashi|card.musashi.demon_swordsman.name": [[40, -1]],
	}
	for card in cards:
		var key := Catalog.card_key(card)
		if not expected.has(key):
			continue
		_check(card.has_explicit_upgrade, "no-op replacement is explicit " + key)
		var upgraded = card.duplicate(true)
		gm.upgrade_card(upgraded)
		_check(upgraded.upgrade_level == 1 and upgraded.cost >= 0, "valid one-upgrade " + key)
		for index in range(expected[key].size()):
			var values: Array = expected[key][index]
			_check(upgraded.effects[index].value == values[0], "fixed upgraded value " + key)
			if values[1] >= 0:
				_check(upgraded.effects[index].bonus_value == values[1], "fixed upgraded bonus " + key)
	_check(expected.size() == 9, "nine previously no-op upgrades are covered")
	gm.free()
	return {"passed": passed, "failed": failed}

func _gameplay_signature(card: Resource) -> Array:
	var result: Array = [card.cost, card.is_exhaust, card.is_retain, card.is_innate]
	for effect in card.effects:
		var value: int = effect.value
		if effect.status_type == "power.spend_all_energy_poison_double":
			value = 0 # 일회성 에너지 소비 효과는 이 필드를 사용하지 않는다.
		result.append([effect.effect_type, value, effect.bonus_value, effect.hit_count, effect.target, effect.status_type, effect.rule_id, effect.rule_params.duplicate(true)])
	return result

func _check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
		push_error("[TestCardUpgradeCompleteness] FAIL: " + label)
