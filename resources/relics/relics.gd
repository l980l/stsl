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
		_ankh_of_life(), _eye_of_horus(), _scarab_talisman(),
		_rune_of_fate(), _mjolnir_shard(), _idun_apple(),
		_dharma_seal(), _dharma_drum(), _prayer_beads(),
		# 도교 신화 렐릭
		_yin_yang_mirror(), _five_elements_jade(), _immortal_crane_feather(),
		# 일본 신화 렐릭
		_ghost_talisman(), _tengu_feather(), _orochi_scale(),
		# 잔다르크 전용 렐릭
		_flag_of_orleans(), _saints_tears(),
		# 칭기즈칸 전용 렐릭
		_thousand_horses(), _conquerors_whip(),
		# 무사시 전용 렐릭
		_niten_ichi_ryu(), _gorin_sho_relic(),
	]

static func _burning_blood() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.burning_blood.name"
	r.description = "relic.burning_blood.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 6; return r

static func _phoenix_feather() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.phoenix_feather.name"
	r.description = "relic.phoenix_feather.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _poison_vial() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.poison_vial.name"
	r.description = "relic.poison_vial.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY; r.value = 3; return r

static func _war_drum() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.war_drum.name"
	r.description = "relic.war_drum.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _ancient_artifact() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.ancient_artifact.name"
	r.description = "relic.ancient_artifact.desc"
	r.trigger = RelicRes.TriggerType.PASSIVE
	r.effect_type = RelicRes.EffectType.MAX_HP; r.value = 15; return r

static func _hourglass() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.hourglass.name"
	r.description = "relic.hourglass.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _blood_stone() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.blood_stone.name"
	r.description = "relic.blood_stone.desc"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; r.condition_value = 5; return r

static func _emperors_seal() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.emperors_seal.name"
	r.description = "relic.emperors_seal.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.GAIN_MORALE
	r.owner_hero_id = "napoleon"; r.value = 0; r.bonus_value = 2; return r

static func _serpent_bracelet() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.serpent_bracelet.name"
	r.description = "relic.serpent_bracelet.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.owner_hero_id = "cleopatra"; r.value = 2; r.bonus_value = 4; return r

static func _turtle_ship_model() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.turtle_ship_model.name"
	r.description = "relic.turtle_ship_model.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.BLOCK
	r.owner_hero_id = "yi_sun_sin"; r.value = 2; r.bonus_value = 4; return r

static func _artillery_horn() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.artillery_horn.name"
	r.description = "relic.artillery_horn.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.GAIN_MORALE
	r.owner_hero_id = "napoleon"; r.value = 0; r.bonus_value = 1; return r

static func _nanjung_ilgi() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.nanjung_ilgi.name"
	r.description = "relic.nanjung_ilgi.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL
	r.owner_hero_id = "yi_sun_sin"; r.value = 0; r.bonus_value = 8; return r

static func _pharaoh_seal() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.pharaoh_seal.name"
	r.description = "relic.pharaoh_seal.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.owner_hero_id = "cleopatra"; r.value = 0; r.bonus_value = 1; return r

static func _devils_contract() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.devils_contract.name"
	r.description = "relic.devils_contract.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 20
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 3; return r

static func _cursed_crown() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.cursed_crown.name"
	r.description = "relic.cursed_crown.desc"
	r.trigger = RelicRes.TriggerType.PASSIVE
	r.effect_type = RelicRes.EffectType.MAX_HP; r.value = 25
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.BATTLE_START
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 8; return r

static func _blood_oath() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.blood_oath.name"
	r.description = "relic.blood_oath.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1
	r.is_cursed = true
	r.penalty_trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.penalty_effect_type = RelicRes.EffectType.DAMAGE_HERO; r.penalty_value = 4; return r

static func _tacticians_map() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.tacticians_map.name"
	r.description = "relic.tacticians_map.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _iron_will() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.iron_will.name"
	r.description = "relic.iron_will.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _ancient_shield() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.ancient_shield.name"
	r.description = "relic.ancient_shield.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 4; return r

# ──── Act 2 렐릭 (이집트 신화) ────

static func _ankh_of_life() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.ankh_of_life.name"
	r.description = "relic.ankh_of_life.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 12; return r

