# resources/enemy_resource.gd
class_name EnemyResource
extends Resource

enum Grade { NORMAL, ELITE, BOSS }

@export var enemy_name: String = ""
@export var mythology: String = ""
@export var grade: Grade = Grade.NORMAL
@export var max_hp: int = 30
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
