# resources/enemy_resource.gd
class_name EnemyResource
extends Resource

enum Grade { NORMAL, ELITE, BOSS }

@export var enemy_name: String = ""
@export var mythology: String = ""
@export var grade: Grade = Grade.NORMAL
@export var max_hp: int = 30
@export var speed: int = 0                   # 0 = grade 기반 폴백 사용 (battle_manager._enemy_effective_speed)
@export var intent_pattern: Array = []
@export var phase_thresholds: Array = []   # HP 비율 기준 [0.6, 0.3]
@export var phase_patterns: Array = []     # Array of Array — 페이즈별 패턴
@export var phase_heal_ratios: Array = []  # 페이즈 전환 시 HP 복구 비율 [0.6] → 60%
# 페이즈 전환 시 자동 적용할 status 묶음. phase_thresholds[i] 도달 시 phase_buffs[i] 적용.
# 각 항목 = Array of Dictionary [{"status": "strength", "value": 3}, ...]
@export var phase_buffs: Array = []
@export var charm_resistance: int = 0  # 매혹 저항: 반함 임계값 = 3 + charm_resistance
@export var character_scene: PackedScene

# 카드 타입 카운터 트리거 (Time Eater식)
# { "card_type": int (CardResource.CardType), "threshold": int, "intent": IntentResource, "repeat": bool }
@export var card_count_trigger: Dictionary = {}

# 신화 시그니처 활성화 게이트 — Phase 3에서 사용. #1~3 인카운터 풀에선 false.
@export var signatures_enabled: bool = true

# DEATH-RATTLE: 사망 시 1회 실행할 인텐트 (T2 단말마)
# IntentResource 1개. ATTACK ALL / DEBUFF ALL / BUFF_ALLY 등 사용 가능.
@export var death_trigger: Resource = null

# Form 전환 보스 — N턴마다 mode 순환. 빈 배열 = 비활성.
# 예: ["offense", "defense", "offense"] — 3턴마다 순환. defense 모드 = damage 절반/면역 등 (구현 측에서 처리).
@export var turn_modes: Array = []

# Charge 카운터 윈도우 — CHARGE_UP intent 발동 시 영웅 INFLICT_WEAKNESS 카드로 무효화 가능 신호.
# { "enabled": bool, "weakness_card_type": String, "stun_on_counter": int } — 빈 dict = 비활성.
@export var counter_window_intent: Dictionary = {}

# CHANGE_AFFINITY 시 랜덤 풀. 빈 배열 = 기본 4 속성 (불/얼음/번개/바람).
# 예: ["holy_fire", "holy_strike", "holy_arrow"] — kronos act3 페이즈 2 진입 시 매 턴 변경.
@export var dynamic_affinity_pool: Array = []

# time_limit (Okumura 영감) — turn_count >= time_limit_turns 시 매 enemy turn 시작 시 광폭화 strength +5.
# 0 = 비활성.
@export var time_limit_turns: int = 0

# dynamic_resistance (Kunino-sagiri Quad-Converge 영감) — 매 enemy turn 시작 시 풀에서 1개 픽.
# 영웅 damage_type 이 current_weakness 와 일치 시 정상 damage, 불일치 시 0.2배 (80% reduction).
# 빈 배열 = 비활성.
@export var dynamic_resistance_pool: Array = []
