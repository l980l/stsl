# resources/data/relics.gd
const RelicRes = preload("res://resources/relic_resource.gd")

static func build_pool() -> Array:
	return [
		_burning_blood(), _phoenix_feather(), _poison_vial(),
		_war_drum(), _ancient_artifact(), _hourglass(),
		_blood_stone(), _emperors_seal(), _serpent_bracelet(),
		_turtle_ship_model(), _artillery_horn(), _nanjung_ilgi(),
		_pharaoh_seal(), _devils_contract(), _cursed_crown(),
		_blood_oath(), _tacticians_map(), _iron_will(), _ancient_shield(),
	]

static func _burning_blood() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "버닝 블러드"
	r.description = "전투 승리 시 팀 전체 HP +6"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 6; return r

static func _phoenix_feather() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "불사조 깃털"
	r.description = "플레이어 턴 시작 시 에너지 +1"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _poison_vial() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "독약 병"
	r.description = "전투 시작 시 무작위 적에게 독 3"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY; r.value = 3; return r

static func _war_drum() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "전쟁 북"
	r.description = "플레이어 턴 시작 시 카드 1장 추가 드로우"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _ancient_artifact() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "고대 유물"
	r.description = "팀 전체 최대 HP +15"
	r.trigger = RelicRes.TriggerType.PASSIVE
	r.effect_type = RelicRes.EffectType.MAX_HP; r.value = 15; return r

static func _hourglass() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "모래시계"
	r.description = "턴 종료 시 덱에서 카드 1장 드로우"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _blood_stone() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "피의 돌"
	r.description = "피해 5 이상 받을 시 에너지 +1"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; r.condition_value = 5; return r

static func _emperors_seal() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "황제의 인장"
	r.description = "전투 시작 시 사기 +2 (나폴레옹 생존 시 적용)"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.GAIN_MORALE
	r.owner_hero_id = "napoleon"; r.value = 0; r.bonus_value = 2; return r

static func _serpent_bracelet() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "독사의 팔찌"
	r.description = "전투 시작 시 무작위 적 독 2 (클레오파트라 생존 시 독 4)"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.owner_hero_id = "cleopatra"; r.value = 2; r.bonus_value = 4; return r

static func _turtle_ship_model() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "거북선 모형"
	r.description = "플레이어 턴 시작 시 방어도 +2 (이순신 생존 시 +4)"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.BLOCK
	r.owner_hero_id = "yi_sun_sin"; r.value = 2; r.bonus_value = 4; return r

static func _artillery_horn() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "포병 나팔"
	r.description = "플레이어 턴 시작 시 사기 +1 (나폴레옹 생존 시 적용)"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.GAIN_MORALE
	r.owner_hero_id = "napoleon"; r.value = 0; r.bonus_value = 1; return r

static func _nanjung_ilgi() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "난중일기"
	r.description = "전투 승리 시 팀 HP +8 (이순신 생존 시 적용)"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL
	r.owner_hero_id = "yi_sun_sin"; r.value = 0; r.bonus_value = 8; return r

static func _pharaoh_seal() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "파라오의 인장"
	r.description = "플레이어 턴 시작 시 무작위 적 독 +1 (클레오파트라 생존 시 적용)"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.owner_hero_id = "cleopatra"; r.value = 0; r.bonus_value = 1; return r

static func _devils_contract() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "악마의 계약"
	r.description = "전투 승리 시 팀 HP +20. 단, 매 플레이어 턴 시작 시 무작위 영웅 HP -3"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 20
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 3; return r

static func _cursed_crown() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "저주받은 왕관"
	r.description = "최대 HP +25. 단, 매 전투 시작 시 무작위 영웅 HP -8"
	r.trigger = RelicRes.TriggerType.PASSIVE
	r.effect_type = RelicRes.EffectType.MAX_HP; r.value = 25
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.BATTLE_START
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 8; return r

static func _blood_oath() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "피의 서약"
	r.description = "플레이어 턴 시작 시 에너지 +1. 단, 턴 종료 시 무작위 영웅 HP -4"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 4; return r

static func _tacticians_map() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "전술가의 지도"
	r.description = "전투 시작 시 카드 1장 추가 드로우"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _iron_will() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "강철 의지"
	r.description = "전투 시작 시 에너지 +1"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _ancient_shield() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "고대의 방패"
	r.description = "전투 시작 시 팀 전체 방어도 +4"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 4; return r
