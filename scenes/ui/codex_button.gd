# scenes/ui/codex_button.gd
# 우측상단 설정 버튼 바로 왼쪽의 도감 아이콘 버튼. 맵/배틀/상점 씬에서 도감 오버레이 열기.
extends CanvasLayer

const CodexOverlayScene := preload("res://scenes/ui/codex_scene.tscn")

@onready var _btn: Button = $Btn

func _ready() -> void:
	_btn.icon = load("res://assets/art/ui/icon_codex.svg") as Texture2D
	_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_btn.pressed.connect(_on_pressed)
	SacredTheme.attach_tooltip(_btn, tr("ui.main_menu.codex"))
	SacredTheme.animate_button(_btn)

func _on_pressed() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if parent.get_node_or_null("CodexOverlay") != null:
		return
	var ov := CodexOverlayScene.instantiate()
	ov.name = "CodexOverlay"
	parent.add_child(ov)
