# tests/test_locale_manager.gd
class_name TestLocaleManager
extends RefCounted

const LocaleManagerClass = preload("res://autoload/locale_manager.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	print("--- TestLocaleManager ---")
	test_locales_list_contains_all_eight()
	test_display_names_for_all_locales()
	test_set_locale_valid_updates_current()
	test_set_locale_invalid_rejected()
	test_get_display_name_known()
	test_get_display_name_unknown_returns_code()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return { "passed": passed, "failed": failed }

func _assert(condition: bool, msg: String) -> void:
	if condition:
		print("  PASS: " + msg)
		passed += 1
	else:
		print("  FAIL: " + msg)
		failed += 1

func _make_lm() -> LocaleManagerClass:
	var lm := LocaleManagerClass.new()
	_to_free.append(lm)
	return lm

func test_locales_list_contains_all_eight() -> void:
	var lm := _make_lm()
	_assert(lm.LOCALES.size() == 9, "LOCALES 9개 (el en es fr it ja ko zh zh_TW)")
	_assert("ko" in lm.LOCALES, "ko 포함")
	_assert("es" in lm.LOCALES, "es(스페인어) 포함")
	_assert(not "ar" in lm.LOCALES, "ar(아랍어) 미지원 — RTL 미구현")

func test_display_names_for_all_locales() -> void:
	var lm := _make_lm()
	for code in lm.LOCALES:
		_assert(lm.get_display_name(code) != code, "display_name '%s' 존재" % code)

func test_set_locale_valid_updates_current() -> void:
	var lm := _make_lm()
	lm.current_locale = "ko"
	lm.set_locale("en")
	_assert(lm.current_locale == "en", "set_locale('en') → current_locale == 'en'")
	lm.set_locale("ko")

func test_set_locale_invalid_rejected() -> void:
	var lm := _make_lm()
	lm.current_locale = "ko"
	lm.set_locale("xx")
	_assert(lm.current_locale == "ko", "잘못된 로케일 'xx' 거부 → current_locale 불변")

func test_get_display_name_known() -> void:
	var lm := _make_lm()
	_assert(lm.get_display_name("ko") == "한국어", "ko → 한국어")
	_assert(lm.get_display_name("es") == "Español", "es → Español")
	_assert(lm.get_display_name("ja") == "日本語", "ja → 日本語")

func test_get_display_name_unknown_returns_code() -> void:
	var lm := _make_lm()
	_assert(lm.get_display_name("zz") == "zz", "알 수 없는 코드 → 코드 자체 반환")
