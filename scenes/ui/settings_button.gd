# scenes/ui/settings_button.gd
extends CanvasLayer

const OverlayScene := preload("res://scenes/ui/settings_overlay.tscn")

@onready var _btn: Button = $Btn

func _ready() -> void:
	_btn.text = tr("ui.common.btn_settings")
	# 앵커 offsets에서 의도한 버튼 너비 계산 (레이아웃 전 기준값으로 사용)
	var target_w := _btn.offset_right - _btn.offset_left
	LabelUtils.fit_text(_btn, 16, 10, target_w)
	_btn.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	var overlay := get_parent().get_node_or_null("SettingsOverlay")
	if overlay == null:
		overlay = OverlayScene.instantiate()
		overlay.name = "SettingsOverlay"
		get_parent().add_child(overlay)
	overlay.open()
