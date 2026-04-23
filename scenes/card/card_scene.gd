# scenes/card/card_scene.gd
class_name CardScene
extends Control

const Mode = {"HAND": 0, "REWARD": 1, "UPGRADE": 2}
const DRAG_THRESHOLD := 10.0
const FRAME_DIR := "res://assets/art/cards/cardframes/"

var _card: Resource
var _mode: int = Mode.HAND
var _disabled: bool = false

func setup(card: Resource, mode: int) -> void:
	_card = card
	_mode = mode
	refresh()

func refresh() -> void:
	$Container/Frame.texture = _resolve_frame_texture(_card.owner_id)
	$Container/CostLabel.text = str(_card.cost)
	$Container/TitleLabel.text = _card.card_name
	$Container/ArtRect.texture = _card.art if _card.art != null else null
	$Container/DescLabel.text = _build_desc()

func _build_desc() -> String:
	var lines: Array = []
	for eff in _card.effects:
		lines.append(eff.display_text())
	return "\n".join(lines)

func _resolve_frame_texture(owner_id: String) -> Texture2D:
	var hero_path := "%s%s_frame.png" % [FRAME_DIR, owner_id]
	if ResourceLoader.exists(hero_path):
		return load(hero_path)
	return load("%ssampleframe.png" % FRAME_DIR)

func set_disabled(v: bool) -> void:
	_disabled = v
	modulate = Color(0.5, 0.5, 0.5) if v else Color.WHITE

func set_highlight(v: bool) -> void:
	modulate = Color(1.2, 1.2, 0.8) if v else Color.WHITE
