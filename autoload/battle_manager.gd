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

# 치명타 시스템 — 기본 확률 5%, 마킹(marked_by) 시 +30% (총 35%), 발동 시 데미지 ×2
const CRIT_BASE_RATE: float = 0.05
const CRIT_MARK_BONUS: float = 0.30
const CRIT_MULTIPLIER: float = 2.0

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
signal signature_fired(enemy_index: int, signature_name: String)  # 신화 시그니처 발동 알림 (UI 토스트용)
signal counter_triggered(hero_id: String, enemy_index: int, is_major: bool)  # 카운터 발동 — VFX 트리거 (major = charge 보스 무효)
signal token_attack_fired(hero_id: String, token_index: int, enemy_index: int)  # 토큰 (병사) 발사 — VFX/SFX 시각 처리용
signal passive_buff_applied(enemy_index: int, status_type: String, value: int)  # phase_buffs / 시그너처 등 intent 외 자동 BUFF — battle_scene 이 VFX spawn 용도
signal hero_turn_skipped(hero_id: String)  # 스턴 등으로 영웅 차례 자동 종료 — 토스트·VFX 용
signal synergy_triggered(synergy_key: String, hero_id: String)  # 교차 영웅 시너지 발동 — battle_scene 토스트용
signal hero_block_vfx(hero_id: String)  # 시너지 등으로 영웅 방어도 획득 — battle_scene defense_buff VFX용
signal synergy_effect_vfx(caster_hero_id: String, vfx_status: String, enemy_indices: Array)  # 시너지 데미지/상태이상 — 지정 시전자에서 VFX 발사
# 시너지 반격 — 지정 시전자→적 VFX 발사. battle_scene 이 VFX 임팩트 시점에 상태이상 적용.
signal synergy_counter_vfx(caster_hero_id: String, target_enemy_index: int, status_type: String, stacks: int)
# 시너지 아군 효과 VFX — 회복/속도버프 등. battle_scene 이 대상 전원에 VFX 재생, 임팩트 시점에 효과 적용.
signal synergy_ally_vfx(vfx_kind: String, hero_ids: Array, value: int, duration: int)

# VFX 차지 시작 — battle_scene 이 받아 caster→target VFX 재생.
# 차지(IMPACT_DELAY) 이후 데미지/상태 적용 + 기존 시그널 (hero_damaged 등) emit.
# target_hero_id: 단일 타겟의 영웅 id ("" 이면 ALL 또는 미지정)
signal intent_vfx_charge_start(enemy_index: int, intent: Resource, target_hero_id: String)
signal card_vfx_charge_start(card: Resource, target_enemy_index: int, target_hero_id: String)
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
	var gs := get_node_or_null("/root/GameSettings")
	return gs.vfx_speed_multiplier if gs else 0.0

func _turn_interval_mul() -> float:
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
	if stype == "weak" or stype == "vulnerable":
		base = _VFX_DEBUFF_HEX.IMPACT_DELAY
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
func _card_vfx_impact_delay(card: Resource, target_enemy_index: int = -1) -> float:
	for effect in card.effects:
		if effect.damage_type != "":
			return _vfx_impact_delay_for_damage_type(effect.damage_type)
		match effect.effect_type:
			EffectRes.EffectType.APPLY_STATUS:
				var d := _vfx_impact_delay_for_status(effect.status_type)
				if d > 0.0:
					return d
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
	if effect.effect_type != EffectRes.EffectType.DAMAGE:
		return effect.value
	var owner_status: Dictionary = _hero_status.get(owner_id, {})
	var ctx := DamageContext.new()
	ctx.base = effect.value
	# strength → flat
	ctx.flat = _active_powers.get("power.strength_player:" + owner_id, {}).get("value", 0)
	# weak → out_pct -0.25
	if owner_status.get("weak", 0) > 0:
		ctx.out_pct -= 0.25
	if target_enemy_index >= 0 and target_enemy_index < _enemy_status.size():
		var t_status: Dictionary = _enemy_status[target_enemy_index]
		# 황제의 무도 (나폴레옹×무사시): 취약 적에게 out_pct +0.25
		var _ed_active: bool = (owner_id == "napoleon" or owner_id == "musashi") \
			and team_mgr != null and team_mgr.is_alive("napoleon") and team_mgr.is_alive("musashi")
		if _ed_active and t_status.get("vulnerable", 0) > 0:
			ctx.out_pct += 0.25
		# FORM_SWITCH offense → out_pct +0.5 (적이 공격자인 경우는 없으므로 영웅 측 카드 기준 불필요)
		# vulnerable → in_pct +0.5
		if t_status.get("vulnerable", 0) > 0:
			ctx.in_pct += 0.5
	# crit_mult = 1.0, dnd_mult = 1.0 (미리보기: 확률·1회성 미포함)
	return compute_damage(ctx)

