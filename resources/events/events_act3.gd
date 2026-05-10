# resources/events/events_act3.gd
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_odin_ravens(), _yggdrasil_fruit(), _ragnarok_prophecy(),
		_valhalla_invitation(), _mimirs_well(), _dragon_gold(),
		_rune_stone(), _thor_hammer_mark(), _frost_giant_corpse(),
		_freyja_tears(), _ymir_blood(),
	]

static func _odin_ravens() -> Resource:
	# 다양화: 60% 드로우 +1 (영구), 40% 까마귀 도망 (효과 없음)
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.odin_ravens.name"; e.description = "event.act3.odin_ravens.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.odin_ravens.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_hp = 8
	ca.success_chance = 60
	ca.alt_effect_type = ChoiceRes.EffectType.NONE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.odin_ravens.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yggdrasil_fruit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.yggdrasil_fruit.name"; e.description = "event.act3.yggdrasil_fruit.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.yggdrasil_fruit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 40; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.yggdrasil_fruit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _ragnarok_prophecy() -> Resource:
	# 다양화: GAMBLE → MULTI (예언 — ADD_RELIC + GOLD +30, 단 cost_hp 추가)
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.ragnarok_prophecy.name"; e.description = "event.act3.ragnarok_prophecy.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.ragnarok_prophecy.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.secondary_effect_type = ChoiceRes.EffectType.GOLD; ca.secondary_value = 30
	ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.ragnarok_prophecy.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE; cb.cost_hp = 15
	e.choices = [ca, cb]; return e

static func _valhalla_invitation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.valhalla_invitation.name"; e.description = "event.act3.valhalla_invitation.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.valhalla_invitation.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.valhalla_invitation.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25
	e.choices = [ca, cb]; return e

static func _mimirs_well() -> Resource:
	# 다양화: 단순 REMOVE_CARD → MULTI (REMOVE_CARD + DRAW_UP +1, 미미르의 진정한 지혜)
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.mimirs_well.name"; e.description = "event.act3.mimirs_well.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.mimirs_well.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1; ca.cost_hp = 20
	ca.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; ca.secondary_value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.mimirs_well.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dragon_gold() -> Resource:
	# 다양화: 단순 GOLD + cost_hp → TRIGGER_BATTLE (엘리트 용 처치). 승리 시 골드 +80.
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.dragon_gold.name"; e.description = "event.act3.dragon_gold.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.dragon_gold.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 1
	ca.reward_effect_type = ChoiceRes.EffectType.GOLD; ca.reward_value = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.dragon_gold.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _rune_stone() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.rune_stone.name"; e.description = "event.act3.rune_stone.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.rune_stone.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 120
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.rune_stone.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 20
	e.choices = [ca, cb]; return e

static func _thor_hammer_mark() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.thor_hammer_mark.name"; e.description = "event.act3.thor_hammer_mark.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.thor_hammer_mark.choice_1"
	ca.effect_type = ChoiceRes.EffectType.DRAW_UP; ca.value = 1; ca.cost_gold = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.thor_hammer_mark.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _frost_giant_corpse() -> Resource:
	# 다양화: GAMBLE → 확률 (80% 일반 렐릭, 20% 저주 렐릭). cost_hp 유지.
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.frost_giant_corpse.name"; e.description = "event.act3.frost_giant_corpse.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.frost_giant_corpse.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_hp = 25
	ca.success_chance = 80
	ca.alt_effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.frost_giant_corpse.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _freyja_tears() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.freyja_tears.name"; e.description = "event.act3.freyja_tears.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.freyja_tears.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.freyja_tears.choice_2"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

# Phase 4 신규: 이미르의 피 (TRIGGER_BATTLE 엘리트 + 이중 보상)
# 거인의 피 = 강대한 힘. 거인 처치 후 골드 + 렐릭.
static func _ymir_blood() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.act3.ymir_blood.name"
	e.description = "event.act3.ymir_blood.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.act3.ymir_blood.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 1
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	# 거리 두기: HEAL +25
	var cb: Resource = ChoiceRes.new(); cb.label = "event.act3.ymir_blood.choice_2"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 25
	# 무시
	var cc: Resource = ChoiceRes.new(); cc.label = "event.act3.ymir_blood.choice_3"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e
