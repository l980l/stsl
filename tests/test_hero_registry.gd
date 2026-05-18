# tests/test_hero_registry.gd
class_name TestHeroRegistry
extends RefCounted

const HR = preload("res://resources/heroes/hero_registry.gd")

var passed: int = 0
var failed: int = 0
var _to_free: Array = []

func run_all() -> Dictionary:
	test_all_hero_ids_returns_default_three()
	test_make_hero_has_unlock_fields_default()
	test_make_hero_joan_of_arc()
	test_make_hero_genghis_khan()
	test_make_hero_musashi()
	test_get_display_info_returns_required_keys()
	for n in _to_free:
		if is_instance_valid(n):
			n.free()
	_to_free.clear()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_all_hero_ids_returns_default_three() -> void:
	print("[TestHeroRegistry] test_all_hero_ids_returns_default_three")
	var ids = HR.all_hero_ids()
	_assert(ids.size() == 6, "영웅 6명 등록")
	_assert("napoleon" in ids, "나폴레옹 포함")
	_assert("cleopatra" in ids, "클레오파트라 포함")
	_assert("yi_sun_sin" in ids, "이순신 포함")
	_assert("joan_of_arc" in ids, "잔다르크 포함")
	_assert("genghis_khan" in ids, "칭기즈칸 포함")
	_assert("musashi" in ids, "무사시 포함")

func test_make_hero_has_unlock_fields_default() -> void:
	print("[TestHeroRegistry] test_make_hero_has_unlock_fields_default")
	var default_heroes := ["napoleon", "cleopatra", "yi_sun_sin"]
	for hid in default_heroes:
		var hero = HR.make_hero(hid)
		_assert(hero != null, hid + " make_hero 반환값 있음")
		_assert(hero.hero_id == hid, hid + " hero_id 일치")
		_assert(hero.max_hp == 1000, hid + " max_hp=1000")
		_assert(hero.unlock_condition == "default", hid + " unlock_condition=default")
		_assert(hero.unlock_description == "", hid + " unlock_description 빈 문자열")

func test_make_hero_joan_of_arc() -> void:
	print("[TestHeroRegistry] test_make_hero_joan_of_arc")
	var hero = HR.make_hero("joan_of_arc")
	_assert(hero != null, "잔다르크 make_hero 반환값 있음")
	_assert(hero.hero_id == "joan_of_arc", "hero_id=joan_of_arc")
	_assert(hero.max_hp == 1000, "max_hp=1000")
	_assert(hero.unlock_condition == "clear_chapter_1", "unlock_condition=clear_chapter_1")
	_assert(hero.unlock_description != "", "unlock_description 비어있지 않음")

func test_make_hero_genghis_khan() -> void:
	print("[TestHeroRegistry] test_make_hero_genghis_khan")
	var hero = HR.make_hero("genghis_khan")
	_assert(hero != null, "칭기즈칸 make_hero 반환값 있음")
	_assert(hero.hero_id == "genghis_khan", "hero_id=genghis_khan")
	_assert(hero.max_hp == 1000, "max_hp=1000")
	_assert(hero.unlock_condition == "flag:kill_boss:enemy.egyptian.osiris", "unlock_condition=flag:kill_boss:enemy.egyptian.osiris")
	_assert(hero.unlock_description != "", "unlock_description 비어있지 않음")

func test_make_hero_musashi() -> void:
	print("[TestHeroRegistry] test_make_hero_musashi")
	var hero = HR.make_hero("musashi")
	_assert(hero != null, "무사시 make_hero 반환값 있음")
	_assert(hero.hero_id == "musashi", "hero_id=musashi")
	_assert(hero.max_hp == 1000, "max_hp=1000")
	_assert(hero.unlock_condition == "elite_kills_total>=10", "unlock_condition=elite_kills_total>=10")
	_assert(hero.unlock_description != "", "unlock_description 비어있지 않음")

func test_get_display_info_returns_required_keys() -> void:
	print("[TestHeroRegistry] test_get_display_info_returns_required_keys")
	for hid in HR.all_hero_ids():
		var info = HR.get_display_info(hid)
		_assert(not info.is_empty(), hid + " display_info 비어있지 않음")
		_assert("name" in info, hid + " name 키 존재")
		_assert("hp" in info, hid + " hp 키 존재")
		_assert("desc" in info, hid + " desc 키 존재")
		_assert("unlock_description" in info, hid + " unlock_description 키 존재")
