# resources/data/events_act1.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_golden_chest(), _wounded_warrior(), _ancient_library(),
		_cursed_altar(), _companion_encounter(), _prometheus_fire(),
		_heracles_trial(), _circe_magic(), _hades_contract(),
		_hermes_gamble(), _devils_deal(),
	]

static func _golden_chest() -> Resource:
	# 재설계: "열기 vs 무시" → 미믹 위험 vs 안전 소량
	# 1번 강제로 연다 → 70% +60 골드 / 30% 미믹 전투 (TRIGGER_BATTLE 보통, 승리 시 +80 골드)
	# 2번 조심스레 살펴본다 → +15 골드 (함정 발견, 떨어진 동전만 회수)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.golden_chest.name"; e.description = "event.act1.golden_chest.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.golden_chest.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60
	ca.success_chance = 70
	# 실패: TRIGGER_BATTLE은 success_chance와 결합할 수 없음 → alt를 REMOVE_CARD로
	# (미믹이 가장 약한 카드 한 장 먹음 — 실은 정화 효과지만 random은 페널티 가능)
	ca.alt_effect_type = ChoiceRes.EffectType.REMOVE_CARD
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.golden_chest.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 15
	# 미믹과 직접 싸우는 옵션 — TRIGGER_BATTLE, 승리 시 +80 + 렐릭 — 추가 옵션
	var cc: Resource = ChoiceRes.new(); cc.label = "event.act1.golden_chest.choice_3"
	cc.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	cc.encounter_tier = 0
	cc.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	e.choices = [ca, cb, cc]; return e

static func _wounded_warrior() -> Resource:
	# 재설계: 무시 → 죽어가는 전사가 마지막 동전을 줌 (양심의 짐)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.wounded_warrior.name"; e.description = "event.act1.wounded_warrior.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.wounded_warrior.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 15; ca.cost_gold = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.wounded_warrior.choice_2"
	# 전사의 무기를 챙긴다 — 약탈 시 페널티 작은 cost_hp + GOLD
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20; cb.cost_hp = 5
	e.choices = [ca, cb]; return e

static func _ancient_library() -> Resource:
	# 재설계: "무시" 없음 — 책을 훔쳐서 팔거나 휴식 둘 중 하나
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.ancient_library.name"
	e.description = "event.act1.ancient_library.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.ancient_library.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 5
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.ancient_library.choice_2"
	# 책 훔치기 — 가치 있는 책 발견
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25
	e.choices = [ca, cb]; return e

static func _cursed_altar() -> Resource:
	# 재설계: "무시" → 봉헌물 강탈 (저주 위험 cost_hp + 골드)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.cursed_altar.name"; e.description = "event.act1.cursed_altar.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.cursed_altar.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.cursed_altar.choice_2"
	# 봉헌물 강탈 — 큰 골드 + 저주 (cost_hp)
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 40; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _companion_encounter() -> Resource:
	# 재설계: 거절 → 동료가 떠나며 작별 선물 (GOLD + HEAL MULTI)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.companion_encounter.name"; e.description = "event.act1.companion_encounter.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.companion_encounter.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.companion_encounter.choice_2"
	# 동료가 떠나며 자기 물자 줌 — GOLD + HEAL
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 30
	cb.secondary_effect_type = ChoiceRes.EffectType.HEAL; cb.secondary_value = 15
	e.choices = [ca, cb]; return e

static func _prometheus_fire() -> Resource:
	# 다양화: 1번 확률(70% 드로우 영구, 30% 카드 소실), 2번 무시 → HEAL +20 (신의 자비)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.prometheus_fire.name"
	e.description = "event.act1.prometheus_fire.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.prometheus_fire.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	ca.success_chance = 70
	ca.alt_effect_type = ChoiceRes.EffectType.REMOVE_CARD
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.prometheus_fire.choice_2"
	# 신성한 곳에서 휴식 — HEAL
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20
	e.choices = [ca, cb]; return e

static func _heracles_trial() -> Resource:
	# 재설계: 포기 → 헤라클레스의 가르침 받음 (HEAL — 영웅이 다친 곳 치료)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.heracles_trial.name"; e.description = "event.act1.heracles_trial.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.heracles_trial.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 60; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.heracles_trial.choice_2"
	# 시련 회피 — 헤라클레스가 자기 가르침 베풂 (소량 HEAL)
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	e.choices = [ca, cb]; return e

static func _circe_magic() -> Resource:
	# 다양화: 1번 MULTI(HEAL + REMOVE_CARD, gold cost), 2번 거절 → 마녀가 돈 줘서 떠나라
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.circe_magic.name"; e.description = "event.act1.circe_magic.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.circe_magic.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25; ca.cost_gold = 50
	ca.secondary_effect_type = ChoiceRes.EffectType.REMOVE_CARD
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.circe_magic.choice_2"
	# 거절 — 마녀가 침묵의 대가로 동전 줌
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e

static func _hades_contract() -> Resource:
	# 재설계: 거절 → 저승 옆에서 약점 정화 (REMOVE_CARD — 죽음을 본 영혼이 가벼워짐)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.hades_contract.name"
	e.description = "event.act1.hades_contract.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.hades_contract.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.hades_contract.choice_2"
	# 거절 — 저승의 정화: REMOVE_CARD
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	e.choices = [ca, cb]; return e

static func _hermes_gamble() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.hermes_gamble.name"; e.description = "event.act1.hermes_gamble.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.hermes_gamble.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.hermes_gamble.choice_2"
	cb.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cb.value = 1
	e.choices = [ca, cb]; return e

static func _devils_deal() -> Resource:
	# 재설계: 거절 → 저항으로 신앙 강화 (HEAL — 영적 회복)
	var e: Resource = EventRes.new()
	e.event_name = "event.act1.devils_deal.name"
	e.description = "event.act1.devils_deal.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act1.devils_deal.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act1.devils_deal.choice_2"
	# 거절 — 영적 회복
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20
	e.choices = [ca, cb]; return e
