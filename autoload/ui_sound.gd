# autoload/ui_sound.gd
extends Node

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node.get_meta("no_ui_sound", false):
		node.mouse_entered.connect(_on_hover.bind(node))
		node.pressed.connect(_on_click.bind(node))

func _on_hover(btn: BaseButton) -> void:
	# 비활성화된 버튼은 호버 사운드를 내지 않는다
	if btn.disabled:
		return
	AudioManager.play_ui("ui_hover")

func _on_click(_btn: BaseButton) -> void:
	AudioManager.play_ui("ui_click")
