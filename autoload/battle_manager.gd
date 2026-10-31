# autoload/battle_manager.gd
class_name BattleManagerClass
extends Node

const EffectRes = preload("res://resources/effect_resource.gd")
const CardRes  = preload("res://resources/card_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const RelicRes = preload("res://resources/relic_resource.gd")
const InteractionSys = preload("res://autoload/enemy_interaction_system.gd")
const SignatureSys = preload("res://autoload/enemy_signature_system.gd")

# VFX 임팩트 지연 조회 — 각 VFX 스크립트의 IMPACT_DELAY 상수 참조 (단일 진실)
const _VFX_LIGHTNING_BEAM = preload("res://scenes/vfx/lightning_beam_gpu.gd")
const _VFX_ICE_SHARDS     = preload("res://scenes/vfx/ice_shards_gpu.gd")
const _VFX_FIRE_BLAST     = preload("res://scenes/vfx/fire_blast_gpu.gd")
const _VFX_POISON_SPLASH  = preload("res://scenes/vfx/poison_splash_gpu.gd")
const _VFX_ACID_SPRAY     = preload("res://scenes/vfx/acid_spray_gpu.gd")
const _VFX_NEEDLE_STING   = preload("res://scenes/vfx/needle_sting_gpu.gd")
const _VFX_BITE_ATTACK    = preload("res://scenes/vfx/bite_attack_gpu.gd")
const _VFX_CLAW_ATTACK    = preload("res://scenes/vfx/claw_attack_gpu.gd")
const _VFX_ARROW_SHOT     = preload("res://scenes/vfx/arrow_shot_gpu.gd")
const _VFX_EXPLOSION_BLAST = preload("res://scenes/vfx/explosion_blast_gpu.gd")
const _VFX_BLUNT_SMASH    = preload("res://scenes/vfx/blunt_smash_gpu.gd")
const _VFX_BULLET_SHOT    = preload("res://scenes/vfx/bullet_shot_gpu.gd")
const _VFX_HOLY_STRIKE    = preload("res://scenes/vfx/holy_strike_gpu.gd")
const _VFX_HOLY_SLASH     = preload("res://scenes/vfx/holy_slash_gpu.gd")
const _VFX_HOLY_ARROW     = preload("res://scenes/vfx/holy_arrow_gpu.gd")
const _VFX_HOLY_FIRE      = preload("res://scenes/vfx/holy_fire_gpu.gd")
const _VFX_HOLY_BLUNT     = preload("res://scenes/vfx/holy_blunt_gpu.gd")
const _VFX_DEBUFF_HEX     = preload("res://scenes/vfx/debuff_hex_gpu.gd")
const _VFX_VULNERABLE     = preload("res://scenes/vfx/vulnerable_debuff_gpu.gd")
const _VFX_WEAKEN         = preload("res://scenes/vfx/weaken_debuff_gpu.gd")
const _VFX_CHARM_KISS     = preload("res://scenes/vfx/charm_kiss_gpu.gd")
const _VFX_INFATUATION    = preload("res://scenes/vfx/infatuation_gpu.gd")
const _VFX_HOLY_BUFF      = preload("res://scenes/vfx/holy_buff_gpu.gd")
const _VFX_WARRIOR_BUFF   = preload("res://scenes/vfx/warrior_buff_gpu.gd")
const _VFX_DEFENSE_BUFF   = preload("res://scenes/vfx/defense_buff.gd")
const _VFX_HEAL_BLESSING  = preload("res://scenes/vfx/heal_blessing_gpu.gd")
const _VFX_POWER_UP       = preload("res://scenes/vfx/power_up_gpu.gd")
const _VFX_SUMMON_CIRCLE  = preload("res://scenes/vfx/summon_circle_gpu.gd")
const _VFX_TARGET_MARKING = preload("res://scenes/vfx/target_marking_gpu.gd")
const _VFX_MIMIC          = preload("res://scenes/vfx/mimic_gpu.gd")
const _VFX_SACRIFICE      = preload("res://scenes/vfx/sacrifice_gpu.gd")
const _VFX_COUNTER_PREPARE = preload("res://scenes/vfx/counter_prepare.gd")
const _VFX_STEAL_CARD     = preload("res://scenes/vfx/steal_card_gpu.gd")

const TOKEN_DMG_PER_STACK: int = 25
const TOKEN_MAX_STACK: int = 6
const CHARM_THRESHOLD_BASE: int = 100

# Resources already use the selected units; never divide incoming card/intent
# values again. Explicit legacy mode is reserved for comparison harnesses.
var combat_unit_divisor: int = 10 if preload("res://resources/balance/combat_scale.gd").enabled() else 1
var _enemy_strength_remainders: Dictionary = {}

# Preserve the rate of repeated tiny enemy gains without fractional strength
# or rounding every authored +1 into an entire new combat point.
@warning_ignore("integer_division")
func gain_authored_enemy_strength(index: int, legacy_amount: int, source: String) -> int:
	var divisor := maxi(1, combat_unit_divisor)
	var key := "%d:%s" % [index, source]
	var total: int = int(_enemy_strength_remainders.get(key, 0)) + legacy_amount
	var gained: int = total / divisor
	_enemy_strength_remainders[key] = total % divisor
	if gained > 0:
		_apply_status_to_enemy(index, "strength", gained)
	return gained

func _combat_literal(legacy_amount: int) -> int:
	if legacy_amount <= 0:
		return legacy_amount
	var divisor: int = max(1, combat_unit_divisor)
	return max(1, int((legacy_amount + divisor / 2) / divisor))

# 치명타 시스템 — 기본 확률 5%, 마킹(marked_by) 시 +30% (총 35%), 발동 시 데미지 ×2
const CRIT_BASE_RATE: float = 0.05
const CRIT_MARK_BONUS: float = 0.30
const CRIT_MULTIPLIER: float = 2.0
const SWORDSMAN_VOW_BANK_CAP: int = 60  # 검사의 약속: 이순신 차례 끝 방어 이월 상한 (기존 단위)

# 튜토리얼 — true면 치명타 확정 (시연용). debug_hero_invincible 패턴.
var tutorial_force_crit: bool = false
var tutorial_active: bool = false
var tutorial_allowed_cards: Array = []
var tutorial_allow_end_turn: bool = false
var tutorial_effect_pending: bool = false

# 의존성 주입 — 프로덕션: BattleScene이 설정, 테스트: 직접 할당
var team_mgr = null
var deck_mgr = null
var turn_interval: float = 0.0  # BattleScene이 0.2로 설정, 테스트는 기본 0.0 (await 스킵)

# 배틀 상태
var is_battle_active: bool = false
var is_player_turn: bool = false

# 적 상태
var _enemies: Array = []
var _enemy_hp: Array = []
var _enemy_alive: Array = []
var _enemy_block: Array = []
var _enemy_status: Array = []
var _enemy_intent_index: Array = []
var _enemy_phase: Array = []
var _last_attacker: Dictionary = {}
# VFX용 — 현재 행동 중인 공격자 (int=적 인덱스 / String=hero_id / null).
# _execute_intent 동안만 유효. battle_scene이 lightning 등 빔 VFX 시전자 좌표 결정에 사용.
var _vfx_caster = null

var debug_hero_invincible: bool = false

# 전투 통계 (보상 씬에서 TALLY 표시용)
var turn_count: int = 0
var damage_taken_this_battle: int = 0
# T3-MIMIC: 플레이어 턴 동안 적에게 가한 누적 데미지 — start_player_turn에서 리셋, MIMIC 인텐트가 비율로 반사
var _player_damage_this_turn: int = 0
var _in_player_turn: bool = false  # MIMIC 트래커 게이트

# 영웅 상태 (HP는 TeamManager가 관리)
var _hero_block: Dictionary = {}
# 성전 보상용 아군 실제 회복량 — 이번 영웅 차례 / 이번 전투 누적 (_heal_hero_safe 에서 집계).
var _team_healed_turn: int = 0
var _team_healed_battle: int = 0
# 람세스의 방패: 이번 영웅 차례에 취약한 적 공격으로 클레오파트라가 방어를 얻은 횟수.
var _vulnerable_guard_hits: int = 0
const VULNERABLE_GUARD_LIMIT: int = 3
var _hero_status: Dictionary = {}

# 지속 효과 (권능 카드): { "<key>": { "value": int, "owner_id": String, "params": Dictionary }, ... }
var _active_powers: Dictionary = {}

# DISCARD_PICK_DRAW 모달 대기 중 상태 (빈 Dictionary면 대기 없음)
var _pending_discard_pick: Dictionary = {}

# 이번 플레이어 턴 카드 사용 횟수 (만리 원정용)
var _cards_played_this_turn: int = 0
# 적별 카드 타입 카운터: { enemy_index: { "count": int, "fired_count": int } }
var _enemy_card_counters: Dictionary = {}
var _cards_drawn_this_turn: int = 0
var _kills_this_card: int = 0
var _enthralls_this_card: int = 0
var _in_echo_replay: bool = false
var _turn_effect_uses: Dictionary = {}

# 개체별 턴 큐 (ATB) — actor_id → 다음 차례 카운터 (작을수록 먼저)
var _turn_queue_at: Dictionary = {}
# 시간의 모래시계 (relic TIME_HOURGLASS) 카운터 — 전투 시작 시 0, 매 영웅 차례 종료마다 ++
var _hourglass_counter: int = 0
var _current_actor_id: String = ""

signal battle_started()
signal battle_won()
signal battle_lost()
signal player_turn_started()
signal enemy_turn_started()
# 개체별 턴 시스템 (33옵스퀴르 식 ATB) — actor_id 는 "hero:<id>" 또는 "enemy:<idx>"
@warning_ignore("unused_signal")
signal turn_started(actor_id: String)
@warning_ignore("unused_signal")
signal turn_ended(actor_id: String)
@warning_ignore("unused_signal")
signal turn_queue_changed(preview: Array)  # 다음 N차례 미리보기 (UI 갱신)
signal enemy_died(enemy_index: int)
# is_crit: 치명타 여부 (UI popup 차별 표시용). 기본 false — 기존 호출처 호환.
signal enemy_damaged(enemy_index: int, amount: int, damage_type: String, is_crit: bool)
signal hero_damaged(hero_id: String, amount: int, damage_type: String, is_crit: bool)
signal hero_block_gained(hero_id: String, amount: int)
signal status_applied(target: String, status_type: String, stacks: int)
signal morale_changed(hero_id: String, new_value: int)
signal active_powers_changed()
signal enemy_counter_changed(enemy_index: int)
signal card_pick_requested(action: String, draw_count: int)
signal boss_phase_changed(enemy_index: int, new_phase: int)
signal enemy_spawned(enemy_index: int)  # T3-SUMMON: 런타임 적 추가 알림 (UI 갱신용)
@warning_ignore("unused_signal")
signal signature_fired(enemy_index: int, signature_name: String, target_hero_id: String)  # 신화 시그니처 발동 알림 (UI 토스트용). target_hero_id: 영웅 대상 시그니처(저주 등)의 타겟, 없으면 ""
signal counter_triggered(hero_id: String, enemy_index: int, is_major: bool)  # 카운터 발동 — VFX 트리거 (major = charge 보스 무효)
signal token_attack_fired(hero_id: String, token_index: int, enemy_index: int)  # 토큰 (병사) 발사 — VFX/SFX 시각 처리용
signal passive_buff_applied(enemy_index: int, status_type: String, value: int)  # phase_buffs / 시그너처 등 intent 외 자동 BUFF — battle_scene 이 VFX spawn 용도
signal hero_turn_skipped(hero_id: String)  # 스턴 등으로 영웅 차례 자동 종료 — 토스트·VFX 용
signal synergy_triggered(synergy_key: String, hero_id: String)  # 교차 영웅 시너지 발동 — battle_scene 토스트용
signal hero_block_vfx(hero_id: String)  # 시너지 등으로 영웅 방어도 획득 — battle_scene defense_buff VFX용
@warning_ignore("unused_signal")
signal synergy_effect_vfx(caster_hero_id: String, vfx_status: String, enemy_indices: Array)  # 시너지 데미지/상태이상 — 지정 시전자에서 VFX 발사
# 시너지 반격 — 지정 시전자→적 VFX 발사. battle_scene 이 VFX 임팩트 시점에 상태이상 적용.
signal synergy_counter_vfx(caster_hero_id: String, target_enemy_index: int, status_type: String, stacks: int)
# 시너지 아군 효과 VFX — 회복/속도버프 등. battle_scene 이 대상 전원에 VFX 재생, 임팩트 시점에 효과 적용.
signal synergy_ally_vfx(vfx_kind: String, hero_ids: Array, value: int, duration: int)
# 시너지 생명 흡수 VFX — 적 위치에서 각 아군에게 빔. battle_scene 이 적→각 아군 life_drain 재생, 임팩트 시점에 회복 적용.
signal synergy_drain_vfx(hero_ids: Array, value: int, target_enemy_index: int)

# VFX 차지 시작 — battle_scene 이 받아 caster→target VFX 재생.
# 차지(IMPACT_DELAY) 이후 데미지/상태 적용 + 기존 시그널 (hero_damaged 등) emit.
# target_hero_id: 단일 타겟의 영웅 id ("" 이면 ALL 또는 미지정)
signal intent_vfx_charge_start(enemy_index: int, intent: Resource, target_hero_id: String)
signal card_vfx_charge_start(card: Resource, target_enemy_index: int, target_hero_id: String)
# 카드의 모든 효과(VFX impact 포함)가 적용된 뒤 발생. 튜토리얼 등 순차 UI가 사용한다.
signal card_effects_resolved(card: Resource)
# fx 임팩트 도달(screen_effect) 시점 중계 — battle_scene 의 fx.screen_effect 가 emit.
# popup·SFX 동기화: timer 보정 대신 fx 의 실제 임팩트 시점에 데미지 적용.
signal vfx_impact_resolved
# 적 SPECIAL 인텐트가 카드 N장을 이번 전투 동안 exhaust 시켰을 때 (battle_scene 토스트용)
signal cards_exhausted_by_enemy(card_names: Array)

# 독 DoT tick — 데미지 시그널과 별개로 가스 VFX/SFX 트리거 (target = "enemy_X" 또는 hero_id)
signal poison_tick_applied(target: String, amount: int)

# 차지 중 카드의 예측 누적 데미지 — UI 가 사망 예정 적 dim/비활성화 + 추가 ATTACK 카드 거부
var _pending_dmg_to_enemy: Dictionary = {}  # enemy_index(int) → int
# 적 SPECIAL remove_card 로 이번 전투 동안 빼앗긴 카드 (전투 종료 시 draw_pile 복원)
var _enemy_stolen_cards: Array = []

# GameSettings autoload 안전 접근 — CLI test 환경에서 식별자 미인식 회피
# null(=test 환경) 시 0 반환 → 모든 await 스킵 → 동기 즉시 적용 유지
func _vfx_speed_mul() -> float:
	if not is_inside_tree():
		return 0.0
	var gs := get_node_or_null("/root/GameSettings")
	return gs.vfx_speed_multiplier if gs else 0.0

func _turn_interval_mul() -> float:
	if not is_inside_tree():
		return 0.0
	var gs := get_node_or_null("/root/GameSettings")
	return gs.turn_interval_multiplier if gs else 0.0

# ── VFX 임팩트 지연 (초) — vfx_speed_multiplier 적용된 값 ──
func _vfx_impact_delay_for_damage_type(dtype: String) -> float:
	var base: float = 0.0
	match dtype:
		"lightning":   base = _VFX_LIGHTNING_BEAM.IMPACT_DELAY
		"ice":         base = _VFX_ICE_SHARDS.IMPACT_DELAY
		"fire":        base = _VFX_FIRE_BLAST.IMPACT_DELAY
		"poison":      base = _VFX_POISON_SPLASH.IMPACT_DELAY
		"acid_spray":  base = _VFX_ACID_SPRAY.IMPACT_DELAY
		"needle_sting": base = _VFX_NEEDLE_STING.IMPACT_DELAY
		"bite_attack": base = _VFX_BITE_ATTACK.IMPACT_DELAY
		"claw_attack": base = _VFX_CLAW_ATTACK.IMPACT_DELAY
		"projectile":  base = _VFX_ARROW_SHOT.IMPACT_DELAY
		"explosive":   base = _VFX_EXPLOSION_BLAST.IMPACT_DELAY
		"blunt":       base = _VFX_BLUNT_SMASH.IMPACT_DELAY
		"bullet":      base = _VFX_BULLET_SHOT.IMPACT_DELAY
		"holy_strike": base = _VFX_HOLY_STRIKE.IMPACT_DELAY
		"holy_slash":  base = _VFX_HOLY_SLASH.IMPACT_DELAY
		"holy_bolt":   base = _VFX_HOLY_ARROW.IMPACT_DELAY
		"holy_fire":   base = _VFX_HOLY_FIRE.IMPACT_DELAY
		"holy_blunt":  base = _VFX_HOLY_BLUNT.IMPACT_DELAY
		"curse":       base = _VFX_DEBUFF_HEX.IMPACT_DELAY  # curse 공격 = debuff hex 빔
		_:             base = 0.0  # slash 등 impact-only — 즉발
	return base * _vfx_speed_mul()

func _vfx_impact_delay_for_status(stype: String) -> float:
	var base: float = 0.0
	if stype == "weak":
		base = _VFX_WEAKEN.IMPACT_DELAY
	elif stype == "vulnerable":
		base = _VFX_VULNERABLE.IMPACT_DELAY
	elif stype == "charm":
		base = _VFX_CHARM_KISS.IMPACT_DELAY
	elif stype == "enthrall":
		base = _VFX_INFATUATION.IMPACT_DELAY
	elif stype == "poison":
		base = _VFX_POISON_SPLASH.IMPACT_DELAY
	elif stype.begins_with("power."):
		base = _VFX_HOLY_BUFF.IMPACT_DELAY  # holy_buff / warrior_buff 동일 차지
	return base * _vfx_speed_mul()

# 적 인텐트 차지 시간
func _intent_vfx_impact_delay(intent: Resource) -> float:
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			return _vfx_impact_delay_for_damage_type(intent.damage_type)
		IntentRes.ActionType.BUFF:
			# 적 자기 강화 — block(defense_buff) / power.*(warrior_buff)
			var base: float = _VFX_DEFENSE_BUFF.IMPACT_DELAY if intent.status_type == "block" else _VFX_WARRIOR_BUFF.IMPACT_DELAY
			return base * _vfx_speed_mul()
		IntentRes.ActionType.DEBUFF:
			return _vfx_impact_delay_for_status(intent.status_type)
		IntentRes.ActionType.CHARGE_UP:
			return _VFX_POWER_UP.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.SUMMON:
			return _VFX_SUMMON_CIRCLE.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.WARD:
			return _VFX_DEFENSE_BUFF.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.HEAL_ALLY:
			return _VFX_HEAL_BLESSING.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.BUFF_ALLY:
			# block 이면 defense_buff, 그 외 warrior_buff
			var base: float = _VFX_DEFENSE_BUFF.IMPACT_DELAY if intent.status_type == "block" else _VFX_WARRIOR_BUFF.IMPACT_DELAY
			return base * _vfx_speed_mul()
		IntentRes.ActionType.MARK_TARGET:
			return _VFX_TARGET_MARKING.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.MIMIC:
			return _VFX_MIMIC.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.SACRIFICE:
			return _VFX_SACRIFICE.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.COUNTER_PREPARE:
			return _VFX_COUNTER_PREPARE.IMPACT_DELAY * _vfx_speed_mul()
		IntentRes.ActionType.SPECIAL:
			# remove_card variant (또는 미설정·"weak") 만 steal_card VFX
			var v: String = intent.status_type
			if v == "" or v == "weak" or v == "remove_card":
				return _VFX_STEAL_CARD.IMPACT_DELAY * _vfx_speed_mul()
			return 0.0
		_:
			return 0.0

# 영웅 카드 차지 시간 — 첫 effect 기준
# damage_type 이 명시된 effect 는 모두 ATTACK 처리 (CONDITIONAL_DMG, DAMAGE_PER_*, SACRIFICE_PAYOFF 등)
# 단일 effect 의 VFX impact delay (해당 VFX screen_effect 시점 근사). 0 = 전용 VFX 없음.
func _effect_vfx_impact_delay(effect: Resource, target_enemy_index: int = -1) -> float:
	if effect.damage_type != "":
		return _vfx_impact_delay_for_damage_type(effect.damage_type)
	match effect.effect_type:
		EffectRes.EffectType.APPLY_STATUS:
			return _vfx_impact_delay_for_status(effect.status_type)
		EffectRes.EffectType.CHARM:
			# CHARM effect_type — enthrall 발동 예정이면 infatuation 빔(긴 차지) 딜레이로 동기
			if target_enemy_index >= 0 and will_enthrall_enemy(target_enemy_index, effect.value):
				return _VFX_INFATUATION.IMPACT_DELAY * _vfx_speed_mul()
			return _VFX_CHARM_KISS.IMPACT_DELAY * _vfx_speed_mul()
		EffectRes.EffectType.HEAL, EffectRes.EffectType.HEAL_ALL, EffectRes.EffectType.HEAL_PER_DEAD_ALLY:
			return _VFX_HEAL_BLESSING.IMPACT_DELAY * _vfx_speed_mul()
		EffectRes.EffectType.BLOCK, EffectRes.EffectType.BLOCK_ALL, EffectRes.EffectType.FORMATION_BLOCK, EffectRes.EffectType.COUNTER_BLOCK, EffectRes.EffectType.BLOCK_PER_CARDS_PLAYED, EffectRes.EffectType.MORALE_TO_BLOCK:
			return _VFX_DEFENSE_BUFF.IMPACT_DELAY * _vfx_speed_mul()
	return 0.0

# 효과가 속한 VFX 그룹 키 — battle_scene._on_card_vfx_start 의 dedup 그룹과 일치.
# 같은 그룹의 여러 효과는 VFX 1개를 공유(첫 효과가 spawn, 나머지는 흡수) → 같은 impact 시점에 적용.
func _effect_vfx_group(effect: Resource) -> String:
	if effect.damage_type != "":
		return "attack"
	match effect.effect_type:
		EffectRes.EffectType.APPLY_STATUS:
			if effect.status_type.begins_with("power.") or effect.target == "SELF":
				return "buff"
			return "debuff"  # 적 디버프 + taunt (battle_scene did_debuff 그룹)
		EffectRes.EffectType.CHARM, EffectRes.EffectType.DEBUFF_SPEED:
			return "debuff"
		EffectRes.EffectType.MARK_ENEMY:
			return "mark"
		EffectRes.EffectType.HEAL, EffectRes.EffectType.HEAL_ALL, EffectRes.EffectType.HEAL_PER_DEAD_ALLY, EffectRes.EffectType.BLOCK, EffectRes.EffectType.BLOCK_ALL, EffectRes.EffectType.FORMATION_BLOCK, EffectRes.EffectType.COUNTER_BLOCK, EffectRes.EffectType.BLOCK_PER_CARDS_PLAYED, EffectRes.EffectType.MORALE_TO_BLOCK, EffectRes.EffectType.SUMMON_TOKEN, EffectRes.EffectType.PURGE_STATUS:
			return "self_aoe"
		EffectRes.EffectType.BUFF_SPEED, EffectRes.EffectType.SACRIFICE_HP, EffectRes.EffectType.GAIN_MORALE:
			return "buff"
	return "none"  # 전용 VFX 없음 (DRAW/ENERGY 등) — 첫 스테이지에서 적용

# 이 효과의 결과 폰트(데미지/상태)가 표시돼야 할 VFX impact delay.
# 효과가 속한 VFX 그룹의 '첫 효과' delay 를 반환 (그룹 내 효과는 VFX 1개 공유 → 같은 시점에 표시).
# ATTACK 빔은 디버프 rider(weak/vulnerable/charm 등)를 흡수 → 데미지와 같은 시점
# (battle_scene 이 attack 발동 시 did_debuff=true 로 디버프 빔을 따로 안 띄움). 단, BLOCK/buff/heal
# 등 별도 VFX 그룹은 자기 impact 시점에 따로 표시.
func _effect_stage_delay(card: Resource, effect: Resource, target_enemy_index: int = -1) -> float:
	var g := _effect_vfx_group(effect)
	if _card_has_damage(card) and (g == "attack" or g == "debuff"):
		for e in card.effects:
			if e.damage_type != "":
				return _vfx_impact_delay_for_damage_type(e.damage_type)
		return 0.0
	for e in card.effects:
		if _effect_vfx_group(e) == g:
			return _effect_vfx_impact_delay(e, target_enemy_index)
	return _effect_vfx_impact_delay(effect, target_enemy_index)

# 차지 중 카드의 예측 데미지 — UI 가 사망 예정 적을 즉시 dim/비활성화 + 추가 ATTACK 거부
signal pending_damage_changed(enemy_index: int)

# 적 인텐트 표시용 — strength·weak·FORM_SWITCH·counter_pool 적용된 실제 데미지 추정
# (치명타·dnd·타겟별 vulnerable 은 미포함 — 실제 경로의 _execute_intent 와 버킷 동일)
func get_intent_display_damage(enemy_index: int, intent: Resource) -> int:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return intent.value
	var status: Dictionary = _enemy_status[enemy_index]
	var ctx := DamageContext.new()
	ctx.base = intent.value
	# strength → flat (실제 경로 동일)
	ctx.flat = status.get("strength", 0)
	# counter_pool → flat 가산 (실제 경로 동일: _atk_ctx.flat += counter_pool)
	ctx.flat += status.get("counter_pool", 0)
	# weak → out_pct -0.25
	if status.get("weak", 0) > 0:
		ctx.out_pct -= 0.25
	# FORM_SWITCH offense → out_pct +0.5
	if _is_enemy_in_offense_mode(enemy_index):
		ctx.out_pct += 0.5
	# crit_mult = 1.0, dnd_mult = 1.0 (미리보기: 확률·1회성 미포함)
	return compute_damage(ctx)

func _card_has_damage(card: Resource) -> bool:
	for effect in card.effects:
		if effect.damage_type != "":
			return true
	return false

# UI 용 — 단일 DAMAGE effect 의 buff/debuff 반영 데미지 (1회 hit 기준).
# target_enemy_index >= 0 시 그 적의 vulnerable/황제의무도 추가 반영. -1 면 hero 측만.
# DAMAGE 아니면 effect.value 그대로.
# 치명타·dnd 는 미포함 (실제 경로 _apply_card_effects 와 동일 버킷, 비치명타 기준)
func estimate_effect_damage(effect: Resource, owner_id: String, target_enemy_index: int = -1) -> int:
	if effect.rule_id == "poison_tick_now":
		return _card_effect_base_damage(effect, owner_id, target_enemy_index, true)
	if effect.rule_id == "paired_draw_damage":
		var pair_ctx := DamageContext.new()
		pair_ctx.base = _paired_draw_damage(owner_id, effect.rule_params)
		if target_enemy_index >= 0 and target_enemy_index < _enemy_status.size():
			var pair_status: Dictionary = _enemy_status[target_enemy_index]
			if pair_status.get("invuln", 0) > 0:
				return 0
			if pair_status.get("vulnerable", 0) > 0:
				pair_ctx.in_pct += 0.5
			if pair_status.get("duel_lock", 0) > 0 and pair_status.get("duel_lock_owner", "") == owner_id:
				pair_ctx.in_pct += 0.5
			if _is_enemy_in_defense_mode(target_enemy_index):
				pair_ctx.mitigation.append(0.5)
		return compute_damage(pair_ctx)
	if effect.effect_type not in [EffectRes.EffectType.DAMAGE, EffectRes.EffectType.CONDITIONAL_DMG]:
		return effect.value
	var owner_status: Dictionary = _hero_status.get(owner_id, {})
	var ctx := DamageContext.new()
	ctx.base = _card_effect_base_damage(effect, owner_id, target_enemy_index, true)
	# strength → flat
	ctx.flat = _hero_strength(owner_id)
	# weak → out_pct -0.25
	if owner_status.get("weak", 0) > 0:
		ctx.out_pct -= 0.25
	if target_enemy_index >= 0 and target_enemy_index < _enemy_status.size():
		var t_status: Dictionary = _damage_status_after_spend(effect, _enemy_status[target_enemy_index])
		if t_status.get("duel_lock", 0) > 0 and t_status.get("duel_lock_owner", "") == owner_id:
			ctx.in_pct += 0.5
		# FORM_SWITCH offense → out_pct +0.5 (적이 공격자인 경우는 없으므로 영웅 측 카드 기준 불필요)
		# vulnerable → in_pct +0.5
		if t_status.get("vulnerable", 0) > 0:
			ctx.in_pct += 0.5
	# crit_mult = 1.0, dnd_mult = 1.0 (미리보기: 확률·1회성 미포함)
	return compute_damage(ctx)

# Pure projection used by card text and the queued-damage indicator.
func _card_effect_base_damage(effect: Resource, owner_id: String, target: int, before_play: bool = false) -> int:
	var st: Dictionary = _hero_status.get(owner_id, {})
	var enemy_st: Dictionary = _enemy_status[target] if target >= 0 and target < _enemy_status.size() else {}
	var p: Dictionary = effect.rule_params
	match effect.rule_id:
		"poison_tick_now": return int(enemy_st.get("poison_dmg", 0)) if enemy_st.get("poison_dur", 0) > 0 else 0
		"block_multi_hit": return effect.value + mini(_hero_block.get(owner_id, 0), p.consume_cap)
		"debuff_cash_damage":
			var spent := 0
			for key in p.statuses:
				spent += mini(int(enemy_st.get(key, 0)), int(p.consume_cap))
			return effect.value + spent * effect.bonus_value
		"marked_cash_all": return effect.value + (effect.bonus_value if owner_id in enemy_st.get("marked_by", []) else 0)
		"duel_status_damage": return effect.bonus_value if _get_living_enemy_count() == 1 and enemy_st.get(p.status, 0) >= int(p.consume) else effect.value
		"paired_draw_damage": return _paired_draw_damage(owner_id, p)
		"morale_spend_damage": return effect.bonus_value if st.get("morale", 0) >= int(p.consume) else effect.value
		"block_damage_all": return effect.value + _hero_block.get(owner_id, 0)
		"heal_turn_damage", "heal_battle_damage": return _heal_cash_damage(effect)
		"consume_own_block": return effect.value + int(mini(_hero_block.get(owner_id, 0), p.consume_cap) * float(p.multiplier))
		"consume_own_tokens", "consume_own_tokens_all": return effect.value + mini(st.get("tokens", 0), p.get("consume_cap", p.get("consume", 0))) * effect.bonus_value
		"team_morale_damage", "team_token_damage":
			var total := 0
			var key := "morale" if effect.rule_id == "team_morale_damage" else "tokens"
			if team_mgr:
				for hero in team_mgr.get_living_heroes():
					total += int(_hero_status.get(hero.hero_id, {}).get(key, 0))
			return effect.value + mini(total * effect.bonus_value, p.cap)
		"damage_per_debuff_type":
			var count := 0
			for key in ["weak", "vulnerable", "charm"]:
				if enemy_st.get(key, 0) > 0:
					count += 1
			if enemy_st.get("poison_dmg", 0) > 0 and enemy_st.get("poison_dur", 0) > 0:
				count += 1
			return effect.value + mini(count, p.cap) * effect.bonus_value
		"consume_charm_damage": return effect.value + mini(enemy_st.get("charm", 0), p.consume_cap) * effect.bonus_value
		"poison_burst_multiplier": return int(enemy_st.get("poison_dmg", 0)) * int(p.multiplier) if enemy_st.get("poison_dur", 0) > 0 else 0
		"sacrifice_bank_payoff": return effect.value + mini(st.get("sacrifice_bank", 0), p.consume_cap)
		"other_card_this_turn_damage":
			var prior: int = deck_mgr.get_cards_played_this_turn(owner_id) if deck_mgr else 0
			return effect.bonus_value if prior >= (1 if before_play else 2) else effect.value
	if effect.effect_type == EffectRes.EffectType.CONDITIONAL_DMG:
		match effect.status_type:
			"low_hp", "very_low_hp":
				var owner: Resource = team_mgr.get_hero(owner_id) if team_mgr else null
				var threshold := 30 if effect.status_type == "very_low_hp" else 50
				if owner != null and team_mgr.get_current_hp(owner_id) * 100 <= owner.max_hp * threshold:
					return effect.bonus_value
			"morale":
				if st.get("morale", 0) > 0:
					return effect.bonus_value
			"has_poison":
				if enemy_st.get("poison_dmg", 0) > 0:
					return effect.bonus_value
			"has_poison_1", "has_poison_2", "has_poison_5", "has_poison_10":
				var gate: int = effect.status_type.trim_prefix("has_poison_").to_int()
				if gate >= 5:
					gate = _combat_literal(gate)
				if enemy_st.get("poison_dmg", 0) >= gate:
					return effect.bonus_value
			"enemy_count_1":
				if _get_living_enemy_count() == 1:
					return effect.bonus_value
			"has_debuffs_3":
				var count := int(enemy_st.get("weak", 0) > 0) + int(enemy_st.get("vulnerable", 0) > 0) + int(enemy_st.get("poison_dmg", 0) > 0)
				if count >= 3:
					return effect.bonus_value
			"cards_played_before":
				if deck_mgr and deck_mgr.get_cards_played_this_turn(owner_id) >= (1 if before_play else 2):
					return effect.bonus_value
			"team_hp_below_30":
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						if team_mgr.get_current_hp(hero.hero_id) * 100 <= hero.max_hp * 30:
							return effect.bonus_value
			"hand_size_0":
				if deck_mgr and deck_mgr.get_hand(owner_id).size() <= (1 if before_play else 0):
					return effect.bonus_value
			"enemy_hp_below_30", "enemy_hp_below_50":
				var threshold := 30 if effect.status_type.ends_with("30") else 50
				if target >= 0 and target < _enemies.size() and _enemy_hp[target] * 100 <= _enemies[target].max_hp * threshold:
					return effect.bonus_value
	return effect.value

func _damage_status_after_spend(effect: Resource, source: Dictionary) -> Dictionary:
	if effect.rule_id != "debuff_cash_damage":
		return source
	var projected := source.duplicate(true)
	for key in effect.rule_params.statuses:
		projected[key] = maxi(0, int(projected.get(key, 0)) - int(effect.rule_params.consume_cap))
	return projected

@warning_ignore("integer_division")
func _paired_draw_damage(owner_id: String, params: Dictionary) -> int:
	var draws: int = deck_mgr.get_draws_this_turn(owner_id) if deck_mgr else 0
	if draws <= 0:
		return 0
	return (draws / 2) * int(params.per_pair) + (draws % 2) * int(params.per_odd) + int(params.get("upgrade_bonus", 0))

# 카드의 단일 타겟/ALL 데미지 추정 — compute_damage 파이프라인 사용 (실제 경로 동일 버킷)
# 결과: enemy_index → 예측 데미지 합 (hit_count 포함)
# 치명타·dnd·bonus_per_hit 는 미포함 (확률·1회성)
func _estimate_card_damage(card: Resource, target_enemy_index: int) -> Dictionary:
	var result: Dictionary = {}
	var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
	var _str_flat: int = _hero_strength(card.owner_id)
	var _base_out_pct: float = 0.0
	if owner_status.get("weak", 0) > 0:
		_base_out_pct -= 0.25
	for effect in card.effects:
		if effect.damage_type == "":
			continue
		if effect.condition != "" and not _evaluate_condition(effect.condition, card):
			continue
		var targets: Array = []
		if effect.target == "ALL":
			for i in range(_enemies.size()):
				if _enemy_alive[i]:
					targets.append(i)
		else:
			if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
				targets.append(target_enemy_index)
		for ti in targets:
			if effect.rule_id == "poison_tick_now":
				result[ti] = int(result.get(ti, 0)) + _card_effect_base_damage(effect, card.owner_id, ti)
				continue
			if effect.rule_id == "paired_draw_damage":
				result[ti] = int(result.get(ti, 0)) + estimate_effect_damage(effect, card.owner_id, ti)
				continue
			var t_status: Dictionary = _damage_status_after_spend(effect, _enemy_status[ti]) if ti < _enemy_status.size() else {}
			var ctx := DamageContext.new()
			ctx.base = _card_effect_base_damage(effect, card.owner_id, ti)
			ctx.flat = 0 if effect.rule_id == "poison_burst_multiplier" else _str_flat
			ctx.out_pct = _base_out_pct
			if t_status.get("duel_lock", 0) > 0 and t_status.get("duel_lock_owner", "") == card.owner_id:
				ctx.in_pct += 0.5
			# vulnerable → in_pct +0.5
			if t_status.get("vulnerable", 0) > 0:
				ctx.in_pct += 0.5
			# crit_mult = 1.0, dnd_mult = 1.0 (미리보기: 확률·1회성 미포함)
			var t_dmg: int = compute_damage(ctx)
			var prev: int = int(result[ti]) if result.has(ti) else 0
			result[ti] = prev + t_dmg * effect.hit_count
	return result

func _add_pending_dmg(idx: int, amount: int) -> void:
	if amount <= 0:
		return
	var cur: int = _pending_dmg_to_enemy[idx] if _pending_dmg_to_enemy.has(idx) else 0
	_pending_dmg_to_enemy[idx] = cur + amount
	pending_damage_changed.emit(idx)

func _clear_pending_dmg(idx: int, amount: int) -> void:
	if amount <= 0 or not _pending_dmg_to_enemy.has(idx):
		return
	var v: int = int(_pending_dmg_to_enemy[idx]) - amount
	if v <= 0:
		_pending_dmg_to_enemy.erase(idx)
	else:
		_pending_dmg_to_enemy[idx] = v
	pending_damage_changed.emit(idx)

func get_pending_dmg(idx: int) -> int:
	return int(_pending_dmg_to_enemy[idx]) if _pending_dmg_to_enemy.has(idx) else 0

func get_enemy_effective_hp(idx: int) -> int:
	return max(0, get_enemy_hp(idx) - get_pending_dmg(idx))

func is_enemy_doomed(idx: int) -> bool:
	if idx < 0 or idx >= _enemy_hp.size():
		return false
	if not _enemy_alive[idx]:
		return false
	return get_enemy_effective_hp(idx) <= 0

# fx 의 screen_effect 시그널(=실제 임팩트 시점) 까지 대기.
# fx 가 emit 안 하는 경우(예: 비공격 즉발) fallback_timeout 후 진행.
func _await_vfx_impact(fallback_timeout: float) -> void:
	# 단위 테스트에서는 BattleManager가 SceneTree 밖에 있으므로 즉시 완료한다.
	if not is_inside_tree() or fallback_timeout <= 0.0:
		return
	var done := [false]
	var on_resolve := func() -> void:
		if not done[0]:
			done[0] = true
	vfx_impact_resolved.connect(on_resolve, CONNECT_ONE_SHOT)
	get_tree().create_timer(fallback_timeout).timeout.connect(on_resolve)
	while not done[0]:
		await get_tree().process_frame
	# 시그널 한 번 더 오면 무시 — connect 가 ONE_SHOT 이라 자동 disconnect

# 시너지 추가 효과 VFX 임팩트까지 대기 — 추가 데미지/상태이상 폰트를 빔 명중 시점에 동기화.
# 테스트 환경(_vfx_speed_mul()==0)에서는 0 → await 스킵 → 동기 즉시 적용.
func _await_synergy_impact(vfx_status: String) -> void:
	var _d: float = _vfx_impact_delay_for_status(vfx_status)
	if _d > 0.0:
		await _await_vfx_impact(_d + 0.5)

# 검사의 약속 (이순신×무사시): 무사시가 공격할 때 이순신에게 방어가 있으면 두 영웅 속도 +1 (전투 동안).
func _swordsman_vow_speed() -> void:
	if not team_mgr.is_alive("yi_sun_sin") or _hero_block.get("yi_sun_sin", 0) <= 0:
		return
	for hid in ["musashi", "yi_sun_sin"]:
		var aid: String = "hero:" + hid
		var old_speed: int = _actor_speed(aid)
		if not _hero_status.has(hid):
			_hero_status[hid] = {}
		if typeof(_hero_status[hid].get("speed_bonus")) != TYPE_ARRAY:
			_hero_status[hid]["speed_bonus"] = []
		# 전투 지속(dur 999) 항목 하나에 누적 — 툴팁 1줄 유지
		var perm = null
		for entry in _hero_status[hid]["speed_bonus"]:
			if typeof(entry) == TYPE_DICTIONARY and int(entry.get("dur", 0)) >= 999:
				perm = entry
				break
		if perm != null:
			perm["value"] = int(perm.get("value", 0)) + 1
		else:
			_hero_status[hid]["speed_bonus"].append({"value": 1, "dur": 999})
		_adjust_turn_queue_for_speed_change(aid, old_speed)
		status_applied.emit(hid, "speed_bonus", 1)
	synergy_triggered.emit("synergy.musashi_yi.name", "musashi")

func _add_first_hit_bonus(hero_id: String, amount: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	_hero_status[hero_id]["next_attack_first_hit_bonus"] = _hero_status[hero_id].get("next_attack_first_hit_bonus", 0) + amount

func _grant_morale(hero_id: String, amount: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	var new_morale: int = _hero_status[hero_id].get("morale", 0) + amount
	_hero_status[hero_id]["morale"] = new_morale
	status_applied.emit(hero_id, "morale", amount)
	morale_changed.emit(hero_id, new_morale)

func setup_battle(enemies: Array, is_tutorial: bool = false) -> void:
	tutorial_active = is_tutorial
	tutorial_force_crit = false
	tutorial_allowed_cards = []
	tutorial_allow_end_turn = false
	tutorial_effect_pending = false
	if deck_mgr != null:
		deck_mgr.consolidate_for_battle()
		# 영웅별 덱 분배 — owner_id 기준
		if team_mgr != null:
			var hero_ids: Array = []
			for hero in team_mgr.heroes:
				hero_ids.append(hero.hero_id)
			deck_mgr.setup_for_battle(hero_ids)
	turn_count = 0
	_enemy_strength_remainders.clear()
	_team_healed_turn = 0
	_vulnerable_guard_hits = 0
	_team_healed_battle = 0
	damage_taken_this_battle = 0
	_enemies = enemies.duplicate()
	if combat_unit_divisor > 1 and preload("res://resources/balance/combat_scale.gd").enabled():
		for i in range(_enemies.size()):
			_enemies[i] = preload("res://resources/balance/enemy_small_numbers.gd").convert(_enemies[i])
	_enemy_hp.clear()
	_enemy_alive.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_intent_index.clear()
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	_active_powers.clear()
	_turn_effect_uses.clear()
	_pending_discard_pick.clear()
	_enemy_card_counters.clear()
	# 부활 시그널 연결 (중복 방지)
	if team_mgr != null:
		if not team_mgr.hero_revived.is_connected(_on_hero_revived_clear_state):
			team_mgr.hero_revived.connect(_on_hero_revived_clear_state)
		if not team_mgr.hero_died.is_connected(_on_hero_died_queue):
			team_mgr.hero_died.connect(_on_hero_died_queue)
	for ei in range(_enemies.size()):
		var trig = _enemies[ei].get("card_count_trigger")
		if trig != null and trig is Dictionary and trig.size() > 0:
			_enemy_card_counters[ei] = {"count": 0, "fired_count": 0}
	for enemy in _enemies:
		_enemy_hp.append(enemy.max_hp)
		_enemy_alive.append(true)
		_enemy_block.append(0)
		var initial_status: Dictionary = {}
		if enemy.charm_resistance > 0:
			initial_status["charm_resistance"] = enemy.charm_resistance
		_enemy_status.append(initial_status)
		_enemy_intent_index.append(0)
	_enemy_phase.clear()
	for _e in _enemies:
		_enemy_phase.append(0)
	is_battle_active = true
	_hourglass_counter = 0
	_initialize_turn_counters()
	battle_started.emit()
	var _gm_bs = _get_gm()
	if _gm_bs and _gm_bs.is_inside_tree():
		_gm_bs.trigger_relics(RelicRes.TriggerType.BATTLE_START)

# autoload GameManager 참조 — Engine.get_singleton()은 autoload를 못 찾으므로
# (autoload는 /root 아래 노드일 뿐 엔진 싱글톤이 아님) SceneTree root에서 직접 가져온다.
func _get_gm() -> Object:
	var ml := Engine.get_main_loop()
	if ml and ml.root:
		return ml.root.get_node_or_null("GameManager")
	return null

# ── 개체별 턴 큐 (ATB) 헬퍼 ──
# actor_id 포맷: "hero:<hero_id>" / "enemy:<index>"
func _actor_id_for_hero(hid: String) -> String:
	return "hero:" + hid

func _actor_id_for_enemy(idx: int) -> String:
	return "enemy:" + str(idx)

func _parse_actor_id(actor_id: String) -> Dictionary:
	var parts := actor_id.split(":", false, 1)
	if parts.size() < 2:
		return {}
	return {"kind": parts[0], "key": parts[1]}

# 적 유효 speed — EnemyResource.speed (없으면 grade 기반 기본값) + status/power 동적
func _enemy_effective_speed(enemy_index: int) -> int:
	if enemy_index < 0 or enemy_index >= _enemies.size():
		return 40
	var enemy = _enemies[enemy_index]
	var base: int = int(enemy.get("speed"))
	if base <= 0:
		# grade 기본값 — NORMAL 45 / ELITE 53 / BOSS 65
		var grade: int = int(enemy.get("grade"))
		match grade:
			1: base = 53  # ELITE
			2: base = 65  # BOSS
			_: base = 45  # NORMAL
	var st: Dictionary = _enemy_status[enemy_index] if enemy_index < _enemy_status.size() else {}
	var bonus: int = _sum_speed_instances(st.get("speed_bonus", [])) - _sum_speed_instances(st.get("speed_penalty", []))
	var power_buff: int = _active_powers.get("power.speed_buff:enemy_%d" % enemy_index, {}).get("value", 0)
	return max(1, base + bonus + power_buff)

func _hero_effective_speed(hid: String) -> int:
	if team_mgr == null:
		return 50
	for hero in team_mgr.heroes:
		if hero.hero_id == hid:
			# base + Σ(status.speed_bonus instances) - Σ(status.speed_penalty instances) + power.speed_buff
			# speed_bonus / speed_penalty = Array of {value: int, dur: int} — 여러 buff/debuff 합산
			var st: Dictionary = _hero_status.get(hid, {})
			var bonus: int = _sum_speed_instances(st.get("speed_bonus", [])) - _sum_speed_instances(st.get("speed_penalty", []))
			var power_buff: int = _active_powers.get("power.speed_buff:" + hid, {}).get("value", 0)
			return max(1, int(hero.speed) + bonus + power_buff)
	return 50

# speed_bonus / speed_penalty 인스턴스 배열의 value 합산
func _sum_speed_instances(arr: Array) -> int:
	var total: int = 0
	for ins in arr:
		total += int(ins.get("value", 0))
	return total

func _actor_speed(actor_id: String) -> int:
	var p := _parse_actor_id(actor_id)
	if p.is_empty():
		return 50
	if p["kind"] == "hero":
		return _hero_effective_speed(p["key"])
	elif p["kind"] == "enemy":
		return _enemy_effective_speed(int(p["key"]))
	return 50

# speed 변경 즉시 _turn_queue_at 비율 보정 + UI 갱신 신호.
# 호출 측: speed_bonus/speed_penalty/power.speed_buff 적용 직후, old_speed 인자로 변경 전 값 전달.
func _adjust_turn_queue_for_speed_change(actor_id: String, old_speed: int) -> void:
	var new_speed: int = _actor_speed(actor_id)
	if old_speed == new_speed or old_speed <= 0 or new_speed <= 0:
		return
	if _turn_queue_at.has(actor_id):
		_turn_queue_at[actor_id] = _turn_queue_at[actor_id] * float(old_speed) / float(new_speed)
	turn_queue_changed.emit(get_turn_queue_preview())

# 초기 큐 — 모든 생존 액터의 next_at = 1000 / speed
func _initialize_turn_counters() -> void:
	_turn_queue_at.clear()
	_current_actor_id = ""
	if team_mgr != null:
		for hero in team_mgr.heroes:
			if team_mgr.is_alive(hero.hero_id):
				var aid := _actor_id_for_hero(hero.hero_id)
				_turn_queue_at[aid] = 1000.0 / max(1, int(hero.speed))
	for i in range(_enemies.size()):
		if _enemy_alive[i]:
			var aid := _actor_id_for_enemy(i)
			_turn_queue_at[aid] = 1000.0 / max(1, _enemy_effective_speed(i))

func get_current_actor_id() -> String:
	return _current_actor_id

func get_current_hero_id() -> String:
	if _current_actor_id.begins_with("hero:"):
		return _current_actor_id.substr(5)
	return ""

# 다음 차례 액터 (가장 작은 _next_turn_at). 동률은 영웅 우선.
func _peek_next_actor() -> String:
	if _turn_queue_at.is_empty():
		return ""
	var best_aid: String = ""
	var best_val: float = INF
	for aid in _turn_queue_at:
		var v: float = _turn_queue_at[aid]
		if v < best_val:
			best_val = v
			best_aid = aid
		elif v == best_val and best_aid != "" and aid.begins_with("hero:") and not best_aid.begins_with("hero:"):
			best_aid = aid
	return best_aid

# 차례 종료 후 카운터 진행 — 모든 액터에서 best_val 만큼 빼고 본인은 +cost 추가
func _advance_turn_counter(actor_id: String) -> void:
	if not _turn_queue_at.has(actor_id):
		return
	var base: float = _turn_queue_at[actor_id]
	for aid in _turn_queue_at.keys():
		_turn_queue_at[aid] = _turn_queue_at[aid] - base
	_turn_queue_at[actor_id] = 1000.0 / max(1, _actor_speed(actor_id))

func _remove_from_queue(actor_id: String) -> void:
	if _turn_queue_at.has(actor_id):
		_turn_queue_at.erase(actor_id)

# UI 미리보기 — 다음 count 차례 시뮬레이션 (실제 큐는 건드리지 않음)
func get_turn_queue_preview(count: int = 5) -> Array:
	var sim: Dictionary = _turn_queue_at.duplicate()
	var result: Array = []
	for _i in range(count):
		if sim.is_empty():
			break
		var best_aid: String = ""
		var best_val: float = INF
		for aid in sim:
			var v: float = sim[aid]
			if v < best_val:
				best_val = v
				best_aid = aid
			elif v == best_val and best_aid != "" and aid.begins_with("hero:") and not best_aid.begins_with("hero:"):
				best_aid = aid
		if best_aid == "":
			break
		result.append(best_aid)
		var cost: float = 1000.0 / max(1, _actor_speed(best_aid))
		var base: float = sim[best_aid]
		for aid in sim.keys():
			sim[aid] = sim[aid] - base
		sim[best_aid] = cost
	return result

## ───────────────────────────────────────────────
## 영구 큐 (ATB) — 개체별 차례 시스템
## ───────────────────────────────────────────────

# 외부 호출 진입점 (battle_scene). 큐를 보고 다음 actor 차례 시작.
# 이름은 호환성 — 실제 동작은 "다음 영웅/적 actor 차례 시작".
func start_player_turn() -> void:
	if not is_battle_active:
		return
	# 큐가 비어있으면 초기화 (호환 — setup_battle 후 첫 호출)
	if _turn_queue_at.is_empty():
		_initialize_turn_counters()
	await _run_next_actor_turn()

# 큐 다음 actor 시작. hero → 사용자 입력 대기. enemy → 자동 진행 후 chain.
func _run_next_actor_turn() -> void:
	if not is_battle_active:
		return
	var next_id: String = _peek_next_actor()
	if next_id == "":
		return
	turn_queue_changed.emit(get_turn_queue_preview())
	if next_id.begins_with("hero:"):
		var hid: String = next_id.substr(5)
		await _start_hero_turn(hid)
	elif next_id.begins_with("enemy:"):
		var idx: int = int(next_id.substr(6))
		await _run_one_enemy_turn(idx)
		# 적 차례 후 다음 actor 자동 진행 — 1x (적→적 너무 느림 방지)
		if is_battle_active:
			if turn_interval > 0.0:
				await get_tree().create_timer(turn_interval * _turn_interval_mul()).timeout
			if is_battle_active:
				await _run_next_actor_turn()

# 단일 영웅 차례 시작 — 본인 영웅만 phase 처리, 입력 대기
func _start_hero_turn(hid: String) -> void:
	_current_actor_id = _actor_id_for_hero(hid)
	turn_count += 1
	_player_damage_this_turn = 0  # T3-MIMIC 트래커 리셋
	_in_player_turn = true
	# 영웅 차례 시작 인터벌 — 1x (적→영웅 너무 빠름 방지, 카메라 줌인과 동시 진행)
	if turn_interval > 0.0:
		await get_tree().create_timer(turn_interval * _turn_interval_mul()).timeout
	if not is_battle_active:
		return
	var pre_did: bool = await _phase_hero_pre(hid)
	if pre_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	# A poison tick may have killed this actor during the pre-turn animation.
	# Never reopen input for a dead hero; advance the surviving queue instead.
	if team_mgr == null or not team_mgr.is_alive(hid):
		is_player_turn = false
		_in_player_turn = false
		_current_actor_id = ""
		await _run_next_actor_turn()
		return
	_phase_hero_main(hid)
	turn_started.emit(_current_actor_id)
	# 스턴 체크 — 카드 뽑기·power trigger 까지는 정상이지만 본인 행동은 막고 자동 종료.
	# 잔여 stun -1 후 hero_turn_skipped 시그널 → battle_scene 토스트/VFX, 잠깐 대기 후 end_player_turn.
	if _hero_status.get(hid, {}).get("stun", 0) > 0:
		_hero_status[hid]["stun"] = max(0, _hero_status[hid]["stun"] - 1)
		hero_turn_skipped.emit(hid)
		if is_inside_tree() and turn_interval > 0.0:
			await get_tree().create_timer(1.0 * _turn_interval_mul()).timeout
		if is_player_turn and is_battle_active:
			await end_player_turn()

# 영웅별 병사 토큰 공격 종류 — 이순신: 함포 폭발 / 칭기즈칸: 화살 / 그 외: 총탄
@warning_ignore("shadowed_variable_base_class")
func _token_dtype_for(owner: String) -> String:
	match owner:
		"yi_sun_sin": return "explosive"
		"genghis_khan": return "projectile"
		_: return "bullet"

# 한 영웅의 병사 토큰 일괄 공격 — owner 기준 VFX·dtype·시너지 후처리
@warning_ignore("shadowed_variable_base_class")
func _run_token_attacks(owner: String, count: int) -> bool:
	var did: bool = false
	for _ti in range(count):
		if not _fire_token(owner, _ti):
			break
		did = true
		# 토큰 사이 짧은 랜덤 지연 — SFX 겹침 방지 (0.08~0.18s)
		if count > 1 and is_inside_tree():
			await get_tree().create_timer(0.08 + randf() * 0.10).timeout
			if not is_battle_active:
				return did
	return did

# 병사 1명의 공격 1회 — 랜덤 생존 적에게 병사 피해(+칸의 깃발 보너스)와 조합 시너지. 생존 적이 없으면 false.
@warning_ignore("shadowed_variable_base_class")
func _fire_token(owner: String, token_index: int) -> bool:
	var alive_indices: Array = []
	for ei in range(_enemies.size()):
		if _enemy_alive[ei]:
			alive_indices.append(ei)
	if alive_indices.is_empty():
		return false
	var pick: int = alive_indices[randi() % alive_indices.size()]
	_last_attacker[pick] = owner
	# 토큰 인덱스 + 타겟 적 전달 — battle_scene 이 병사 타일 위치에서 VFX 발사
	token_attack_fired.emit(owner, token_index, pick)
	var bonus: int = _active_powers.get("power.token_bonus_dmg:" + owner, {}).get("value", 0)
	_deal_damage_to_enemy(pick, _combat_literal(TOKEN_DMG_PER_STACK) + bonus, _token_dtype_for(owner))
	# 혼란의 돌격 (황제×파라오): 나폴레옹 병사 공격 1회당 매혹 +3
	if owner == "napoleon" and team_mgr.is_alive("cleopatra") and _enemy_alive[pick]:
		_apply_status_to_enemy(pick, "charm", _combat_literal(3))
		synergy_triggered.emit("synergy.napoleon_cleopatra.name", owner)
	# 약탈과 독 (정복자×파라오): 칭기즈칸 병사 공격 1회당 독 +5
	if owner == "genghis_khan" and team_mgr.is_alive("cleopatra") and _enemy_alive[pick]:
		_apply_status_to_enemy(pick, "poison", _combat_literal(5))
		synergy_triggered.emit("synergy.genghis_cleopatra.name", owner)
	return true

# 람세스의 방패: 아군 영웅(차례 중인 영웅 포함)이 취약한 적을 칠 때마다 클레오파트라 방어 (차례당 3회).
func _vulnerable_guard(source_owner: String) -> void:
	var hitter: String = source_owner
	if hitter == "" and _current_actor_id.begins_with("hero:"):
		hitter = _current_actor_id.substr(5)
	if hitter == "" or team_mgr == null or not team_mgr.is_alive("cleopatra"):
		return
	var power: Dictionary = _active_powers.get("power.vulnerable_hit_block:cleopatra", {})
	if power.is_empty() or _vulnerable_guard_hits >= VULNERABLE_GUARD_LIMIT:
		return
	_vulnerable_guard_hits += 1
	_gain_block("cleopatra", int(power.get("value", 0)))

# 매혹 저항을 반영한 반함 임계치 (모든 영웅의 power.charm_threshold_minus 합산 차감).
func charm_threshold_for_resistance(resistance: int) -> int:
	var reduce: int = 0
	for key in _active_powers:
		if key.begins_with("power.charm_threshold_minus:"):
			reduce += int(_active_powers[key].get("value", 0))
	return maxi(1, _combat_literal(CHARM_THRESHOLD_BASE) + resistance - reduce)

# 성전 회복량 피해 — 기본 피해 + 회복량의 percent% (cap 이 있으면 보너스 상한).
func _heal_cash_damage(effect: Resource) -> int:
	var p: Dictionary = effect.rule_params
	var healed: int = _team_healed_turn if effect.rule_id == "heal_turn_damage" else _team_healed_battle
	var bonus: int = int(healed * int(p.get("percent", 0)) / 100)
	if p.has("cap"):
		bonus = mini(bonus, int(p.cap))
	return effect.value + bonus

# 본인이 모든 생존 적보다 빠른가 — 질주 보상 조건.
func _owner_outpaces_enemies(hid: String) -> bool:
	var speed: int = _hero_effective_speed(hid)
	for ei in range(_enemies.size()):
		if _enemy_alive[ei] and _enemy_effective_speed(ei) >= speed:
			return false
	return true

# 본인 영웅 차례 시작 사전 처리 — 본인 토큰 공격 + 본인 poison tick
func _phase_hero_pre(hid: String) -> bool:
	if team_mgr == null or not team_mgr.is_alive(hid):
		return false
	_team_healed_turn = 0
	_vulnerable_guard_hits = 0
	var did_work: bool = false
	var token_count: int = _hero_status.get(hid, {}).get("tokens", 0)
	# 본인 병사가 있을 때만 토큰 공격 — 본인 병사가 없으면 파트너 병사도 합류하지 않음
	if token_count > 0:
		# 본인 병사 먼저 공격 (출현 → 공격 → 복귀)
		if await _run_token_attacks(hid, token_count):
			did_work = true
		if not is_battle_active:
			return did_work
		# 수륙 협공 (이순신×칭기즈칸): 본인 병사 복귀 후 파트너 병사가 이어서 합동 공격
		if (hid == "yi_sun_sin" or hid == "genghis_khan") and team_mgr.is_alive("yi_sun_sin") and team_mgr.is_alive("genghis_khan"):
			var _jt_partner: String = "genghis_khan" if hid == "yi_sun_sin" else "yi_sun_sin"
			var _jt_extra: int = _hero_status.get(_jt_partner, {}).get("tokens", 0)
			if _jt_extra > 0:
				synergy_triggered.emit("synergy.yi_genghis.name", hid)
				# 본인 병사가 모두 복귀할 때까지 대기 후 파트너 병사 출현
				if is_inside_tree():
					await get_tree().create_timer(0.6).timeout
				if not is_battle_active:
					return did_work
				if await _run_token_attacks(_jt_partner, _jt_extra):
					did_work = true
	# 본인 poison tick (영웅이 받은 독)
	var dmg: int = _hero_status.get(hid, {}).get("poison_dmg", 0)
	var dur: int = _hero_status.get(hid, {}).get("poison_dur", 0)
	if dmg > 0 and dur > 0:
		_tick_hero_poison(hid)
		did_work = true
	return did_work

# 본인 영웅 차례 메인 — power trigger·덱 시작. 방어구는 턴 넘어 유지(리셋 안 함)
func _phase_hero_main(hid: String) -> void:
	is_player_turn = true
	_cards_played_this_turn = 0
	_cards_drawn_this_turn = 0
	_turn_effect_uses[hid] = {}
	if deck_mgr:
		deck_mgr.start_hero_turn(hid)
	_trigger_active_powers("player_turn_start", {"hero_id": hid})
	var _gm_pts = _get_gm()
	if _gm_pts and _gm_pts.is_inside_tree():
		_gm_pts.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_START, {"turn": turn_count, "hero_id": hid})
	player_turn_started.emit()

# 본인 영웅 차례 종료 — 본인 status -1
func _phase_hero_post(hid: String) -> bool:
	var did_work: bool = false
	var old_speed: int = _hero_effective_speed(hid)
	if _hero_status.has(hid):
		_hero_status[hid].erase("next_attack_first_hit_bonus")
	# 검사의 약속 (이순신×무사시): 이순신 차례가 끝날 때 남은 방어의 절반(최대 6)을 무사시 다음 공격 첫 타에 더한다.
	if hid == "yi_sun_sin" and team_mgr.is_alive("musashi"):
		var banked: int = mini(_hero_block.get(hid, 0) / 2, _combat_literal(SWORDSMAN_VOW_BANK_CAP))
		if banked > 0:
			_add_first_hit_bonus("musashi", banked)
			synergy_triggered.emit("synergy.musashi_yi.name", hid)
	for stype: String in ["weak", "vulnerable", "taunt", "silence"]:
		var cur: int = _hero_status.get(hid, {}).get(stype, 0)
		if cur > 0:
			if not _hero_status.has(hid):
				_hero_status[hid] = {}
			_hero_status[hid][stype] = cur - 1
			# 도발 0 도달 시 taunt_source 도 정리 (적 부여 도발의 lock 해제)
			if stype == "taunt" and _hero_status[hid][stype] == 0 and _hero_status[hid].has("taunt_source"):
				_hero_status[hid].erase("taunt_source")
			did_work = true
	# speed_bonus / speed_penalty — Array of {value, dur}. 각 instance dur -1, dur<=0 인 인스턴스 제거
	for key in ["speed_bonus", "speed_penalty"]:
		var arr: Array = _hero_status.get(hid, {}).get(key, [])
		if arr.is_empty():
			continue
		var kept: Array = []
		for ins in arr:
			if ins.get("dur", 0) == -1:
				kept.append(ins)
				continue
			if ins.get("skip_current_end", false):
				ins.erase("skip_current_end")
				kept.append(ins)
				continue
			var new_dur: int = int(ins.get("dur", 0)) - 1
			if new_dur > 0:
				kept.append({"value": int(ins.get("value", 0)), "dur": new_dur})
		if not _hero_status.has(hid):
			_hero_status[hid] = {}
		_hero_status[hid][key] = kept
		did_work = true
	_adjust_turn_queue_for_speed_change(_actor_id_for_hero(hid), old_speed)
	_check_win_condition()
	return did_work

func play_card(card: Resource, target_enemy_index: int, target_hero_id: String = "") -> bool:
	if not is_player_turn or not is_battle_active:
		return false
	if not _pending_discard_pick.is_empty():
		return false
	if tutorial_active and (tutorial_effect_pending or card.card_name not in tutorial_allowed_cards):
		return false
	# silence — 시전 영웅이 silence 상태면 카드 사용 불가 (Ameno-sagiri Foolish Whisper 영감).
	if _hero_status.get(card.owner_id, {}).get("silence", 0) > 0:
		return false
	# 적 부여 도발 lock — 시전 영웅이 적이 부여한 taunt 상태면 SINGLE 효과 타겟을 그 적으로 강제.
	# ALL 타겟 카드는 영향 X (자연스럽게 모든 적 포함). 도발 적이 이미 사망했으면 lock 해제 (cleanup 이 처리).
	var lock_idx: int = _get_taunt_lock_target(card.owner_id)
	if lock_idx >= 0 and _card_has_single_target(card):
		target_enemy_index = lock_idx
	# ATTACK 카드 단일 타겟 — 사망 예정(앞 카드 누적으로 effective_hp 0) 적 거부
	if target_enemy_index >= 0 and is_enemy_doomed(target_enemy_index) and _card_has_damage(card):
		return false
	# DeckManager emits hand/energy changes synchronously; lock the tutorial before those UI updates.
	tutorial_effect_pending = tutorial_active
	if deck_mgr == null or not deck_mgr.play_card(card):
		tutorial_effect_pending = false
		return false
	_cards_played_this_turn += 1
	_track_card_type_counters(card)
	_start_card_effects(card, target_enemy_index, target_hero_id)  # fire-and-forget
	return true

# 시전 영웅이 적 부여 도발 상태면 lock 대상 적 index 반환. 아니면 -1.
# 도발 적이 이미 사망했으면 cleanup 이 source 를 지운 상태이므로 -1.
func _get_taunt_lock_target(owner_id: String) -> int:
	var status: Dictionary = _hero_status.get(owner_id, {})
	if status.get("taunt", 0) <= 0:
		return -1
	var src: int = status.get("taunt_source", -1)
	if src < 0 or src >= _enemy_status.size():
		return -1
	# 적이 살아있나? 죽었으면 cleanup hook 이 곧 정리하지만 그 전에 사용 시 안전.
	if team_mgr == null or _is_enemy_dead(src):
		return -1
	return src

# 카드의 효과 중 SINGLE 타겟이 하나라도 있으면 true. 모두 SELF/ALL/SELF면 false.
func _card_has_single_target(card: Resource) -> bool:
	for eff in card.effects:
		if eff.target == "SINGLE":
			return true
	return false

# 적 사망 여부 (battle_manager 가 자체 추적). _enemy_hp_remaining 또는 _enemy_block 등 활용 어렵다면
# team_mgr 의 적 시스템 통해 확인. 가장 안전: _enemy_max_hp 와 누적 데미지 비교 대신,
# 이미 battle_scene 이 enemy_died 시 panel.queue_free 하므로 _enemy_status 가 비어있으면 죽음.
func _is_enemy_dead(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return true
	# _enemy_status 는 사망 시 클리어되지 않음 — 별도 alive 마커 필요. 안전한 폴백: hp 0 여부.
	if _enemy_hp.size() > enemy_index and _enemy_hp[enemy_index] <= 0:
		return true
	return false

# play_card 를 동기로 유지하면서 _apply_card_effects 의 await 패턴을 흡수.
func _start_card_effects(card: Resource, target_enemy_index: int, target_hero_id: String) -> void:
	await _apply_card_effects(card, target_enemy_index, target_hero_id)
	tutorial_effect_pending = false
	card_effects_resolved.emit(card)

func end_player_turn() -> void:
	if not is_player_turn or not is_battle_active:
		return
	if not _pending_discard_pick.is_empty():
		return
	if tutorial_active and (tutorial_effect_pending or not tutorial_allow_end_turn):
		return
	is_player_turn = false
	_in_player_turn = false
	# 현재 hero actor id 추출 (없으면 fallback — 첫 hero)
	var hid: String = ""
	if _current_actor_id.begins_with("hero:"):
		hid = _current_actor_id.substr(5)
	elif team_mgr != null and team_mgr.heroes.size() > 0:
		hid = team_mgr.heroes[0].hero_id
	var _gm_pte = _get_gm()
	if _gm_pte and _gm_pte.is_inside_tree():
		_gm_pte.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_END, {"hero_id": hid})
	if deck_mgr and hid != "":
		deck_mgr.end_hero_turn(hid)
	var post_did: bool = _phase_hero_post(hid)
	if post_did and turn_interval > 0.0:
		await get_tree().create_timer(turn_interval).timeout
	if not is_battle_active:
		return
	# 큐 진행 — 현재 영웅 차례 비용 +1000/speed
	_advance_turn_counter(_current_actor_id)
	turn_ended.emit(_current_actor_id)
	_current_actor_id = ""
	# 영웅 종료 후 인터벌 제거 — 다음 actor 의 시작 인터벌 (영웅/적 각각) 으로 통합
	if is_battle_active:
		await _run_next_actor_turn()

const DND_KEY := "power.double_next_damage:__global__"

func _hero_strength(owner_id: String) -> int:
	return int(_hero_status.get(owner_id, {}).get("strength", 0)) + int(_active_powers.get("power.strength_player:" + owner_id, {}).get("value", 0))

func _gain_block(hero_id: String, amount: int) -> void:
	if amount <= 0 or (team_mgr != null and not team_mgr.is_alive(hero_id)):
		return
	_hero_block[hero_id] = _hero_block.get(hero_id, 0) + amount
	hero_block_gained.emit(hero_id, amount)

func _use_turn_effect(owner_id: String, key: String) -> bool:
	if not _turn_effect_uses.has(owner_id):
		_turn_effect_uses[owner_id] = {}
	if _turn_effect_uses[owner_id].get(key, false):
		return false
	_turn_effect_uses[owner_id][key] = true
	return true

func _spend_hero_resource(owner_id: String, key: String, cap: int) -> int:
	if not _hero_status.has(owner_id):
		_hero_status[owner_id] = {}
	var spent: int = mini(_hero_status[owner_id].get(key, 0), cap)
	_hero_status[owner_id][key] = _hero_status[owner_id].get(key, 0) - spent
	status_applied.emit(owner_id, key, _hero_status[owner_id][key])
	if key == "morale":
		morale_changed.emit(owner_id, _hero_status[owner_id][key])
	return spent

func _revision_damage(card: Resource, effect: Resource, target: int, amount: int, all: bool = false, first_bonus: int = 0) -> void:
	var ctx := DamageContext.new()
	ctx.base = amount
	ctx.flat = _hero_strength(card.owner_id) + first_bonus
	var base_out_pct := 0.0
	if _hero_status.get(card.owner_id, {}).get("weak", 0) > 0:
		base_out_pct -= 0.25
	var targets: Array = range(_enemies.size()) if all else [target]
	for idx in targets:
		if idx < 0 or idx >= _enemies.size() or not _enemy_alive[idx]:
			continue
		var crit := _roll_crit(idx, not _enemy_status[idx].get("marked_by", []).is_empty(), card.owner_id)
		ctx.out_pct = base_out_pct
		ctx.crit_mult = crit.crit_mult
		_last_attacker[idx] = card.owner_id
		_deal_damage_to_enemy(idx, _outgoing_damage(ctx), effect.damage_type, crit.is_crit, card.owner_id)

func _apply_revision_effect(card: Resource, effect: Resource, target: int, ally: String, first_bonus: int = 0) -> void:
	var p: Dictionary = effect.rule_params
	var hid: String = card.owner_id
	var ally_id: String = ally if ally != "" else hid
	var target_alive: bool = target >= 0 and target < _enemies.size() and _enemy_alive[target]
	match effect.rule_id:
		"morale_if_survives":
			if target_alive:
				_apply_status_to_hero(hid, "morale", p.amount)
				morale_changed.emit(hid, _hero_status[hid].morale)
		"resource_to_block":
			var spent := _spend_hero_resource(hid, p.resource, p.consume_cap)
			var amount: int = int(p.get("base", 0)) + spent * int(p.per_resource)
			if effect.target == "ALL":
				for hero in team_mgr.get_living_heroes():
					_gain_block(hero.hero_id, amount)
			else:
				_gain_block(hid, amount)
		"recruit_or_draw":
			var tokens: int = _hero_status.get(hid, {}).get("tokens", 0)
			if tokens >= TOKEN_MAX_STACK:
				deck_mgr.draw_cards_h(hid, p.draw)
			else:
				_apply_status_to_hero(hid, "tokens", mini(int(p.tokens), TOKEN_MAX_STACK - tokens))
		"discard_for_draw":
			_trigger_discard_pick(p.draw, 0, hid, true, true)
		"morale_attack_discount":
			if _hero_status.get(hid, {}).get("morale", 0) >= int(p.consume):
				_spend_hero_resource(hid, "morale", p.consume)
				deck_mgr.reserve_cost_reduction(hid, p.amount, 1, true)
		"poison_seed_spread":
			if target_alive:
				var poisoned: bool = _enemy_status[target].get("poison_dmg", 0) > 0 and _enemy_status[target].get("poison_dur", 0) > 0
				if poisoned:
					for i in range(_enemies.size()):
						if i != target and _enemy_alive[i]:
							_apply_status_to_enemy(i, "poison", p.spread)
				else:
					_apply_status_to_enemy(target, "poison", p.seed)
		"poison_tick_now":
			var targets: Array = range(_enemies.size()) if effect.target == "ALL" else [target]
			for i in targets:
				if is_enemy_alive(i) and _enemy_status[i].get("poison_dur", 0) > 0 and _enemy_status[i].get("poison_dmg", 0) > 0:
					_tick_enemy_poison(i)
		"curse_weave":
			if target_alive:
				var had_weak: bool = _enemy_status[target].get("weak", 0) > 0
				var had_vulnerable: bool = _enemy_status[target].get("vulnerable", 0) > 0
				_apply_status_to_enemy(target, "weak" if had_vulnerable else "vulnerable", p.weak if had_vulnerable else p.vulnerable)
				if had_weak and had_vulnerable:
					deck_mgr.draw_cards_h(hid, p.draw)
		"debuff_cash_damage":
			var targets: Array = range(_enemies.size()) if effect.target == "ALL" else [target]
			for i in targets:
				if not is_enemy_alive(i):
					continue
				var spent := 0
				for key in p.statuses:
					spent += _spend_enemy_status(i, key, p.consume_cap)
				_revision_damage(card, effect, i, effect.value + spent * effect.bonus_value, false, first_bonus)
		"charm_to_block":
			var gained := 0
			for i in range(_enemies.size()):
				if not _enemy_alive[i] or gained >= int(p.block_cap):
					continue
				var remaining_charm := ceili(float(int(p.block_cap) - gained) / int(p.block_per_charm))
				var spent := _spend_enemy_status(i, "charm", mini(int(p.consume_cap), remaining_charm))
				gained += mini(int(p.block_cap) - gained, spent * int(p.block_per_charm))
			_gain_block(hid, gained)
		"guard_attack_discount":
			if _hero_block.get(hid, 0) >= int(p.threshold):
				deck_mgr.reserve_cost_reduction(hid, p.amount, 1, true)
		"block_transfer":
			if team_mgr.is_alive(ally_id):
				var moved := _spend_block(hid, p.consume_cap) if ally_id != hid else 0
				_gain_block(ally_id, int(p.base) + moved)
				# 검사의 약속 (이순신×무사시): 이순신이 옮긴 방어만큼 무사시의 다음 공격 첫 타 피해 +
				if hid == "yi_sun_sin" and moved > 0 and team_mgr.is_alive("musashi"):
					_add_first_hit_bonus("musashi", moved)
					synergy_triggered.emit("synergy.musashi_yi.name", hid)
		"formation_drill":
			for hero in team_mgr.get_living_heroes():
				if _hero_block.get(hero.hero_id, 0) <= 0:
					_gain_block(hero.hero_id, p.block)
				else:
					_apply_status_to_hero(hero.hero_id, "morale", 1)
					morale_changed.emit(hero.hero_id, _hero_status[hero.hero_id].morale)
		"heal_if_enemy_debuff":
			if target_alive and _enemy_status[target].get(p.status, 0) > 0:
				_heal_hero_safe(hid, p.amount)
		"overflow_heal":
			if team_mgr.is_alive(ally_id):
				var before: int = team_mgr.get_current_hp(ally_id)
				var amount: int = p.heal
				if _heal_hero_safe(ally_id, amount):
					var restored: int = team_mgr.get_current_hp(ally_id) - before
					_gain_block(ally_id, mini(p.block_cap, maxi(0, amount - restored)))
		"block_to_heal":
			if team_mgr.is_alive(ally_id):
				var spent := _spend_block(ally_id, p.consume_cap)
				if spent > 0:
					_heal_hero_safe(ally_id, spent)
				deck_mgr.draw_cards_h(hid, p.draw)
		"bank_draw":
			var spent := _spend_hero_resource(hid, "sacrifice_bank", p.consume_cap)
			deck_mgr.draw_cards_h(hid, int(p.draw) + (int(p.bonus_draw) if spent == int(p.consume_cap) else 0))
		"opening_status":
			if target_alive and deck_mgr.get_cards_played_this_turn(hid) == 1:
				_apply_status_to_enemy(target, p.status, p.amount)
		"combo_energy_once":
			if _use_turn_effect(hid, "synergy_combo_energy"):
				var prior: int = maxi(0, deck_mgr.get_cards_played_this_turn(hid) - 1)
				deck_mgr.add_energy_h(hid, p.combo if prior >= int(p.threshold) else p.normal)
		"marked_scout":
			if target_alive:
				var marks: Array = _enemy_status[target].get("marked_by", []).duplicate()
				if hid in marks and _use_turn_effect(hid, "synergy_marked_scout"):
					marks.erase(hid)
					_enemy_status[target]["marked_by"] = marks
					status_applied.emit("enemy_%d" % target, "marked_by", marks.size())
					deck_mgr.draw_cards_h(hid, p.marked_draw)
				else:
					if hid not in marks:
						marks.append(hid)
					_enemy_status[target]["marked_by"] = marks
					status_applied.emit("enemy_%d" % target, "marked_by", marks.size())
					deck_mgr.draw_cards_h(hid, p.draw)
		"marked_cash_all":
			var any_spent := false
			for i in range(_enemies.size()):
				if not _enemy_alive[i]:
					continue
				var marks: Array = _enemy_status[i].get("marked_by", []).duplicate()
				var spent: bool = hid in marks
				if spent:
					marks.erase(hid)
					_enemy_status[i]["marked_by"] = marks
					status_applied.emit("enemy_%d" % i, "marked_by", marks.size())
					any_spent = true
				_revision_damage(card, effect, i, effect.value + (effect.bonus_value if spent else 0), false, first_bonus)
			if any_spent:
				deck_mgr.draw_cards_h(hid, p.draw)
		"block_multi_hit":
			if target_alive:
				var spent := _spend_block(hid, p.consume_cap)
				var per_hit: int = _active_powers.get("power.bonus_per_hit:" + hid, {}).get("value", 0)
				for hit in range(effect.hit_count):
					if team_mgr != null and not team_mgr.is_alive(hid):
						break
					_revision_damage(card, effect, target, effect.value + spent, false, first_bonus if hit == 0 else 0)
					# Preserve the normal multi-hit power's separate bonus hit;
					# it is not multiplied by outgoing weakness or critical chance.
					if per_hit > 0 and is_enemy_alive(target) and team_mgr.is_alive(hid):
						_deal_damage_to_enemy(target, per_hit, effect.damage_type)
				if not _in_echo_replay and team_mgr.is_alive(hid):
					_trigger_damage_rhythm(card, effect, target)
		"duel_preparation":
			var amount: int = p.solo_amount if _get_living_enemy_count() == 1 else p.amount
			if not _hero_status.has(hid):
				_hero_status[hid] = {}
			_hero_status[hid]["next_attack_first_hit_bonus"] = maxi(_hero_status[hid].get("next_attack_first_hit_bonus", 0), amount)
		"duel_status_damage":
			if target_alive:
				var empowered: bool = _get_living_enemy_count() == 1 and _enemy_status[target].get(p.status, 0) >= int(p.consume)
				if empowered:
					_spend_enemy_status(target, p.status, p.consume)
				_revision_damage(card, effect, target, effect.bonus_value if empowered else effect.value, false, first_bonus)
		"empty_reload":
			if deck_mgr.get_hand(hid).is_empty():
				_gain_block(hid, p.block)
				deck_mgr.draw_cards_h(hid, p.draw)
			else:
				deck_mgr.draw_cards_h(hid, p.fallback_draw)
		"paired_draw_damage":
			var damage: int = _paired_draw_damage(hid, p)
			# Preserve legacy PER_DRAW_DMG: no strength, weak or crit additions.
			if target_alive and damage > 0:
				_deal_damage_to_enemy(target, damage)
		"weak_enemy_draw":
			# 저주 보상: 약화된 생존 적 1명당 1장 더 (최대 cap).
			var weakened := 0
			for ei in range(_enemies.size()):
				if _enemy_alive[ei] and _enemy_status[ei].get("weak", 0) > 0:
					weakened += 1
			deck_mgr.draw_cards_h(hid, int(p.draw) + mini(weakened, int(p.cap)))
		"heal_turn_damage", "heal_battle_damage":
			# 성전 보상: 아군이 실제로 회복한 양을 모든 적 피해로 바꾼다.
			_revision_damage(card, effect, target, _heal_cash_damage(effect), true, first_bonus)
		"block_damage_all":
			# 거북선 이정표: 현재 방어만큼 모든 적에게 피해, 방어는 소비하지 않는다.
			_revision_damage(card, effect, target, effect.value + _hero_block.get(hid, 0), true, first_bonus)
		"soldier_volley":
			# 질주 보상: 모든 적 피해 후 병사 전원이 즉시 공격하고, 모든 적보다 빠르면 한 번 더 공격한다.
			_revision_damage(card, effect, target, effect.value, true, first_bonus)
			var volleys: int = 2 if _owner_outpaces_enemies(hid) else 1
			for _v in range(volleys):
				for ti in range(int(_hero_status.get(hid, {}).get("tokens", 0))):
					_fire_token(hid, ti)
		"morale_spend_damage":
			var damage: int = effect.value
			if _hero_status.get(hid, {}).get("morale", 0) >= int(p.consume):
				_spend_hero_resource(hid, "morale", p.consume)
				damage = effect.bonus_value
			_revision_damage(card, effect, target, damage, false, first_bonus)
		"consume_own_block":
			var spent: int = mini(_hero_block.get(hid, 0), p.consume_cap)
			_hero_block[hid] = _hero_block.get(hid, 0) - spent
			hero_block_gained.emit(hid, -spent)
			_revision_damage(card, effect, target, effect.value + int(spent * float(p.multiplier)), false, first_bonus)
		"consume_own_tokens", "consume_own_tokens_all":
			var spent: int = _spend_hero_resource(hid, "tokens", p.get("consume_cap", p.get("consume", 0)))
			_revision_damage(card, effect, target, effect.value + spent * effect.bonus_value, effect.rule_id.ends_with("_all"), first_bonus)
		"team_morale_damage", "team_token_damage":
			var total := 0
			var key := "morale" if effect.rule_id == "team_morale_damage" else "tokens"
			if team_mgr:
				for hero in team_mgr.get_living_heroes():
					total += int(_hero_status.get(hero.hero_id, {}).get(key, 0))
			_revision_damage(card, effect, target, effect.value + mini(total * effect.bonus_value, p.cap), false, first_bonus)
		"damage_per_debuff_type":
			if target_alive:
				var count := 0
				var st: Dictionary = _enemy_status[target]
				for key in ["weak", "vulnerable", "charm"]:
					if st.get(key, 0) > 0:
						count += 1
				if st.get("poison_dmg", 0) > 0 and st.get("poison_dur", 0) > 0:
					count += 1
				_revision_damage(card, effect, target, effect.value + mini(count, p.cap) * effect.bonus_value, false, first_bonus)
		"poison_burst_multiplier":
			if target_alive:
				var poison: int = _enemy_status[target].get("poison_dmg", 0) if _enemy_status[target].get("poison_dur", 0) > 0 else 0
				_enemy_status[target]["poison_dmg"] = 0
				_enemy_status[target]["poison_dur"] = 0
				if poison > 0:
					_deal_damage_to_enemy(target, poison * int(p.multiplier), effect.damage_type, false, hid)
		"consume_charm_damage":
			if target_alive:
				# Base hit resolves first; a killed target cannot pay the follow-up.
				_revision_damage(card, effect, target, effect.value, false, first_bonus)
				if _enemy_alive[target]:
					var spent: int = mini(_enemy_status[target].get("charm", 0), p.consume_cap)
					_enemy_status[target]["charm"] = _enemy_status[target].get("charm", 0) - spent
					status_applied.emit("enemy_%d" % target, "charm", _enemy_status[target]["charm"])
					if spent > 0:
						_deal_damage_to_enemy(target, spent * effect.bonus_value, effect.damage_type, false, hid)
		"poison_existing_all_bonus", "extend_enemy_debuffs":
			for i in range(_enemies.size()):
				if not _enemy_alive[i]:
					continue
				if effect.rule_id == "poison_existing_all_bonus":
					if _enemy_status[i].get("poison_dmg", 0) > 0 and _enemy_status[i].get("poison_dur", 0) > 0:
						_enemy_status[i]["poison_dmg"] += int(p.amount)
						status_applied.emit("enemy_%d" % i, "poison", p.amount)
				else:
					for key in p.statuses:
						if _enemy_status[i].get(key, 0) > 0:
							_enemy_status[i][key] += int(p.turns)
							status_applied.emit("enemy_%d" % i, key, p.turns)
		"formation_block":
			_gain_block(hid, int(p.base) + maxi(0, team_mgr.get_living_heroes().size() - 1) * int(p.per_other_ally))
		"heal_ally_if_owner_hp_below":
			if team_mgr.get_current_hp(hid) * 100 <= team_mgr.get_hero(hid).max_hp * int(p.hp_percent):
				_heal_hero_safe(ally_id, p.amount)
		"team_block_consume_morale":
			var spent := 0
			for hero in team_mgr.get_living_heroes():
				spent += _spend_hero_resource(hero.hero_id, "morale", p.morale_per_hero)
			for hero in team_mgr.get_living_heroes():
				_gain_block(hero.hero_id, int(p.base) + spent * int(p.per_morale))
		"block_ally_if_owner_survives":
			if team_mgr.is_alive(hid):
				_gain_block(ally_id, p.amount)
		"delayed_team_heal":
			_register_power("power.limited_team_heal", hid, p.amount, {"remaining_turns": p.turns})
		"revive_or_heal":
			var dead_id := ""
			for hero in team_mgr.heroes:
				if not team_mgr.is_alive(hero.hero_id):
					dead_id = hero.hero_id
					if dead_id == ally:
						break
			if dead_id != "":
				team_mgr.revive(dead_id, maxi(1, int(team_mgr.get_hero(dead_id).max_hp * float(p.revive_percent) / 100.0)))
			else:
				_heal_hero_safe(ally_id, p.heal)
		"sacrifice_then_power":
			var hp_before: int = team_mgr.get_current_hp(hid)
			team_mgr.take_damage(hid, p.sacrifice)
			if not _hero_status.has(hid):
				_hero_status[hid] = {}
			_hero_status[hid]["sacrifice_bank"] = _hero_status[hid].get("sacrifice_bank", 0) + hp_before - team_mgr.get_current_hp(hid)
			status_applied.emit(hid, "sacrifice_bank", _hero_status[hid]["sacrifice_bank"])
			if team_mgr.is_alive(hid):
				_register_power(p.power, hid, p.amount, {"card_name": card.card_name})
			_check_lose_condition()
		"sacrifice_bank_payoff", "sacrifice_bank_team_block":
			var spent := _spend_hero_resource(hid, "sacrifice_bank", p.consume_cap)
			if effect.rule_id == "sacrifice_bank_payoff":
				_revision_damage(card, effect, target, effect.value + spent, true, first_bonus)
			else:
				for hero in team_mgr.get_living_heroes():
					_gain_block(hero.hero_id, int(p.base) + spent)
		"other_card_this_turn_damage":
			var prior: int = deck_mgr.get_cards_played_this_turn(hid) - 1 if deck_mgr else 0
			_revision_damage(card, effect, target, effect.bonus_value if prior > 0 else effect.value, false, first_bonus)
		"third_card_draw_once":
			if deck_mgr and deck_mgr.get_cards_played_this_turn(hid) >= int(p.threshold) and _use_turn_effect(hid, "third_card_draw"):
				deck_mgr.draw_cards_h(hid, p.draw)
		"block_per_prior_card":
			var prior: int = maxi(0, deck_mgr.get_cards_played_this_turn(hid) - 1) if deck_mgr else 0
			_gain_block(hid, mini(prior * int(p.per_card), p.cap))
		"next_cards_cost_reduction", "next_attack_cost_reduction":
			if deck_mgr:
				deck_mgr.reserve_cost_reduction(hid, p.amount, p.count, effect.rule_id == "next_attack_cost_reduction")
		"next_attack_first_hit_bonus":
			if not _hero_status.has(hid):
				_hero_status[hid] = {}
			_hero_status[hid]["next_attack_first_hit_bonus"] = maxi(_hero_status[hid].get("next_attack_first_hit_bonus", 0), p.amount)
		"discard_up_to_one_for_block":
			_gain_block(hid, p.amount)
			_trigger_discard_pick(0, 0, hid, true)
		"block_if_target_survives":
			if target_alive:
				_gain_block(hid, p.amount)
		"hand_empty_energy_once":
			if deck_mgr and deck_mgr.get_hand(hid).is_empty() and _use_turn_effect(hid, "empty_hand_energy"):
				deck_mgr.add_energy_h(hid, p.amount)
		"cleanse_self_weak_vulnerable_if_hand_empty":
			if deck_mgr and deck_mgr.get_hand(hid).is_empty() and _hero_status.has(hid):
				_hero_status[hid].erase("weak")
				_hero_status[hid].erase("vulnerable")
		"counter_reflect":
			if target < 0:
				for i in range(_enemies.size()):
					if is_counter_window_active(i):
						target = i
						break
			if is_counter_window_active(target):
				_enemy_status[target].erase("charge_remaining")
				_enemy_status[target].erase("_charge_block_advance")
				_enemy_intent_index[target] = 0
				_apply_status_to_enemy(target, "stun", 1)
				counter_triggered.emit(hid, target, true)
			else:
				if not _hero_status.has(hid):
					_hero_status[hid] = {}
				_hero_status[hid]["counter_pending"] = 1
				status_applied.emit(hid, "counter_pending", 1)

func _trigger_damage_rhythm(card: Resource, effect: Resource, target: int) -> void:
	for key in _active_powers.keys():
		if not key.begins_with("power.every_nth_attack_bonus:") or _active_powers[key].get("owner_id", "") != card.owner_id:
			continue
		var power: Dictionary = _active_powers[key]
		var interval: int = int(power.get("params", {}).get("bonus_value", 3))
		if interval <= 0:
			interval = 3
		if not power.has("params"):
			power["params"] = {}
		power.params["count"] = int(power.params.get("count", 0)) + 1
		if int(power.params.count) < interval:
			continue
		power.params["count"] = 0
		var amount: int = power.get("value", 0)
		if amount <= 0:
			continue
		var targets: Array = range(_enemies.size()) if effect.target == "ALL" else [target]
		for i in targets:
			if is_enemy_alive(i):
				_deal_damage_to_enemy(i, amount, effect.damage_type)

func _spend_block(hero_id: String, cap: int) -> int:
	var spent: int = mini(_hero_block.get(hero_id, 0), maxi(0, cap))
	_hero_block[hero_id] = _hero_block.get(hero_id, 0) - spent
	if spent > 0:
		hero_block_gained.emit(hero_id, -spent)
	return spent

func _spend_enemy_status(index: int, key: String, cap: int) -> int:
	var spent: int = mini(int(_enemy_status[index].get(key, 0)), maxi(0, cap))
	_enemy_status[index][key] = int(_enemy_status[index].get(key, 0)) - spent
	if spent > 0:
		status_applied.emit("enemy_%d" % index, key, _enemy_status[index][key])
	return spent

func _dnd_key(hid: String) -> String:
	return "power.double_next_damage:" + hid

func _consume_double_next_damage(amount: int) -> int:
	# 현재 hero actor 의 DND 우선, 없으면 글로벌 키. 한 번 ×2 적용 후 둘 다 erase.
	var consumed: bool = false
	if _current_actor_id.begins_with("hero:"):
		var hid: String = _current_actor_id.substr(5)
		var key: String = _dnd_key(hid)
		if _active_powers.has(key):
			amount *= 2
			_active_powers.erase(key)
			consumed = true
	if _active_powers.has(DND_KEY):
		if not consumed:
			amount *= 2
		_active_powers.erase(DND_KEY)
		consumed = true
	if consumed:
		active_powers_changed.emit()
	return amount

func _apply_discard_pick_reward(draw_count: int, energy_gain: int, owner_id: String = "") -> void:
	if not deck_mgr:
		return
	if owner_id == "":
		owner_id = get_current_hero_id()
	if owner_id == "" and not deck_mgr._heroes.is_empty():
		owner_id = deck_mgr._heroes.keys()[0]
	deck_mgr.draw_cards_h(owner_id, draw_count)
	_cards_drawn_this_turn += draw_count
	if energy_gain > 0:
		deck_mgr.add_energy_h(owner_id, energy_gain)

func _trigger_discard_pick(draw_count: int, energy_gain: int, owner_id: String = "", optional: bool = false, reward_requires_discard: bool = false) -> void:
	if not deck_mgr:
		return
	if owner_id == "":
		owner_id = get_current_hero_id()
	if owner_id == "" and not deck_mgr._heroes.is_empty():
		owner_id = deck_mgr._heroes.keys()[0]
	if deck_mgr.get_hand(owner_id).is_empty():
		if not reward_requires_discard:
			_apply_discard_pick_reward(draw_count, energy_gain, owner_id)
	else:
		_pending_discard_pick = {"draw_count": draw_count, "energy_gain": energy_gain, "owner_id": owner_id, "optional": optional, "reward_requires_discard": reward_requires_discard}
		card_pick_requested.emit("discard_optional" if optional else "discard", draw_count)

func get_pending_discard_owner() -> String:
	return _pending_discard_pick.get("owner_id", "")

func is_discard_pick_optional() -> bool:
	return _pending_discard_pick.get("optional", false)

func resolve_pending_discard_pick(picked_card: Resource) -> void:
	if _pending_discard_pick.is_empty():
		return
	var draw_count: int = _pending_discard_pick.get("draw_count", 0)
	var energy_gain: int = _pending_discard_pick.get("energy_gain", 0)
	var reward_requires_discard: bool = _pending_discard_pick.get("reward_requires_discard", false)
	var owner_id: String = get_pending_discard_owner()
	if picked_card == null and not is_discard_pick_optional():
		return
	if picked_card != null and (picked_card.owner_id != owner_id or not deck_mgr.get_hand(owner_id).has(picked_card)):
		return
	_pending_discard_pick = {}
	if deck_mgr and picked_card != null:
		deck_mgr.discard_card(picked_card)
	if picked_card != null or not reward_requires_discard:
		_apply_discard_pick_reward(draw_count, energy_gain, owner_id)

func _register_power(key: String, owner_id: String, value: int, params: Dictionary = {}) -> void:
	var power_key: String = key + ":" + owner_id
	if key == "power.strength_player" and params.has("card_name"):
		var source: String = params.card_name
		var sources: Dictionary = _active_powers.get(power_key, {}).get("params", {}).get("sources", {})
		sources[source] = maxi(sources.get(source, 0), value)
		var total := 0
		for strength in sources.values():
			total += int(strength)
		_active_powers[power_key] = {"value": total, "owner_id": owner_id, "params": {"sources": sources}}
		active_powers_changed.emit()
		return
	if _active_powers.has(power_key):
		var existing: Dictionary = _active_powers[power_key]
		existing["value"] = maxi(existing.get("value", 0), value)
		for param in params:
			if typeof(params[param]) == TYPE_INT:
				existing["params"][param] = maxi(existing["params"].get(param, 0), params[param])
			elif not existing["params"].has(param):
				existing["params"][param] = params[param]
		active_powers_changed.emit()
		return
	_active_powers[power_key] = {
		"value": value,
		"owner_id": owner_id,
		"params": params.duplicate(true),
	}
	active_powers_changed.emit()

func _trigger_active_powers(phase: String, ctx: Dictionary = {}) -> void:
	# 본인 영웅 차례 한정 — owner_id 영웅 power 만 발동 (owner 없는 글로벌 power 는 모든 영웅 차례에 발동, 3× 효과)
	var target_hero: String = ctx.get("hero_id", "")
	for power_key in _active_powers.keys():
		var power: Dictionary = _active_powers[power_key]
		var key: String = power_key.split(":")[0] if ":" in power_key else power_key
		var owner_id: String = power.get("owner_id", "")
		var v: int = power.get("value", 0)
		# player_turn_start 시 본인 영웅 power 만 발동 (다른 영웅 차례에는 skip)
		if phase == "player_turn_start" and target_hero != "" and owner_id != "" and owner_id != target_hero:
			continue
		if phase == "player_turn_start" and key in ["power.poison_per_turn", "power.block_per_turn", "power.heal_team_per_turn"]:
			var params: Dictionary = power.get("params", {})
			var period: int = int(params.get("upgrade_tick_period", 0))
			if period > 0:
				params["_upgrade_tick_count"] = int(params.get("_upgrade_tick_count", 0)) + 1
				if int(params["_upgrade_tick_count"]) % period == 0:
					v += int(params.get("upgrade_tick_bonus", 0))
		match key:
			"power.poison_per_turn":
				if phase == "player_turn_start":
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_apply_status_to_enemy(ei, "poison", v)
			"power.block_per_turn":
				if phase == "player_turn_start":
					_hero_block[owner_id] = _hero_block.get(owner_id, 0) + v
			"power.heal_team_per_turn", "power.limited_team_heal":
				if phase == "player_turn_start" and team_mgr:
					for hero in team_mgr.heroes:
						_heal_hero_safe(hero.hero_id, v)
					if power.get("params", {}).has("remaining_turns"):
						power["params"]["remaining_turns"] -= 1
						if power["params"]["remaining_turns"] <= 0:
							_active_powers.erase(power_key)
			"power.draw_per_turn":
				if phase == "player_turn_start" and deck_mgr:
					# 본인 영웅에게 추가 드로우
					deck_mgr.draw_cards_h(owner_id, v)
					_cards_drawn_this_turn += v  # legacy 호환 카운터
			"power.counter_per_attack":
				if phase == "enemy_attack":
					var enemy_idx: int = ctx.get("enemy_index", -1)
					var blk: int = _hero_block.get(owner_id, 0)
					if enemy_idx >= 0 and blk > 0:
						_deal_damage_to_enemy(enemy_idx, int(blk * v / 100.0))
			"power.morale_per_turn":
				if phase == "player_turn_start":
					if not _hero_status.has(owner_id):
						_hero_status[owner_id] = {}
					var cur_morale: int = _hero_status[owner_id].get("morale", 0) + v
					_hero_status[owner_id]["morale"] = cur_morale
					morale_changed.emit(owner_id, cur_morale)
			"power.summon_per_turn":
				if phase == "player_turn_start":
					if not _hero_status.has(owner_id):
						_hero_status[owner_id] = {}
					var cur_tok: int = _hero_status[owner_id].get("tokens", 0)
					_hero_status[owner_id]["tokens"] = min(cur_tok + v, TOKEN_MAX_STACK)
					status_applied.emit(owner_id, "tokens", v)
			"power.on_enthrall_strength":
				if phase == "on_enthrall":
					var _oes_id: String = power.get("owner_id", "")
					var cur_str: int = _active_powers.get("power.strength_player:" + _oes_id, {}).get("value", 0)
					_active_powers["power.strength_player:" + _oes_id] = {
						"value": cur_str + v,
						"owner_id": _oes_id,
						"params": {},
					}
					active_powers_changed.emit()
	if phase == "player_turn_start":
		active_powers_changed.emit()

func _track_card_type_counters(card: Resource) -> void:
	for ei in _enemy_card_counters:
		if not _enemy_alive[int(ei)]:
			continue
		var trigger: Dictionary = _enemies[int(ei)].card_count_trigger
		if int(card.card_type) != int(trigger.get("card_type", -1)):
			continue
		var ctr: Dictionary = _enemy_card_counters[ei]
		ctr["count"] += 1
		var threshold: int = trigger.get("threshold", 0)
		var fired: int = ctr.get("fired_count", 0)
		var should_fire: bool = threshold > 0 and ctr["count"] >= threshold
		if should_fire and not trigger.get("repeat", true) and fired >= 1:
			should_fire = false
		if should_fire:
			ctr["fired_count"] = fired + 1
			ctr["count"] = 0
			var intent: Resource = trigger.get("intent")
			if intent != null and intent is IntentRes:
				_execute_intent(int(ei), intent)
		enemy_counter_changed.emit(int(ei))

func get_enemy_counter(enemy_index: int) -> Dictionary:
	if not _enemy_card_counters.has(enemy_index):
		return {}
	var ctr: Dictionary = _enemy_card_counters[enemy_index]
	var trigger: Dictionary = _enemies[enemy_index].card_count_trigger
	return {
		"count": ctr.get("count", 0),
		"threshold": trigger.get("threshold", 0),
		"card_type": trigger.get("card_type", -1),
		"intent": trigger.get("intent"),
		"tooltip_key": trigger.get("tooltip_key", ""),
	}

func _apply_card_effects(card: Resource, target_enemy_index: int, target_hero_id: String = "") -> void:
	# 카드 소유 영웅이 사망 상태면 효과 없음
	if team_mgr and not team_mgr.is_alive(card.owner_id):
		return
	# VFX 차지 시작 — battle_scene 이 받아 owner→target VFX 재생
	card_vfx_charge_start.emit(card, target_enemy_index, target_hero_id)
	# 차지 중 카드의 예측 데미지 즉시 누적 — 다음 카드 입력 시 사망 예정 적 차단/UI 갱신
	var _pending_estimate := _estimate_card_damage(card, target_enemy_index)
	for _ei in _pending_estimate:
		_add_pending_dmg(_ei, _pending_estimate[_ei])
	# 각 효과를 자기 VFX 그룹의 impact 시점에 맞춰 적용 — 데미지/상태 폰트가 해당 VFX 임팩트와 동기.
	# 효과를 impact delay 오름차순(동일 delay 는 원래 순서 유지)으로 정렬 후, 각 효과 적용 직전
	# 자기 VFX 그룹 impact 까지 대기. ATTACK 카드는 모든 효과가 같은 delay → 한 번에 적용 (기존 동작).
	# 테스트 환경(_vfx_speed_mul()==0)에서는 모든 delay 0 → 대기 없이 즉시 일괄 적용.
	var _ordered: Array = []
	for _oi in range(card.effects.size()):
		_ordered.append([_effect_stage_delay(card, card.effects[_oi], target_enemy_index), _oi, card.effects[_oi]])
	# Effects resolve in authored order; VFX timing must not reorder sacrifice/payoff.
	_kills_this_card = 0
	_enthralls_this_card = 0
	var next_hit_bonus: int = 0
	if card.card_type == CardRes.CardType.ATTACK:
		next_hit_bonus = _hero_status.get(card.owner_id, {}).get("next_attack_first_hit_bonus", 0)
		if _hero_status.has(card.owner_id):
			_hero_status[card.owner_id].erase("next_attack_first_hit_bonus")
		if card.owner_id == "musashi":
			_swordsman_vow_speed()
		# 황제의 무도 (나폴레옹×무사시): 적이 1명뿐일 때 무사시가 공격하면 나폴레옹 사기 +1 (무사시 차례당 1회)
		if card.owner_id == "musashi" and _get_living_enemy_count() == 1 and team_mgr.is_alive("napoleon") and _use_turn_effect("musashi", "synergy_emperor_dance_solo"):
			_grant_morale("napoleon", 1)
			synergy_triggered.emit("synergy.napoleon_musashi.name", "musashi")
	var first_damage_effect := true
	var _stage_elapsed := 0.0
	var _pending_cleared := false
	for _op in _ordered:
		if team_mgr and not team_mgr.is_alive(card.owner_id):
			break
		var _stage_d: float = _op[0]
		var effect = _op[2]
		if _stage_d > _stage_elapsed:
			# 이 효과 VFX 그룹의 impact 까지 대기 (다음 vfx_impact_resolved 신호 = 이 그룹 빔).
			await _await_vfx_impact((_stage_d - _stage_elapsed) + 0.5)
			_stage_elapsed = _stage_d
			if not is_battle_active:
				if not _pending_cleared:
					for _ei in _pending_estimate:
						_clear_pending_dmg(_ei, _pending_estimate[_ei])
				return
			if team_mgr and not team_mgr.is_alive(card.owner_id):
				if not _pending_cleared:
					for _ei in _pending_estimate:
						_clear_pending_dmg(_ei, _pending_estimate[_ei])
				return
		# 첫 실제 적용 직전 1회 pending(예측 데미지) 차감 → 실제 데미지 시그널이 hp 갱신
		if not _pending_cleared:
			for _ei in _pending_estimate:
				_clear_pending_dmg(_ei, _pending_estimate[_ei])
			_pending_cleared = true
		# condition 필드 평가 — 조건 불충족 시 이 효과 스킵
		if effect.condition != "" and not _evaluate_condition(effect.condition, card):
			continue
		if effect.rule_id != "":
			_apply_revision_effect(card, effect, target_enemy_index, target_hero_id, next_hit_bonus if first_damage_effect else 0)
			if effect.effect_type == EffectRes.EffectType.DAMAGE:
				first_damage_effect = false
			continue
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
				# power.strength_player: 영웅 측 strength 플랫 보너스
				var _str_flat: int = _hero_strength(card.owner_id)
				# 공격자 out_pct 기본값 — weak(-0.25)
				var _base_out_pct: float = 0.0
				if owner_status.get("weak", 0) > 0:
					_base_out_pct -= 0.25
				# power.bonus_per_hit: 히트당 추가 피해
				var _bph: int = _active_powers.get("power.bonus_per_hit:" + card.owner_id, {}).get("value", 0)
				for _hit in range(effect.hit_count):
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								# 치명타 — 적 status.marked_by 비어있지 않으면 +30%
								var _all_hm: bool = not _enemy_status[i].get("marked_by", []).is_empty()
								var _all_cr: Dictionary = _roll_crit(i, _all_hm, card.owner_id)
								var _all_out_pct: float = _base_out_pct
								var _all_ctx := DamageContext.new()
								_all_ctx.base = effect.value
								_all_ctx.flat = _str_flat + (next_hit_bonus if _hit == 0 and first_damage_effect else 0)
								_all_ctx.out_pct = _all_out_pct
								_all_ctx.crit_mult = _all_cr["crit_mult"]
								var _all_dmg: float = _outgoing_damage(_all_ctx)
								_deal_damage_to_enemy(i, _all_dmg, effect.damage_type, _all_cr["is_crit"], card.owner_id)
								if _bph > 0:
									_deal_damage_to_enemy(i, _bph, effect.damage_type)
								_last_attacker[i] = card.owner_id
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							var _hm: bool = not _enemy_status[target_enemy_index].get("marked_by", []).is_empty()
							var _cr: Dictionary = _roll_crit(target_enemy_index, _hm, card.owner_id)
							var _sgl_out_pct: float = _base_out_pct
							var _sgl_ctx := DamageContext.new()
							_sgl_ctx.base = effect.value
							_sgl_ctx.flat = _str_flat + (next_hit_bonus if _hit == 0 and first_damage_effect else 0)
							_sgl_ctx.out_pct = _sgl_out_pct
							_sgl_ctx.crit_mult = _cr["crit_mult"]
							var _sgl_dmg: float = _outgoing_damage(_sgl_ctx)
							_deal_damage_to_enemy(target_enemy_index, _sgl_dmg, effect.damage_type, _cr["is_crit"], card.owner_id)
							if _bph > 0:
								_deal_damage_to_enemy(target_enemy_index, _bph, effect.damage_type)
							_last_attacker[target_enemy_index] = card.owner_id
				# power.every_nth_attack_bonus: N번째 DAMAGE 효과마다 추가 피해
				first_damage_effect = false
				_trigger_damage_rhythm(card, effect, target_enemy_index)
			EffectRes.EffectType.BLOCK:
				var block_id: String = target_hero_id if effect.target == "ALLY" and target_hero_id != "" else card.owner_id
				_gain_block(block_id, effect.value)
			EffectRes.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					var _pw_params: Dictionary = {}
					if effect.bonus_value > 0:
						_pw_params["bonus_value"] = effect.bonus_value
					_pw_params.merge(effect.rule_params, true)
					_pw_params["card_name"] = card.card_name
					var _pw_aid: String = "hero:" + card.owner_id
					var _pw_old_sp: int = _actor_speed(_pw_aid) if effect.status_type == "power.speed_buff" else 0
					if effect.status_type == "power.spend_all_energy_poison_double":
						_spend_all_energy_poison_double(card.owner_id)
					else:
						_register_power(effect.status_type, card.owner_id, effect.value, _pw_params)
					if effect.rule_params.get("immediate_morale", 0) > 0:
						_apply_status_to_hero(card.owner_id, "morale", effect.rule_params.immediate_morale)
						morale_changed.emit(card.owner_id, _hero_status[card.owner_id].get("morale", 0))
					if effect.status_type == "power.speed_buff":
						_adjust_turn_queue_for_speed_change(_pw_aid, _pw_old_sp)
				else:
					var _as_stacks: int = effect.value
					# power.debuff_amplify: 약화/취약/독 부여 시 추가 스택
					if effect.status_type in ["weak", "vulnerable", "poison"]:
						_as_stacks += _active_powers.get("power.debuff_amplify:" + card.owner_id, {}).get("value", 0)
					# power.poison_double_application: 독 부여 시 스택 ×2
					if effect.status_type == "poison" and _active_powers.has("power.poison_double_application:" + card.owner_id):
						_as_stacks = _as_stacks * 2
					if effect.status_type == "duel_lock":
						_apply_duel_lock(target_enemy_index, card.owner_id, _as_stacks)
					elif effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								if effect.status_type == "taunt":
									_apply_taunt_to_enemy(i, _as_stacks, card.owner_id)
								else:
									_apply_status_to_enemy(i, effect.status_type, _as_stacks)
					elif effect.target == "SELF":
						_apply_status_to_hero(card.owner_id, effect.status_type, _as_stacks)
					elif effect.target == "ALL_ALLIES":
						if team_mgr:
							for hero in team_mgr.get_living_heroes():
								_apply_status_to_hero(hero.hero_id, effect.status_type, _as_stacks)
					elif effect.target == "ALLY":
						var ally_id: String = target_hero_id if target_hero_id != "" else card.owner_id
						_apply_status_to_hero(ally_id, effect.status_type, _as_stacks)
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							if effect.status_type == "taunt":
								_apply_taunt_to_enemy(target_enemy_index, _as_stacks, card.owner_id)
							else:
								_apply_status_to_enemy(target_enemy_index, effect.status_type, _as_stacks)
			EffectRes.EffectType.DRAW:
				if deck_mgr:
					deck_mgr.draw_cards_h(card.owner_id, effect.value)
					_cards_drawn_this_turn += effect.value
			EffectRes.EffectType.ENERGY:
				if deck_mgr:
					deck_mgr.add_energy_h(card.owner_id, effect.value)
			EffectRes.EffectType.HEAL:
				if team_mgr:
					var heal_id: String
					if effect.target == "LOWEST_HP":
						var min_ratio: float = 2.0
						heal_id = card.owner_id
						for hero in team_mgr.get_living_heroes():
							var ratio: float = float(team_mgr.get_current_hp(hero.hero_id)) / float(max(1, hero.max_hp))
							if ratio < min_ratio:
								min_ratio = ratio
								heal_id = hero.hero_id
					else:
						heal_id = target_hero_id if effect.target != "SELF" and target_hero_id != "" else card.owner_id
					_heal_hero_safe(heal_id, effect.value)
					# 성녀의 방패 (잔다르크×이순신): 잔다르크 힐 시 대상 방어구 +40
					if card.owner_id == "joan_of_arc" and team_mgr.is_alive("yi_sun_sin"):
						_hero_block[heal_id] = _hero_block.get(heal_id, 0) + _combat_literal(40)
						hero_block_gained.emit(heal_id, _combat_literal(40))
						hero_block_vfx.emit(heal_id)
			EffectRes.EffectType.GAIN_MORALE:
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				var new_morale: int = _hero_status[card.owner_id].get("morale", 0) + effect.value
				_hero_status[card.owner_id]["morale"] = new_morale
				status_applied.emit(card.owner_id, "morale", effect.value)
				morale_changed.emit(card.owner_id, new_morale)
			EffectRes.EffectType.CHARM:
				var _charm_stacks: int = effect.value
				# power.charm_double_apply: 적용 스택 수 배증
				var _cdbl: int = _active_powers.get("power.charm_double_apply:" + card.owner_id, {}).get("value", 0)
				if _cdbl > 0:
					_charm_stacks = _charm_stacks * (1 + _cdbl)
				if effect.target == "ALL":
					for ei in range(_enemies.size()):
						if not _enemy_alive[ei]:
							continue
						if effect.condition == "enemy_hp_below_50":
							var _max_chp: int = _enemies[ei].max_hp
							if not (_max_chp > 0 and float(_enemy_hp[ei]) / float(_max_chp) <= 0.50):
								continue
						_apply_status_to_enemy(ei, "charm", _charm_stacks)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_apply_status_to_enemy(target_enemy_index, "charm", _charm_stacks)
			EffectRes.EffectType.CONSUME_MORALE:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale >= effect.value:
					var new_morale: int = morale - effect.value
					_hero_status[card.owner_id]["morale"] = new_morale
					morale_changed.emit(card.owner_id, new_morale)
					if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
						_deal_damage_to_enemy(target_enemy_index, effect.bonus_value, effect.damage_type)
			EffectRes.EffectType.POISON_BURST:
				if effect.target == "ALL":
					for _pbi in range(_enemies.size()):
						if _enemy_alive[_pbi]:
							var _pb_pdmg: int = _enemy_status[_pbi].get("poison_dmg", 0)
							if _pb_pdmg > 0:
								var _pb_dmg: int = _pb_pdmg * effect.value / 100
								_deal_damage_to_enemy(_pbi, _pb_dmg, effect.damage_type)
								_enemy_status[_pbi]["poison_dmg"] = 0
								_enemy_status[_pbi]["poison_dur"] = 0
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					var pdmg: int = _enemy_status[target_enemy_index].get("poison_dmg", 0)
					if pdmg > 0:
						var burst_dmg: int = pdmg * effect.value / 100
						_deal_damage_to_enemy(target_enemy_index, burst_dmg, effect.damage_type)
						_enemy_status[target_enemy_index]["poison_dmg"] = 0
						_enemy_status[target_enemy_index]["poison_dur"] = 0
			EffectRes.EffectType.COUNTER_BLOCK:
				var block: int = _hero_block.get(card.owner_id, 0)
				var dmg: int = int(block * effect.value / 100.0)
				if target_enemy_index >= 0 and dmg > 0:
					_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.BLOCK_ALL:
				if team_mgr:
					# 사망 영웅 제외 — 살아있는 영웅만 BLOCK
					for hero in team_mgr.heroes:
						if team_mgr.is_alive(hero.hero_id):
							_hero_block[hero.hero_id] = _hero_block.get(hero.hero_id, 0) + effect.value
							hero_block_gained.emit(hero.hero_id, effect.value)
							hero_block_vfx.emit(hero.hero_id)
			EffectRes.EffectType.HEAL_ALL:
				if team_mgr:
					var heal_amt: int = effect.value
					if effect.status_type == "dead_ally_count":
						var dead_count: int = 0
						for hero in team_mgr.heroes:
							if not team_mgr.is_alive(hero.hero_id):
								dead_count += 1
						heal_amt = effect.value * dead_count
					heal_amt = heal_amt
					# 사망 영웅 제외 — 살아있는 영웅만 HEAL (REVIVE 는 별도 effect_type)
					for hero in team_mgr.heroes:
						if team_mgr.is_alive(hero.hero_id):
							_heal_hero_safe(hero.hero_id, heal_amt)
			EffectRes.EffectType.FORMATION_BLOCK:
				if team_mgr:
					var count: int = team_mgr.get_living_heroes().size()
					_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + count * effect.value
			EffectRes.EffectType.COST_NEXT:
				if deck_mgr:
					deck_mgr.add_pending_cost_reduction(card.owner_id, effect.value)
			EffectRes.EffectType.CONDITIONAL_DMG:
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					if effect.status_type == "dead_ally_count":
						# 사망 아군 수 × bonus_value + value 피해
						var dead_count: int = 0
						if team_mgr:
							for h in team_mgr.heroes:
								if not team_mgr.is_alive(h.hero_id):
									dead_count += 1
						var total_dmg: int = effect.value + effect.bonus_value * dead_count
						_revision_damage(card, effect, target_enemy_index, total_dmg, false, next_hit_bonus if first_damage_effect else 0)
					else:
						var condition_met: bool
						var es: Dictionary = _enemy_status[target_enemy_index]
						match effect.status_type:
							"low_hp", "very_low_hp":
								condition_met = _evaluate_condition(effect.status_type, card)
							"morale":
								condition_met = _hero_status.get(card.owner_id, {}).get("morale", 0) > 0
							"has_poison":
								condition_met = es.get("poison_dmg", 0) > 0
							"has_poison_5":
								condition_met = es.get("poison_dmg", 0) >= _combat_literal(5)
							"has_poison_10":
								condition_met = es.get("poison_dmg", 0) >= _combat_literal(10)
							"has_poison_1", "has_poison_2":
								condition_met = es.get("poison_dmg", 0) >= effect.status_type.trim_prefix("has_poison_").to_int()
							"has_debuffs_3":
								var dc: int = 0
								for dt: String in ["weak", "vulnerable"]:
									if es.get(dt, 0) > 0:
										dc += 1
								if es.get("poison_dmg", 0) > 0:
									dc += 1
								condition_met = dc >= 3
							"enemy_count_1":
								condition_met = _get_living_enemy_count() == 1
							"hand_size_0":
								condition_met = deck_mgr != null and deck_mgr.get_hand(card.owner_id).is_empty()
							"cards_played_before":
								condition_met = deck_mgr != null and deck_mgr.get_cards_played_this_turn(card.owner_id) >= 2
							"enemy_hp_below_30":
								var _max_hp_30: int = _enemies[target_enemy_index].max_hp
								condition_met = _max_hp_30 > 0 and float(_enemy_hp[target_enemy_index]) / float(_max_hp_30) <= 0.30
							"enemy_hp_below_50":
								var _max_hp_50: int = _enemies[target_enemy_index].max_hp
								condition_met = _max_hp_50 > 0 and float(_enemy_hp[target_enemy_index]) / float(_max_hp_50) <= 0.50
							"team_hp_below_30":
								var below_30: bool = false
								if team_mgr:
									for h in team_mgr.heroes:
										if team_mgr.is_alive(h.hero_id):
											var ratio: float = float(team_mgr.get_current_hp(h.hero_id)) / float(h.max_hp)
											if ratio <= 0.30:
												below_30 = true
												break
								condition_met = below_30
							_:
								condition_met = es.get(effect.status_type, 0) > 0
						var dmg: int = effect.bonus_value if condition_met else effect.value
						_revision_damage(card, effect, target_enemy_index, dmg, false, next_hit_bonus if first_damage_effect else 0)
					first_damage_effect = false
			EffectRes.EffectType.SUMMON_TOKEN:
				if not _hero_status.has(card.owner_id):
					_hero_status[card.owner_id] = {}
				var cur: int = _hero_status[card.owner_id].get("tokens", 0)
				_hero_status[card.owner_id]["tokens"] = min(cur + effect.value, TOKEN_MAX_STACK)
				status_applied.emit(card.owner_id, "tokens", effect.value)
			EffectRes.EffectType.REVIVE:
				if team_mgr:
					var revive_id: String = target_hero_id
					if revive_id == "" or team_mgr.is_alive(revive_id):
						for hero in team_mgr.heroes:
							if not team_mgr.is_alive(hero.hero_id):
								revive_id = hero.hero_id
								break
					if revive_id != "" and not team_mgr.is_alive(revive_id):
						var revive_hero = team_mgr.get_hero(revive_id)
						if revive_hero != null:
							var revive_hp: int = max(1, revive_hero.max_hp * effect.value / 100)
							team_mgr.revive(revive_id, revive_hp)
			EffectRes.EffectType.SACRIFICE_HP:
				if team_mgr:
					var hp_before: int = team_mgr.get_current_hp(card.owner_id)
					team_mgr.take_damage(card.owner_id, effect.value)
					# 전투 중 누적 희생 HP — 잔다르크 고유 상태이상 sacrifice_bank (상태이상 UI 표시)
					if not _hero_status.has(card.owner_id):
						_hero_status[card.owner_id] = {}
					var _bank_total: int = _hero_status[card.owner_id].get("sacrifice_bank", 0) + hp_before - team_mgr.get_current_hp(card.owner_id)
					_hero_status[card.owner_id]["sacrifice_bank"] = _bank_total
					status_applied.emit(card.owner_id, "sacrifice_bank", _bank_total)
					_check_lose_condition()
			EffectRes.EffectType.COST_ZERO_TURN:
				if deck_mgr:
					deck_mgr.set_pending_all_cost_zero(card.owner_id, true)
			EffectRes.EffectType.BLOCK_PER_CARDS_PLAYED:
				# 본인 영웅 차례 내 카드 사용 횟수 (DeckManager 영웅별)
				var played: int = deck_mgr.get_cards_played_this_turn(card.owner_id) if deck_mgr else 0
				var block_amount: int = played * effect.value
				_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + block_amount
			EffectRes.EffectType.ON_KILL_DRAW:
				# 이번 카드로 처치된 적 수만큼 본인 영웅 드로우
				if deck_mgr:
					for _i in range(_kills_this_card):
						deck_mgr.draw_cards_h(card.owner_id, effect.value)
			EffectRes.EffectType.DRAW_PER_ENTHRALL:
				# 이번 카드로 반함 발동 횟수 × value, 본인 영웅 드로우
				if deck_mgr and _enthralls_this_card > 0:
					var _draw_amt: int = _enthralls_this_card * effect.value
					deck_mgr.draw_cards_h(card.owner_id, _draw_amt)
					_cards_drawn_this_turn += _draw_amt
			EffectRes.EffectType.DAMAGE_PER_CHARMED_ENEMY:
				# charm 스택 보유 적 수 × value 피해
				var _charmed_count: int = 0
				for _cei in range(_enemies.size()):
					if _enemy_alive[_cei] and _enemy_status[_cei].get("charm", 0) > 0:
						_charmed_count += 1
				var _cpce_dmg: int = _charmed_count * effect.value
				if effect.target == "ALL":
					for _cei2 in range(_enemies.size()):
						if _enemy_alive[_cei2]:
							_deal_damage_to_enemy(_cei2, _cpce_dmg, effect.damage_type)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_deal_damage_to_enemy(target_enemy_index, _cpce_dmg, effect.damage_type)
			EffectRes.EffectType.PURGE_STATUS:
				if team_mgr:
					var heroes_to_purge: Array = []
					if effect.target == "ALL":
						heroes_to_purge = team_mgr.heroes
					else:
						for h in team_mgr.heroes:
							if h.hero_id == card.owner_id:
								heroes_to_purge = [h]
								break
					for h in heroes_to_purge:
						if not _hero_status.has(h.hero_id):
							continue
						for debuff in ["weak", "vulnerable", "poison_dmg", "charm"]:
							_hero_status[h.hero_id].erase(debuff)
					# 성스러운 독 (잔다르크×클레오파트라): 정화한 아군을 힐 100
					if card.owner_id == "joan_of_arc" and team_mgr.is_alive("cleopatra"):
						for _sv_h in heroes_to_purge:
							_heal_hero_safe(_sv_h.hero_id, _combat_literal(100))
			EffectRes.EffectType.PER_DRAW_DMG:
				# 본인 영웅의 이번 차례 드로우 수 × value
				var drawn: int = deck_mgr.get_draws_this_turn(card.owner_id) if deck_mgr else 0
				if target_enemy_index >= 0 and drawn > 0:
					var dmg: int = drawn * effect.value
					_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.DAMAGE_PER_BLOCK:
				var block: int = _hero_block.get(card.owner_id, 0)
				var dmg: int = int(block * effect.value / 100.0)
				if target_enemy_index >= 0 and dmg > 0:
					_deal_damage_to_enemy(target_enemy_index, dmg)
			EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY:
				if target_enemy_index >= 0 and team_mgr:
					var dead_count: int = 0
					for h in team_mgr.heroes:
						if not team_mgr.is_alive(h.hero_id):
							dead_count += 1
					if dead_count > 0:
						_deal_damage_to_enemy(target_enemy_index, dead_count * effect.value, effect.damage_type)
			EffectRes.EffectType.DOUBLE_NEXT_DAMAGE:
				# 본인 영웅 다음 데미지 ×2 + 글로벌 슬롯도 등록 (cross-hero / poison tick 호환)
				_active_powers[_dnd_key(card.owner_id)] = {"value": 1, "owner_id": card.owner_id, "params": {}}
				_active_powers[DND_KEY] = {"value": 1, "owner_id": "__global__", "params": {}}
				active_powers_changed.emit()
			EffectRes.EffectType.DISCARD_PICK_DRAW:
				_trigger_discard_pick(effect.value, 1, card.owner_id)
			EffectRes.EffectType.MORALE_TO_BLOCK:
				var morale: int = _hero_status.get(card.owner_id, {}).get("morale", 0)
				if morale > 0:
					_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + morale * effect.value
			EffectRes.EffectType.DAMAGE_PER_HAND_SIZE:
				# 본인 영웅의 현재 핸드 크기 × value
				if target_enemy_index >= 0 and deck_mgr:
					var hand_size: int = deck_mgr.get_hand(card.owner_id).size()
					if hand_size > 0:
						_deal_damage_to_enemy(target_enemy_index, hand_size * effect.value, effect.damage_type)
			EffectRes.EffectType.DAMAGE_PER_TOKEN:
				var _dpt_tokens: int = _hero_status.get(card.owner_id, {}).get("tokens", 0)
				if _dpt_tokens > 0:
					var _dpt_bonus: int = _active_powers.get("power.token_bonus_dmg:" + card.owner_id, {}).get("value", 0)
					var _dpt_dmg: int = _dpt_tokens * (effect.value + _dpt_bonus)
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								_deal_damage_to_enemy(i, _dpt_dmg, effect.damage_type)
					elif target_enemy_index >= 0:
						_deal_damage_to_enemy(target_enemy_index, _dpt_dmg, effect.damage_type)
			EffectRes.EffectType.DAMAGE_PER_TEAM_MORALE:
				# 교차 영웅: 생존 영웅 전원의 사기 합산 × value 피해
				if team_mgr:
					var _dptm_total: int = 0
					for h in team_mgr.heroes:
						if team_mgr.is_alive(h.hero_id):
							_dptm_total += _hero_status.get(h.hero_id, {}).get("morale", 0)
					if _dptm_total > 0:
						var _dptm_dmg: int = _dptm_total * effect.value
						if effect.target == "ALL":
							for i in range(_enemies.size()):
								if _enemy_alive[i]:
									_deal_damage_to_enemy(i, _dptm_dmg, effect.damage_type)
						elif target_enemy_index >= 0:
							_deal_damage_to_enemy(target_enemy_index, _dptm_dmg, effect.damage_type)
			EffectRes.EffectType.DAMAGE_PER_TEAM_TOKEN:
				# 교차 영웅: 생존 영웅 전원의 토큰 합산 × value 피해
				if team_mgr:
					var _dptt_total: int = 0
					for h in team_mgr.heroes:
						if team_mgr.is_alive(h.hero_id):
							_dptt_total += _hero_status.get(h.hero_id, {}).get("tokens", 0)
					if _dptt_total > 0:
						var _dptt_dmg: int = _dptt_total * effect.value
						if effect.target == "ALL":
							for i in range(_enemies.size()):
								if _enemy_alive[i]:
									_deal_damage_to_enemy(i, _dptt_dmg, effect.damage_type)
						elif target_enemy_index >= 0:
							_deal_damage_to_enemy(target_enemy_index, _dptt_dmg, effect.damage_type)
			EffectRes.EffectType.CONSUME_TEAM_MORALE:
				# 교차 영웅: 생존 영웅 각자 value 사기 소모 → 소모 총량 × bonus_value 만큼 팀 전체 방어
				if team_mgr:
					var _ctm_spent: int = 0
					for h in team_mgr.heroes:
						if not team_mgr.is_alive(h.hero_id):
							continue
						var _ctm_m: int = _hero_status.get(h.hero_id, {}).get("morale", 0)
						var _ctm_take: int = min(_ctm_m, effect.value)
						if _ctm_take > 0:
							if not _hero_status.has(h.hero_id):
								_hero_status[h.hero_id] = {}
							_hero_status[h.hero_id]["morale"] = _ctm_m - _ctm_take
							morale_changed.emit(h.hero_id, _ctm_m - _ctm_take)
							_ctm_spent += _ctm_take
					if _ctm_spent > 0:
						var _ctm_block: int = _ctm_spent * effect.bonus_value
						for h2 in team_mgr.heroes:
							if team_mgr.is_alive(h2.hero_id):
								_hero_block[h2.hero_id] = _hero_block.get(h2.hero_id, 0) + _ctm_block
								hero_block_gained.emit(h2.hero_id, _ctm_block)
								hero_block_vfx.emit(h2.hero_id)
			EffectRes.EffectType.HEAL_PER_DEAD_ALLY:
				if team_mgr:
					var dead_count: int = 0
					for h in team_mgr.heroes:
						if not team_mgr.is_alive(h.hero_id):
							dead_count += 1
					if dead_count > 0:
						var heal_amt: int = dead_count * effect.value
						if effect.target == "ALL":
							for hero in team_mgr.heroes:
								_heal_hero_safe(hero.hero_id, heal_amt)
						else:
							_heal_hero_safe(card.owner_id, heal_amt)
			EffectRes.EffectType.ENERGY_TO_DAMAGE:
				# 본인 영웅의 현재 에너지 × value (모두 소비)
				if target_enemy_index >= 0 and deck_mgr:
					var energy: int = deck_mgr.get_energy(card.owner_id)
					if energy > 0:
						_deal_damage_to_enemy(target_enemy_index, energy * effect.value, effect.damage_type)
						deck_mgr.set_energy_h(card.owner_id, 0)
			EffectRes.EffectType.STATUS_DOUBLE:
				var sd_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							sd_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					sd_targets = [target_enemy_index]
				for i in sd_targets:
					for key in ["weak", "vulnerable", "poison_dmg", "charm"]:
						var cur: int = _enemy_status[i].get(key, 0)
						if cur > 0:
							_enemy_status[i][key] = cur * 2
							status_applied.emit("enemy_%d" % i, key, cur * 2)
			EffectRes.EffectType.SACRIFICE_PAYOFF:
				var _banked: int = _hero_status.get(card.owner_id, {}).get("sacrifice_bank", 0)
				if _banked > 0:
					@warning_ignore("integer_division")
					var _payout: int = (_banked / _combat_literal(100)) * effect.value
					if _payout > 0:
						if effect.status_type == "block":
							if effect.target == "ALL" and team_mgr:
								for hero in team_mgr.heroes:
									_hero_block[hero.hero_id] = _hero_block.get(hero.hero_id, 0) + _payout
							else:
								_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + _payout
						else:
							if effect.target == "ALL":
								for i in range(_enemies.size()):
									if _enemy_alive[i]:
										_deal_damage_to_enemy(i, _payout, effect.damage_type)
							elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
								_deal_damage_to_enemy(target_enemy_index, _payout, effect.damage_type)
			EffectRes.EffectType.CHARM_TO_DAMAGE:
				var _ctd_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_ctd_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_ctd_targets = [target_enemy_index]
				for i in _ctd_targets:
					var _cstacks: int = _enemy_status[i].get("charm", 0)
					if _cstacks > 0:
						_enemy_status[i]["charm"] = 0
						_deal_damage_to_enemy(i, _cstacks * effect.bonus_value, effect.damage_type)
			EffectRes.EffectType.MULTI_HIT_RANDOM:
				var _mhr_living: Array = []
				for i in range(_enemies.size()):
					if _enemy_alive[i]:
						_mhr_living.append(i)
				for _h in range(effect.hit_count):
					if _mhr_living.is_empty():
						break
					var _rand_e: int = _mhr_living[randi() % _mhr_living.size()]
					_deal_damage_to_enemy(_rand_e, effect.value, effect.damage_type)
					_last_attacker[_rand_e] = card.owner_id
					_mhr_living.clear()
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_mhr_living.append(i)
			EffectRes.EffectType.DAMAGE_PER_STATUS_TYPE:
				var _dpst_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_dpst_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_dpst_targets.append(target_enemy_index)
				for _di in _dpst_targets:
					var _dst: Dictionary = _enemy_status[_di]
					var _types: int = 0
					if _dst.get("weak", 0) > 0: _types += 1
					if _dst.get("vulnerable", 0) > 0: _types += 1
					if _dst.get("poison_dmg", 0) > 0 and _dst.get("poison_dur", 0) > 0: _types += 1
					if _dst.get("charm", 0) > 0: _types += 1
					if _types > 0:
						_deal_damage_to_enemy(_di, _types * effect.value, effect.damage_type)
						_last_attacker[_di] = card.owner_id
			EffectRes.EffectType.BUFF_SPEED:
				# value = 강도, bonus_value = 지속 턴. target SELF/ALL_ALLIES/ALLY. instance append (누적)
				var _bs_targets: Array = []
				if effect.target == "ALL_ALLIES" and team_mgr:
					for h in team_mgr.get_living_heroes():
						_bs_targets.append(h.hero_id)
				elif effect.target == "ALLY":
					_bs_targets.append(target_hero_id if target_hero_id != "" else card.owner_id)
				else:
					_bs_targets.append(card.owner_id)
				for _bs_hid in _bs_targets:
					var _bs_aid: String = "hero:" + _bs_hid
					var _bs_old_sp: int = _actor_speed(_bs_aid)
					if not _hero_status.has(_bs_hid):
						_hero_status[_bs_hid] = {}
					if not _hero_status[_bs_hid].has("speed_bonus") or typeof(_hero_status[_bs_hid]["speed_bonus"]) != TYPE_ARRAY:
						_hero_status[_bs_hid]["speed_bonus"] = []
					var speed_instance: Dictionary = {"value": effect.value, "dur": effect.bonus_value}
					if effect.rule_params.get("exclude_current_turn_end", false):
						speed_instance["skip_current_end"] = true
					if card.card_type == CardRes.CardType.POWER:
						speed_instance["dur"] = -1
						for ins in _hero_status[_bs_hid]["speed_bonus"]:
							if ins.get("card_name", "") == card.card_name:
								speed_instance["value"] = maxi(speed_instance["value"], ins.get("value", 0))
						_hero_status[_bs_hid]["speed_bonus"] = _hero_status[_bs_hid]["speed_bonus"].filter(func(ins): return ins.get("card_name", "") != card.card_name)
						speed_instance["card_name"] = card.card_name
					_hero_status[_bs_hid]["speed_bonus"].append(speed_instance)
					_adjust_turn_queue_for_speed_change(_bs_aid, _bs_old_sp)
					status_applied.emit(_bs_hid, "speed_bonus", effect.value)
			EffectRes.EffectType.DEBUFF_SPEED:
				var _ds_targets: Array = []
				if effect.target == "ALL":
					for i in range(_enemies.size()):
						if _enemy_alive[i]:
							_ds_targets.append(i)
				elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					_ds_targets.append(target_enemy_index)
				for _ds_ei in _ds_targets:
					var _ds_aid: String = "enemy:%d" % _ds_ei
					var _ds_old_sp: int = _actor_speed(_ds_aid)
					if not _enemy_status[_ds_ei].has("speed_penalty") or typeof(_enemy_status[_ds_ei]["speed_penalty"]) != TYPE_ARRAY:
						_enemy_status[_ds_ei]["speed_penalty"] = []
					_enemy_status[_ds_ei]["speed_penalty"].append({"value": effect.value, "dur": effect.bonus_value})
					_adjust_turn_queue_for_speed_change(_ds_aid, _ds_old_sp)
					status_applied.emit("enemy_%d" % _ds_ei, "speed_penalty", effect.value)
			EffectRes.EffectType.MARK_ENEMY:
				# 영웅이 적 마킹 — 모든 영웅의 그 적 공격 치명타 확률 +30%.
				# target SINGLE 만 지원. 같은 영웅이 같은 적 중복 마킹 시 noop.
				if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
					if not _enemy_status[target_enemy_index].has("marked_by"):
						_enemy_status[target_enemy_index]["marked_by"] = []
					var _me_arr: Array = _enemy_status[target_enemy_index]["marked_by"]
					if not _me_arr.has(card.owner_id):
						_me_arr.append(card.owner_id)
						_enemy_status[target_enemy_index]["marked_by"] = _me_arr
						status_applied.emit("enemy_%d" % target_enemy_index, "marked_by", _me_arr.size())
			EffectRes.EffectType.COUNTER_REFLECT:
				# 카운터 (universal starter). 카드 자체는 타겟 미지정 — counter window 활성 적 자동 선택.
				# A) counter window 활성 보스 → 즉시 차지 무효 + stun 1 (워닝 의도 표시 중에도 발동)
				# B) 그 외 → 영웅에 counter_pending 부여 (다음 받는 공격에서 50% 반감 + 100% 반사)
				var _cr_target: int = target_enemy_index
				if _cr_target < 0 or not is_counter_window_active(_cr_target):
					for _ci in range(_enemies.size()):
						if is_counter_window_active(_ci):
							_cr_target = _ci
							break
				var _cr_a_done: bool = false
				if is_counter_window_active(_cr_target):
					_enemy_status[_cr_target].erase("charge_remaining")
					_apply_status_to_enemy(_cr_target, "stun", 1)
					_enemy_status[_cr_target].erase("_charge_block_advance")
					# 패턴 사이클 reset — 차지업 + 후속 공격 (그 패턴 전체) 취소, 다음 사이클은 처음부터
					_enemy_intent_index[_cr_target] = 0
					counter_triggered.emit(card.owner_id, _cr_target, true)
					_cr_a_done = true
				if not _cr_a_done:
					# 모드 B — 영웅에 counter_pending 부여
					_apply_status_to_hero(card.owner_id, "counter_pending", 1)
	# power.echo_next_attack: 이 ATTACK 카드 효과 전체를 1회 재시전 (재진입 가드)
	if not _in_echo_replay and card.card_type == CardRes.CardType.ATTACK and (team_mgr == null or team_mgr.is_alive(card.owner_id)):
		var _echo_key: String = "power.echo_next_attack:" + card.owner_id
		if _active_powers.has(_echo_key):
			_active_powers.erase(_echo_key)
			active_powers_changed.emit()
			_in_echo_replay = true
			for effect in card.effects:
				if team_mgr != null and not team_mgr.is_alive(card.owner_id):
					break
				if effect.condition != "" and not _evaluate_condition(effect.condition, card):
					continue
				if effect.rule_id != "":
					_apply_revision_effect(card, effect, target_enemy_index, target_hero_id)
					continue
				match effect.effect_type:
					EffectRes.EffectType.CONDITIONAL_DMG:
						_revision_damage(card, effect, target_enemy_index, _card_effect_base_damage(effect, card.owner_id, target_enemy_index))
					EffectRes.EffectType.DAMAGE:
						var dmg2: float = effect.value
						var _os2: Dictionary = _hero_status.get(card.owner_id, {})
						if preload("res://resources/balance/combat_scale.gd").enabled():
							var echo_ctx := DamageContext.new()
							echo_ctx.base = effect.value
							echo_ctx.flat = _hero_strength(card.owner_id)
							if _os2.get("weak", 0) > 0:
								echo_ctx.out_pct = -0.25
							dmg2 = _outgoing_damage(echo_ctx)
						else:
							if _os2.get("weak", 0) > 0:
								dmg2 = int(dmg2 * 0.75)
							dmg2 += _hero_strength(card.owner_id)
						var _bph2: int = _active_powers.get("power.bonus_per_hit:" + card.owner_id, {}).get("value", 0)
						for _eh in range(effect.hit_count):
							if effect.target == "ALL":
								for i in range(_enemies.size()):
									if _enemy_alive[i]:
										_deal_damage_to_enemy(i, dmg2, effect.damage_type)
										if _bph2 > 0:
											_deal_damage_to_enemy(i, _bph2, effect.damage_type)
										_last_attacker[i] = card.owner_id
							else:
								if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
									_deal_damage_to_enemy(target_enemy_index, dmg2, effect.damage_type)
									if _bph2 > 0:
										_deal_damage_to_enemy(target_enemy_index, _bph2, effect.damage_type)
									_last_attacker[target_enemy_index] = card.owner_id
			_in_echo_replay = false
	_apply_synergy_bonus(card, target_enemy_index)

## dnd 플래그 존재 여부 확인 후 소진 — ×2는 적용하지 않음.
## _deal_damage_to_enemy 전용: compute_damage ctx.dnd_mult 에서 ×2를 담당하므로
## _consume_double_next_damage(×2 반환) 대신 이 함수로 플래그만 소진한다.
func _consume_dnd_flag() -> bool:
	var consumed: bool = false
	if _current_actor_id.begins_with("hero:"):
		var hid: String = _current_actor_id.substr(5)
		var key: String = _dnd_key(hid)
		if _active_powers.has(key):
			_active_powers.erase(key)
			consumed = true
	if _active_powers.has(DND_KEY):
		_active_powers.erase(DND_KEY)
		consumed = true
	if consumed:
		active_powers_changed.emit()
	return consumed


func _deal_damage_to_enemy(enemy_index: int, incoming_amount: float, damage_type: String = "", is_crit: bool = false, source_owner: String = "") -> void:
	if not _enemy_alive[enemy_index]:
		return
	# ── 받는 측 DamageContext 구성 ──
	var ctx := DamageContext.new()
	ctx.base = incoming_amount
	# T3-WARD: invuln 활성화 시 데미지 무시 — dnd 소진 전에 early-return
	if _enemy_status[enemy_index].get("invuln", 0) > 0:
		enemy_damaged.emit(enemy_index, 0, damage_type, false)
		return
	# double_next_damage: 플래그 확인·소진 후 ctx.dnd_mult=2.0 (×2는 ctx가 담당)
	if _consume_dnd_flag():
		ctx.dnd_mult = 2.0
	# vulnerable: 받는 측 +50%
	if _enemy_status[enemy_index].get("vulnerable", 0) > 0:
		ctx.in_pct += 0.5
		_vulnerable_guard(source_owner)
	# Fate Duel: only its caster gains the bonus against the marked enemy.
	# Most card damage calls omit source_owner, so use the active hero turn as the
	# authoritative owner for normal play while retaining explicit-source callers.
	var duel_owner: String = source_owner
	if duel_owner == "" and _current_actor_id.begins_with("hero:"):
		duel_owner = _current_actor_id.substr(5)
	if _enemy_status[enemy_index].get("duel_lock", 0) > 0 and _enemy_status[enemy_index].get("duel_lock_owner", "") == duel_owner:
		ctx.in_pct += 0.5
	# FORM_SWITCH defense — turn_modes 의 index 0 = defense 모드. 받는 damage 50%.
	if _is_enemy_in_defense_mode(enemy_index):
		ctx.mitigation.append(0.5)
	# dynamic_resistance (Kunino Quad-Converge 영감) — current_weakness 와 damage_type 불일치 시 0.2배
	var _cur_weak: String = _enemy_status[enemy_index].get("current_weakness", "")
	if _cur_weak != "" and damage_type != "" and damage_type != _cur_weak:
		ctx.mitigation.append(0.2)
	var amount: int = compute_damage(ctx)
	var absorbed: int = min(_enemy_block[enemy_index], amount)
	_enemy_block[enemy_index] -= absorbed
	amount -= absorbed
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - amount)
	enemy_damaged.emit(enemy_index, amount, damage_type, is_crit)
	# T3-MIMIC: 플레이어 턴 동안 가한 데미지 누적 (MIMIC 인텐트가 비율로 반사)
	if amount > 0 and _in_player_turn:
		_player_damage_this_turn += amount
	# T3-COUNTER: counter_ratio 설정된 적은 받은 데미지의 N% counter_pool에 누적
	if amount > 0:
		var counter_ratio: float = _enemy_status[enemy_index].get("counter_ratio", 0.0)
		if counter_ratio > 0.0:
			_enemy_status[enemy_index]["counter_pool"] = _enemy_status[enemy_index].get("counter_pool", 0) + int(amount * counter_ratio)
	# 시그니처 hook: 받음 (휴브리스/라그나로크/damage_taken 누적)
	if amount > 0:
		SignatureSys.on_enemy_damaged(self, enemy_index, amount)
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		_remove_from_queue(_actor_id_for_enemy(enemy_index))
		_kills_this_card += 1
		_fire_death_trigger(enemy_index)
		# 시그니처 hook: 사망 (불교 인과응보)
		SignatureSys.on_enemy_death(self, enemy_index)
		_cleanup_enemy_status_on_death(enemy_index)
		enemy_died.emit(enemy_index)
		for _pke in _active_powers:
			if _pke.split(":")[0] == "power.on_kill_energy":
				if deck_mgr:
					deck_mgr.add_energy_h(_active_powers[_pke].get("owner_id", ""), _active_powers[_pke].get("value", 1))
		if source_owner != "" and deck_mgr:
			var bounty: Dictionary = _active_powers.get("power.on_kill_energy_once:" + source_owner, {})
			if not bounty.is_empty() and _use_turn_effect(source_owner, "kill_energy"):
				deck_mgr.add_energy_h(source_owner, bounty.get("value", 1))
		# 황제의 무도 (나폴레옹×무사시): 무사시가 처치해 적이 1명만 남으면 나폴레옹 사기 +2 (차례당 1회)
		if duel_owner == "musashi" and _get_living_enemy_count() == 1 and team_mgr.is_alive("napoleon") and _use_turn_effect("musashi", "synergy_emperor_dance"):
			_grant_morale("napoleon", 2)
			synergy_triggered.emit("synergy.napoleon_musashi.name", "musashi")
	_check_phase_transition(enemy_index)
	_check_win_condition()

func _deal_damage_to_hero(hero_id: String, incoming_amount: float, damage_type: String = "", is_crit: bool = false, from_enemy_index: int = -1, action_block: Dictionary = {}) -> void:
	if debug_hero_invincible:
		return
	if team_mgr == null or not team_mgr.is_alive(hero_id):
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	# ── 받는 측 DamageContext 구성 ──
	var ctx := DamageContext.new()
	ctx.base = incoming_amount
	# vulnerable: 받는 측 +50%
	if status.get("vulnerable", 0) > 0:
		ctx.in_pct += 0.5
	# Fate Duel: the marked enemy's damage is amplified only against its duelist.
	if from_enemy_index >= 0 and from_enemy_index < _enemy_status.size():
		var duel_status: Dictionary = _enemy_status[from_enemy_index]
		if duel_status.get("duel_lock", 0) > 0 and duel_status.get("duel_lock_owner", "") == hero_id:
			ctx.in_pct += 0.5
	# counter_pending: 반감(×0.5)만 mitigation에 추가 — 반사·소진·VFX는 아래에서 그대로 처리
	if status.get("counter_pending", 0) > 0 and from_enemy_index >= 0 and from_enemy_index < _enemies.size():
		ctx.mitigation.append(0.5)
	var amount: int = compute_damage(ctx)
	# counter_pending — 다음 받는 공격 100% 반사 + 1회 소멸 + VFX. (반감은 위 ctx에서 완료)
	if status.get("counter_pending", 0) > 0 and from_enemy_index >= 0 and from_enemy_index < _enemies.size():
		var _reflect_amt: int = int(ctx.base * (1.0 + ctx.in_pct))  # vulnerable 적용 후 반사 (구버전 동작 복원)
		if _enemy_alive[from_enemy_index]:
			_deal_damage_to_enemy(from_enemy_index, _reflect_amt, damage_type)
		_hero_status[hero_id]["counter_pending"] = 0
		status_applied.emit(hero_id, "counter_pending", 0)
		# 적 공격 VFX 의 hit reaction 후 counter VFX 발동 (시각 분리)
		var _ct_hid: String = hero_id
		var _ct_ei: int = from_enemy_index
		if is_inside_tree():
			get_tree().create_timer(0.2).timeout.connect(func() -> void:
				counter_triggered.emit(_ct_hid, _ct_ei, false))
	# 독침 반격 (이순신×클레오파트라): 파티원 피격 시 클레오파트라가 공격한 적에 독 30 반격.
	# 적 공격 impact 이후 — 클레오 → 적 독 VFX, VFX 임팩트 시점에 poison 적용 (battle_scene).
	if from_enemy_index >= 0 and from_enemy_index < _enemies.size() and _enemy_alive[from_enemy_index] and team_mgr.is_alive("yi_sun_sin") and team_mgr.is_alive("cleopatra"):
		synergy_triggered.emit("synergy.yi_cleopatra.name", hero_id)
		if is_inside_tree():
			var _vc_ei: int = from_enemy_index
			get_tree().create_timer(0.2).timeout.connect(func() -> void:
				if _vc_ei < _enemy_alive.size() and _enemy_alive[_vc_ei]:
					synergy_counter_vfx.emit("cleopatra", _vc_ei, "poison", _combat_literal(30)))
		else:
			_apply_status_to_enemy(from_enemy_index, "poison", _combat_literal(30))  # 테스트 환경 — VFX 없이 즉시
	var block: int = _hero_block.get(hero_id, 0)
	var absorbed: int = min(block, amount)
	_hero_block[hero_id] = block - absorbed
	# Consume the pre-attack pool first. Reactive Block gained below belongs to
	# the next attack and must not be erased when this action finishes.
	if action_block.has(hero_id):
		action_block[hero_id] = maxi(0, int(action_block[hero_id]) - absorbed)
	amount -= absorbed
	if amount > 0:
		damage_taken_this_battle += amount
		team_mgr.take_damage(hero_id, amount)
		var _gm_hd = _get_gm()
		if _gm_hd and _gm_hd.is_inside_tree():
			_gm_hd.trigger_relics(RelicRes.TriggerType.ON_HERO_DAMAGED,
				{"hero_id": hero_id, "amount": amount})
	hero_damaged.emit(hero_id, amount, damage_type, is_crit)
	# 영웅 사망 시 보유 토큰 전멸
	if not team_mgr.is_alive(hero_id) and _hero_status.has(hero_id):
		_hero_status[hero_id]["tokens"] = 0
		status_applied.emit(hero_id, "tokens", 0)
	_check_lose_condition()

func _apply_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
	if status_type == "poison":
		_enemy_status[enemy_index]["poison_dmg"] = _enemy_status[enemy_index].get("poison_dmg", 0) + stacks
		_enemy_status[enemy_index]["poison_dur"] = 3
	elif status_type == "taunt":
		# 도발 — source 는 _apply_taunt_to_enemy 가 별도로 처리하므로 여기서는 단순 max 만.
		# (직접 호출 시 fallback. 일반 흐름에선 _apply_taunt_to_enemy 사용.)
		var cur: int = _enemy_status[enemy_index].get("taunt", 0)
		_enemy_status[enemy_index]["taunt"] = max(cur, stacks)
	elif status_type == "charm":
		var new_charm: int = _enemy_status[enemy_index].get("charm", 0) + stacks
		# power.charm_threshold_minus: 임계치 하향 (모든 영웅의 합산)
		var _charm_reduce: int = 0
		for _cpk in _active_powers:
			if _cpk.begins_with("power.charm_threshold_minus:"):
				_charm_reduce += _active_powers[_cpk].get("value", 0)
		var threshold: int = max(1, _combat_literal(CHARM_THRESHOLD_BASE) + _enemy_status[enemy_index].get("charm_resistance", 0) - _charm_reduce)
		if new_charm >= threshold:
			_enemy_status[enemy_index]["charm"] = 0
			_enemy_status[enemy_index]["enthrall"] = _enemy_status[enemy_index].get("enthrall", 0) + 1
			status_applied.emit("enemy_%d" % enemy_index, "enthrall", 1)
			_enthralls_this_card += 1
			_trigger_active_powers("on_enthrall", {"enemy_index": enemy_index})
			return
		else:
			_enemy_status[enemy_index]["charm"] = new_charm
	else:
		_enemy_status[enemy_index][status_type] = _enemy_status[enemy_index].get(status_type, 0) + stacks
	status_applied.emit("enemy_%d" % enemy_index, status_type, stacks)

# 파라오의 독력: 남은 에너지를 한 번에 비우고, 이미 걸린 독만
# 에너지당 2배(2 * spent)로 선형 증폭한다. 새 독을 만들거나 권능을 남기지 않는다.
func _spend_all_energy_poison_double(owner_id: String) -> void:
	if deck_mgr == null:
		return
	var spent: int = deck_mgr.get_energy(owner_id)
	if spent <= 0:
		return
	deck_mgr.set_energy_h(owner_id, 0)
	var multiplier: int = spent * 2
	for enemy_index in range(_enemies.size()):
		if not _enemy_alive[enemy_index]:
			continue
		var status: Dictionary = _enemy_status[enemy_index]
		if status.get("poison_dmg", 0) <= 0 or status.get("poison_dur", 0) <= 0:
			continue
		status["poison_dmg"] = int(status["poison_dmg"]) * multiplier
		status_applied.emit("enemy_%d" % enemy_index, "poison", status["poison_dmg"])

# 운명의 결투: 지정 적과 시전 영웅 사이의 피해만 +50%. 적 자신의 차례가
# 끝날 때 하나씩 줄어들어 value=3이면 적의 세 번 행동에 정확히 적용된다.
func _apply_duel_lock(enemy_index: int, owner_id: String, turns: int) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_status.size() or not _enemy_alive[enemy_index] or turns <= 0:
		return
	var status: Dictionary = _enemy_status[enemy_index]
	if status.get("duel_lock_owner", "") == owner_id:
		status["duel_lock"] = max(int(status.get("duel_lock", 0)), turns)
	else:
		status["duel_lock"] = turns
		status["duel_lock_owner"] = owner_id
	status_applied.emit("enemy_%d" % enemy_index, "duel_lock", status["duel_lock"])


# 시너지 VFX 임팩트 시점에 battle_scene 이 호출 — 상태이상 적용 (status_applied → 폰트 동기).
func apply_synergy_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
	if enemy_index >= 0 and enemy_index < _enemy_alive.size() and _enemy_alive[enemy_index]:
		_apply_status_to_enemy(enemy_index, status_type, stacks)

# 속도 버프 — speed_bonus 스택 추가 + 턴 큐 갱신 + status_applied(상태 아이콘). 시너지·릴릭 공용.
func apply_speed_bonus(hero_id: String, value: int, dur: int) -> void:
	var _aid: String = "hero:" + hero_id
	var _old: int = _actor_speed(_aid)
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	if not _hero_status[hero_id].has("speed_bonus") or typeof(_hero_status[hero_id]["speed_bonus"]) != TYPE_ARRAY:
		_hero_status[hero_id]["speed_bonus"] = []
	_hero_status[hero_id]["speed_bonus"].append({"value": value, "dur": dur})
	_adjust_turn_queue_for_speed_change(_aid, _old)
	status_applied.emit(hero_id, "speed_bonus", value)

# 시너지 아군 효과 — battle_scene 이 VFX 임팩트 시점에 호출 (heal / speed_buff).
func apply_synergy_ally_effect(vfx_kind: String, hero_id: String, value: int, duration: int) -> void:
	if team_mgr == null or not team_mgr.is_alive(hero_id):
		return
	if vfx_kind == "heal":
		_heal_hero_safe(hero_id, value)
	elif vfx_kind == "speed_buff":
		apply_speed_bonus(hero_id, value, duration)
	elif vfx_kind == "morale":
		if not _hero_status.has(hero_id):
			_hero_status[hero_id] = {}
		var _m: int = _hero_status[hero_id].get("morale", 0) + value
		_hero_status[hero_id]["morale"] = _m
		morale_changed.emit(hero_id, _m)

# 영웅이 적에게 도발 부여 — source 비교로 누적/덮어쓰기 결정.
# - 같은 source (이미 그 영웅이 도발 중) → 지속 시간 합산 (스택 누적)
# - 다른 source → 기존 덮어쓰기 (max 가 아니라 value 로 강제 갱신) + source 교체
# - 신규 → value 설정 + source 등록
func _apply_taunt_to_enemy(enemy_index: int, value: int, source_hero_id: String) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return
	var cur_src: String = _enemy_status[enemy_index].get("taunt_source", "")
	var cur_val: int = _enemy_status[enemy_index].get("taunt", 0)
	if cur_src == source_hero_id and cur_val > 0:
		# 같은 시전자 — 누적
		_enemy_status[enemy_index]["taunt"] = cur_val + value
	else:
		# 다른 시전자 또는 신규 — 덮어쓰기 + source 교체
		_enemy_status[enemy_index]["taunt"] = value
		_enemy_status[enemy_index]["taunt_source"] = source_hero_id
	status_applied.emit("enemy_%d" % enemy_index, "taunt", _enemy_status[enemy_index]["taunt"])

# 적이 영웅에게 도발 부여 — 대칭 로직.
func _apply_taunt_to_hero(hero_id: String, value: int, source_enemy_index: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	var cur_src: int = _hero_status[hero_id].get("taunt_source", -1)
	var cur_val: int = _hero_status[hero_id].get("taunt", 0)
	if cur_src == source_enemy_index and cur_val > 0:
		_hero_status[hero_id]["taunt"] = cur_val + value
	else:
		_hero_status[hero_id]["taunt"] = value
		_hero_status[hero_id]["taunt_source"] = source_enemy_index
	status_applied.emit(hero_id, "taunt", _hero_status[hero_id]["taunt"])

# Legacy 호환 (테스트가 직접 호출). 신규 코드는 _apply_taunt_to_enemy 사용 권장.
func _set_enemy_taunt_source(enemy_index: int, hero_id: String) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return
	_enemy_status[enemy_index]["taunt_source"] = hero_id

# FORM_SWITCH helper: 현재 mode 가 turn_modes 의 첫 항목 (index 0) 이면 "defense" 로 간주.
# defense 모드 보스: 받는 damage 50%. offense 모드: 주는 damage 1.5x (apply_offense_bonus).
func _is_enemy_in_defense_mode(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return false
	var src: Resource = _enemies[enemy_index]
	var modes: Array = src.get("turn_modes") if src.get("turn_modes") != null else []
	if modes.is_empty():
		return false
	var cur_idx: int = _enemy_status[enemy_index].get("current_mode_index", 0)
	return cur_idx == 0  # turn_modes[0] = defense (관습)

# FORM_SWITCH offense 모드: 주는 damage 1.5x.
func _is_enemy_in_offense_mode(enemy_index: int) -> bool:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return false
	var src: Resource = _enemies[enemy_index]
	var modes: Array = src.get("turn_modes") if src.get("turn_modes") != null else []
	if modes.is_empty():
		return false
	var cur_idx: int = _enemy_status[enemy_index].get("current_mode_index", 0)
	return cur_idx > 0  # index >= 1 = offense

# CHANGE_AFFINITY override: 보스의 current_affinity 가 있으면 그것으로 damage_type 대체.
func _resolve_enemy_damage_type(enemy_index: int, intent_damage_type: String) -> String:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return intent_damage_type
	var override: String = _enemy_status[enemy_index].get("current_affinity", "")
	return override if override != "" else intent_damage_type

# heal 시 heal_block status 가 있으면 차단 (Dualliste Inverted 영감).
# 반환: 실제 회복 적용 여부 (true) / 차단 (false).
func _heal_hero_safe(hero_id: String, amount: int) -> bool:
	if _hero_status.get(hero_id, {}).get("heal_block", 0) > 0:
		return false
	if team_mgr == null:
		return false
	var before_hp: int = team_mgr.get_current_hp(hero_id)
	team_mgr.heal(hero_id, amount)
	var healed: int = team_mgr.get_current_hp(hero_id) - before_hp
	_team_healed_turn += healed
	_team_healed_battle += healed
	# 성전 (잔다르크×나폴레옹): 잔다르크 차례에 실제로 회복시키면 나폴레옹 사기 +1 (차례당 1회)
	if healed > 0 and get_current_hero_id() == "joan_of_arc" and team_mgr.is_alive("napoleon") and _use_turn_effect("joan_of_arc", "synergy_holy_war"):
		_grant_morale("napoleon", 1)
		synergy_triggered.emit("synergy.joan_napoleon.name", "joan_of_arc")
	# 성녀의 방패 (성녀×통제사): 힐 적용 시 대상 방어구 +30
	if amount > 0 and team_mgr.is_alive("joan_of_arc") and team_mgr.is_alive("yi_sun_sin"):
		_hero_block[hero_id] = _hero_block.get(hero_id, 0) + _combat_literal(30)
		hero_block_vfx.emit(hero_id)
		synergy_triggered.emit("synergy.joan_yi.name", hero_id)
	return true

func _apply_status_to_hero(hero_id: String, status_type: String, stacks: int) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	if status_type == "poison":
		_hero_status[hero_id]["poison_dmg"] = _hero_status[hero_id].get("poison_dmg", 0) + stacks
		_hero_status[hero_id]["poison_dur"] = 3
	elif status_type == "counter_pending":
		# 카운터 준비 — 중첩 X (binary). 항상 1 로 set.
		_hero_status[hero_id][status_type] = 1
	else:
		_hero_status[hero_id][status_type] = _hero_status[hero_id].get(status_type, 0) + stacks
	status_applied.emit(hero_id, status_type, stacks)

func _tick_hero_poison(hero_id: String) -> void:
	if debug_hero_invincible:
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	var dmg: int = status.get("poison_dmg", 0)
	var dur: int = status.get("poison_dur", 0)
	if dmg <= 0 or dur <= 0:
		return
	var tick_amt: int = dmg
	team_mgr.take_damage(hero_id, tick_amt)
	# 데미지 popup 표시용 — battle_scene._on_hero_damaged 가 popup·VFX 처리 (_tick_enemy_poison 대칭)
	hero_damaged.emit(hero_id, tick_amt, "poison", false)
	poison_tick_applied.emit(hero_id, tick_amt)
	dur -= 1
	if dur <= 0:
		_hero_status[hero_id]["poison_dmg"] = 0
		_hero_status[hero_id]["poison_dur"] = 0
	else:
		_hero_status[hero_id]["poison_dur"] = dur
	_check_lose_condition()

func _tick_enemy_poison(enemy_index: int) -> void:
	var dmg: int = _enemy_status[enemy_index].get("poison_dmg", 0)
	var dur: int = _enemy_status[enemy_index].get("poison_dur", 0)
	if dmg <= 0 or dur <= 0:
		return
	var tick_dmg: int = _consume_double_next_damage(dmg)
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - tick_dmg)
	enemy_damaged.emit(enemy_index, tick_dmg, "poison", false)
	poison_tick_applied.emit("enemy_%d" % enemy_index, tick_dmg)
	SignatureSys.on_enemy_damaged(self, enemy_index, tick_dmg)
	dur -= 1
	if dur <= 0:
		_enemy_status[enemy_index]["poison_dmg"] = 0
		_enemy_status[enemy_index]["poison_dur"] = 0
	else:
		_enemy_status[enemy_index]["poison_dur"] = dur
	if _enemy_hp[enemy_index] == 0:
		_enemy_alive[enemy_index] = false
		_remove_from_queue(_actor_id_for_enemy(enemy_index))
		_fire_death_trigger(enemy_index)
		SignatureSys.on_enemy_death(self, enemy_index)
		_cleanup_enemy_status_on_death(enemy_index)
		enemy_died.emit(enemy_index)
		_check_win_condition()

# Legacy 호환 — 테스트가 직접 호출. 모든 생존 적을 순차 진행.
func _execute_enemy_turn() -> void:
	if not is_battle_active:
		return
	enemy_turn_started.emit()
	var first: bool = true
	for i in range(_enemies.size()):
		if not _enemy_alive[i]:
			continue
		if not first and turn_interval > 0.0:
			await get_tree().create_timer(turn_interval * _turn_interval_mul()).timeout
		first = false
		await _run_one_enemy_turn(i, true)  # legacy 모드: 큐 카운터 진행 스킵
	_check_win_condition()
	_check_lose_condition()

# 단일 적 차례 처리 — 본인 차례 시작 (status -1, 시그니처 hook, charm, intent 실행).
# legacy=true 면 _advance_turn_counter 스킵 (테스트 호환용).
func _run_one_enemy_turn(i: int, legacy: bool = false) -> void:
	if not is_battle_active:
		return
	if i < 0 or i >= _enemies.size() or not _enemy_alive[i]:
		return
	if not legacy:
		_current_actor_id = _actor_id_for_enemy(i)
		_in_player_turn = false  # MIMIC 트래커 게이트 종료
		enemy_turn_started.emit()
		turn_started.emit(_current_actor_id)
		# 적 차례 시작 인터벌 — 사용자가 적 차례 인식 시간 (영웅 차례보다 짧게 느껴지지 않게 2배)
		if turn_interval > 0.0:
			await get_tree().create_timer(turn_interval * 2.0 * _turn_interval_mul()).timeout
		if not is_battle_active:
			return
	# time_limit (Okumura 영감) — turn_count 초과 시 광폭화 strength +5/turn 누적
	var _tlsrc: Resource = _enemies[i]
	var _tlturns: int = int(_tlsrc.get("time_limit_turns")) if _tlsrc.get("time_limit_turns") != null else 0
	if _tlturns > 0 and turn_count >= _tlturns:
		gain_authored_enemy_strength(i, 5, "time_limit")
	# dynamic_resistance (Kunino Quad-Converge 영감) — 매 enemy turn 시작 시 풀에서 1개 픽
	var _drpool: Array = _tlsrc.get("dynamic_resistance_pool") if _tlsrc.get("dynamic_resistance_pool") != null else []
	if not _drpool.is_empty():
		_enemy_status[i]["current_weakness"] = _drpool[randi() % _drpool.size()]
		status_applied.emit("enemy_%d" % i, "current_weakness", 1)
	# 시그니처 hook: 턴 시작 (휴브리스 pending 처리, 도교 음양, 일본 결계)
	# emit 된 passive_buff_applied 횟수만큼 VFX impact 대기 — 후속 intent VFX 와 순차 처리
	var _sig_buffs: int = SignatureSys.on_enemy_turn_start(self, i)
	for _b in range(_sig_buffs):
		await _await_vfx_impact(_VFX_WARRIOR_BUFF.IMPACT_DELAY + 0.5)
		if not is_battle_active:
			return
	# weak/vulnerable: 자기 턴 시작 시 -1 (즉시 본인 행동에 영향 없음 — 표준 디버프 decay)
	# taunt: 부여 시점부터 N turn 유지가 자연스러우므로 turn 종료 시점에 decay (아래 turn_ended 직전)
	for stype: String in ["vulnerable"]:
		if _enemy_status[i].get(stype, 0) > 0:
			_enemy_status[i][stype] -= 1
	# speed_bonus / speed_penalty — Array of {value, dur}. 각 instance dur -1, dur<=0 제거
	for key in ["speed_bonus", "speed_penalty"]:
		var arr_e: Array = _enemy_status[i].get(key, [])
		if arr_e.is_empty():
			continue
		var kept_e: Array = []
		for ins in arr_e:
			var new_dur_e: int = int(ins.get("dur", 0)) - 1
			if new_dur_e > 0:
				kept_e.append({"value": int(ins.get("value", 0)), "dur": new_dur_e})
		_enemy_status[i][key] = kept_e
	# 본인 poison tick (영웅이 가한 독 — 본인 차례 시작 시 발동)
	var p_dmg: int = _enemy_status[i].get("poison_dmg", 0)
	var p_dur: int = _enemy_status[i].get("poison_dur", 0)
	if p_dmg > 0 and p_dur > 0:
		_tick_enemy_poison(i)
		# 독 적용 후 인터벌 — 공격과 분리해서 인식 시간 (2x — 독 데미지 popup 시각 확인 시간)
		if not legacy and turn_interval > 0.0:
			await get_tree().create_timer(turn_interval * 2.0 * _turn_interval_mul()).timeout
		if not _enemy_alive[i]:
			if not legacy:
				_advance_turn_counter(_current_actor_id)
				turn_ended.emit(_current_actor_id)
				_current_actor_id = ""
			return
	# T3-WARD: invuln 카운트 매 턴 감소 (만료 시 0)
	if _enemy_status[i].get("invuln", 0) > 0:
		_enemy_status[i]["invuln"] -= 1
	var charm: int = _enemy_status[i].get("charm", 0)
	var _charm_reduce_turn: int = 0
	for _cpk2 in _active_powers:
		if _cpk2.begins_with("power.charm_threshold_minus:"):
			_charm_reduce_turn += _active_powers[_cpk2].get("value", 0)
	var charm_threshold: int = max(1, _combat_literal(CHARM_THRESHOLD_BASE) + _enemy_status[i].get("charm_resistance", 0) - _charm_reduce_turn)
	if charm >= charm_threshold:
		_enemy_status[i]["charm"] = 0
		_enemy_status[i]["enthrall"] = _enemy_status[i].get("enthrall", 0) + 1
		status_applied.emit("enemy_%d" % i, "enthrall", 1)
		_trigger_active_powers("on_enthrall", {"enemy_index": i})
	var enthrall: int = _enemy_status[i].get("enthrall", 0)
	if enthrall > 0:
		_enemy_status[i]["enthrall"] = enthrall - 1
		status_applied.emit("enemy_%d" % i, "enthrall", _enemy_status[i]["enthrall"])
		var other_targets: Array = []
		for j in range(_enemies.size()):
			if j != i and _enemy_alive[j]:
				other_targets.append(j)
		if not other_targets.is_empty():
			var target_j: int = other_targets[randi() % other_targets.size()]
			var charm_pattern: Array = _get_active_pattern(i)
			if not charm_pattern.is_empty():
				var charm_intent: Resource = charm_pattern[_enemy_intent_index[i]]
				if charm_intent.action_type == IntentRes.ActionType.ATTACK:
					_deal_damage_to_enemy(target_j, charm_intent.value)
		var charm_pat: Array = _get_active_pattern(i)
		if not charm_pat.is_empty():
			_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % charm_pat.size()
	elif i < _enemy_status.size() and _enemy_status[i].get("stun", 0) > 0:
		# 스턴 — 이번 turn skip + stun -1. intent advance 도 차단.
		_enemy_status[i]["stun"] = max(0, _enemy_status[i]["stun"] - 1)
		var _new_stun: int = _enemy_status[i]["stun"]
		status_applied.emit("enemy_%d" % i, "stun", _new_stun)
		# STUN popup 페이드 시간만큼 대기 (남은 스턴이 있을 때만 popup 표시됨)
		if _new_stun > 0:
			await get_tree().create_timer(0.9).timeout
	else:
		var pattern: Array = _get_active_pattern(i)
		if not pattern.is_empty():
			var intent: Resource = pattern[_enemy_intent_index[i]]
			_vfx_caster = i  # 이 적이 공격자 — lightning 등 빔 VFX 시전자 좌표용
			await _execute_intent(i, intent)
			_vfx_caster = null
			# CHARGE_UP 진행 중이면 같은 intent 유지 (advance 차단)
			if i < _enemy_status.size() and _enemy_status[i].get("_charge_block_advance", false):
				_enemy_status[i].erase("_charge_block_advance")
			else:
				_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern.size()
			# double_action (Renoir/Izanami Enrage 영감) — 적이 같은 turn 안 한 번 더 행동.
			# 매 사용 시 1 decrement. 적 사망 시 skip.
			if i < _enemy_status.size() and _enemy_alive[i] and _enemy_status[i].get("double_action", 0) > 0:
				_enemy_status[i]["double_action"] -= 1
				var pattern2: Array = _get_active_pattern(i)
				if not pattern2.is_empty():
					var intent2: Resource = pattern2[_enemy_intent_index[i]]
					_vfx_caster = i
					await _execute_intent(i, intent2)
					_vfx_caster = null
					if i < _enemy_status.size() and _enemy_status[i].get("_charge_block_advance", false):
						_enemy_status[i].erase("_charge_block_advance")
					else:
						_enemy_intent_index[i] = (_enemy_intent_index[i] + 1) % pattern2.size()
	# 적 turn 종료 시 도발 decay — 부여 시점부터 N turn 유지 보장 (시작 decay 대신).
	if i < _enemy_status.size():
		if _enemy_status[i].get("weak", 0) > 0:
			_enemy_status[i]["weak"] -= 1
		var t_cur: int = _enemy_status[i].get("taunt", 0)
		if t_cur > 0:
			_enemy_status[i]["taunt"] = t_cur - 1
			if _enemy_status[i]["taunt"] == 0 and _enemy_status[i].has("taunt_source"):
				_enemy_status[i].erase("taunt_source")
				status_applied.emit("enemy_%d" % i, "taunt", 0)
		var duel_turns: int = _enemy_status[i].get("duel_lock", 0)
		if duel_turns > 0:
			_enemy_status[i]["duel_lock"] = duel_turns - 1
			if _enemy_status[i]["duel_lock"] <= 0:
				_enemy_status[i].erase("duel_lock_owner")
			status_applied.emit("enemy_%d" % i, "duel_lock", _enemy_status[i]["duel_lock"])
	if not legacy:
		if is_battle_active:
			_advance_turn_counter(_current_actor_id)
		turn_ended.emit(_current_actor_id)
		_current_actor_id = ""

func _execute_intent(enemy_index: int, intent: Resource) -> void:
	# One action includes every CHARGE_UP payoff hit, but not double_action's
	# separate next intent. Local state also keeps overlapping death triggers
	# from clearing another action's targets.
	var action_block: Dictionary = {}
	await _execute_intent_effects(enemy_index, intent, action_block)
	for hero_id: String in action_block:
		_spend_block(hero_id, int(action_block[hero_id]))

func _execute_intent_effects(enemy_index: int, intent: Resource, action_block: Dictionary) -> void:
	# 단일 타겟 인텐트는 시그널 emit 전에 영웅 타겟 미리 결정 — battle_scene 이 정확한 영웅 위치에 VFX 표시
	var pre_target_id: String = ""
	if intent.target != IntentRes.TargetType.ALL:
		# 영웅 공격성 인텐트 모두 action_type 전달 → _pick_hero_target 의 도발 우회 작동
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				pre_target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.ATTACK)
			IntentRes.ActionType.DEBUFF:
				pre_target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.DEBUFF)
			IntentRes.ActionType.MARK_TARGET:
				pre_target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.MARK_TARGET)
			IntentRes.ActionType.MIMIC:
				pre_target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.MIMIC)
	# VFX 차지 시작 — battle_scene 이 받아 caster→target VFX 재생
	intent_vfx_charge_start.emit(enemy_index, intent, pre_target_id)
	var _delay := _intent_vfx_impact_delay(intent)
	if _delay > 0.0:
		# popup·SFX 동기화: fx.screen_effect 시점까지 대기 (fallback timer = _delay + 0.5s)
		await _await_vfx_impact(_delay + 0.5)
		# 차지 중 전투 종료 / 적 사망 시 데미지 적용 스킵
		if not is_battle_active:
			return
		if enemy_index >= 0 and enemy_index < _enemy_alive.size() and not _enemy_alive[enemy_index]:
			return
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			# ── 공격자 측 DamageContext 구성 ──
			var _atk_ctx := DamageContext.new()
			_atk_ctx.base = intent.value
			# strength: 곱연산 → flat 합연산 (영웅 strength 와 동작 통일)
			_atk_ctx.flat = _enemy_status[enemy_index].get("strength", 0)
			# T3-COUNTER: 누적된 counter_pool 가산 후 소진
			var counter_pool: int = _enemy_status[enemy_index].get("counter_pool", 0)
			if counter_pool > 0:
				_atk_ctx.flat += counter_pool
				_enemy_status[enemy_index]["counter_pool"] = 0
				_enemy_status[enemy_index]["counter_ratio"] = 0.0
			# weak: −25%, FORM_SWITCH offense: +50% (out_pct 합산)
			if _enemy_status[enemy_index].get("weak", 0) > 0:
				_atk_ctx.out_pct -= 0.25
			# FORM_SWITCH offense — turn_modes index >= 1 = offense, 주는 damage 1.5x
			if _is_enemy_in_offense_mode(enemy_index):
				_atk_ctx.out_pct += 0.5
			# CHANGE_AFFINITY override — intent.damage_type 대신 current_affinity 사용
			var resolved_dmg_type: String = _resolve_enemy_damage_type(enemy_index, intent.damage_type)
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						# 치명타: 영웅 status.marked_by 비어있지 않으면 +30%
						var _all_hm: bool = not _hero_status.get(hero.hero_id, {}).get("marked_by", []).is_empty()
						var _all_crit_e: Dictionary = _roll_crit_enemy(_all_hm)
						_atk_ctx.crit_mult = _all_crit_e["crit_mult"]
						var _all_outgoing: float = _outgoing_damage(_atk_ctx)
						if not action_block.has(hero.hero_id):
							action_block[hero.hero_id] = _hero_block.get(hero.hero_id, 0)
						_deal_damage_to_hero(hero.hero_id, _all_outgoing, resolved_dmg_type, _all_crit_e["is_crit"], enemy_index, action_block)
				_trigger_active_powers("enemy_attack", {"enemy_index": enemy_index, "target_hero_id": ""})
			else:
				# 미리 결정된 타겟 사용 (사망 시 fallback 으로 재결정)
				var target_id: String = pre_target_id
				if target_id == "" or (team_mgr and not team_mgr.is_alive(target_id)):
					target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.ATTACK)
				if target_id != "":
					# 치명타: 영웅 status.marked_by 비어있지 않으면 +30% (마킹한 적 한정 X — 모든 적)
					var has_mark: bool = not _hero_status.get(target_id, {}).get("marked_by", []).is_empty()
					var crit_result_e: Dictionary = _roll_crit_enemy(has_mark)
					_atk_ctx.crit_mult = crit_result_e["crit_mult"]
					var outgoing: float = _outgoing_damage(_atk_ctx)
					if not action_block.has(target_id):
						action_block[target_id] = _hero_block.get(target_id, 0)
					_deal_damage_to_hero(target_id, outgoing, resolved_dmg_type, crit_result_e["is_crit"], enemy_index, action_block)
					# 시그니처 hook: 적의 단일 타겟 공격 (이집트 저주 누적)
					SignatureSys.on_enemy_attack(self, enemy_index, target_id)
				_trigger_active_powers("enemy_attack", {"enemy_index": enemy_index, "target_hero_id": target_id})
		IntentRes.ActionType.BUFF:
			if intent.status_type == "block" or intent.status_type == "":
				_enemy_block[enemy_index] += intent.value
			elif intent.status_type in ["speed_bonus", "speed_penalty"]:
				# 일정 효과 — value=강도, duration=지속 턴. instance append (누적)
				var _bs_aid: String = "enemy:%d" % enemy_index
				var _bs_old_sp: int = _actor_speed(_bs_aid)
				if not _enemy_status[enemy_index].has(intent.status_type) or typeof(_enemy_status[enemy_index][intent.status_type]) != TYPE_ARRAY:
					_enemy_status[enemy_index][intent.status_type] = []
				_enemy_status[enemy_index][intent.status_type].append({"value": intent.value, "dur": max(1, intent.duration)})
				_adjust_turn_queue_for_speed_change(_bs_aid, _bs_old_sp)
				status_applied.emit(_bs_aid, intent.status_type, intent.value)
			else:
				_apply_status_to_enemy(enemy_index, intent.status_type, intent.value)
		IntentRes.ActionType.DEBUFF:
			var stype: String = intent.status_type
			var _is_speed: bool = stype in ["speed_bonus", "speed_penalty"]
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						if _is_speed:
							var _ds_aid: String = "hero:" + hero.hero_id
							var _ds_old_sp: int = _actor_speed(_ds_aid)
							if not _hero_status.has(hero.hero_id):
								_hero_status[hero.hero_id] = {}
							if not _hero_status[hero.hero_id].has(stype) or typeof(_hero_status[hero.hero_id][stype]) != TYPE_ARRAY:
								_hero_status[hero.hero_id][stype] = []
							_hero_status[hero.hero_id][stype].append({"value": intent.value, "dur": max(1, intent.duration)})
							_adjust_turn_queue_for_speed_change(_ds_aid, _ds_old_sp)
							status_applied.emit(hero.hero_id, stype, intent.value)
						else:
							_apply_status_to_hero(hero.hero_id, stype, intent.value)
			else:
				var target_id: String = pre_target_id
				if target_id == "" or (team_mgr and not team_mgr.is_alive(target_id)):
					target_id = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.DEBUFF)
				if target_id != "":
					if _is_speed:
						var _ds_aid2: String = "hero:" + target_id
						var _ds_old_sp2: int = _actor_speed(_ds_aid2)
						if not _hero_status.has(target_id):
							_hero_status[target_id] = {}
						if not _hero_status[target_id].has(stype) or typeof(_hero_status[target_id][stype]) != TYPE_ARRAY:
							_hero_status[target_id][stype] = []
						_hero_status[target_id][stype].append({"value": intent.value, "dur": max(1, intent.duration)})
						_adjust_turn_queue_for_speed_change(_ds_aid2, _ds_old_sp2)
						status_applied.emit(target_id, stype, intent.value)
					elif stype == "taunt":
						# 적 부여 도발 — 같은 적 추가 부여 시 누적, 다른 적이면 덮어쓰기.
						_apply_taunt_to_hero(target_id, intent.value, enemy_index)
					else:
						_apply_status_to_hero(target_id, stype, intent.value)
		IntentRes.ActionType.SPECIAL:
			_execute_special(enemy_index, intent)
		IntentRes.ActionType.PREPARE:
			pass  # 준비 턴 — 아무 효과 없음
		IntentRes.ActionType.CHARGE_UP:
			# N턴 숨고르기. 첫 진입 시 charge_remaining 초기화. 매 적 턴 -1.
			# 0 도달 시 payoff_intents 순차 실행 + advance 정상. 그 외엔 advance 차단.
			if enemy_index < _enemy_status.size():
				var c_st: Dictionary = _enemy_status[enemy_index]
				if not c_st.has("charge_remaining"):
					c_st["charge_remaining"] = max(1, intent.charge_turns)
				c_st["charge_remaining"] = int(c_st["charge_remaining"]) - 1
				if c_st["charge_remaining"] > 0:
					c_st["_charge_block_advance"] = true  # caller 가 advance skip + flag erase
				else:
					c_st.erase("charge_remaining")
					for payoff in intent.payoff_intents:
						if payoff != null:
							await _execute_intent_effects(enemy_index, payoff, action_block)
		IntentRes.ActionType.HEAL_ALLY:
			# 동료 1명 HP 회복 (target=LOWEST_HP 우선, 그 외 무작위)
			var target_idx: int = -1
			if intent.target == IntentRes.TargetType.LOWEST_HP:
				target_idx = InteractionSys.pick_lowest_hp_ally(self, enemy_index)
			else:
				target_idx = InteractionSys.pick_random_ally(self, enemy_index)
			if target_idx >= 0:
				InteractionSys.heal_ally(self, enemy_index, target_idx, intent.value)
		IntentRes.ActionType.BUFF_ALLY:
			# 동료 1명에게 status 부여 (strength/block/weak 무관 status_type 따름)
			var target_idx: int = -1
			if intent.target == IntentRes.TargetType.LOWEST_HP:
				target_idx = InteractionSys.pick_lowest_hp_ally(self, enemy_index)
			else:
				target_idx = InteractionSys.pick_random_ally(self, enemy_index)
			if target_idx >= 0:
				InteractionSys.buff_ally(self, enemy_index, target_idx, intent.status_type, intent.value)
		IntentRes.ActionType.COUNTER_PREPARE:
			# T3-COUNTER: 다음 ATTACK까지 받은 데미지의 N% 누적 (intent.value = 퍼센트, 30 = 30%)
			_enemy_status[enemy_index]["counter_ratio"] = float(intent.value) / 100.0
			_enemy_status[enemy_index]["counter_pool"] = 0
		IntentRes.ActionType.MARK_TARGET:
			# T3-MARK: 한 영웅 마킹 — 마킹 동안 그 enemy의 ATTACK +50% 데미지
			var mark_target: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.MARK_TARGET)
			if mark_target != "" and team_mgr:
				if not _hero_status.has(mark_target):
					_hero_status[mark_target] = {}
				if not _hero_status[mark_target].has("marked_by"):
					_hero_status[mark_target]["marked_by"] = []
				if not _hero_status[mark_target]["marked_by"].has(enemy_index):
					_hero_status[mark_target]["marked_by"].append(enemy_index)
		IntentRes.ActionType.SACRIFICE:
			# T3-SACRIFICE: 자기 HP -10×value 깎고 strength +value (intent.value = strength gain)
			var hp_cost: int = intent.small_sacrifice_hp_cost if intent.small_sacrifice_hp_cost >= 0 else intent.value * _combat_literal(10)
			_enemy_hp[enemy_index] = max(1, _enemy_hp[enemy_index] - hp_cost)
			_apply_status_to_enemy(enemy_index, "strength", intent.value)
			enemy_damaged.emit(enemy_index, hp_cost, "", false)
		IntentRes.ActionType.WARD:
			# T3-WARD: N턴(intent.value) 동안 자기 invuln (모든 데미지 무시)
			_enemy_status[enemy_index]["invuln"] = intent.value
		IntentRes.ActionType.SUMMON:
			# T3-SUMMON: 같은 mythology 의 normals 모듈에서 팩토리 호출, value 마릿수 spawn
			# intent.status_type = 팩토리 함수 이름 (예: "scarab")
			var src: Resource = _enemies[enemy_index]
			var factory_name: String = intent.status_type
			if factory_name == "" or src == null or src.mythology == "":
				push_warning("[battle_manager] SUMMON 누락: factory_name 또는 mythology 미설정")
			else:
				var module_path: String = "res://resources/enemies/%s/%s_normals.gd" % [src.mythology, src.mythology]
				var module: GDScript = load(module_path)
				if module != null:
					for _i in range(max(1, intent.value)):
						var spawned: Resource = module.call(factory_name, null)
						if spawned != null:
							_add_enemy_to_battle(spawned)
		IntentRes.ActionType.MIMIC:
			# T3-MIMIC: 이전 플레이어 턴 누적 데미지의 N% 반사 (intent.value = 퍼센트, 50 = 50%)
			var ratio: float = float(intent.value) / 100.0
			var dmg: int = int(_player_damage_this_turn * ratio)
			if dmg > 0:
				var target_id: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.ATTACK)
				if target_id != "":
					if not action_block.has(target_id):
						action_block[target_id] = _hero_block.get(target_id, 0)
					_deal_damage_to_hero(target_id, dmg, intent.damage_type, false, enemy_index, action_block)
		IntentRes.ActionType.DISPEL:
			# 영웅 (또는 ALL) 의 status_type 키 제거 — Atlus Dekaja 영감.
			# intent.status_type = 제거할 키 (예: "strength", "block"). 빈 문자열 = 기본 buff 셋 (strength + block).
			var keys_to_remove: Array = [intent.status_type] if intent.status_type != "" else ["strength", "block"]
			var targets: Array = []
			if intent.target == IntentRes.TargetType.ALL:
				if team_mgr:
					for hero in team_mgr.get_living_heroes():
						targets.append(hero.hero_id)
			else:
				var tid: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.DEBUFF)
				if tid != "":
					targets.append(tid)
			for tid in targets:
				if _hero_status.has(tid):
					for k in keys_to_remove:
						_hero_status[tid][k] = 0
						status_applied.emit(tid, k, 0)
		IntentRes.ActionType.FORM_SWITCH:
			# Form 전환 — turn_modes 순환. enemy.turn_modes = ["offense", "defense", ...] 면 status 의 current_mode_index +1.
			# Melancholia Zorba 영감. 효과는 보스별 phase_patterns / damage 처리에서 mode 키 참조.
			var src_enemy: Resource = _enemies[enemy_index]
			var modes: Array = src_enemy.get("turn_modes") if src_enemy.get("turn_modes") != null else []
			if not modes.is_empty():
				var cur_idx: int = _enemy_status[enemy_index].get("current_mode_index", 0)
				var new_idx: int = (cur_idx + 1) % modes.size()
				_enemy_status[enemy_index]["current_mode_index"] = new_idx
				_enemy_status[enemy_index]["current_mode"] = modes[new_idx]
				status_applied.emit("enemy_%d" % enemy_index, "form_" + str(modes[new_idx]), 1)
		IntentRes.ActionType.CHANGE_AFFINITY:
			# 자기 공격 damage_type 동적 변경 — Louis Unlock Affinity 영감.
			# dynamic_affinity_pool 에서 랜덤 1개 픽. 빈 풀이면 4 기본 속성.
			var src_enemy2: Resource = _enemies[enemy_index]
			var pool: Array = src_enemy2.get("dynamic_affinity_pool") if src_enemy2.get("dynamic_affinity_pool") != null else []
			if pool.is_empty():
				pool = ["holy_fire", "holy_strike", "holy_arrow", "holy_slash"]
			var chosen: String = pool[randi() % pool.size()]
			_enemy_status[enemy_index]["current_affinity"] = chosen
			status_applied.emit("enemy_%d" % enemy_index, "affinity_" + chosen, 1)
		IntentRes.ActionType.INFLICT_WEAKNESS:
			# 적이 영웅에 사용 시: 일시적 약점 부여 (영웅이 자기 일시 약점 받음).
			# 영웅 카드 측에서 적에게 사용하는 effect 는 카드 시스템에서 별도 처리.
			# 단순 status 부여 — intent.status_type = 약점 type (예: "weak_fire"), value = N턴
			var tid2: String = _pick_hero_target(intent.target, enemy_index, IntentRes.ActionType.DEBUFF)
			if tid2 != "":
				var st_key: String = intent.status_type if intent.status_type != "" else "weakness_inflicted"
				_apply_status_to_hero(tid2, st_key, intent.value)

