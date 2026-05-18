# resources/events/events_act2.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	# _ra_sunboat 제거 — ADD_HERO 이벤트. 영입은 Act1 trigger 로 일원화.
	return [
		_book_of_the_dead(), _anubis_judgment(), _scarab_beetle(),
		_pharaoh_tomb(), _nile_flood(), _thoth_wisdom(),
		_bastet_cats(), _oasis_merchant(), _mummy_curse(),
		_sphinx_gate(),
	]

static func _book_of_the_dead() -> Resource:
	# 다양화: 1번 TRIGGER_BATTLE → 영구 드로우 +1, 2번 책장에서 한 페이지 찢어 골드로 판다
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.book_of_the_dead.name"; e.description = "event.act2.book_of_the_dead.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.book_of_the_dead.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 0
	ca.reward_effect_type = ChoiceRes.EffectType.DRAW_UP; ca.reward_value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.book_of_the_dead.choice_2"
	# 한 페이지 찢어 판매 — 작은 골드, 망령 분노로 HP 소량
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 30; cb.cost_hp = 10
	e.choices = [ca, cb]; return e

static func _anubis_judgment() -> Resource:
	# 다양화: 1번 MULTI(REMOVE_CARD + ADD_RELIC, HP -25), 2번 거부하면 심판의 깃털 (HEAL — 영혼 정화)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.anubis_judgment.name"; e.description = "event.act2.anubis_judgment.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.anubis_judgment.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	ca.secondary_effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.anubis_judgment.choice_2"
	# 거부 — 정화의 깃털만 받음 (HEAL, 작은 cost_hp는 그대로)
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25; cb.cost_hp = 10
	e.choices = [ca, cb]; return e

static func _scarab_beetle() -> Resource:
	# 재설계: 1번 풍뎅이 잡기 → 골드 +40, 2번 살려보내기 → 풍뎅이가 길 인도 (HEAL + DRAW_UP MULTI)
	# 스카라베 = 부활/축복의 상징
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.scarab_beetle.name"; e.description = "event.act2.scarab_beetle.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.scarab_beetle.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.scarab_beetle.choice_2"
	# 풍뎅이 살려주기 → 축복 (작은 HEAL + 작은 영구 드로우 — 확률)
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 15
	cb.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; cb.secondary_value = 1
	cb.success_chance = 50  # 50% 축복, 50% 그냥 날아감
	cb.alt_effect_type = ChoiceRes.EffectType.HEAL; cb.alt_value = 15  # 실패해도 HEAL은 받음
	e.choices = [ca, cb]; return e

static func _pharaoh_tomb() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.pharaoh_tomb.name"; e.description = "event.act2.pharaoh_tomb.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.pharaoh_tomb.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 35
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.pharaoh_tomb.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 15
	e.choices = [ca, cb]; return e

static func _nile_flood() -> Resource:
	# 다양화: 1번 MULTI(HEAL + DRAW_UP, gold cost), 2번 강에서 노다지 (GOLD + 작은 cost_hp 악어 위험)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.nile_flood.name"; e.description = "event.act2.nile_flood.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.nile_flood.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 40
	ca.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; ca.secondary_value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.nile_flood.choice_2"
	# 강물 뒤져서 진흙 속 보물 — GOLD, 악어 물어서 cost_hp
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 35; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _thoth_wisdom() -> Resource:
	# 재설계: 1번 영구 드로우 (gold cost), 2번 토트의 시험 (확률 — REMOVE_CARD or GOLD)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.thoth_wisdom.name"; e.description = "event.act2.thoth_wisdom.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.thoth_wisdom.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 60
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.thoth_wisdom.choice_2"
	# 시험에 도전 (무료) → 60% 카드 정화, 40% 토트 분노 (-15 HP)
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	cb.success_chance = 60
	cb.alt_effect_type = ChoiceRes.EffectType.NONE  # 실패 시 효과 없음
	cb.cost_hp = 0  # 비용 없음 (실패도 페널티 없음 — 단순 정화 시도)
	e.choices = [ca, cb]; return e

static func _bastet_cats() -> Resource:
	# 재설계: 1번 고양이에게 우유 (HEAL gold cost), 2번 고양이 사냥 (GOLD, 발톱에 긁힘)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.bastet_cats.name"; e.description = "event.act2.bastet_cats.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.bastet_cats.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.bastet_cats.choice_2"
	# 고양이 신성 무시하고 잡기 — 가죽 판매 GOLD, 발톱에 cost_hp + 바스테트 분노
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25; cb.cost_hp = 8
	e.choices = [ca, cb]; return e

static func _oasis_merchant() -> Resource:
	# 재설계: 1번 렐릭 구매 (gold cost), 2번 HEAL gold cost, 3번 상인 약탈 (GOLD + cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.oasis_merchant.name"; e.description = "event.act2.oasis_merchant.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.oasis_merchant.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 100
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.oasis_merchant.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = "event.act2.oasis_merchant.choice_3"
	# 상인 약탈 — 큰 GOLD, 호위병 저항 cost_hp
	cc.effect_type = ChoiceRes.EffectType.GOLD; cc.value = 50; cc.cost_hp = 20
	e.choices = [ca, cb, cc]; return e

static func _mummy_curse() -> Resource:
	# 다양화: 1번 TRIGGER_BATTLE(엘리트, 렐릭), 2번 봉인 강화 (HEAL — 저주 봉인 의식, 작은 cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.mummy_curse.name"; e.description = "event.act2.mummy_curse.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.mummy_curse.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 1
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.mummy_curse.choice_2"
	# 저주받은 카드를 석관에 봉인 — 덱 압축
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	e.choices = [ca, cb]; return e

# Phase 4 신규: 스핑크스의 수수께끼 (확률 + 다중 효과)
static func _sphinx_gate() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act2.sphinx_gate.name"
	e.description = "event.act2.sphinx_gate.desc"
	e.bgm_type = "mysterious"
	# 답한다: 70% REMOVE_CARD + GOLD +30, 30% NONE (오답 시 효과 없음)
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act2.sphinx_gate.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	ca.secondary_effect_type = ChoiceRes.EffectType.GOLD; ca.secondary_value = 30
	ca.success_chance = 70
	ca.alt_effect_type = ChoiceRes.EffectType.NONE
	# 회피한다: 골드 -30 우회료
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act2.sphinx_gate.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_gold = 30
	# 결투 — TRIGGER_BATTLE, 승리 시 영구 드로우 +1
	var cc: Resource = ChoiceRes.new(); cc.label = "event.act2.sphinx_gate.choice_3"
	cc.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	cc.encounter_tier = 1
	cc.reward_effect_type = ChoiceRes.EffectType.DRAW_UP; cc.reward_value = 1
	e.choices = [ca, cb, cc]; return e