static func _eye_of_horus() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.eye_of_horus.name"
	r.description = "relic.eye_of_horus.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.DRAW
	r.value = 1; r.bonus_value = 2; r.owner_hero_id = "cleopatra"; return r

static func _scarab_talisman() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.scarab_talisman.name"
	r.description = "relic.scarab_talisman.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 8; return r

# ──── Act 3 렐릭 (북유럽 신화) ────

static func _rune_of_fate() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.rune_of_fate.name"
	r.description = "relic.rune_of_fate.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 2; return r

static func _mjolnir_shard() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.mjolnir_shard.name"
	r.description = "relic.mjolnir_shard.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 10; return r

static func _idun_apple() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.idun_apple.name"
	r.description = "relic.idun_apple.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 15; return r

# ──── 챕터 2 렐릭 (불교 신화) ────

static func _dharma_seal() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.dharma_seal.name"
	r.description = "relic.dharma_seal.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.ENERGY; r.value = 1; return r

static func _dharma_drum() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.dharma_drum.name"
	r.description = "relic.dharma_drum.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.GAIN_MORALE; r.value = 3; return r

static func _prayer_beads() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.prayer_beads.name"
	r.description = "relic.prayer_beads.desc"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.BLOCK; r.value = 10; return r

# ──── 챕터 2 렐릭 (도교 신화) ────

static func _yin_yang_mirror() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.yin_yang_mirror.name"
	r.description = "relic.yin_yang_mirror.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.COST_REDUCTION; r.value = 1; return r

static func _five_elements_jade() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.five_elements_jade.name"
	r.description = "relic.five_elements_jade.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.effect_type = RelicRes.EffectType.HEAL; r.value = 15; return r

static func _immortal_crane_feather() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.immortal_crane_feather.name"
	r.description = "relic.immortal_crane_feather.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.MAX_HP; r.value = 10; return r

# ──── 챕터 2 렐릭 (일본 신화) ────

static func _ghost_talisman() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.ghost_talisman.name"
	r.description = "relic.ghost_talisman.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_END
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.status_type = "poison"; r.value = 2; return r

static func _tengu_feather() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.tengu_feather.name"
	r.description = "relic.tengu_feather.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.DRAW; r.value = 1; return r

static func _orochi_scale() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.orochi_scale.name"
	r.description = "relic.orochi_scale.desc"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.APPLY_STATUS_ENEMY
	r.status_type = "weak"; r.value = 1; return r

# ──── 잔다르크 전용 렐릭 ────

static func _flag_of_orleans() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.flag_of_orleans.name"
	r.description = "relic.flag_of_orleans.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.HEAL
	r.owner_hero_id = "joan_of_arc"; r.value = 20; r.bonus_value = 40; return r

static func _saints_tears() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.saints_tears.name"
	r.description = "relic.saints_tears.desc"
	r.trigger = RelicRes.TriggerType.ON_HERO_DAMAGED
	r.effect_type = RelicRes.EffectType.HEAL
	r.owner_hero_id = "joan_of_arc"; r.value = 30; r.bonus_value = 60; return r

# ──── 칭기즈칸 전용 렐릭 ────

static func _thousand_horses() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.thousand_horses.name"
	r.description = "relic.thousand_horses.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.BLOCK
	r.owner_hero_id = "genghis_khan"; r.value = 30; return r

static func _conquerors_whip() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.conquerors_whip.name"
	r.description = "relic.conquerors_whip.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_WIN
	r.effect_type = RelicRes.EffectType.DRAW
	r.owner_hero_id = "genghis_khan"; r.value = 1; return r

# ──── 무사시 전용 렐릭 ────

static func _niten_ichi_ryu() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.niten_ichi_ryu.name"
	r.description = "relic.niten_ichi_ryu.desc"
	r.trigger = RelicRes.TriggerType.BATTLE_START
	r.effect_type = RelicRes.EffectType.ENERGY
	r.owner_hero_id = "musashi"; r.value = 1; return r

static func _gorin_sho_relic() -> Resource:
	var r: Resource = RelicRes.new(); r.relic_name = "relic.gorin_sho_relic.name"
	r.description = "relic.gorin_sho_relic.desc"
	r.trigger = RelicRes.TriggerType.PLAYER_TURN_START
	r.effect_type = RelicRes.EffectType.DRAW
	r.owner_hero_id = "musashi"; r.value = 1; return r