# 카드의 단일 타겟/ALL 데미지 추정 — compute_damage 파이프라인 사용 (실제 경로 동일 버킷)
# 결과: enemy_index → 예측 데미지 합 (hit_count 포함)
# 치명타·dnd·bonus_per_hit 는 미포함 (확률·1회성)
func _estimate_card_damage(card: Resource, target_enemy_index: int) -> Dictionary:
	var result: Dictionary = {}
	var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
	var _str_flat: int = _active_powers.get("power.strength_player:" + card.owner_id, {}).get("value", 0)
	var _base_out_pct: float = 0.0
	if owner_status.get("weak", 0) > 0:
		_base_out_pct -= 0.25
	# 황제의 무도 활성 여부 (타겟별 vulnerable 확인은 루프 내에서)
	var _ed_active: bool = (card.owner_id == "napoleon" or card.owner_id == "musashi") \
		and team_mgr != null and team_mgr.is_alive("napoleon") and team_mgr.is_alive("musashi")
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
			var t_status: Dictionary = _enemy_status[ti] if ti < _enemy_status.size() else {}
			var ctx := DamageContext.new()
			ctx.base = effect.value
			ctx.flat = _str_flat
			ctx.out_pct = _base_out_pct
			# 황제의 무도: 취약 적에게 out_pct +0.25
			if _ed_active and t_status.get("vulnerable", 0) > 0:
				ctx.out_pct += 0.25
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

# 성전 (잔다르크×나폴레옹) — 두 영웅 생존 시 힐량을 나폴레옹 사기에 비례 증폭 (사기 1당 +7%)
func _holy_war_amplify(base_heal: int) -> int:
	if team_mgr == null or not team_mgr.is_alive("joan_of_arc") or not team_mgr.is_alive("napoleon"):
		return base_heal
	var morale: int = _hero_status.get("napoleon", {}).get("morale", 0)
	return int(base_heal * (1.0 + morale * 0.07))

func setup_battle(enemies: Array) -> void:
	if deck_mgr != null:
		deck_mgr.consolidate_for_battle()
		# 영웅별 덱 분배 — owner_id 기준
		if team_mgr != null:
			var hero_ids: Array = []
			for hero in team_mgr.heroes:
				hero_ids.append(hero.hero_id)
			deck_mgr.setup_for_battle(hero_ids)
	turn_count = 0
	damage_taken_this_battle = 0
	_enemies = enemies.duplicate()
	_enemy_hp.clear()
	_enemy_alive.clear()
	_enemy_block.clear()
	_enemy_status.clear()
	_enemy_intent_index.clear()
	_hero_block.clear()
	_hero_status.clear()
	_last_attacker.clear()
	_active_powers.clear()
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
		_start_hero_turn(hid)
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
	_phase_hero_main(hid)
	turn_started.emit(_current_actor_id)
	# 스턴 체크 — 카드 뽑기·power trigger 까지는 정상이지만 본인 행동은 막고 자동 종료.
	# 잔여 stun -1 후 hero_turn_skipped 시그널 → battle_scene 토스트/VFX, 잠깐 대기 후 end_player_turn.
	if _hero_status.get(hid, {}).get("stun", 0) > 0:
		_hero_status[hid]["stun"] = max(0, _hero_status[hid]["stun"] - 1)
		hero_turn_skipped.emit(hid)
		await get_tree().create_timer(1.0 * _turn_interval_mul()).timeout
		if is_player_turn and is_battle_active:
			end_player_turn()

