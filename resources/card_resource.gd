# resources/card_resource.gd
class_name CardResource
extends Resource

enum CardType { ATTACK, SKILL, POWER }

enum Rarity {
	COMMON,     # 1강까지
	UNCOMMON,   # 1강까지
	RARE,       # 1강까지
	LEGENDARY,  # 1강까지
	DIVINE,     # 1강까지
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
	# 모든 등급 1강까지 통일 (COMMON 포함).
	# 이전: COMMON 0강 / LEGENDARY·DIVINE 2강 — 등급별 한도 차이가 의미적 복잡성만 더하고
	# 단계별 unique 효과 (DIVINE 2강) 는 미구현 상태였음. 일괄 1강으로 단순화.
	return 1

func can_upgrade() -> bool:
	return upgrade_level < max_upgrade_level()
