# resources/enemy_resource.gd
class_name EnemyResource
extends Resource

enum Grade { NORMAL, ELITE, BOSS }

@export var enemy_name: String = ""
@export var mythology: String = ""
@export var grade: Grade = Grade.NORMAL
@export var max_hp: int = 30
@export var intent_pattern: Array = []
@export var phase_thresholds: Array[float] = []
@export var character_scene: PackedScene
