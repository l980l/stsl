# resources/card_catalog.gd
# 도감용 전체 카드 집계기. 각 영웅 카드 파일의 pool() 을 모아 반환한다.
# 자동 연동: 기존 영웅의 카드 파일에 카드를 추가하면 pool() 에 들어가는 한 도감에 자동 노출.
#   (신규 영웅 추가 시에만 아래 _HERO_CARDS 에 한 줄 등록 필요 — HeroRegistry 와 동일 수준)
class_name CardCatalog
extends RefCounted

const _NapoleonCards   = preload("res://resources/cards/cards_napoleon.gd")
const _CleopatraCards  = preload("res://resources/cards/cards_cleopatra.gd")
const _YiSunSinCards   = preload("res://resources/cards/cards_yi_sun_sin.gd")
const _JoanCards       = preload("res://resources/cards/cards_joan_of_arc.gd")
const _GenghisCards    = preload("res://resources/cards/cards_genghis_khan.gd")
const _MusashiCards    = preload("res://resources/cards/cards_musashi.gd")

# 도감 영웅 표시 순서 + pool 소스
const HERO_ORDER := ["napoleon", "cleopatra", "yi_sun_sin", "joan_of_arc", "genghis_khan", "musashi"]
const _HERO_CARDS := {
	"napoleon":     _NapoleonCards,
	"cleopatra":    _CleopatraCards,
	"yi_sun_sin":   _YiSunSinCards,
	"joan_of_arc":  _JoanCards,
	"genghis_khan": _GenghisCards,
	"musashi":      _MusashiCards,
}

# 카드 고유 식별 키 — owner_id + card_name.
# 카운터(card.counter.name)처럼 여러 영웅이 공유하는 card_name 을 영웅별로 구분하기 위함.
static func card_key(card) -> String:
	return card.owner_id + "|" + card.card_name

# 전체 카드(베이스, upgrade_level 0) 배열. 영웅별 키(owner_id+card_name)로 중복 제거.
# pool()(획득 가능 풀) + starter_deck()(초기 기본 카드: 공격/방어/카운터 등)를 병합 —
# 스타터 기본 카드도 도감에 노출하기 위함.
static func get_all_cards() -> Array:
	var out: Array = []
	var seen: Dictionary = {}
	for hid in HERO_ORDER:
		var src = _HERO_CARDS[hid]
		if src == null:
			continue
		var lists: Array = []
		if src.has_method("pool"):
			lists.append(src.pool())
		if src.has_method("starter_deck"):
			lists.append(src.starter_deck())
		for lst in lists:
			for c in lst:
				if c == null or c.card_name == "":
					continue
				var key: String = card_key(c)
				if key in seen:
					continue
				seen[key] = true
				out.append(c)
	return out