# 본인 영웅 차례 시작 사전 처리 — 본인 토큰 공격 + 본인 poison tick
func _phase_hero_pre(hid: String) -> bool:
	if team_mgr == null or not team_mgr.is_alive(hid):
		return false
	var did_work: bool = false
	var token_count: int = _hero_status.get(hid, {}).get("tokens", 0)
	# 수륙 협공 (이순신×칭기즈칸): 토큰 그리드 공용 — 두 영웅의 병사가 함께 공격
	if (hid == "yi_sun_sin" or hid == "genghis_khan") and team_mgr != null and team_mgr.is_alive("yi_sun_sin") and team_mgr.is_alive("genghis_khan"):
		var _jt_partner: String = "genghis_khan" if hid == "yi_sun_sin" else "yi_sun_sin"
		var _jt_extra: int = _hero_status.get(_jt_partner, {}).get("tokens", 0)
		if _jt_extra > 0:
			token_count += _jt_extra
			synergy_triggered.emit("synergy.yi_genghis.name", hid)
	for _ti in range(token_count):
		var alive_indices: Array = []
		for ei in range(_enemies.size()):
			if _enemy_alive[ei]:
				alive_indices.append(ei)
		if alive_indices.is_empty():
			break
		var pick: int = alive_indices[randi() % alive_indices.size()]
		_last_attacker[pick] = hid
		# 토큰 인덱스 + 타겟 적 전달 — battle_scene 이 병사 타일 위치에서 bullet VFX 발사
		token_attack_fired.emit(hid, _ti, pick)
		_deal_damage_to_enemy(pick, TOKEN_DMG_PER_STACK, "bullet")
		# 혼란의 돌격 (황제×파라오): 나폴레옹 병사 공격 1회당 매혹 +3
		if hid == "napoleon" and team_mgr.is_alive("cleopatra") and _enemy_alive[pick]:
			_apply_status_to_enemy(pick, "charm", 3)
			synergy_triggered.emit("synergy.napoleon_cleopatra.name", hid)
		# 약탈과 독 (정복자×파라오): 칭기즈칸 병사 공격 1회당 독 +5
		if hid == "genghis_khan" and team_mgr.is_alive("cleopatra") and _enemy_alive[pick]:
			_apply_status_to_enemy(pick, "poison", 5)
			synergy_triggered.emit("synergy.genghis_cleopatra.name", hid)
		did_work = true
		# 토큰 사이 짧은 랜덤 지연 — SFX 겹침 방지 (0.08~0.18s)
		if token_count > 1:
			await get_tree().create_timer(0.08 + randf() * 0.10).timeout
			if not is_battle_active:
				return did_work
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
	_trigger_active_powers("player_turn_start", {"hero_id": hid})
	if deck_mgr:
		deck_mgr.start_hero_turn(hid)
	var _gm_pts = _get_gm()
	if _gm_pts and _gm_pts.is_inside_tree():
		_gm_pts.trigger_relics(RelicRes.TriggerType.PLAYER_TURN_START, {"turn": turn_count, "hero_id": hid})
	player_turn_started.emit()

# 본인 영웅 차례 종료 — 본인 status -1
func _phase_hero_post(hid: String) -> bool:
	var did_work: bool = false
	for stype: String in ["weak", "vulnerable", "taunt"]:
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
			var new_dur: int = int(ins.get("dur", 0)) - 1
			if new_dur > 0:
				kept.append({"value": int(ins.get("value", 0)), "dur": new_dur})
		if not _hero_status.has(hid):
			_hero_status[hid] = {}
		_hero_status[hid][key] = kept
		did_work = true
	_check_win_condition()
	return did_work

func play_card(card: Resource, target_enemy_index: int, target_hero_id: String = "") -> bool:
	if not is_player_turn or not is_battle_active:
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
	if deck_mgr == null or not deck_mgr.play_card(card):
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

func end_player_turn() -> void:
	if not is_player_turn or not is_battle_active:
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

func _apply_discard_pick_reward(draw_count: int, energy_gain: int) -> void:
	if not deck_mgr:
		return
	deck_mgr.draw_cards(draw_count)
	_cards_drawn_this_turn += draw_count
	if energy_gain > 0:
		deck_mgr.current_energy += energy_gain
		deck_mgr.energy_changed.emit(deck_mgr.current_energy)

func _trigger_discard_pick(draw_count: int, energy_gain: int) -> void:
	if not deck_mgr:
		return
	if deck_mgr.hand.is_empty():
		_apply_discard_pick_reward(draw_count, energy_gain)
	else:
		_pending_discard_pick = {"draw_count": draw_count, "energy_gain": energy_gain}
		card_pick_requested.emit("discard", draw_count)

func resolve_pending_discard_pick(picked_card: Resource) -> void:
	if _pending_discard_pick.is_empty():
		return
	var draw_count: int = _pending_discard_pick.get("draw_count", 0)
	var energy_gain: int = _pending_discard_pick.get("energy_gain", 0)
	_pending_discard_pick = {}
	if deck_mgr:
		deck_mgr.discard_card(picked_card)
	_apply_discard_pick_reward(draw_count, energy_gain)

