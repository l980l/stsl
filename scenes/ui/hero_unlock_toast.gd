# scenes/ui/hero_unlock_toast.gd
# 신규 영웅 해금 시 3초간 표시 후 자동 제거
extends CanvasLayer

const _HR = preload("res://resources/heroes/hero_registry.gd")
const DISPLAY_SECONDS := 3.0

@onready var _label: Label = $Label

func _ready() -> void:
	var pm = get_node_or_null("/root/ProgressManager")
	if pm:
		pm.hero_unlocked.connect(_on_hero_unlocked)

func _on_hero_unlocked(hero_id: String) -> void:
	var info: Dictionary = _HR.get_display_info(hero_id)
	var hero_name: String = info.get("name", hero_id)
	_label.text = "새 영웅 해금: %s" % hero_name
	visible = true
	await get_tree().create_timer(DISPLAY_SECONDS).timeout
	queue_free()
