# scenes/ui/settings_button.gd
extends CanvasLayer

const OverlayScene := preload("res://scenes/ui/settings_overlay.tscn")

@onready var _btn: Button = $Btn

func _ready() -> void:
	_btn.text = tr("ui.common.btn_settings")
	LabelUtils.fit_text(_btn, 16, 10)
	_btn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var overlay := get_parent().get_node_or_null("SettingsOverlay")
	if overlay == null:
		overlay = OverlayScene.instantiate()
		overlay.name = "SettingsOverlay"
		get_parent().add_child(overlay)
	overlay.open()