# T3-SUMMON: 런타임에 적 1마리를 전투에 추가. 모든 _enemy_* 배열 동기화 + 시그널 발화.
func _add_enemy_to_battle(enemy: Resource) -> void:
	if enemy == null:
		return
	if combat_unit_divisor > 1 and preload("res://resources/balance/combat_scale.gd").enabled():
		enemy = preload("res://resources/balance/enemy_small_numbers.gd").convert(enemy)
	_enemies.append(enemy)
	_enemy_alive.append(true)
	_enemy_hp.append(enemy.max_hp)
	_enemy_block.append(0)
	_enemy_status.append({})
	_enemy_phase.append(0)
	_enemy_intent_index.append(0)
	var new_idx: int = _enemies.size() - 1
	# 큐 등재 — 평균 카운터 + 1턴 비용 (소환 즉시 행동 방지)
	var aid := _actor_id_for_enemy(new_idx)
	var avg: float = 0.0
	var n: int = _turn_queue_at.size()
	if n > 0:
		for v in _turn_queue_at.values():
			avg += v
		avg /= float(n)
	_turn_queue_at[aid] = avg + 1000.0 / max(1, _enemy_effective_speed(new_idx))
	enemy_spawned.emit(new_idx)

# DEATH-RATTLE: 사망 직후 1회 실행. 자기 자신은 이미 _enemy_alive=false 상태이므로
# BUFF_ALLY 등 동료 효과는 자신을 제외한 살아있는 동료에게만 적용됨.
func _fire_death_trigger(enemy_index: int) -> void:
	var enemy: Resource = _enemies[enemy_index]
	if enemy.get("death_trigger") == null:
		return
	_execute_intent(enemy_index, enemy.death_trigger)

