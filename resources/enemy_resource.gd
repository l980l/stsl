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
@export var charm_resistance: int = 0  # 매혹 저항: 반함 임계값 = 3 + charm_resistance
@export var character_scene: PackedScene

# 카드 타입 카운터 트리거 (Time Eater식)
# { "card_type": int (CardResource.CardType), "threshold": int, "intent": IntentResource, "repeat": bool }
@export var card_count_trigger: Dictionary = {}
