# resources/events/events_japanese.gd
# 일본 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	# _shuten_doji_feast 제거 — ADD_HERO 이벤트. 영입은 Act1 trigger 로 일원화.
	return [
		_ise_shrine_blessing(), _oni_shogi(), _yuki_onna_blizzard(),
		_tengu_training(), _shrine_omamori(), _tanuki_illusion(),
		_kappa_river_crossing(), _fujisan_spirit(),
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
	# 다양화: 1번 TRIGGER_BATTLE 오니와 결투 (렐릭), 2번 판돈 걸고 장기 (확률 70% GOLD +50, 30% cost_gold)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.oni_shogi.name"
	e.description = "event.japanese.oni_shogi.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.oni_shogi.choice_1"
	ca.effect_type = ChoiceRes.EffectType.TRIGGER_BATTLE
	ca.encounter_tier = 0
	ca.reward_effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.oni_shogi.choice_2"
	# 장기 대국 — 70% +50 GOLD, 30% 효과 없음. cost_gold 30 판돈
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 50; cb.cost_gold = 30
	cb.success_chance = 70
	cb.alt_effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _yuki_onna_blizzard() -> Resource:
	# 재설계: 1번 GOLD HP cost, 2번 렐릭 HP cost, 3번 우회 (cost_gold + HEAL — 안전한 길)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.yuki_onna_blizzard.name"
	e.description = "event.japanese.yuki_onna_blizzard.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.yuki_onna_blizzard.choice_1"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80; ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.yuki_onna_blizzard.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC; cb.cost_hp = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.yuki_onna_blizzard.choice_3"
	# 안전한 우회로 — gold cost + HEAL (눈보라 피해 따뜻한 숙소)
	cc.effect_type = ChoiceRes.EffectType.HEAL; cc.value = 20; cc.cost_gold = 30
	e.choices = [ca, cb, cc]; return e

static func _tengu_training() -> Resource:
	# 다양화: 1번 수련 (REMOVE_CARD), musashi 옵션 (MULTI), 2번 천구 깃털 (HEAL 작게 + 깃털 자랑 GOLD)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.tengu_training.name"
	e.description = "event.japanese.tengu_training.desc"
	e.bgm_type = "encounter"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.tengu_training.choice_1"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cm: Resource = ChoiceRes.new(); cm.label = "event.japanese.tengu_training.choice_musashi"
	cm.effect_type = ChoiceRes.EffectType.REMOVE_CARD; cm.value = 1
	cm.secondary_effect_type = ChoiceRes.EffectType.DRAW_UP; cm.secondary_value = 1
	cm.required_hero_id = "musashi"
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.tengu_training.choice_2"
	# 거절 — 텐구가 떨어뜨린 깃털 줍기 (GOLD)
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 25
	e.choices = [ca, cm, cb]; return e

static func _shrine_omamori() -> Resource:
	# 재설계: 1번 정품 부적 (gold), 2번 도박 (gold), 3번 봉헌함 약탈 (GOLD, cost_hp)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.shrine_omamori.name"
	e.description = "event.japanese.shrine_omamori.desc"
	e.bgm_type = "mysterious"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.shrine_omamori.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.shrine_omamori.choice_2"
	cb.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE; cb.cost_gold = 20
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.shrine_omamori.choice_3"
	# 봉헌함 약탈 — GOLD, 신관 분노 cost_hp
	cc.effect_type = ChoiceRes.EffectType.GOLD; cc.value = 35; cc.cost_hp = 15
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
	# 다양화: 1번 MULTI(HEAL + ADD_RELIC, cost_hp), 2번 우회 (cost_gold + 안전)
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.kappa_river_crossing.name"
	e.description = "event.japanese.kappa_river_crossing.desc"
	e.bgm_type = "dark"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.kappa_river_crossing.choice_1"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 20
	ca.secondary_effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.cost_hp = 20
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.kappa_river_crossing.choice_2"
	# 우회 (다리 통행료) — gold cost + HEAL 소량
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 15; cb.cost_gold = 30
	e.choices = [ca, cb]; return e

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
static func _kitsune_kit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "event.japanese.kitsune_kit.name"
	e.description = "event.japanese.kitsune_kit.desc"
	e.bgm_type = "fortune"
	var ca: Resource = ChoiceRes.new(); ca.label = "event.japanese.kitsune_kit.choice_1"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	ca.success_chance = 60
	ca.alt_effect_type = ChoiceRes.EffectType.HEAL; ca.alt_value = 10
	var cb: Resource = ChoiceRes.new(); cb.label = "event.japanese.kitsune_kit.choice_2"
	cb.effect_type = ChoiceRes.EffectType.GOLD; cb.value = 40
	var cc: Resource = ChoiceRes.new(); cc.label = "event.japanese.kitsune_kit.choice_3"
	# 가죽 회수 — GOLD, 키츠네 어미의 저주 cost_hp
	cc.effect_type = ChoiceRes.EffectType.GOLD; cc.value = 50; cc.cost_hp = 20
	e.choices = [ca, cb, cc]; return e