# SPECIAL 액션 분기 — status_type 으로 변종 식별.
# 하위 호환: IntentResource.status_type 기본값 "weak"는 DEBUFF용으로, SPECIAL에선 미설정과 동일 취급 → remove_card.
func _execute_special(_enemy_index: int, intent: Resource) -> void:
	var variant: String = intent.status_type
	if variant == "" or variant == "weak":
		variant = "remove_card"
	match variant:
		"remove_card":
			# 카드 이번 전투 동안 빼앗김 — _enemy_stolen_cards 에 보관, 전투 종료 시 draw_pile 복원
			if deck_mgr:
				var pools: Array = [deck_mgr.draw_pile, deck_mgr.hand, deck_mgr.discard_pile]
				var removed_names: Array = []
				for _i in range(intent.value):
					var avail: Array = pools.filter(func(p: Array) -> bool: return not p.is_empty())
					if avail.is_empty():
						break
					var pool: Array = avail[randi() % avail.size()]
					var pick_idx: int = randi() % pool.size()
					var card: Resource = pool[pick_idx]
					pool.remove_at(pick_idx)
					_enemy_stolen_cards.append(card)
					removed_names.append(tr(card.card_name))
				if not removed_names.is_empty():
					cards_exhausted_by_enemy.emit(removed_names)
					deck_mgr.hand_changed.emit()
		_:
			# 잘못된 데이터는 전투를 중단시키지 않고 무시한다. 상세 정보는 verbose 실행에서만 남긴다.
			print_verbose("[battle_manager] 알 수 없는 SPECIAL variant: %s" % variant)

