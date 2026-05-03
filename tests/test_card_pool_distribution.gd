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
	test_cleopatra_archetype_distribution()
	test_joan_rarity_distribution()
	test_joan_archetype_distribution()
	test_genghis_rarity_distribution()
	test_genghis_archetype_distribution()
	test_musashi_rarity_distribution()
	test_musashi_archetype_distribution()
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
	_assert(pool.size() == 40, "나폴레옹 풀 40장")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 8: 신속기동, 전열재편, 전진명령, 참호구축, 척후정찰, 북소리, 진격나팔, 기병위협
	_assert(counts["COMMON"] == 8, "나폴레옹 COMMON 8장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 12: 경기병돌격, 그랑다르메방패, 살보사격, 원수서임, 근위대돌격, 전선돌파, 지휘관눈, 보급선확보, 포병집결, 기동사격, 교두보점령, 황실포병대
	_assert(counts["UNCOMMON"] == 14, "나폴레옹 UNCOMMON 14장 (실제: %d)" % counts["UNCOMMON"])
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
	_assert(pool.size() == 41, "이순신 풀 41장")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 7: 거북선방패, 해군기동, 장갑강화, 방패막이, 군기진작, 진형결속, 기사회생
	_assert(counts["COMMON"] == 7, "이순신 COMMON 7장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 12: 거북선돌격, 반격, 진형강화, 수군훈련, 불굴, 연속방어, 함포사격, 사기고취, 전열정비, 이판사판, 사즉생돌격, 독전
	_assert(counts["UNCOMMON"] == 13, "이순신 UNCOMMON 13장 (실제: %d)" % counts["UNCOMMON"])
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
	_assert(pool.size() == 30, "클레오파트라 풀 30장 (H2 재설계)")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 3: 독의씨앗, 모래폭풍, 뱀의눈빛
	_assert(counts["COMMON"] == 3, "클레오파트라 COMMON 3장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 9: 아스프독니, 독의향연, 독의잔치, 독의정화, 저주의시선, 사막의비책, 유혹, 파라오칙령, 매혹의언어
	_assert(counts["UNCOMMON"] == 9, "클레오파트라 UNCOMMON 9장 (실제: %d)" % counts["UNCOMMON"])
	# RARE 13: 나일안개, 독사권능, 파라오독력, 독살의식, 나일분노, 람세스방패, 이시스진노, 저주낙인, 파라오분노, 독꽃만개, 여왕위엄, 매혹향기, 매혹처형
	_assert(counts["RARE"] == 13, "클레오파트라 RARE 13장 (실제: %d)" % counts["RARE"])
	# LEGENDARY 4: 나일천벌, 독의옥좌, 이시스심판, 여왕포옹
	_assert(counts["LEGENDARY"] == 4, "클레오파트라 LEGENDARY 4장 (실제: %d)" % counts["LEGENDARY"])
	# DIVINE 1: 클레오입맞춤
	_assert(counts["DIVINE"] == 1, "클레오파트라 DIVINE 1장 (실제: %d)" % counts["DIVINE"])

func test_cleopatra_archetype_distribution() -> void:
	print("[TestCardPoolDistribution] test_cleopatra_archetype_distribution")
	var gm = _load_gm()
	var pool: Array = gm._cleopatra_card_pool()
	var archetypes := {"독살": 0, "저주": 0, "조종": 0}
	for c in pool:
		var a_key: String = c.get("archetype") if c.get("archetype") != null else ""
		var a: String = TranslationServer.translate(a_key) if a_key != "" else ""
		if a in archetypes:
			archetypes[a] += 1
	_assert(archetypes["독살"] == 12, "클레오파트라 독살 12장 (실제: %d)" % archetypes["독살"])
	_assert(archetypes["저주"] == 10, "클레오파트라 저주 10장 (실제: %d)" % archetypes["저주"])
	_assert(archetypes["조종"] == 8, "클레오파트라 조종 8장 (실제: %d)" % archetypes["조종"])

func test_joan_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_joan_rarity_distribution")
	var JoanCards = load("res://resources/cards/cards_joan_of_arc.gd")
	var pool: Array = JoanCards.pool()
	_assert(pool.size() == 30, "잔다르크 풀 30장 (H3 재설계)")
	var counts: Dictionary = _count_rarities(pool)
	# COMMON 3: holy_bolt, holy_touch, communion
	_assert(counts["COMMON"] == 3, "잔다르크 COMMON 3장 (실제: %d)" % counts["COMMON"])
	# UNCOMMON 11: orleans,holy_wave,crusaders_faith,crusade,hymn,holy_purification,knights_oath,martyrs_will,altar_flame,martyrdom_steps,martyr_strength
	_assert(counts["UNCOMMON"] == 11, "잔다르크 UNCOMMON 11장 (실제: %d)" % counts["UNCOMMON"])
	# RARE 11: holy_fury,divine_echo,archangels_wrath,holy_judge,oracle_light,guardian_angel,angel_wings,miracle_revive,passion_power,saints_revelation,last_shield
	_assert(counts["RARE"] == 11, "잔다르크 RARE 11장 (실제: %d)" % counts["RARE"])
	# LEGENDARY 4: divine_punishment,joan_return,flag_of_orleans,martyrs_light
	_assert(counts["LEGENDARY"] == 4, "잔다르크 LEGENDARY 4장 (실제: %d)" % counts["LEGENDARY"])
	# DIVINE 1: saints_flame
	_assert(counts["DIVINE"] == 1, "잔다르크 DIVINE 1장 (실제: %d)" % counts["DIVINE"])

func test_joan_archetype_distribution() -> void:
	print("[TestCardPoolDistribution] test_joan_archetype_distribution")
	var JoanCards = load("res://resources/cards/cards_joan_of_arc.gd")
	var pool: Array = JoanCards.pool()
	var archetypes := {"신성": 0, "부활": 0, "순교": 0}
	for c in pool:
		var a_key: String = c.get("archetype") if c.get("archetype") != null else ""
		var a: String = TranslationServer.translate(a_key) if a_key != "" else ""
		if a in archetypes:
			archetypes[a] += 1
	_assert(archetypes["신성"] == 11, "잔다르크 신성 11장 (실제: %d)" % archetypes["신성"])
	_assert(archetypes["부활"] == 10, "잔다르크 부활 10장 (실제: %d)" % archetypes["부활"])
	_assert(archetypes["순교"] == 9, "잔다르크 순교 9장 (실제: %d)" % archetypes["순교"])

func test_genghis_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_genghis_rarity_distribution")
	var GhisCards = load("res://resources/cards/cards_genghis_khan.gd")
	var pool: Array = GhisCards.pool()
	_assert(pool.size() == 41, "칭기즈칸 풀 41장")
	var counts: Dictionary = _count_rarities(pool)
	# starter_deck(strike/defend) 제외 — COMMON 8장
	_assert(counts["COMMON"] == 8, "칭기즈칸 COMMON 8장 (실제: %d)" % counts["COMMON"])
	_assert(counts["UNCOMMON"] == 14, "칭기즈칸 UNCOMMON 14장 (실제: %d)" % counts["UNCOMMON"])
	_assert(counts["RARE"] == 16, "칭기즈칸 RARE 16장 (실제: %d)" % counts["RARE"])
	_assert(counts["LEGENDARY"] == 2, "칭기즈칸 LEGENDARY 2장 (실제: %d)" % counts["LEGENDARY"])
	_assert(counts["DIVINE"] == 1, "칭기즈칸 DIVINE 1장 (실제: %d)" % counts["DIVINE"])

func test_genghis_archetype_distribution() -> void:
	print("[TestCardPoolDistribution] test_genghis_archetype_distribution")
	var GhisCards = load("res://resources/cards/cards_genghis_khan.gd")
	var pool: Array = GhisCards.pool()
	var archetypes := {"기동": 0, "몽골 기병": 0, "약탈": 0}
	for c in pool:
		var a: String = c.get("archetype") if c.get("archetype") != null else ""
		if a in archetypes:
			archetypes[a] += 1
	# starter_deck 제외: 기동 11, 몽골 기병 15, 약탈 12
	_assert(archetypes["기동"] == 11, "칭기즈칸 기동 11장 (실제: %d)" % archetypes["기동"])
	_assert(archetypes["몽골 기병"] == 15, "칭기즈칸 몽골 기병 15장 (실제: %d)" % archetypes["몽골 기병"])
	_assert(archetypes["약탈"] == 12, "칭기즈칸 약탈 12장 (실제: %d)" % archetypes["약탈"])

func test_musashi_rarity_distribution() -> void:
	print("[TestCardPoolDistribution] test_musashi_rarity_distribution")
	var MusaCards = load("res://resources/cards/cards_musashi.gd")
	var pool: Array = MusaCards.pool()
	_assert(pool.size() == 30, "무사시 풀 30장 (H1 재설계)")
	var counts: Dictionary = _count_rarities(pool)
	_assert(counts["COMMON"] == 5, "무사시 COMMON 5장 (실제: %d)" % counts["COMMON"])
	_assert(counts["UNCOMMON"] == 12, "무사시 UNCOMMON 12장 (실제: %d)" % counts["UNCOMMON"])
	_assert(counts["RARE"] == 10, "무사시 RARE 10장 (실제: %d)" % counts["RARE"])
	_assert(counts["LEGENDARY"] == 2, "무사시 LEGENDARY 2장 (실제: %d)" % counts["LEGENDARY"])
	_assert(counts["DIVINE"] == 1, "무사시 DIVINE 1장 (실제: %d)" % counts["DIVINE"])

func test_musashi_archetype_distribution() -> void:
	print("[TestCardPoolDistribution] test_musashi_archetype_distribution")
	var MusaCards = load("res://resources/cards/cards_musashi.gd")
	var pool: Array = MusaCards.pool()
	var archetypes := {"이도류": 0, "결투": 0, "무심": 0}
	for c in pool:
		var a_key: String = c.get("archetype") if c.get("archetype") != null else ""
		var a: String = TranslationServer.translate(a_key) if a_key != "" else ""
		if a in archetypes:
			archetypes[a] += 1
	_assert(archetypes["이도류"] == 10, "무사시 이도류 10장 (실제: %d)" % archetypes["이도류"])
	_assert(archetypes["결투"] == 10, "무사시 결투 10장 (실제: %d)" % archetypes["결투"])
	_assert(archetypes["무심"] == 10, "무사시 무심 10장 (실제: %d)" % archetypes["무심"])