func _register_power(key: String, owner_id: String, value: int, params: Dictionary = {}) -> void:
	var power_key: String = key + ":" + owner_id
	_active_powers[power_key] = {
		"value": value,
		"owner_id": owner_id,
		"params": params,
	}
	active_powers_changed.emit()

func _trigger_active_powers(phase: String, ctx: Dictionary = {}) -> void:
	# 본인 영웅 차례 한정 — owner_id 영웅 power 만 발동 (owner 없는 글로벌 power 는 모든 영웅 차례에 발동, 3× 효과)
	var target_hero: String = ctx.get("hero_id", "")
	for power_key in _active_powers:
		var power: Dictionary = _active_powers[power_key]
		var key: String = power_key.split(":")[0] if ":" in power_key else power_key
		var owner_id: String = power.get("owner_id", "")
		var v: int = power.get("value", 0)
		# player_turn_start 시 본인 영웅 power 만 발동 (다른 영웅 차례에는 skip)
		if phase == "player_turn_start" and target_hero != "" and owner_id != "" and owner_id != target_hero:
			continue
		match key:
			"power.poison_per_turn":
				if phase == "player_turn_start":
					for ei in range(_enemies.size()):
						if _enemy_alive[ei]:
							_apply_status_to_enemy(ei, "poison", v)
			"power.block_per_turn":
				if phase == "player_turn_start":
					_hero_block[owner_id] = _hero_block.get(owner_id, 0) + v
			"power.heal_team_per_turn":
				if phase == "player_turn_start" and team_mgr:
					for hero in team_mgr.heroes:
						_heal_hero_safe(hero.hero_id, v)
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
	var _delay := _card_vfx_impact_delay(card, target_enemy_index)
	if _delay > 0.0:
		# popup·SFX 동기화: fx.screen_effect 시점까지 대기 (fallback timer = _delay + 0.5s)
		await _await_vfx_impact(_delay + 0.5)
		if not is_battle_active:
			for _ei in _pending_estimate:
				_clear_pending_dmg(_ei, _pending_estimate[_ei])
			return
		if team_mgr and not team_mgr.is_alive(card.owner_id):
			for _ei in _pending_estimate:
				_clear_pending_dmg(_ei, _pending_estimate[_ei])
			return
	# 임팩트 도달 — pending 차감 후 실제 효과 적용 (실제 데미지 시그널이 hp 갱신)
	for _ei in _pending_estimate:
		_clear_pending_dmg(_ei, _pending_estimate[_ei])
	_kills_this_card = 0
	_enthralls_this_card = 0
	for effect in card.effects:
		# condition 필드 평가 — 조건 불충족 시 이 효과 스킵
		if effect.condition != "" and not _evaluate_condition(effect.condition, card):
			continue
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				var owner_status: Dictionary = _hero_status.get(card.owner_id, {})
				# power.strength_player: 영웅 측 strength 플랫 보너스
				var _str_flat: int = _active_powers.get("power.strength_player:" + card.owner_id, {}).get("value", 0)
				# 공격자 out_pct 기본값 — weak(-0.25), 황제의 무도(+0.25) 는 hit 루프 안에서 합산
				var _base_out_pct: float = 0.0
				if owner_status.get("weak", 0) > 0:
					_base_out_pct -= 0.25
				# power.bonus_per_hit: 히트당 추가 피해
				var _bph: int = _active_powers.get("power.bonus_per_hit:" + card.owner_id, {}).get("value", 0)
				# 황제의 무도 (나폴레옹×무사시): 취약 적에게 가하는 피해 +25%
				var _ed_active: bool = (card.owner_id == "napoleon" or card.owner_id == "musashi") and team_mgr != null and team_mgr.is_alive("napoleon") and team_mgr.is_alive("musashi")
				var _ed_fired: bool = false  # 황제의 무도 라벨 1회/카드
				for _hit in range(effect.hit_count):
					if effect.target == "ALL":
						for i in range(_enemies.size()):
							if _enemy_alive[i]:
								# 치명타 — 적 status.marked_by 비어있지 않으면 +30%
								var _all_hm: bool = not _enemy_status[i].get("marked_by", []).is_empty()
								var _all_cr: Dictionary = _roll_crit(i, _all_hm)
								# 황제의 무도: 취약 적에게 +25% 합산
								var _all_out_pct: float = _base_out_pct
								if _ed_active and _enemy_status[i].get("vulnerable", 0) > 0:
									_all_out_pct += 0.25
									if not _ed_fired:
										_ed_fired = true
										synergy_triggered.emit("synergy.napoleon_musashi.name", card.owner_id)
								var _all_ctx := DamageContext.new()
								_all_ctx.base = effect.value
								_all_ctx.flat = _str_flat
								_all_ctx.out_pct = _all_out_pct
								_all_ctx.crit_mult = _all_cr["crit_mult"]
								var _all_dmg: int = compute_damage(_all_ctx)
								_deal_damage_to_enemy(i, _all_dmg, effect.damage_type, _all_cr["is_crit"])
								if _bph > 0:
									_deal_damage_to_enemy(i, _bph, effect.damage_type)
								_last_attacker[i] = card.owner_id
					else:
						if target_enemy_index >= 0 and target_enemy_index < _enemies.size():
							var _hm: bool = not _enemy_status[target_enemy_index].get("marked_by", []).is_empty()
							var _cr: Dictionary = _roll_crit(target_enemy_index, _hm)
							# 황제의 무도: 취약 적에게 +25% 합산
							var _sgl_out_pct: float = _base_out_pct
							if _ed_active and _enemy_status[target_enemy_index].get("vulnerable", 0) > 0:
								_sgl_out_pct += 0.25
								if not _ed_fired:
									_ed_fired = true
									synergy_triggered.emit("synergy.napoleon_musashi.name", card.owner_id)
							var _sgl_ctx := DamageContext.new()
							_sgl_ctx.base = effect.value
							_sgl_ctx.flat = _str_flat
							_sgl_ctx.out_pct = _sgl_out_pct
							_sgl_ctx.crit_mult = _cr["crit_mult"]
							var _sgl_dmg: int = compute_damage(_sgl_ctx)
							_deal_damage_to_enemy(target_enemy_index, _sgl_dmg, effect.damage_type, _cr["is_crit"])
							if _bph > 0:
								_deal_damage_to_enemy(target_enemy_index, _bph, effect.damage_type)
							_last_attacker[target_enemy_index] = card.owner_id
				# power.every_nth_attack_bonus: N번째 DAMAGE 효과마다 추가 피해
				for _nth_pk in _active_powers:
					if _nth_pk.begins_with("power.every_nth_attack_bonus:") and _active_powers[_nth_pk].get("owner_id", "") == card.owner_id:
						var _nth: Dictionary = _active_powers[_nth_pk]
						var _interval: int = _nth.get("params", {}).get("bonus_value", 3)
						if _interval <= 0:
							_interval = 3
						if not _nth.has("params"):
							_nth["params"] = {}
						_nth["params"]["count"] = _nth["params"].get("count", 0) + 1
						if _nth["params"]["count"] >= _interval:
							_nth["params"]["count"] = 0
							var _nth_bonus: int = _nth.get("value", 0)
							if _nth_bonus > 0:
								if effect.target == "ALL":
									for i in range(_enemies.size()):
										if _enemy_alive[i]:
											_deal_damage_to_enemy(i, _nth_bonus, effect.damage_type)
								elif target_enemy_index >= 0 and target_enemy_index < _enemies.size():
									_deal_damage_to_enemy(target_enemy_index, _nth_bonus, effect.damage_type)
			EffectRes.EffectType.BLOCK:
				_hero_block[card.owner_id] = _hero_block.get(card.owner_id, 0) + effect.value
				hero_block_gained.emit(card.owner_id, effect.value)
			EffectRes.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					var _pw_params: Dictionary = {}
					if effect.bonus_value > 0:
						_pw_params["bonus_value"] = effect.bonus_value
					var _pw_aid: String = "hero:" + card.owner_id
					var _pw_old_sp: int = _actor_speed(_pw_aid) if effect.status_type == "power.speed_buff" else 0
					_register_power(effect.status_type, card.owner_id, effect.value, _pw_params)
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
					if effect.target == "ALL":
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
					deck_mgr.draw_cards(effect.value)
					_cards_drawn_this_turn += effect.value
			EffectRes.EffectType.ENERGY:
				if deck_mgr:
					deck_mgr.current_energy += effect.value
					deck_mgr.energy_changed.emit(deck_mgr.current_energy)
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
						heal_id = target_hero_id if target_hero_id != "" else card.owner_id
					_heal_hero_safe(heal_id, _holy_war_amplify(effect.value))
					# 성녀의 방패 (잔다르크×이순신): 잔다르크 힐 시 대상 방어구 +40
					if card.owner_id == "joan_of_arc" and team_mgr.is_alive("yi_sun_sin"):
						_hero_block[heal_id] = _hero_block.get(heal_id, 0) + 40
						hero_block_gained.emit(heal_id, 40)
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
					heal_amt = _holy_war_amplify(heal_amt)
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
						_deal_damage_to_enemy(target_enemy_index, total_dmg, effect.damage_type)
					else:
						var condition_met: bool
						var es: Dictionary = _enemy_status[target_enemy_index]
						match effect.status_type:
							"morale":
								condition_met = _hero_status.get(card.owner_id, {}).get("morale", 0) > 0
							"has_poison":
								condition_met = es.get("poison_dmg", 0) > 0
							"has_poison_5":
								condition_met = es.get("poison_dmg", 0) >= 5
							"has_poison_10":
								condition_met = es.get("poison_dmg", 0) >= 10
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
								condition_met = deck_mgr != null and deck_mgr.hand.size() == 0
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
						_deal_damage_to_enemy(target_enemy_index, dmg, effect.damage_type)
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
					team_mgr.take_damage(card.owner_id, effect.value)
					# 전투 중 누적 희생 HP — 잔다르크 고유 상태이상 sacrifice_bank (상태이상 UI 표시)
					if not _hero_status.has(card.owner_id):
						_hero_status[card.owner_id] = {}
					var _bank_total: int = _hero_status[card.owner_id].get("sacrifice_bank", 0) + effect.value
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
							_heal_hero_safe(_sv_h.hero_id, 100)
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
				_trigger_discard_pick(effect.value, 1)
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
					var _payout: int = (_banked / 100) * effect.value
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
					if _dst.get("poison", 0) > 0: _types += 1
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
					_hero_status[_bs_hid]["speed_bonus"].append({"value": effect.value, "dur": effect.bonus_value})
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
	if not _in_echo_replay and card.card_type == CardRes.CardType.ATTACK:
		var _echo_key: String = "power.echo_next_attack:" + card.owner_id
		if _active_powers.has(_echo_key):
			_active_powers.erase(_echo_key)
			active_powers_changed.emit()
			_in_echo_replay = true
			for effect in card.effects:
				if effect.condition != "" and not _evaluate_condition(effect.condition, card):
					continue
				match effect.effect_type:
					EffectRes.EffectType.DAMAGE:
						var dmg2: int = effect.value
						var _os2: Dictionary = _hero_status.get(card.owner_id, {})
						if _os2.get("weak", 0) > 0:
							dmg2 = int(dmg2 * 0.75)
						dmg2 += _active_powers.get("power.strength_player:" + card.owner_id, {}).get("value", 0)
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
	await _apply_synergy_bonus(card, target_enemy_index)

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


