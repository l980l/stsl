# resources/hero_resource.gd
class_name HeroResource
extends Resource

@export var hero_id: String = ""             # 고유 식별자 (예: "napoleon")
@export var hero_name: String = ""           # 표시명
@export var historical_figure: String = ""   # 역사 인물 원래 이름
@export var max_hp: int = 70
@export var card_pool: Array = []            # CardResource 배열
@export var character_scene: PackedScene     # 캐릭터 애니메이션 씬 (AnimationPlayer 포함)
@export var portrait: Texture2D              # UI용 초상화 (정적 이미지)
