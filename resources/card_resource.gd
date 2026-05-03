# resources/card_resource.gd
class_name CardResource
extends Resource

enum CardType { ATTACK, SKILL, POWER }

enum Rarity {
	COMMON,     # 0강 고정
	UNCOMMON,   # 1강까지
	RARE,       # 1강까지
	LEGENDARY,  # 2강까지
	DIVINE,     # 2강까지 + 단계별 유니크 효과
}

@export var card_name: String = ""
@export var owner_id: String = ""
@export var cost: int = 1
@export var card_type: CardType = CardType.ATTACK
@export var rarity: Rarity = Rarity.COMMON
@export var upgrade_level: int = 0
@export var effects: Array = []
@export var description: String = ""
@export var art: Texture2D
@export var play_animation: String = ""
@export var archetype: String = ""
@export var is_exhaust: bool = false   # 사용 후 소멸
@export var is_ethereal: bool = false  # 턴 끝 손에 있으면 소멸
@export var is_retain: bool = false    # 턴 끝 손에 남음
@export var is_innate: bool = false    # 전투 시작 시 손패 보장

func max_upgrade_level() -> int:
	match rarity:
		Rarity.COMMON:
			return 0
		Rarity.UNCOMMON, Rarity.RARE:
			return 1
		Rarity.LEGENDARY, Rarity.DIVINE:
			return 2
	return 0

func can_upgrade() -> bool:
	return upgrade_level < max_upgrade_level()
