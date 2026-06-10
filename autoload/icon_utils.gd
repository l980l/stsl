# autoload/icon_utils.gd
extends Node

const STATUS_DIR := "res://assets/art/ui/status/"
const SYNERGY_DIR := "res://assets/art/ui/synergy/"
const RELIC_DIR := "res://assets/art/ui/relic/"
const MAP_DIR := "res://assets/art/ui/map/"
const INTENT_DIR := "res://assets/art/ui/intent/"
const HUD_DIR := "res://assets/art/ui/hud/"
const SIGNATURE_DIR := "res://assets/art/ui/signature/"
const TOAST_DIR := "res://assets/art/ui/toast/"

const _ROOM_ICON_FILES := {
	0: "icon_room_battle",
	1: "icon_room_elite",
	2: "icon_room_rest",
	3: "icon_room_shop",
	4: "icon_room_boss",
	5: "icon_room_event",
}

const STATUS_FILE_ALIAS := {
	"poison_dmg": "poison",
	"counter_pending": "counter_block",  # 카운터 준비 — 방패 아이콘 재사용
}

var _cache: Dictionary = {}

func get_status_icon(key: String) -> Texture2D:
	var fname: String = STATUS_FILE_ALIAS.get(key, key)
	var svg_path := STATUS_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(STATUS_DIR + fname + ".png")

func get_synergy_icon(name_key: String) -> Texture2D:
	var fname := _strip(name_key)
	var svg_path := SYNERGY_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(SYNERGY_DIR + fname + ".png")

func get_room_icon(room_type: int) -> Texture2D:
	var fname: String = _ROOM_ICON_FILES.get(room_type, "")
	if fname == "":
		return null
	var svg_path := MAP_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	return _load(MAP_DIR + fname + ".png")

func get_relic_icon(name_key: String) -> Texture2D:
	var fname := _strip(name_key)
	var svg_path := RELIC_DIR + fname + ".svg"
	if ResourceLoader.exists(svg_path):
		return _load(svg_path)
	var png_path := RELIC_DIR + fname + ".png"
	if ResourceLoader.exists(png_path):
		return _load(png_path)
	# 변형 렐릭(sacred_scroll_1 등)은 끝의 _숫자를 떼고 base 아이콘을 공유
	var us := fname.rfind("_")
	if us > 0 and fname.substr(us + 1).is_valid_int():
		return _load(RELIC_DIR + fname.substr(0, us) + ".svg")
	return _load(png_path)

const _INTENT_ICON_FILES := {
	0: "attack",
	1: "buff",
	2: "debuff",
	3: "power",
	4: "prepare",
	13: "prepare",  # CHARGE_UP — prepare 아이콘 재활용
}

const _CARD_TYPE_ICON_FILES := {
	0: "attack",
	1: "skill",
	2: "power",
}

func get_intent_icon(action_type: int) -> Texture2D:
	var fname: String = _INTENT_ICON_FILES.get(action_type, "")
	if fname == "":
		return null
	return _load(INTENT_DIR + fname + ".svg")

# 인텐트 종류별 단색 라인 아이콘 (intent/) — action_type/status_type/target 로 결정. 이모지 라벨 대체.
# action_type int: 0=ATTACK 1=BUFF 2=DEBUFF 3=SPECIAL 4=PREPARE 5=HEAL_ALLY 6=BUFF_ALLY
#   7=COUNTER_PREPARE 8=MARK_TARGET 9=SACRIFICE 10=WARD 11=SUMMON 12=MIMIC 13=CHARGE_UP
#   14=DISPEL 15=FORM_SWITCH 16=CHANGE_AFFINITY 17=INFLICT_WEAKNESS. TargetType.ALL == 3.
const _INTENT_STATUS_ICON := {
	"strength": "strength", "block": "block", "speed_bonus": "haste",
	"weak": "weak", "vulnerable": "vulnerable", "poison": "poison",
	"charm": "charm", "speed_penalty": "slow", "stun": "stun", "silence": "silence",
}
const _INTENT_ACTION_ICON := {
	4: "prepare", 5: "heal", 7: "counter", 8: "mark", 9: "sacrifice",
	10: "ward", 11: "summon", 12: "mimic", 13: "charge_up",
	3: "special", 14: "special", 15: "form_switch", 16: "special", 17: "debuff",
}

func get_intent_icon_for(intent) -> Texture2D:
	if intent == null:
		return null
	var at: int = intent.action_type
	var fname: String = ""
	if at == 0:  # ATTACK — target ALL 이면 광역 아이콘
		fname = "attack_all" if int(intent.target) == 3 else "attack"
	elif at == 1 or at == 6:  # BUFF / BUFF_ALLY — 부여 스탯 아이콘
		fname = _INTENT_STATUS_ICON.get(intent.status_type, "buff")
	elif at == 2:  # DEBUFF — 상태이상 아이콘
		fname = _INTENT_STATUS_ICON.get(intent.status_type, "debuff")
	else:
		fname = _INTENT_ACTION_ICON.get(at, "")
	if fname == "":
		return null
	return _load(INTENT_DIR + fname + ".svg")

# intent/ 의 임의 라인 아이콘 (warning, dead 등 — action_type 비의존)
func get_intent_named(name: String) -> Texture2D:
	return _load(INTENT_DIR + name + ".svg")

# 신화 시그니처 아이콘 (signature_name: hubris/ragnarok/karma/kekkai/egyptian_curse/yin_yang)
func get_signature_icon(name: String) -> Texture2D:
	return _load(SIGNATURE_DIR + name + ".svg")

# 토스트 아이콘 (victory/defeat 등)
func get_toast_icon(name: String) -> Texture2D:
	return _load(TOAST_DIR + name + ".svg")

func get_card_type_icon(card_type: int) -> Texture2D:
	var fname: String = _CARD_TYPE_ICON_FILES.get(card_type, "")
	if fname == "":
		return null
	return _load(INTENT_DIR + fname + ".svg")

func get_energy_icon() -> Texture2D:
	return _load(HUD_DIR + "energy.svg")

func get_counter_icon() -> Texture2D:
	return _load("res://assets/art/ui/clock.svg")

func get_power_icon(base_key: String) -> Texture2D:
	var fname := base_key.replace(".", "_")
	return _load(STATUS_DIR + fname + ".svg")

func _strip(key: String) -> String:
	var parts := key.split(".")
	return parts[1] if parts.size() >= 2 else key

func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = tex
	return tex
