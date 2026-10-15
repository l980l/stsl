# resources/relic_resource.gd
class_name RelicResource
extends Resource

const CombatScale = preload("res://resources/balance/combat_scale.gd")

enum TriggerType {
	PASSIVE,            # 런 시작 시 1회 적용 (최대 HP 등)
	BATTLE_START,       # 전투 시작
	PLAYER_TURN_START,  # 플레이어 턴 시작
	PLAYER_TURN_END,    # 플레이어 턴 종료
	ON_HERO_DAMAGED,    # 영웅 피해 시
}

enum EffectType {
	HEAL, ENERGY, DRAW, APPLY_STATUS_ENEMY, MAX_HP, RECOVER_CARD,
	GAIN_MORALE, COST_REDUCTION, BLOCK,
	DAMAGE_HERO, RUN_STRENGTH,
	BUFF_SPEED_TEAM,    # BATTLE_START — 모든 영웅 power.speed_buff = value (전투 끝까지)
	TIME_HOURGLASS,     # PLAYER_TURN_END — 매 영웅 차례 종료 시 counter++, condition_value 배수마다 모든 영웅 speed_buff += value 누적
}

@export var relic_name: String = ""
@export var description: String = ""
@export var trigger: TriggerType = TriggerType.PASSIVE
@export var effect_type: EffectType = EffectType.HEAL
@export var value: int = 0
@export var owner_hero_id: String = ""  # "" = 공용. 특정 id = 해당 캐릭터 전용
@export var bonus_value: int = 0        # 전용 캐릭터 생존 시 value 대신 사용
@export var status_type: String = ""    # APPLY_STATUS_ENEMY: 부여할 상태이상 ("poison", "weak", 등)
@export var condition_value: int = 0    # ON_HERO_DAMAGED: 최소 피해량 조건
@export var is_cursed: bool = false
@export var penalty_trigger: TriggerType = TriggerType.PASSIVE
@export var penalty_effect_type: EffectType = EffectType.DAMAGE_HERO
@export var penalty_value: int = 0

# 스토리 단서용 i18n lore 키 — relic_name("relic.X.name") → "relic.X.lore" 파생.
# 호출부에서 tr() 후 키 원문/빈값이면 생략 (lore 미존재 유물 안전).
func lore_key() -> String:
	if relic_name.ends_with(".name"):
		return relic_name.trim_suffix(".name") + ".lore"
	return ""

# Keep RUN_STRENGTH's per-run coefficient in legacy units. Its aggregate is
# converted only after multiplying by battles/kills in GameManager; scaling the
# coefficient itself would make low values disproportionately strong.
func scale_for_combat() -> Resource:
	if not CombatScale.enabled() or has_meta("stsl_combat_scaled"):
		return self
	var display_numbers: Dictionary = {}
	if _effect_uses_combat_units(effect_type, status_type):
		value = _scale_display_value(value, display_numbers)
		bonus_value = _scale_display_value(bonus_value, display_numbers)
	if _effect_uses_combat_units(penalty_effect_type, ""):
		penalty_value = _scale_display_value(penalty_value, display_numbers)
	if trigger == TriggerType.ON_HERO_DAMAGED:
		condition_value = _scale_display_value(condition_value, display_numbers)
	if not display_numbers.is_empty():
		set_meta("stsl_combat_display_numbers", display_numbers)
	set_meta("stsl_combat_scaled", true)
	return self

static func _effect_uses_combat_units(effect: EffectType, applied_status: String) -> bool:
	if effect in [EffectType.HEAL, EffectType.MAX_HP, EffectType.BLOCK, EffectType.DAMAGE_HERO]:
		return true
	# GameManager's empty status defaults to poison, not a count-like status.
	return effect == EffectType.APPLY_STATUS_ENEMY and applied_status in ["", "poison", "charm", "strength"]

func format_description(localized: String) -> String:
	var replacements: Dictionary = get_meta("stsl_combat_display_numbers", {})
	if replacements.is_empty():
		return localized
	# Replace complete numeric tokens in a single pass. Sequential String.replace
	# would corrupt 100 through its "10" entry or rewrite a freshly inserted 1.
	var numbers := RegEx.new()
	numbers.compile("[0-9]+")
	var result := ""
	var cursor := 0
	for hit in numbers.search_all(localized):
		var start := hit.get_start()
		var legacy_text := hit.get_string()
		result += localized.substr(cursor, start - cursor)
		var legacy_value := legacy_text.to_int()
		result += str(replacements.get(legacy_value, legacy_value))
		cursor = hit.get_end()
	return result + localized.substr(cursor)

func display_description_key() -> String:
	if not CombatScale.enabled() or effect_type != EffectType.RUN_STRENGTH:
		return description
	match status_type:
		"kills_strength": return "relic.rune_of_fate.small.desc"
		"battles_strength": return "relic.tengu_feather.small.desc"
		"battles_per_hit": return "relic.conquerors_whip.small.desc"
	return description

static func _scale_display_value(legacy_value: int, replacements: Dictionary) -> int:
	var scaled := CombatScale.amount(legacy_value)
	if legacy_value > 0 and scaled != legacy_value:
		replacements[legacy_value] = scaled
	return scaled
