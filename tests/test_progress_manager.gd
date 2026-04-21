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
	test_increment_flag_accumulates()
	test_get_flag_int_defaults_to_zero()
	test_evaluate_default_condition()
	test_evaluate_clear_chapter_condition()
	test_evaluate_flag_prefix_condition()
	test_evaluate_threshold_condition()
	test_check_unlock_conditions_unlocks_default_heroes()
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

func test_increment_flag_accumulates() -> void:
	print("[TestProgressManager] test_increment_flag_accumulates")
	var pm = PM.new()
	pm.reset_progress()
	pm.increment_flag("elite_kills_total")
	pm.increment_flag("elite_kills_total")
	pm.increment_flag("elite_kills_total", 3)
	_assert(pm.get_flag_int("elite_kills_total") == 5, "increment_flag 누적 합산")

func test_get_flag_int_defaults_to_zero() -> void:
	print("[TestProgressManager] test_get_flag_int_defaults_to_zero")
	var pm = PM.new()
	pm.reset_progress()
	_assert(pm.get_flag_int("nonexistent") == 0, "미등록 키 기본값 0")

func test_evaluate_default_condition() -> void:
	print("[TestProgressManager] test_evaluate_default_condition")
	var pm = PM.new()
	pm.reset_progress()
	_assert(pm._evaluate_condition("default"), "default 조건은 항상 참")
	_assert(pm._evaluate_condition(""), "빈 문자열도 항상 참")

func test_evaluate_clear_chapter_condition() -> void:
	print("[TestProgressManager] test_evaluate_clear_chapter_condition")
	var pm = PM.new()
	pm.reset_progress()
	pm.chapters_cleared.clear()
	_assert(not pm._evaluate_condition("clear_chapter_1"), "챕터 미클리어 시 false")
	pm.chapters_cleared.append(1)
	_assert(pm._evaluate_condition("clear_chapter_1"), "챕터 1 클리어 후 true")

func test_evaluate_flag_prefix_condition() -> void:
	print("[TestProgressManager] test_evaluate_flag_prefix_condition")
	var pm = PM.new()
	pm.reset_progress()
	_assert(not pm._evaluate_condition("flag:kill_boss:hydra"), "플래그 미설정 시 false")
	pm.set_flag("kill_boss:hydra")
	_assert(pm._evaluate_condition("flag:kill_boss:hydra"), "플래그 설정 후 true")

func test_evaluate_threshold_condition() -> void:
	print("[TestProgressManager] test_evaluate_threshold_condition")
	var pm = PM.new()
	pm.reset_progress()
	_assert(not pm._evaluate_condition("elite_solo_kills>=5"), "카운터 부족 시 false")
	pm.increment_flag("elite_solo_kills", 5)
	_assert(pm._evaluate_condition("elite_solo_kills>=5"), "카운터 충족 시 true")
	_assert(pm._evaluate_condition("elite_solo_kills>=4"), "카운터 초과도 true")

func test_check_unlock_conditions_unlocks_default_heroes() -> void:
	print("[TestProgressManager] test_check_unlock_conditions_unlocks_default_heroes")
	var pm = PM.new()
	pm.reset_progress()
	pm.unlocked_heroes.clear()
	_assert(not pm.is_hero_unlocked("napoleon"), "초기 클리어 후 미해금 상태")
	var newly = pm.check_unlock_conditions()
	_assert("napoleon" in newly, "check_unlock_conditions: 나폴레옹 해금")
	_assert("cleopatra" in newly, "check_unlock_conditions: 클레오파트라 해금")
	_assert("yi_sun_sin" in newly, "check_unlock_conditions: 이순신 해금")
	_assert(pm.is_hero_unlocked("napoleon"), "해금 후 is_hero_unlocked true")
