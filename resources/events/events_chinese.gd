# resources/events/events_chinese.gd
# 중국 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_queen_mother_peach(), _monkey_king_challenge(), _tang_monk_scripture(),
		_eight_immortals_feast(), _celestial_market(), _dragon_king_invitation(),
		_lu_dongbin_sword(), _pangu_fragment(), _shennong_herbs(),
		_phoenix_rebirth(),
	]

static func _queen_mother_peach() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.queen_mother_peach.name")
	e.description = TranslationServer.translate("event.chinese.queen_mother_peach.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.queen_mother_peach.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.queen_mother_peach.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _monkey_king_challenge() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.monkey_king_challenge.name")
	e.description = TranslationServer.translate("event.chinese.monkey_king_challenge.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.monkey_king_challenge.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.monkey_king_challenge.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _tang_monk_scripture() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.tang_monk_scripture.name")
	e.description = TranslationServer.translate("event.chinese.tang_monk_scripture.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.tang_monk_scripture.choice_1")
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.tang_monk_scripture.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _eight_immortals_feast() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.eight_immortals_feast.name")
	e.description = TranslationServer.translate("event.chinese.eight_immortals_feast.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.eight_immortals_feast.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 50; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.eight_immortals_feast.choice_2")
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 60
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.chinese.eight_immortals_feast.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _celestial_market() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.celestial_market.name")
	e.description = TranslationServer.translate("event.chinese.celestial_market.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.celestial_market.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 80
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.celestial_market.choice_2")
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 30
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.chinese.celestial_market.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _dragon_king_invitation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.dragon_king_invitation.name")
	e.description = TranslationServer.translate("event.chinese.dragon_king_invitation.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.dragon_king_invitation.choice_1")
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 90; ca.cost_hp = 25
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.dragon_king_invitation.choice_2")
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 40
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.chinese.dragon_king_invitation.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _lu_dongbin_sword() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.lu_dongbin_sword.name")
	e.description = TranslationServer.translate("event.chinese.lu_dongbin_sword.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.lu_dongbin_sword.choice_1")
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.lu_dongbin_sword.choice_2")
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _pangu_fragment() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.pangu_fragment.name")
	e.description = TranslationServer.translate("event.chinese.pangu_fragment.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.pangu_fragment.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.pangu_fragment.choice_2")
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50
	e.choices = [ca, cb]; return e

static func _shennong_herbs() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.shennong_herbs.name")
	e.description = TranslationServer.translate("event.chinese.shennong_herbs.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.shennong_herbs.choice_1")
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_hp = 15
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.shennong_herbs.choice_2")
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 40
	var cc: Resource = ChoiceRes.new(); cc.label = TranslationServer.translate("event.chinese.shennong_herbs.choice_3")
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _phoenix_rebirth() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = TranslationServer.translate("event.chinese.phoenix_rebirth.name")
	e.description = TranslationServer.translate("event.chinese.phoenix_rebirth.desc")
	var ca: Resource = ChoiceRes.new(); ca.label = TranslationServer.translate("event.chinese.phoenix_rebirth.choice_1")
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = TranslationServer.translate("event.chinese.phoenix_rebirth.choice_2")
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 30
	e.choices = [ca, cb]; return e