# 적 사망 시 그 적이 부여한 영웅 status 정리 (taunt_source, marked_by).
# enemy_died.emit 전에 호출 — UI 가 갱신된 status 를 읽도록.
func _cleanup_enemy_status_on_death(enemy_index: int) -> void:
	for hid in _hero_status.keys():
		var status: Dictionary = _hero_status[hid]
		# 도발: source 가 이 적이면 즉시 해제
		if status.get("taunt_source", -1) == enemy_index:
			status["taunt"] = 0
			status.erase("taunt_source")
			status_applied.emit(hid, "taunt", 0)
		# marked_by: 이 적이 Array 에 있으면 제거 (다른 적이 부여한 마크는 유지)
		var marked: Array = status.get("marked_by", [])
		if marked.has(enemy_index):
			marked.erase(enemy_index)
			status["marked_by"] = marked
			status_applied.emit(hid, "marked_by", marked.size())

# 영웅 사망 시 그 영웅이 부여한 적 status 정리 (taunt_source, marked_by).
# 영웅이 부여한 도발은 그 영웅이 죽으면 강제 타겟이 없어지므로 해제.
# 마킹도 같이 — 그 영웅이 부여한 마크는 영웅 사망 시 의미 없음.
func _cleanup_hero_status_on_death(hero_id: String) -> void:
	for i in range(_enemy_status.size()):
		var status: Dictionary = _enemy_status[i]
		if status.get("taunt_source", "") == hero_id:
			status["taunt"] = 0
			status.erase("taunt_source")
			status_applied.emit("enemy_%d" % i, "taunt", 0)
		var marked: Array = status.get("marked_by", [])
		if marked.has(hero_id):
			marked.erase(hero_id)
			status["marked_by"] = marked
			status_applied.emit("enemy_%d" % i, "marked_by", marked.size())

