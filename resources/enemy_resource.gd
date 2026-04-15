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
@export var character_scene: PackedScene
