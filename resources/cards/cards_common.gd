# resources/cards/cards_common.gd
# 모든 영웅이 공통 보유하는 universal 카드.
# 덱 최대 1장 — starter 만 보유, pool 풀에 추가 안 함 (자동으로 상점/카드보상씬 제외).
const CardRes = preload("res://resources/card_resource.gd")
const EffRes  = preload("res://resources/effect_resource.gd")

# 카운터 — RARE, 3코 (강화 시 2코), SKILL, exhaust.
# 효과 분기 (EffectType.COUNTER_REFLECT 처리):
#   A) charge_up + counter_window 활성 보스 → 즉시 차지 무효 + stun 1
#   B) 그 외 → counter_pending status 부여, 다음 받는 공격 50% 반감 + 100% 반사
static func counter(owner_id: String) -> Resource:
	var c := CardRes.new()
	c.card_name = "card.counter.name"
	c.owner_id = owner_id
	c.cost = 3
	c.card_type = CardRes.CardType.SKILL
	c.rarity = CardRes.Rarity.RARE
	c.play_animation = "idle"
	c.is_exhaust = true
	var e := EffRes.new()
	e.effect_type = EffRes.EffectType.COUNTER_REFLECT
	e.value = 0  # 효과 자체는 status 부여 / 차지 무효 — value 불필요
	c.effects = [e]
	return c