var _test_disable_crit: bool = false  # 테스트 환경 — 정확한 데미지 검증 위해 crit 비활성

# 적 공격 전용 치명타 굴림 — 기본 5% + marked_by 보유 시 +30%.
# 아군 시너지(독날·초원의 결투사·신의 원정) 적용 안 함.
# 반환: {crit_mult: float, is_crit: bool}
func _roll_crit_enemy(has_mark: bool) -> Dictionary:
	if _test_disable_crit or tutorial_active:
		return {"crit_mult": 1.0, "is_crit": false}
	var rate: float = CRIT_BASE_RATE + (CRIT_MARK_BONUS if has_mark else 0.0)
	var is_crit: bool = randf() < rate
	var crit_mult: float = CRIT_MULTIPLIER if is_crit else 1.0
	return {"crit_mult": crit_mult, "is_crit": is_crit}

# 치명타 굴림 (배율 전용) — _apply_card_effects DAMAGE 분기에서 사용.
# 반환: {crit_mult: float, is_crit: bool}
func _roll_crit(target_enemy_index: int, has_mark: bool, attacker: String = "") -> Dictionary:
	if tutorial_force_crit:
		return {"crit_mult": CRIT_MULTIPLIER, "is_crit": true}
	if tutorial_active:
		return {"crit_mult": 1.0, "is_crit": false}
	# 초원의 결투사 (칭기즈칸×무사시): 무사시가 칭기즈칸 표식이 있는 적을 치면 표식을 지우고 치명타 확정 (차례당 1회).
	# 확률이 아닌 확정 규칙이라 테스트의 치명타 끄기보다 먼저 판정한다.
	var is_crit: bool = _steppe_duel_crit(target_enemy_index, attacker)
	if not is_crit:
		if _test_disable_crit:
			return {"crit_mult": 1.0, "is_crit": false}
		var rate: float = CRIT_BASE_RATE + (CRIT_MARK_BONUS if has_mark else 0.0)
		# 독날 (클레오파트라×무사시): 반함 상태 적에게 치명타 확률 100%
		if team_mgr != null and team_mgr.is_alive("cleopatra") and team_mgr.is_alive("musashi") and target_enemy_index < _enemy_status.size() and _enemy_status[target_enemy_index].get("enthrall", 0) > 0:
			rate = 1.0
		is_crit = randf() < rate
	var crit_mult: float = CRIT_MULTIPLIER
	# 신의 원정 (잔다르크×칭기즈칸): 아군 치명타 발동 시 아군 전체 힐 +30
	if is_crit and team_mgr != null and team_mgr.is_alive("joan_of_arc") and team_mgr.is_alive("genghis_khan"):
		synergy_triggered.emit("synergy.joan_genghis.name", "joan_of_arc")
		var _jg_ids: Array = []
		for _de_h in team_mgr.get_living_heroes():
			_jg_ids.append(_de_h.hero_id)
		if is_inside_tree():
			synergy_drain_vfx.emit(_jg_ids, _combat_literal(30), target_enemy_index)
		else:
			for _jg_id in _jg_ids:
				_heal_hero_safe(_jg_id, _combat_literal(30))
	return {"crit_mult": crit_mult if is_crit else 1.0, "is_crit": is_crit}

