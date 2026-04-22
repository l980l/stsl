# tests/test_card_pool_distribution.gd
# 1차 영웅 3인 카드 풀 등급 분포 검증
class_name TestCardPoolDistribution
extends RefCounted

var passed: int = 0
var failed: int = 0

func run_all() -> Dictionary:
	test_napoleon_rarity_distribution()
	test_yi_sun_sin_rarity_distribution()
	test_cleopatra_rarity_distribution()
	return {"passed": passed, "failed": failed}

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  PASS: " + msg)
	else:
		failed += 1
		print("  FAIL: " + msg)

func _load_gm():
	return load("res://autoload/game_manager.gd").new()

func _count_rarities(pool: Array) -> Dictionary:
	var counts := {"COMMON": 0, "UNCOMMON": 0, "RARE": 0, "LEGENDARY": 0, "DIVINE": 0}
	var CardRes = load("res://resources/card_resource.gd")
	for c in pool:
		match c.rarity:
			CardRes.Rarity.COMMON:    counts["COMMON"] += 1
			CardRes.Rarity.UNCOMMON:  counts["UNCOMMON"] += 1
			CardRes.Rarity.RARE:      counts["RARE"] += 1
			CardRes.Rarity.LEGENDARY: counts["LEGENDARY"] += 1
			CardRes.Rarity.DIVINE:    counts["DIVINE"] += 1
	return counts

func test_napoleon_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_napoleon_rarity_distribution")
	var gm = _load_gm()
	var pool: Array = gm._napoleon_card_pool()
	_assert(pool.size() == 38, "나폴레옹 풀 38장")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 8: 신속기동, 전열재편, 전진명령, 참호구축, 척후정찰, 북소리, 진격나팔, 기병위협
	_assert(counts["COMMON"] == 8, "나폴레옹 COMMON 8장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 12: 경기병돌격, 그랑다르메방패, 살보사격, 원수서임, 근위대돌격, 전선돌파, 지휘관눈, 보급선확보, 포병집결, 기동사격, 교두보점령, 황실포병대
	_assert(counts["UNCOMMON"] == 12, "나폴레옹 UNCOMMON 12장 (실제: %d)" % counts["UNCOMMON"])
	# RARE 13: 아르콜레돌파, 포병일제사격, 예나기습, 보로디노포격, 총공세명령, 제국보병소집, 아우스터리츠기동, 워털루결의, 독수리군기, 승리포고, 대육군포위전, 황제포위령, 일기당천
	_assert(counts["RARE"] == 13, "나폴레옹 RARE 13장 (실제: %d)" % counts["RARE"])
	# LEGENDARY 3: 황제명령, 전략적후퇴, 황제돌격
	_assert(counts["LEGENDARY"] == 3, "나폴레옹 LEGENDARY 3장 (실제: %d)" % counts["LEGENDARY"])
	# DIVINE 2: 황제기개, 제국영광
	_assert(counts["DIVINE"] == 2, "나폴레옹 DIVINE 2장 (실제: %d)" % counts["DIVINE"])

func test_yi_sun_sin_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_yi_sun_sin_rarity_distribution")
	var gm = _load_gm()
	var pool: Array = gm._yi_sun_sin_card_pool()
	_assert(pool.size() == 40, "이순신 풀 40장")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 7: 거북선방패, 해군기동, 장갑강화, 방패막이, 군기진작, 진형결속, 기사회생
	_assert(counts["COMMON"] == 7, "이순신 COMMON 7장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 12: 거북선돌격, 반격, 진형강화, 수군훈련, 불굴, 연속방어, 함포사격, 사기고취, 전열정비, 이판사판, 사즉생돌격, 독전
	_assert(counts["UNCOMMON"] == 12, "이순신 UNCOMMON 12장 (실제: %d)" % counts["UNCOMMON"])
	# RARE 15: 철갑, 학익진, 엄정한훈련, 배수진, 철벽, 돌격태세, 반격태세, 함대결집, 진형사수, 함대지휘, 일제사격, 사지결단, 위기돌파, 혈전, 전사의각오
	_assert(counts["RARE"] == 15, "이순신 RARE 15장 (실제: %d)" % counts["RARE"])
	# LEGENDARY 4: 한산대첩, 필사즉생, 지휘본능, 불사조
	_assert(counts["LEGENDARY"] == 4, "이순신 LEGENDARY 4장 (실제: %d)" % counts["LEGENDARY"])
	# DIVINE 2: 노량해전, 학익진완성
	_assert(counts["DIVINE"] == 2, "이순신 DIVINE 2장 (실제: %d)" % counts["DIVINE"])

func test_cleopatra_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_cleopatra_rarity_distribution")
	var gm = _load_gm()
	var pool: Array = gm._cleopatra_card_pool()
	_assert(pool.size() == 38, "클레오파트라 풀 38장")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 8: 독씨앗, 이시스가호, 독안개살포, 밀납덫, 모래폭풍, 나일축복, 뱀눈빛, 이중독니
	_assert(counts["COMMON"] == 8, "클레오파트라 COMMON 8장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 12: 아스프독니, 사막독무, 저주시선, 유혹, 유혹눈길, 독향연, 파라오저주, 나일흐름, 뱀독무, 매혹언어, 사막약법, 독심판
	_assert(counts["UNCOMMON"] == 12, "클레오파트라 UNCOMMON 12장 (실제: %d)" % counts["UNCOMMON"])
	# RARE 12: 나일안개, 독사마수, 파라오독, 람세스방패, 이시스분노, 독살의식, 여왕포옹, 저주낙인, 나일파멸, 매혹강습, 파라오분노, 저주교차로
	_assert(counts["RARE"] == 12, "클레오파트라 RARE 12장 (실제: %d)" % counts["RARE"])
	# LEGENDARY 4: 나일분노, 파라오명, 독왕좌, 이시스심판
	_assert(counts["LEGENDARY"] == 4, "클레오파트라 LEGENDARY 4장 (실제: %d)" % counts["LEGENDARY"])
	# DIVINE 2: 클레오파트라입맞춤, 세케메트저주
	_assert(counts["DIVINE"] == 2, "클레오파트라 DIVINE 2장 (실제: %d)" % counts["DIVINE"])