func _deal_damage_to_enemy(enemy_index: int, amount: int, damage_type: String = "", is_crit: bool = false) -> void:
	if not _enemy_alive[enemy_index]:
		return
	# ── 받는 측 DamageContext 구성 ──
	var ctx := DamageContext.new()
	ctx.base = amount
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
	# FORM_SWITCH defense — turn_modes 의 index 0 = defense 모드. 받는 damage 50%.
	if _is_enemy_in_defense_mode(enemy_index):
		ctx.mitigation.append(0.5)
	# dynamic_resistance (Kunino Quad-Converge 영감) — current_weakness 와 damage_type 불일치 시 0.2배
	var _cur_weak: String = _enemy_status[enemy_index].get("current_weakness", "")
	if _cur_weak != "" and damage_type != "" and damage_type != _cur_weak:
		ctx.mitigation.append(0.2)
	amount = compute_damage(ctx)
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
					deck_mgr.current_energy += _active_powers[_pke].get("value", 1)
					deck_mgr.energy_changed.emit(deck_mgr.current_energy)
	_check_phase_transition(enemy_index)
	_check_win_condition()

func _deal_damage_to_hero(hero_id: String, amount: int, damage_type: String = "", is_crit: bool = false, from_enemy_index: int = -1) -> void:
	if debug_hero_invincible:
		return
	if team_mgr == null or not team_mgr.is_alive(hero_id):
		return
	var status: Dictionary = _hero_status.get(hero_id, {})
	# ── 받는 측 DamageContext 구성 ──
	var ctx := DamageContext.new()
	ctx.base = amount
	# vulnerable: 받는 측 +50%
	if status.get("vulnerable", 0) > 0:
		ctx.in_pct += 0.5
	# counter_pending: 반감(×0.5)만 mitigation에 추가 — 반사·소진·VFX는 아래에서 그대로 처리
	if status.get("counter_pending", 0) > 0 and from_enemy_index >= 0 and from_enemy_index < _enemies.size():
		ctx.mitigation.append(0.5)
	amount = compute_damage(ctx)
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
					synergy_counter_vfx.emit("cleopatra", _vc_ei, "poison", 30))
		else:
			_apply_status_to_enemy(from_enemy_index, "poison", 30)  # 테스트 환경 — VFX 없이 즉시
	var block: int = _hero_block.get(hero_id, 0)
	var absorbed: int = min(block, amount)
	_hero_block[hero_id] = block - absorbed
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
		var threshold: int = max(1, CHARM_THRESHOLD_BASE + _enemy_status[enemy_index].get("charm_resistance", 0) - _charm_reduce)
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