func _steppe_duel_crit(target_enemy_index: int, attacker: String) -> bool:
	if attacker != "musashi" or team_mgr == null or not team_mgr.is_alive("genghis_khan") or target_enemy_index < 0 or target_enemy_index >= _enemy_status.size():
		return false
	var marks: Array = _enemy_status[target_enemy_index].get("marked_by", []).duplicate()
	if not "genghis_khan" in marks or not _use_turn_effect("musashi", "synergy_steppe_duel"):
		return false
	marks.erase("genghis_khan")
	_enemy_status[target_enemy_index]["marked_by"] = marks
	status_applied.emit("enemy_%d" % target_enemy_index, "marked_by", marks.size())
	synergy_triggered.emit("synergy.genghis_musashi.name", attacker)
	return true

func _pick_highest_hp(hero_ids: Array) -> String:
	if hero_ids.is_empty():
		return ""
	var best_id: String = hero_ids[0]
	var best_hp: int = team_mgr.get_current_hp(best_id)
	for hid in hero_ids:
		var hp: int = team_mgr.get_current_hp(hid)
		if hp > best_hp:
			best_hp = hp
			best_id = hid
	return best_id

func _pick_hero_target(target_type: int, enemy_index: int, action_type: int = -1) -> String:
	if team_mgr == null:
		return ""
	var living_all: Array = team_mgr.get_living_heroes()
	# exiled 상태 영웅 제외 (Renoir Vanish 영감) — 적의 target select 에서 제외.
	var living: Array = []
	for h in living_all:
		if _hero_status.get(h.hero_id, {}).get("exiled", 0) <= 0:
			living.append(h)
	if living.is_empty():
		return ""
	# 도발 우회: 영웅 공격성 인텐트 (ATTACK / DEBUFF / MARK_TARGET / MIMIC) 가 영웅에게 도발당했으면
	# → 그 시전 영웅 강제 타겟. ALLY 타겟 (HEAL_ALLY / BUFF_ALLY) 은 도발 무관 (적간 효과).
	# 단 매혹/반함 (charm 또는 enthrall) 이 우선 — 매혹된 적은 도발 시전자에게 끌리지 않음.
	var is_hero_offensive: bool = action_type == IntentRes.ActionType.ATTACK \
		or action_type == IntentRes.ActionType.DEBUFF \
		or action_type == IntentRes.ActionType.MARK_TARGET \
		or action_type == IntentRes.ActionType.MIMIC
	if is_hero_offensive and enemy_index >= 0 and enemy_index < _enemy_status.size():
		var has_charm_cc: bool = _enemy_status[enemy_index].get("charm", 0) > 0 \
			or _enemy_status[enemy_index].get("enthrall", 0) > 0
		var taunt_v: int = _enemy_status[enemy_index].get("taunt", 0)
		var src_hid: String = _enemy_status[enemy_index].get("taunt_source", "")
		if taunt_v > 0 and src_hid != "" and team_mgr.is_alive(src_hid) and not has_charm_cc:
			return src_hid
	match target_type:
		IntentRes.TargetType.RANDOM:
			return living[randi() % living.size()].hero_id
		IntentRes.TargetType.LOWEST_HP:
			var lowest: Resource = living[0]
			for hero in living:
				if team_mgr.get_current_hp(hero.hero_id) < team_mgr.get_current_hp(lowest.hero_id):
					lowest = hero
			return lowest.hero_id
		IntentRes.TargetType.LAST_ATTACKER:
			var last_id: String = _last_attacker.get(enemy_index, "")
			if last_id != "" and team_mgr.is_alive(last_id):
				return last_id
			return living[randi() % living.size()].hero_id
	return ""

