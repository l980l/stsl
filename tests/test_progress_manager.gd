# tests/test_progress_manager.gd
class_name TestProgressManager
extends RefCounted

const PM = preload("res://autoload/progress_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_default_unlocked_heroes()
	test_mark_chapter_cleared_dedup()
	test_is_chapter_unlocked()
	test_unlock_hero_returns_false_if_duplicate()
	test_unlock_flags_roundtrip()
	test_to_dict_from_dict_roundtrip()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func test_default_unlocked_heroes() -> void:
	print("[TestProgressManager] test_default_unlocked_heroes")
	var pm = PM.new()
	pm.reset_progress()
	_assert(pm.is_hero_unlocked("napoleon"), "나폴레옹 기본 해금")
	_assert(pm.is_hero_unlocked("cleopatra"), "클레오파트라 기본 해금")
	_assert(pm.is_hero_unlocked("yi_sun_sin"), "이순신 기본 해금")
	_assert(not pm.is_hero_unlocked("jeanne_darc"), "미등록 영웅은 잠금")

func test_mark_chapter_cleared_dedup() -> void:
	print("[TestProgressManager] test_mark_chapter_cleared_dedup")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.clear()
	pm.mark_chapter_cleared(1)
	pm.mark_chapter_cleared(1)
	_assert(pm.chapters_cleared.size() == 1, "중복 마킹 시 1회만 기록")

func test_is_chapter_unlocked() -> void:
	print("[TestProgressManager] test_is_chapter_unlocked")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.clear()
	_assert(pm.is_chapter_unlocked(1), "챕터 1은 항상 해금")
	_assert(not pm.is_chapter_unlocked(2), "챕터 1 미클리어 시 챕터 2 잠금")
	pm.chapters_cleared.append(1)
	_assert(pm.is_chapter_unlocked(2), "챕터 1 클리어 후 챕터 2 해금")

func test_unlock_hero_returns_false_if_duplicate() -> void:
	print("[TestProgressManager] test_unlock_hero_returns_false_if_duplicate")
	var pm = PM.new()
	pm.reset_progress()
	var first = pm.unlock_hero("jeanne_darc")
	var second = pm.unlock_hero("jeanne_darc")
	_assert(first == true, "신규 해금은 true 반환")
	_assert(second == false, "중복 해금은 false 반환")
	_assert(pm.is_hero_unlocked("jeanne_darc"), "신규 영웅 해금 상태 보존")

func test_unlock_flags_roundtrip() -> void:
	print("[TestProgressManager] test_unlock_flags_roundtrip")
	var pm = PM.new()
	pm.reset_progress()
	_assert(not pm.has_flag("killed_hydra"), "초기값 false")
	pm.unlock_flags["killed_hydra"] = true
	_assert(pm.has_flag("killed_hydra"), "플래그 설정 후 true")

func test_to_dict_from_dict_roundtrip() -> void:
	print("[TestProgressManager] test_to_dict_from_dict_roundtrip")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.append(1)
	pm.unlocked_heroes.append("jeanne_darc")
	pm.unlock_flags["killed_hydra"] = true

	var d = pm.to_dict()
	var pm2 = PM.new()
	pm2.from_dict(d)
	_assert(pm2.chapters_cleared == [1], "chapters_cleared 복원")
	_assert("jeanne_darc" in pm2.unlocked_heroes, "unlocked_heroes 복원")
	_assert(pm2.has_flag("killed_hydra"), "unlock_flags 복원")