# 시너지 VFX 임팩트 시점에 battle_scene 이 호출 — 상태이상 적용 (status_applied → 폰트 동기).
func apply_synergy_status_to_enemy(enemy_index: int, status_type: String, stacks: int) -> void:
	if enemy_index >= 0 and enemy_index < _enemy_alive.size() and _enemy_alive[enemy_index]:
		_apply_status_to_enemy(enemy_index, status_type, stacks)

# 시너지 속도 버프 — speed_bonus 스택 추가 + 턴 큐 갱신 (희생의 칼날 등).
func _apply_synergy_speed_bonus(hero_id: String, value: int, dur: int) -> void:
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
		_apply_synergy_speed_bonus(hero_id, value, duration)
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
	team_mgr.heal(hero_id, amount)
	# 성녀의 방패 (성녀×통제사): 힐 적용 시 대상 방어구 +30
	if amount > 0 and team_mgr.is_alive("joan_of_arc") and team_mgr.is_alive("yi_sun_sin"):
		_hero_block[hero_id] = _hero_block.get(hero_id, 0) + 30
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

func _tick_enemy_poison(enemy_index: int) -> void:
	var dmg: int = _enemy_status[enemy_index].get("poison_dmg", 0)
	var dur: int = _enemy_status[enemy_index].get("poison_dur", 0)
	if dmg <= 0 or dur <= 0:
		return
	var tick_dmg: int = _consume_double_next_damage(dmg)
	_enemy_hp[enemy_index] = max(0, _enemy_hp[enemy_index] - tick_dmg)
	enemy_damaged.emit(enemy_index, tick_dmg, "poison", false)
	poison_tick_applied.emit("enemy_%d" % enemy_index, tick_dmg)
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
		_apply_status_to_enemy(i, "strength", 5)
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
	for stype: String in ["weak", "vulnerable"]:
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
	var charm_threshold: int = max(1, CHARM_THRESHOLD_BASE + _enemy_status[i].get("charm_resistance", 0) - _charm_reduce_turn)
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
		var t_cur: int = _enemy_status[i].get("taunt", 0)
		if t_cur > 0:
			_enemy_status[i]["taunt"] = t_cur - 1
			if _enemy_status[i]["taunt"] == 0 and _enemy_status[i].has("taunt_source"):
				_enemy_status[i].erase("taunt_source")
				status_applied.emit("enemy_%d" % i, "taunt", 0)
	if not legacy:
		if is_battle_active:
			_advance_turn_counter(_current_actor_id)
		turn_ended.emit(_current_actor_id)
		_current_actor_id = ""

