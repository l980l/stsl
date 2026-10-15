# tests/test_effect_display_text.gd
class_name TestEffectDisplayText
extends RefCounted

const EffectRes = preload("res://resources/effect_resource.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_all_effect_types_return_string()
	test_morale_block_displays_actual_coefficient()
	test_poison_burst_displays_actual_multiplier()
	test_content_contracts_are_localized()
	test_charm_power_displays_actual_multiplier()
	test_block_ratio_displays_integer_percent()
	return {"passed": passed, "failed": failed}

func test_block_ratio_displays_integer_percent() -> void:
	var original_locale := TranslationServer.get_locale()
	var eff := EffectRes.new()
	eff.rule_id = "consume_own_block"
	eff.value = 6
	eff.rule_params = {"consume_cap": 8, "multiplier": 1.5}
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		var text := eff.display_text()
		_assert(text.contains("150%") and not text.contains("1.5") and not text.contains("{"), "방어 소비 비율은 소수 없는 150%% 표시 (%s)" % locale)
	TranslationServer.set_locale(original_locale)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_all_effect_types_return_string() -> void:
	var eff := EffectRes.new()
	for t in EffectRes.EffectType.values():
		eff.effect_type = t
		eff.value = 5
		eff.bonus_value = 10
		eff.hit_count = 1
		eff.target = "SINGLE"
		eff.status_type = "test"
		var result: String = eff.display_text()
		_assert(result != null, "EffectType %d display_text() non-null" % t)
		_assert(result is String, "EffectType %d display_text() is String" % t)
		_assert(result != "", "EffectType %d display_text() 빈 문자열 아님" % t)

func test_morale_block_displays_actual_coefficient() -> void:
	var original_locale := TranslationServer.get_locale()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.MORALE_TO_BLOCK
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for amount in [1, 5]:
			eff.value = amount
			var text := eff.display_text()
			_assert(text.contains(str(amount)) and not text.contains("{amount}"), "사기 방어 실제 계수 %d 표시 (%s)" % [amount, locale])
	TranslationServer.set_locale(original_locale)

func test_poison_burst_displays_actual_multiplier() -> void:
	var original_locale := TranslationServer.get_locale()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.POISON_BURST
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for target in ["SINGLE", "ALL"]:
			eff.target = target
			for amount in [100, 114]:
				eff.value = amount
				_assert(eff.display_text().contains(str(amount)), "독 폭발 실제 계수 %d%% 표시 (%s/%s)" % [amount, locale, target])
	TranslationServer.set_locale(original_locale)

func test_content_contracts_are_localized() -> void:
	var original_locale := TranslationServer.get_locale()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.APPLY_STATUS
	for locale in ["ko", "en", "fr", "it", "es", "ja", "el", "zh", "zh_TW", "ru", "pt", "pl", "de"]:
		TranslationServer.set_locale(locale)
		eff.status_type = "duel_lock"
		eff.value = 3
		var duel := eff.display_text()
		_assert(duel.contains("3") and duel.contains("50%") and not duel.contains("{turns}"), "결투 계약 번역·지속 표시 (%s)" % locale)
		eff.status_type = "power.spend_all_energy_poison_double"
		var poison := eff.display_text()
		_assert(not poison.begins_with("effect.") and poison.contains("0"), "독력 소비·에너지 0 계약 번역 (%s)" % locale)
	TranslationServer.set_locale(original_locale)

func test_charm_power_displays_actual_multiplier() -> void:
	var original_locale := TranslationServer.get_locale()
	var eff := EffectRes.new()
	eff.effect_type = EffectRes.EffectType.APPLY_STATUS
	eff.status_type = "power.charm_double_apply"
	for locale in ["ko", "en"]:
		TranslationServer.set_locale(locale)
		for amount in [1, 2]:
			eff.value = amount
			_assert(eff.display_text().contains(str(1 + amount)), "매혹 실제 배율 %d 표시 (%s)" % [1 + amount, locale])
	TranslationServer.set_locale(original_locale)