func debug_instant_win() -> void:
	if not is_battle_active:
		return
	for i in range(_enemies.size()):
		if _enemy_alive[i]:
			_enemy_hp[i] = 0
			_enemy_alive[i] = false
			_cleanup_enemy_status_on_death(i)
			enemy_died.emit(i)
	is_battle_active = false
	_restore_stolen_cards()
	battle_won.emit()

func _check_win_condition() -> void:
	if not is_battle_active:
		return
	for alive in _enemy_alive:
		if alive:
			return
	# 적 전멸 — 영웅도 전멸이면 패배 우선 (동시 KO 시 패배)
	if team_mgr != null and team_mgr.get_living_heroes().is_empty():
		is_battle_active = false
		_restore_stolen_cards()
		battle_lost.emit()
		return
	is_battle_active = false
	_restore_stolen_cards()
	battle_won.emit()

func _check_lose_condition() -> void:
	if not is_battle_active:
		return
	if team_mgr == null:
		return
	if team_mgr.get_living_heroes().is_empty():
		is_battle_active = false
		_restore_stolen_cards()
		battle_lost.emit()

# 적 SPECIAL 로 빼앗긴 카드 — 전투 종료 시 draw_pile 으로 복원
func _restore_stolen_cards() -> void:
	if deck_mgr == null or _enemy_stolen_cards.is_empty():
		return
	for card in _enemy_stolen_cards:
		deck_mgr.draw_pile.append(card)
	_enemy_stolen_cards.clear()