func _execute_intent(enemy_index: int, intent: Resource) -> void:
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
						var _all_outgoing: int = compute_damage(_atk_ctx)
						_deal_damage_to_hero(hero.hero_id, _all_outgoing, resolved_dmg_type, _all_crit_e["is_crit"], enemy_index)
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
					var outgoing: int = compute_damage(_atk_ctx)
					_deal_damage_to_hero(target_id, outgoing, resolved_dmg_type, crit_result_e["is_crit"], enemy_index)
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
							await _execute_intent(enemy_index, payoff)
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
			var hp_cost: int = intent.value * 10
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
					_deal_damage_to_hero(target_id, dmg, intent.damage_type, false, enemy_index)
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
			push_warning("[battle_manager] 알 수 없는 SPECIAL variant: %s" % variant)

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
	if _test_disable_crit:
		return {"crit_mult": 1.0, "is_crit": false}
	var rate: float = CRIT_BASE_RATE + (CRIT_MARK_BONUS if has_mark else 0.0)
	var is_crit: bool = randf() < rate
	var crit_mult: float = CRIT_MULTIPLIER if is_crit else 1.0
	return {"crit_mult": crit_mult, "is_crit": is_crit}

# 치명타 굴림 (배율 전용) — _apply_card_effects DAMAGE 분기에서 사용.
# 반환: {crit_mult: float, is_crit: bool}
func _roll_crit(target_enemy_index: int, has_mark: bool) -> Dictionary:
	if _test_disable_crit:
		return {"crit_mult": 1.0, "is_crit": false}
	var rate: float = CRIT_BASE_RATE + (CRIT_MARK_BONUS if has_mark else 0.0)
	# 독날 (클레오파트라×무사시): 반함 상태 적에게 치명타 확률 100%
	if team_mgr != null and team_mgr.is_alive("cleopatra") and team_mgr.is_alive("musashi") and target_enemy_index < _enemy_status.size() and _enemy_status[target_enemy_index].get("enthrall", 0) > 0:
		rate = 1.0
	var is_crit: bool = randf() < rate
	# 초원의 결투사 (칭기즈칸×무사시): 파티 치명타 데미지 ×3 (기본 ×2)
	var crit_mult: float = CRIT_MULTIPLIER
	if team_mgr != null and team_mgr.is_alive("genghis_khan") and team_mgr.is_alive("musashi"):
		crit_mult = 3.0
	# 신의 원정 (잔다르크×칭기즈칸): 아군 치명타 발동 시 아군 전체 힐 +30
	if is_crit and team_mgr != null and team_mgr.is_alive("joan_of_arc") and team_mgr.is_alive("genghis_khan"):
		synergy_triggered.emit("synergy.joan_genghis.name", "joan_of_arc")
		var _jg_ids: Array = []
		for _de_h in team_mgr.get_living_heroes():
			_jg_ids.append(_de_h.hero_id)
		if is_inside_tree():
			synergy_ally_vfx.emit("heal", _jg_ids, 30, 0)
		else:
			for _jg_id in _jg_ids:
				_heal_hero_safe(_jg_id, 30)
	return {"crit_mult": crit_mult if is_crit else 1.0, "is_crit": is_crit}

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
	var threshold: int = max(1, CHARM_THRESHOLD_BASE + _enemy_status[enemy_index].get("charm_resistance", 0) - charm_reduce)
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

