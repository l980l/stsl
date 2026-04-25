# scenes/ui/settings_button.gd
extends CanvasLayer

const OverlayScene := preload("res://scenes/ui/settings_overlay.tscn")

@onready var _btn: Button = $Btn

func _ready() -> void:
	_btn.icon = load("res://assets/art/ui/icon_settings.svg") as Texture2D
	_btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	_btn.modulate = SacredPalette.BRASS_300
	_btn.pressed.connect(_on_pressed)
	SacredTheme.animate_button(_btn)

func _on_pressed() -> void:
	var overlay := get_parent().get_node_or_null("SettingsOverlay")
	if overlay == null:
		overlay = OverlayScene.instantiate()
		overlay.name = "SettingsOverlay"
		get_parent().add_child(overlay)
	overlay.open()
