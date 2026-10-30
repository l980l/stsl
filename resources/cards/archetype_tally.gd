# resources/cards/archetype_tally.gd
# 보상 화면 아키타입 태그용 집계. 장면 스크립트와 분리해 테스트에서 오토로드 없이 부른다.
extends RefCounted

# 보상 카드의 주 아키타입(첫 태그) 이름과, 덱에서 같은 영웅·같은 이름의 태그를 단 카드 수.
# 번역 키가 달라도 같은 이름으로 번역되면 같은 아키타입으로 센다. 태그가 없으면 빈 사전.
# 스트라이크·디펜드는 태그가 있어도 덱 방향이 아니므로 세지 않는다.
static func of(card: Resource, deck: Array) -> Dictionary:
	if card == null or card.archetype.is_empty():
		return {}
	var label: String = TranslationServer.translate(card.archetype[0])
	var owned := 0
	for other in deck:
		if other == null or other.owner_id != card.owner_id:
			continue
		if other.card_name.ends_with(".strike.name") or other.card_name.ends_with(".defend.name"):
			continue
		for tag in other.archetype:
			if TranslationServer.translate(tag) == label:
				owned += 1
				break
	return {"label": label, "owned": owned}