func _evaluate_condition(cond: String, _card: Resource) -> bool:
	match cond:
		"hand_size_0":
			return deck_mgr != null and deck_mgr.hand.size() == 0
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
						_hero_block[_iw_h.hero_id] = _hero_block.get(_iw_h.hero_id, 0) + effect.value * 5
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
							_apply_synergy_speed_bonus(_jm_id, 5, 3)
			EffectRes.EffectType.DAMAGE:
				# 검사의 약속 (이순신×무사시): 두 영웅 공격 시 둘 다 속도 +1 (전투 지속)
				if (card_owner == "yi_sun_sin" or card_owner == "musashi") and team_mgr.is_alive("yi_sun_sin") and team_mgr.is_alive("musashi"):
					for _sv_h in ["yi_sun_sin", "musashi"]:
						var _sv_aid: String = "hero:" + _sv_h
						var _sv_old: int = _actor_speed(_sv_aid)
						if not _hero_status.has(_sv_h):
							_hero_status[_sv_h] = {}
						if not _hero_status[_sv_h].has("speed_bonus") or typeof(_hero_status[_sv_h]["speed_bonus"]) != TYPE_ARRAY:
							_hero_status[_sv_h]["speed_bonus"] = []
						_hero_status[_sv_h]["speed_bonus"].append({"value": 1, "dur": 999})
						_adjust_turn_queue_for_speed_change(_sv_aid, _sv_old)
						status_applied.emit(_sv_h, "speed_bonus", 1)
					synergy_triggered.emit("synergy.musashi_yi.name", card_owner)
			EffectRes.EffectType.APPLY_STATUS:
				# 성스러운 독 (성녀×파라오): 클레오파트라 독 부여 시 아군 전체 회복 +15
				if card_owner == "cleopatra" and effect.status_type == "poison" and team_mgr.is_alive("joan_of_arc"):
					for _hc_h in team_mgr.get_living_heroes():
						_heal_hero_safe(_hc_h.hero_id, 15)
					synergy_triggered.emit("synergy.joan_cleopatra.name", card_owner)


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
	e.max_hp = 100
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
	var base: int = 0
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
	if ctx.invuln:
		return 0
	var d: float = (ctx.base + ctx.flat) * (1.0 + ctx.out_pct) * ctx.crit_mult * ctx.dnd_mult * (1.0 + ctx.in_pct)
	for m in ctx.mitigation:
		d *= m
	return max(0, int(floor(d)))
