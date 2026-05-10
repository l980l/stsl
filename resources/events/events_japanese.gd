# resources/events/events_japanese.gd
# 일본 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_ise_shrine_blessing(), _oni_shogi(), _yuki_onna_blizzard(),
		_tengu_training(), _shrine_omamori(), _tanuki_illusion(),
		_kappa_river_crossing(), _shuten_doji_feast(), _fujisan_spirit(),
		_amaterasu_return(), _kitsune_kit(),
	]

static func _ise_shrine_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.ise_shrine_blessing.name"
	e.description = "event.japanese.ise_shrine_blessing.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.ise_shrine_blessing.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.ise_shrine_blessing.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20
	e.choices = [ca, cb]; return e

static func _oni_shogi() -> Resource:
	# 다양화: GAMBLE → TRIGGER_BATTLE (오니가 패배를 인정하지 않음). 승리 시 렐릭.
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.oni_shogi.name"
	e.description = "event.japanese.oni_shogi.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.oni_shogi.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 0
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.oni_shogi.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yuki_onna_blizzard() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.yuki_onna_blizzard.name"
	e.description = "event.japanese.yuki_onna_blizzard.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.yuki_onna_blizzard.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.yuki_onna_blizzard.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.yuki_onna_blizzard.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tengu_training() -> Resource:
	# 다양화: 단순 REMOVE_CARD → musashi 보유 시 강화된 옵션 추가 (조건부 선택지)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.tengu_training.name"
	e.description = "event.japanese.tengu_training.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.tengu_training.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	# 무사시 전용: 텐구의 진짜 검술 — 카드 1장 제거 + 드로우 +1
	var cm: Resource = ChoiceRes.new(); cm.label = "event.japanese.tengu_training.choice_musashi"
	cm.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cm.value = 1
	cm.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; cm.secondary_value = 1
	cm.required_hero_id = "musashi"
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.tengu_training.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cm, cb]; return e

static func _shrine_omamori() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.shrine_omamori.name"
	e.description = "event.japanese.shrine_omamori.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.shrine_omamori.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.shrine_omamori.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 20
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.shrine_omamori.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _tanuki_illusion() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.tanuki_illusion.name"
	e.description = "event.japanese.tanuki_illusion.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.tanuki_illusion.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.tanuki_illusion.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _kappa_river_crossing() -> Resource:
	# 다양화: GAMBLE → MULTI (HEAL +20 + ADD_RELIC). 캇파의 강물 시험 통과 보상.
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.kappa_river_crossing.name"
	e.description = "event.japanese.kappa_river_crossing.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.kappa_river_crossing.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 20
	ca.secondary_effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.kappa_river_crossing.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shuten_doji_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.shuten_doji_feast.name"
	e.description = "event.japanese.shuten_doji_feast.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.shuten_doji_feast.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.shuten_doji_feast.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 70
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.shuten_doji_feast.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _fujisan_spirit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.fujisan_spirit.name"
	e.description = "event.japanese.fujisan_spirit.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.fujisan_spirit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.fujisan_spirit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	e.choices = [ca, cb]; return e

static func _amaterasu_return() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.amaterasu_return.name"
	e.description = "event.japanese.amaterasu_return.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.amaterasu_return.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 45
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.amaterasu_return.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb]; return e

# Phase 4 신규: 키츠네의 새끼 (다단계 양자택일 + 확률)
# 여우 새끼를 데려가면 60%로 보상, 40%로 환술 페널티.
static func _kitsune_kit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.kitsune_kit.name"
	e.description = "event.japanese.kitsune_kit.desc"
	e.bgm_type = "fortune"
	# 데려간다: 60% ADD_RELIC, 40% HEAL +10 (위로 정도)
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.kitsune_kit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.success_chance = 60
	ca.alt_effect_type = ChoiceRes.EffectType.HEAL; ca.alt_value = 10
	# 보내준다: GOLD +40 (어미가 감사 표시)
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.kitsune_kit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 40
	# 무시
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.kitsune_kit.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e
