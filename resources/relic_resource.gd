# resources/relic_resource.gd
class_name RelicResource
extends Resource

@export var relic_name: String = ""
@export var owner_id: String = ""
@export var base_effect: Resource = null      # EffectResource — 헤드리스 로드 순서 제약으로 Resource 사용
@export var bonus_effect: Resource = null     # EffectResource — 동일
@export var description: String = ""
@export var art: Texture2D