func _get_living_enemy_count() -> int:
	var count: int = 0
	for alive in _enemy_alive:
		if alive:
			count += 1
	return count

func get_enemy_hp(index: int) -> int:
	if index < 0 or index >= _enemy_hp.size():
		return 0
	return _enemy_hp[index]

func get_enemy_block(index: int) -> int:
	if index < 0 or index >= _enemy_block.size():
		return 0
	return _enemy_block[index]

func get_hero_block(hero_id: String) -> int:
	return _hero_block.get(hero_id, 0)

func is_enemy_alive(index: int) -> bool:
	if index < 0 or index >= _enemy_alive.size():
		return false
	return _enemy_alive[index]

# VFX 미리 결정용 — 카드의 charm stacks 가 적용되면 enthrall 발동할지 사전 판정
# (실제 적용은 _apply_status_to_enemy 가 수행. 여기서는 시각이펙트 분기만)
func will_enthrall_enemy(enemy_index: int, charm_stacks: int) -> bool:
	if enemy_index < 0 or enemy_index >= _enemy_status.size():
		return false
	if not _enemy_alive[enemy_index]:
		return false
	var current: int = _enemy_status[enemy_index].get("charm", 0)
	var new_charm: int = current + charm_stacks
	var charm_reduce: int = 0
	for _cpk in _active_powers:
		if _cpk.begins_with("power.charm_threshold_minus:"):
			charm_reduce += _active_powers[_cpk].get("value", 0)
	var threshold: int = max(1, _combat_literal(CHARM_THRESHOLD_BASE) + _enemy_status[enemy_index].get("charm_resistance", 0) - charm_reduce)
	return new_charm >= threshold

func get_enemy_current_intent(index: int) -> Resource:
	# 단일 intent — 첫 항목만 (기존 호환성).
	var arr := get_enemy_current_intents(index)
	return arr[0] if not arr.is_empty() else null

# 같은 턴에 동시 발동할 모든 intent (가로로 함께 표시되어야 하는 묶음).
# CHARGE_UP 마지막 턴이면 payoff_intents 전체, 그 외엔 [현재 intent] 단일.
# 카운터 윈도우 활성 — counter_window_intent.enabled + (이미 차지 중 OR 현재 의도가 CHARGE_UP).
# 워닝 의도 표시 시점부터 카운터 사용 가능 (charge_remaining 부여 전이라도).
func is_counter_window_active(index: int) -> bool:
	if index < 0 or index >= _enemies.size() or not _enemy_alive[index]:
		return false
	var w: Dictionary = _enemies[index].get("counter_window_intent") if _enemies[index].get("counter_window_intent") != null else {}
	if not bool(w.get("enabled", false)):
		return false
	if _enemy_status[index].get("charge_remaining", 0) > 0:
		return true
	for it in get_enemy_current_intents(index):
		if it != null and it.action_type == IntentRes.ActionType.CHARGE_UP:
			return true
	return false

func get_enemy_current_intents(index: int) -> Array:
	if index < 0 or index >= _enemies.size():
		return []
	var pattern: Array = _get_active_pattern(index)
	if pattern.is_empty():
		return []
	var intent: Resource = pattern[_enemy_intent_index[index]]
	if intent != null and intent.action_type == IntentRes.ActionType.CHARGE_UP:
		var st: Dictionary = _enemy_status[index] if index < _enemy_status.size() else {}
		var remaining: int = st.get("charge_remaining", max(1, intent.charge_turns))
		if remaining <= 1:
			var out: Array = []
			for p in intent.payoff_intents:
				if p != null:
					out.append(p)
			if not out.is_empty():
				return out
	return [intent] if intent != null else []

func get_enemy_count() -> int:
	return _enemies.size()

func get_enemy(index: int) -> Resource:
	if index < 0 or index >= _enemies.size():
		return null
	return _enemies[index]

func get_hero_status(hero_id: String) -> Dictionary:
	return _hero_status.get(hero_id, {}).duplicate()

func get_enemy_status(index: int) -> Dictionary:
	if index < 0 or index >= _enemy_status.size():
		return {}
	return _enemy_status[index].duplicate()

func get_active_power(key: String) -> Dictionary:
	return _active_powers.get(key, {}).duplicate()

func get_all_active_powers() -> Dictionary:
	return _active_powers.duplicate()

func clear() -> void:
	_enemy_strength_remainders.clear()
	tutorial_active = false
	tutorial_force_crit = false
	tutorial_allowed_cards.clear()
	tutorial_allow_end_turn = false
	tutorial_effect_pending = false
	_enemies.clear()
	_enemy_hp.clear()
	_enemy_alive.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_intent_index.clear()
	_enemy_phase.clear()
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	is_battle_active = false
	is_player_turn = false
	turn_count = 0
	damage_taken_this_battle = 0

func _on_hero_revived_clear_state(hero_id: String) -> void:
	# 부활 시 블록·상태 초기화 (사망 전 독/출혈/블록 제거)
	_hero_block[hero_id] = 0
	_hero_status[hero_id] = {}
	# 부활 영웅 큐 재진입 — 평균 카운터 + 1턴 비용 (즉시 행동 방지)
	var aid := _actor_id_for_hero(hero_id)
	if not _turn_queue_at.has(aid):
		var avg: float = 0.0
		var n: int = _turn_queue_at.size()
		if n > 0:
			for v in _turn_queue_at.values():
				avg += v
			avg /= float(n)
		_turn_queue_at[aid] = avg + 1000.0 / max(1, _hero_effective_speed(hero_id))

func _on_hero_died_queue(hero_id: String) -> void:
	_remove_from_queue(_actor_id_for_hero(hero_id))
	_cleanup_hero_status_on_death(hero_id)

func _evaluate_condition(cond: String, card: Resource) -> bool:
	match cond:
		"hand_size_0":
			return deck_mgr != null and deck_mgr.get_hand(card.owner_id).is_empty()
		"owner_hp_below_50", "low_hp", "very_low_hp":
			var owner: Resource = team_mgr.get_hero(card.owner_id) if team_mgr else null
			var threshold := 30 if cond == "very_low_hp" else 50
			return owner != null and team_mgr.get_current_hp(card.owner_id) * 100 <= owner.max_hp * threshold
		"team_count_3":
			return team_mgr != null and team_mgr.get_living_heroes().size() >= 3
		"enemy_count_1":
			return _get_living_enemy_count() == 1
		"not_enemy_count_1":
			return _get_living_enemy_count() != 1
		"team_hp_below_30":
			if team_mgr:
				for h in team_mgr.heroes:
					if team_mgr.is_alive(h.hero_id):
						var ratio: float = float(team_mgr.get_current_hp(h.hero_id)) / float(h.max_hp)
						if ratio <= 0.30:
							return true
			return false
		"dead_ally_any":
			if team_mgr:
				for hero in team_mgr.heroes:
					if not team_mgr.is_alive(hero.hero_id):
						return true
			return false
	return false  # 알 수 없는 조건 키는 조건 불충족으로 처리

func _get_active_pattern(enemy_index: int) -> Array:
	var enemy: Resource = _enemies[enemy_index]
	var phase: int = _enemy_phase[enemy_index]
	if not enemy.phase_patterns.is_empty() and phase < enemy.phase_patterns.size():
		return enemy.phase_patterns[phase]
	return enemy.intent_pattern

func _check_phase_transition(enemy_index: int) -> void:
	if not _enemy_alive[enemy_index]:
		return
	var enemy: Resource = _enemies[enemy_index]
	if enemy.phase_thresholds.is_empty():
		return
	var current_phase: int = _enemy_phase[enemy_index]
	if current_phase >= enemy.phase_thresholds.size():
		return
	var hp_ratio: float = float(_enemy_hp[enemy_index]) / float(enemy.max_hp)
	if hp_ratio <= enemy.phase_thresholds[current_phase]:
		_enemy_phase[enemy_index] += 1
		_enemy_intent_index[enemy_index] = 0
		boss_phase_changed.emit(enemy_index, _enemy_phase[enemy_index])
		if enemy.get("phase_heal_ratios") != null and current_phase < enemy.phase_heal_ratios.size():
			var heal_ratio: float = enemy.phase_heal_ratios[current_phase]
			if heal_ratio > 0.0:
				_enemy_hp[enemy_index] = int(enemy.max_hp * heal_ratio)
				# UI 갱신만 — enemy_damaged 는 데미지 popup 트리거하므로 사용 X.
				pending_damage_changed.emit(enemy_index)
		# Phase 전환 시 자동 status 부여 (광폭화·디스트레스 등)
		if enemy.get("phase_buffs") != null and current_phase < enemy.phase_buffs.size():
			var buffs: Array = enemy.phase_buffs[current_phase]
			for buff in buffs:
				var _bs_type: String = buff.get("status", "")
				var _bs_val: int = int(buff.get("value", 0))
				_apply_status_to_enemy(enemy_index, _bs_type, _bs_val)
				# 자동 BUFF VFX 트리거 — battle_scene 이 받아 warrior_buff 등 spawn
				passive_buff_applied.emit(enemy_index, _bs_type, _bs_val)


func _apply_synergy_bonus(card: Resource, target_enemy_index: int) -> void:
	if team_mgr == null:
		return
	var card_owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.GAIN_MORALE:
				# 철벽 진군 (나폴레옹×이순신) — 사기 획득 시 아군 전원 방어도 +(획득 사기×5)
				if card_owner == "napoleon" and team_mgr.is_alive("yi_sun_sin"):
					for _iw_h in team_mgr.get_living_heroes():
						_hero_block[_iw_h.hero_id] = _hero_block.get(_iw_h.hero_id, 0) + _combat_literal(effect.value * 5)
						hero_block_vfx.emit(_iw_h.hero_id)
					synergy_triggered.emit("synergy.napoleon_yi.name", card_owner)
				# 정복자의 기세 (나폴레옹×칭기즈칸) — 사기 획득 카드 시 파트너도 동일 사기
				var _cs_partner: String = ""
				if card_owner == "napoleon" and team_mgr.is_alive("genghis_khan"):
					_cs_partner = "genghis_khan"
				elif card_owner == "genghis_khan" and team_mgr.is_alive("napoleon"):
					_cs_partner = "napoleon"
				if _cs_partner != "":
					synergy_triggered.emit("synergy.napoleon_genghis.name", card_owner)
					if is_inside_tree():
						# 파트너 사기 획득 — morale VFX 임팩트 시점에 적용
						synergy_ally_vfx.emit("morale", [_cs_partner], effect.value, 0)
					else:
						if not _hero_status.has(_cs_partner):
							_hero_status[_cs_partner] = {}
						var _cs_m: int = _hero_status[_cs_partner].get("morale", 0) + effect.value
						_hero_status[_cs_partner]["morale"] = _cs_m
						morale_changed.emit(_cs_partner, _cs_m)
			EffectRes.EffectType.SACRIFICE_HP:
				# 희생의 칼날 (잔다르크×무사시) — 체력 희생 시 파티 전원 속도 +5 (3턴) — 속도 버프 VFX 임팩트에 적용
				if card_owner == "joan_of_arc" and team_mgr.is_alive("musashi"):
					synergy_triggered.emit("synergy.joan_musashi.name", card_owner)
					var _jm_ids: Array = []
					for _bof_h in team_mgr.get_living_heroes():
						_jm_ids.append(_bof_h.hero_id)
					if is_inside_tree():
						synergy_ally_vfx.emit("speed_buff", _jm_ids, 5, 3)
					else:
						for _jm_id in _jm_ids:
							apply_speed_bonus(_jm_id, 5, 3)
			EffectRes.EffectType.APPLY_STATUS:
				# 성스러운 독 (성녀×파라오): 클레오파트라 독 부여 시 아군 전체 회복 +15 — 흡수 VFX 임팩트에 적용
				if card_owner == "cleopatra" and effect.status_type == "poison" and team_mgr.is_alive("joan_of_arc"):
					synergy_triggered.emit("synergy.joan_cleopatra.name", card_owner)
					var _hc_ids: Array = []
					for _hc_h in team_mgr.get_living_heroes():
						_hc_ids.append(_hc_h.hero_id)
					if is_inside_tree():
						synergy_drain_vfx.emit(_hc_ids, _combat_literal(15), target_enemy_index)
					else:
						for _hc_id in _hc_ids:
							_heal_hero_safe(_hc_id, _combat_literal(15))


func get_active_synergies() -> Array:
	if team_mgr == null:
		return []
	var synergies: Array = []
	var n: bool = team_mgr.is_alive("napoleon")
	var y: bool = team_mgr.is_alive("yi_sun_sin")
	var c: bool = team_mgr.is_alive("cleopatra")
	var j: bool = team_mgr.is_alive("joan_of_arc")
	var g: bool = team_mgr.is_alive("genghis_khan")
	var m: bool = team_mgr.is_alive("musashi")
	if n and y:
		synergies.append({"name_key": "synergy.napoleon_yi.name", "desc_key": "synergy.napoleon_yi.desc"})
	if y and c:
		synergies.append({"name_key": "synergy.yi_cleopatra.name", "desc_key": "synergy.yi_cleopatra.desc"})
	if n and c:
		synergies.append({"name_key": "synergy.napoleon_cleopatra.name", "desc_key": "synergy.napoleon_cleopatra.desc"})
	if j and n:
		synergies.append({"name_key": "synergy.joan_napoleon.name", "desc_key": "synergy.joan_napoleon.desc"})
	if g and c:
		synergies.append({"name_key": "synergy.genghis_cleopatra.name", "desc_key": "synergy.genghis_cleopatra.desc"})
	if m and y:
		synergies.append({"name_key": "synergy.musashi_yi.name", "desc_key": "synergy.musashi_yi.desc"})
	if j and y:
		synergies.append({"name_key": "synergy.joan_yi.name", "desc_key": "synergy.joan_yi.desc"})
	if j and c:
		synergies.append({"name_key": "synergy.joan_cleopatra.name", "desc_key": "synergy.joan_cleopatra.desc"})
	if j and g:
		synergies.append({"name_key": "synergy.joan_genghis.name", "desc_key": "synergy.joan_genghis.desc"})
	if j and m:
		synergies.append({"name_key": "synergy.joan_musashi.name", "desc_key": "synergy.joan_musashi.desc"})
	if n and g:
		synergies.append({"name_key": "synergy.napoleon_genghis.name", "desc_key": "synergy.napoleon_genghis.desc"})
	if n and m:
		synergies.append({"name_key": "synergy.napoleon_musashi.name", "desc_key": "synergy.napoleon_musashi.desc"})
	if y and g:
		synergies.append({"name_key": "synergy.yi_genghis.name", "desc_key": "synergy.yi_genghis.desc"})
	if g and m:
		synergies.append({"name_key": "synergy.genghis_musashi.name", "desc_key": "synergy.genghis_musashi.desc"})
	if c and m:
		synergies.append({"name_key": "synergy.cleopatra_musashi.name", "desc_key": "synergy.cleopatra_musashi.desc"})
	return synergies


func _any_enemy_poisoned() -> bool:
	for i in range(_enemy_status.size()):
		if _enemy_alive[i] and _enemy_status[i].get("poison_dmg", 0) > 0:
			return true
	return false

func has_synergy_bonus(card: Resource) -> bool:
	if team_mgr == null:
		return false
	var card_owner: String = card.get("owner_id") if card.get("owner_id") != null else ""
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.GAIN_MORALE:
				if card_owner == "napoleon" and (team_mgr.is_alive("yi_sun_sin") or team_mgr.is_alive("genghis_khan")):
					return true
			EffectRes.EffectType.CONSUME_MORALE:
				if card_owner == "napoleon" and (team_mgr.is_alive("cleopatra") or team_mgr.is_alive("musashi")) and _hero_status.get("napoleon", {}).get("morale", 0) >= effect.value:
					return true
			EffectRes.EffectType.REVIVE:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("yi_sun_sin"):
					return true
			EffectRes.EffectType.PURGE_STATUS:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("cleopatra"):
					return true
			EffectRes.EffectType.SACRIFICE_HP:
				if card_owner == "joan_of_arc" and team_mgr.is_alive("musashi"):
					return true
			EffectRes.EffectType.DAMAGE:
				if card_owner == "yi_sun_sin" and team_mgr.is_alive("cleopatra") and _any_enemy_poisoned():
					return true
				if card_owner == "yi_sun_sin" and effect.target == "ALL" and team_mgr.is_alive("genghis_khan"):
					return true
				if card_owner == "genghis_khan" and effect.target == "ALL" and team_mgr.is_alive("cleopatra"):
					return true
				if card_owner == "musashi" and (team_mgr.is_alive("genghis_khan") or team_mgr.is_alive("cleopatra")):
					return true
			EffectRes.EffectType.CONDITIONAL_DMG:
				if card_owner == "musashi" and effect.status_type == "enemy_count_1" and team_mgr.is_alive("yi_sun_sin"):
					return true
			EffectRes.EffectType.HEAL_ALL:
				if card_owner == "joan_of_arc" and (team_mgr.is_alive("napoleon") or team_mgr.is_alive("genghis_khan")):
					return true
			EffectRes.EffectType.DAMAGE_PER_TEAM_MORALE, EffectRes.EffectType.CONSUME_TEAM_MORALE, EffectRes.EffectType.DAMAGE_PER_TEAM_TOKEN:
				# 교차 영웅 빌드 카드 — 생존 영웅 2명 이상(팀)이면 후광
				var _team_n: int = 0
				for h in team_mgr.heroes:
					if team_mgr.is_alive(h.hero_id):
						_team_n += 1
				if _team_n >= 2:
					return true
	return false

func debug_add_dummy_enemy(max_count: int = 6) -> bool:
	if _enemies.size() >= max_count:
		return false
	var e := EnemyResource.new()
	e.enemy_name = "debug.dummy_enemy"
	e.max_hp = _combat_literal(100)
	_enemies.append(e)
	_enemy_hp.append(e.max_hp)
	_enemy_alive.append(true)
	_enemy_block.append(0)
	_enemy_status.append({})
	_enemy_intent_index.append(0)
	_enemy_phase.append(0)
	return true

func debug_add_dummy_token(hero_id: String) -> void:
	if not _hero_status.has(hero_id):
		_hero_status[hero_id] = {}
	var cur: int = _hero_status[hero_id].get("tokens", 0)
	_hero_status[hero_id]["tokens"] = min(cur + 1, TOKEN_MAX_STACK)

func debug_set_enemy_hp(index: int, hp: int) -> void:
	if index < 0 or index >= _enemy_hp.size():
		return
	hp = max(0, hp)
	_enemy_hp[index] = hp
	if hp == 0 and _enemy_alive[index]:
		_enemy_alive[index] = false
		_remove_from_queue(_actor_id_for_enemy(index))
		_cleanup_enemy_status_on_death(index)
		enemy_died.emit(index)
		_check_win_condition()
	elif hp > 0 and not _enemy_alive[index]:
		_enemy_alive[index] = true
	# UI 갱신만 — enemy_damaged 는 데미지 popup ("Block" 등) 트리거하므로 사용 X.
	pending_damage_changed.emit(index)
	_check_phase_transition(index)


## ───────────────────────────────────────────────
## 데미지 파이프라인 — DamageContext + compute_damage
## ───────────────────────────────────────────────

## 데미지 계산에 필요한 모든 수치를 담는 값 객체.
## block 차감은 호출부 책임 — 이 구조체는 block을 다루지 않는다.
class DamageContext extends RefCounted:
	var base: float = 0.0
	var flat: int = 0            # 공격자 평탄 보너스 합산 (strength 등)
	var out_pct: float = 0.0     # 공격자 증폭 % 합산 풀 (weak −0.25, 황제의무도 +0.25 등)
	var crit_mult: float = 1.0   # 치명타 배율 (비치명타 시 1.0)
	var dnd_mult: float = 1.0    # double_next_damage 배율 (없으면 1.0)
	var in_pct: float = 0.0      # 받는 쪽 % 합산 풀 (vulnerable +0.5 등)
	var mitigation: Array = []   # 경감 곱연쇄 (방어모드 0.5, 내성 0.2 등) — Array[float]
	var invuln: bool = false      # 무적 — true면 데미지 0


## 순수 함수 — DamageContext를 받아 최종 데미지 정수를 반환한다.
## 공식: (base + flat) × (1 + out_pct) × crit_mult × dnd_mult × (1 + in_pct) × mitigation 곱연쇄
## block 차감은 호출부 책임이므로 이 함수는 block을 다루지 않는다.
static func compute_damage(ctx: DamageContext) -> int:
	var d := _unrounded_damage(ctx)
	if preload("res://resources/balance/combat_scale.gd").enabled() and d > 0.0:
		return maxi(1, int(floor(d)))
	return max(0, int(floor(d)))

# Attacker and receiver modifiers form one calculation in small units. Only
# the final HP/block outcome is rounded; the historical harness keeps its
# original intermediate truncation so before/after comparisons stay valid.
static func _outgoing_damage(ctx: DamageContext) -> float:
	return _unrounded_damage(ctx) if preload("res://resources/balance/combat_scale.gd").enabled() else float(compute_damage(ctx))

static func _unrounded_damage(ctx: DamageContext) -> float:
	if ctx.invuln:
		return 0.0
	var d: float = (ctx.base + ctx.flat) * (1.0 + ctx.out_pct) * ctx.crit_mult * ctx.dnd_mult * (1.0 + ctx.in_pct)
	for m in ctx.mitigation:
		d *= m
	return maxf(0.0, d)
