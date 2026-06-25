# resources/relic_catalog.gd
# 도감용 전체 렐릭 집계기. relics.gd 의 정의에서 모아 반환한다.
# 자동 연동: relics.gd build_pool() 에 렐릭을 추가하면 도감에 자동 노출.
class_name RelicCatalog
extends RefCounted

const _RelicData = preload("res://resources/relics/relics.gd")

# 소유 표시 순서 — 공용("") 먼저, 그다음 영웅별 (CardCatalog.HERO_ORDER 와 동일 순서)
const OWNER_ORDER := ["", "napoleon", "cleopatra", "yi_sun_sin", "joan_of_arc", "genghis_khan", "musashi"]

# 렐릭 고유 식별 키 — relic_name 은 전역 유일.
static func relic_key(relic) -> String:
	return relic.relic_name

# 전체 렐릭 배열. relic_name 으로 중복 제거.
# build_pool()(획득 가능 풀) + sacred_scroll 3종(이벤트 전용)을 병합 —
# 이벤트 전용 렐릭도 도감에 노출하기 위함.
static func get_all_relics() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	var lists: Array = [_RelicData.build_pool()]
	# 이벤트 전용 신성한 두루마리 (1/2/3턴 변형) — 결정적으로 추가
	var scrolls: Array = []
	for turn in [1, 2, 3]:
		scrolls.append(_RelicData._make_sacred_scroll(turn))
	lists.append(scrolls)
	for lst in lists:
		for r in lst:
			if r == null or r.relic_name == "":
				continue
			var key: String = relic_key(r)
			if key in seen:
				continue
			seen[key] = true
			out.append(r)
	return out
