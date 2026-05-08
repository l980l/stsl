# tests/test_encounter_weighting.gd
class_name TestEncounterWeighting
extends RefCounted

const _GMScript = preload("res://autoload/game_manager.gd")

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_floor0_low_indices()
	test_floor5_mid_indices()
	test_floor9_high_indices()
	test_weighted_pick_deterministic()
	test_fallback_zero_weights()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

# 테스트용 인카운터 배열 — 인덱스 자체를 반환하도록 래핑
func _mock_encounters(n: int) -> Array:
	var arr: Array = []
	for i in range(n):
		arr.append([str(i)])  # 인카운터 배열의 첫 번째 원소 = 인덱스 문자열
	return arr

func _sample_index(gm, encounters: Array, floor_idx: int, trials: int) -> Dictionary:
	var counts: Dictionary = {}
	for i in range(encounters.size()):
		counts[i] = 0
	for _t in range(trials):
		var enc: Array = gm._pick_weighted_encounter(encounters, floor_idx)
		var idx: int = int(enc[0])
		counts[idx] += 1
	return counts

func test_floor0_low_indices() -> void:
	print("[TestEncounterWeighting] test_floor0_low_indices")
	var gm = _GMScript.new()
	var encounters := _mock_encounters(10)
	var counts := _sample_index(gm, encounters, 0, 2000)
	# floor=0 → target=0 → window [0,3]에서 추출. 인덱스 4~9는 가중치 0
	var high_zone_total: int = 0
	for i in range(4, 10):
		high_zone_total += counts[i]
	_assert(high_zone_total == 0, "floor=0 에서 인덱스 4~9 추출 없음")
	var low_zone_total: int = counts[0] + counts[1] + counts[2] + counts[3]
	_assert(low_zone_total == 2000, "floor=0 에서 인덱스 0~3이 전부 차지")
	# 인덱스 0이 가장 빈번해야 함 (가중치 4)
	_assert(counts[0] > counts[1], "floor=0 에서 idx0 > idx1")
	_assert(counts[1] > counts[2], "floor=0 에서 idx1 > idx2")
	gm.free()

func test_floor5_mid_indices() -> void:
	print("[TestEncounterWeighting] test_floor5_mid_indices")
	var gm = _GMScript.new()
	var encounters := _mock_encounters(10)
	var counts := _sample_index(gm, encounters, 5, 3000)
	# floor=5 → target=5 → window [2,8]에서 추출. 인덱스 0,1,9는 가중치 0
	_assert(counts[0] == 0, "floor=5 에서 인덱스 0 추출 없음")
	_assert(counts[1] == 0, "floor=5 에서 인덱스 1 추출 없음")
	_assert(counts[9] == 0, "floor=5 에서 인덱스 9 추출 없음")
	# 인덱스 5가 가장 빈번 (가중치 4)
	var peak: int = counts[5]
	_assert(peak > counts[2] and peak > counts[8], "floor=5 에서 idx5 피크")
	gm.free()

func test_floor9_high_indices() -> void:
	print("[TestEncounterWeighting] test_floor9_high_indices")
	var gm = _GMScript.new()
	var encounters := _mock_encounters(10)
	var counts := _sample_index(gm, encounters, 9, 2000)
	# floor=9 → target=9 → window [6,9]에서 추출. 인덱스 0~5는 가중치 0
	var low_zone_total: int = 0
	for i in range(0, 6):
		low_zone_total += counts[i]
	_assert(low_zone_total == 0, "floor=9 에서 인덱스 0~5 추출 없음")
	var high_zone_total: int = counts[6] + counts[7] + counts[8] + counts[9]
	_assert(high_zone_total == 2000, "floor=9 에서 인덱스 6~9가 전부 차지")
	# 인덱스 9가 가장 빈번
	_assert(counts[9] > counts[8], "floor=9 에서 idx9 > idx8")
	gm.free()

func test_weighted_pick_deterministic() -> void:
	print("[TestEncounterWeighting] test_weighted_pick_deterministic")
	var gm = _GMScript.new()
	# 가중치 [1, 0, 0, 0] → 항상 인덱스 0
	var items: Array = ["A", "B", "C", "D"]
	var weights: Array[float] = [10.0, 0.0, 0.0, 0.0]
	var all_a: bool = true
	for _i in range(100):
		if gm._weighted_pick(items, weights) != "A":
			all_a = false
			break
	_assert(all_a, "가중치 [10,0,0,0] → 항상 A")
	gm.free()

func test_fallback_zero_weights() -> void:
	print("[TestEncounterWeighting] test_fallback_zero_weights")
	var gm = _GMScript.new()
	# 모든 가중치 0 → pick_random 폴백, 크래시 없음
	var items: Array = ["X", "Y"]
	var weights: Array[float] = [0.0, 0.0]
	var result = gm._weighted_pick(items, weights)
	_assert(result == "X" or result == "Y", "모든 가중치 0 → 크래시 없이 반환")
	gm.free()
