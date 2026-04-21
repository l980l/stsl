# resources/events/events_korean.gd
# 한국 신화 이벤트 10종
const EventRes  = preload("res://resources/event_resource.gd")
const ChoiceRes = preload("res://resources/event_choice_resource.gd")

static func build_pool() -> Array:
	return [
		_death_reaper_visit(), _dokkaebi_hammer(), _gumiho_temptation(),
		_shaman_gut(), _samsin_blessing(), _dangun_prophecy(),
		_mountain_god_bet(), _sea_king_test(), _hero_joins(),
		_underworld_deal(),
	]

static func _death_reaper_visit() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "저승사자의 방문"
	e.description = "밤길을 걷다 검은 갓을 쓴 저승사자와 마주쳤다. '아직은 아니오. 대신, 무언가를 가져가겠소.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "받아들인다 (HP -40)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 70; ca.cost_hp = 40
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dokkaebi_hammer() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "도깨비 방망이"
	e.description = "길가에 낡은 방망이가 떨어져 있다. 잡으면 이상한 기운이 느껴진다."
	var ca: Resource = ChoiceRes.new(); ca.label = "금 나와라 뚝딱!"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 80
	var cb: Resource = ChoiceRes.new(); cb.label = "쌀 나와라 뚝딱!"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 35
	var cc: Resource = ChoiceRes.new(); cc.label = "가져간다 (도박)"
	cc.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	e.choices = [ca, cb, cc]; return e

static func _gumiho_temptation() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "구미호의 유혹"
	e.description = "여우 눈빛의 여인이 앞을 막는다. '당신의 약점 하나를 제거해 드리죠. 대신 힘을 드릴게요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "거래한다 (카드 1장 제거)"
	ca.effect_type = ChoiceRes.EffectType.REMOVE_CARD; ca.value = 1
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _shaman_gut() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "무당의 굿판"
	e.description = "붉은 무복의 무당이 굿을 올린다. '제물이 있으면 상처를 치유해드릴 수 있어요.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "굿을 부탁한다 (골드 -50)"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30; ca.cost_gold = 50
	var cb: Resource = ChoiceRes.new(); cb.label = "구경만 한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _samsin_blessing() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "삼신할머니의 축복"
	e.description = "노파가 따뜻한 빛을 내밀며 말한다. '이 사람들은 한이 많겠구만. 내가 하나 점지해줄게.'"
	# MAX_HP가 EffectType에 없으므로 HEAL로 대체
	var ca: Resource = ChoiceRes.new(); ca.label = "감사히 받는다"
	ca.effect_type = ChoiceRes.EffectType.HEAL; ca.value = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "괜찮다고 한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _dangun_prophecy() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "단군의 예언"
	e.description = "마니산 제단에서 고요한 목소리가 들린다. '너희의 길에는 두 갈래가 있다.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "강인함의 길"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC
	var cb: Resource = ChoiceRes.new(); cb.label = "지혜의 길"
	cb.effect_type = ChoiceRes.EffectType.DRAW_UP; cb.value = 1
	e.choices = [ca, cb]; return e

static func _mountain_god_bet() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "산신령과의 내기"
	e.description = "백발 노인이 바위 위에 앉아 말한다. '나를 이기면 소원을 들어주겠네.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "내기를 수락한다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "그냥 지나친다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _sea_king_test() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "용왕의 시험"
	e.description = "용의 발톱이 물 속에서 드러난다. '내 바다를 지나가려면 시험을 통과하여라.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "시험에 응한다 (HP -30)"
	ca.effect_type = ChoiceRes.EffectType.GOLD; ca.value = 100; ca.cost_hp = 30
	var cb: Resource = ChoiceRes.new(); cb.label = "뇌물을 바친다 (골드 -60)"
	cb.effect_type = ChoiceRes.EffectType.HEAL; cb.value = 20; cb.cost_gold = 60
	var cc: Resource = ChoiceRes.new(); cc.label = "돌아간다"
	cc.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb, cc]; return e

static func _hero_joins() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "동료 영웅의 합류"
	e.description = "전장을 헤매던 한 영웅이 당신의 팀을 발견했다."
	var ca: Resource = ChoiceRes.new(); ca.label = "함께 싸우자"
	ca.effect_type = ChoiceRes.EffectType.ADD_HERO
	var cb: Resource = ChoiceRes.new(); cb.label = "아직은 아니야"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e

static func _underworld_deal() -> Resource:
	var e: Resource = EventRes.new()
	e.event_name = "저승의 거래"
	e.description = "어둠 속 흰 도포를 입은 자가 나타난다. '내가 가진 것 하나와 당신의 것 하나를 교환하죠.'"
	var ca: Resource = ChoiceRes.new(); ca.label = "거래한다"
	ca.effect_type = ChoiceRes.EffectType.ADD_RELIC_GAMBLE
	var cb: Resource = ChoiceRes.new(); cb.label = "거절한다"
	cb.effect_type = ChoiceRes.EffectType.NONE
	e.choices = [ca, cb]; return e
