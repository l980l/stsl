# resources/card_resource.gd
class_name CardResource
extends Resource

enum CardType { ATTACK, SKILL, POWER }

@export var card_name: String = ""
@export var owner_id: String = ""          # HeroResource.hero_id 참조
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var effects: Array = []
@export var upgraded: bool = false
@export var description: String = ""
@export var art: Texture2D                 # 카드 일러스트 (정적 이미지)
@export var play_animation: String = ""    # 카드 사용 시 캐릭터가 재생할 애니메이션 이름
