# resources/relic_resource.gd
class_name RelicResource
extends Resource

@export var relic_name: String = ""
@export var owner_id: String = ""
@export var base_effect: Resource = null
@export var bonus_effect: Resource = null
@export var description: String = ""
@export var art: Texture2D
