# scenes/card/card_scene.gd
class_name CardScene
extends Control

signal card_clicked(card)
signal card_drag_started(card, screen_pos)
signal card_drag_moved(card, screen_pos)
signal card_drag_released(card, screen_pos)
signal card_hovered(card)
signal card_unhovered(card)

enum Mode { HAND, REWARD, UPGRADE }
const DRAG_THRESHOLD := 10.0
const FRAME_DIR := "res://assets/art/cards/cardframes/"
const GEM_DIR := "res://assets/art/cards/cardgems/"
const TYPE_ICON_DIR := "res://assets/art/cards/cardtypes/"

var _card: CardResource
var _mode: int = Mode.HAND
var _disabled: bool = false
var _press_pos: Vector2
var _pressing: bool = false
var _dragging: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if _card != null:
		refresh()

func setup(card: Resource, mode: int) -> void:
	_card = card
	_mode = mode
	refresh()

func refresh() -> void:
	if _card == null:
		return
	$Container/Frame.texture = _resolve_frame_texture(_card.owner_id)
	$Container/CostLabel.text = str(_card.cost)
	$Container/TitleLabel.text = tr(_card.card_name)
	LabelUtils.fit_text($Container/TitleLabel, 50, 28)
	$Container/ArtRect.texture = _card.art
	$Container/RarityGem.texture = _resolve_gem_texture(_card.rarity)
	$Container/TypeIcon.texture = _resolve_type_icon(_card.card_type)
	$Container/DescLabel.text = _build_desc()


func _build_desc() -> String:
	var lines: Array = []
	for eff in _card.effects:
		lines.append(eff.display_text())
	return ", ".join(lines)

func _resolve_gem_texture(rarity: int) -> Texture2D:
	const NAMES := {
		CardResource.Rarity.COMMON:    "card_rarity_common.png",
		CardResource.Rarity.UNCOMMON:  "card_rarity_uncommon.png",
		CardResource.Rarity.RARE:      "card_rarity_rare.png",
		CardResource.Rarity.LEGENDARY: "card_rarity_legendary.png",
		CardResource.Rarity.DIVINE:    "card_rarity_divine.png",
	}
	return load(GEM_DIR + NAMES.get(rarity, "card_rarity_common.png"))

func _resolve_type_icon(card_type: int) -> Texture2D:
	const NAMES := {
		CardResource.CardType.ATTACK: "card_type_attack.png",
		CardResource.CardType.SKILL:  "card_type_skill.png",
		CardResource.CardType.POWER:  "card_type_power.png",
	}
	return load(TYPE_ICON_DIR + NAMES.get(card_type, "card_type_attack.png"))

func _resolve_frame_texture(owner_id: String) -> Texture2D:
	var hero_path := "%s%s_frame.png" % [FRAME_DIR, owner_id]
	if ResourceLoader.exists(hero_path):
		return load(hero_path)
	return load("%ssampleframe.png" % FRAME_DIR)

func set_disabled(v: bool) -> void:
	_disabled = v
	if _mode == Mode.HAND:
		$Container/CostLabel.modulate = Color(1.0, 0.3, 0.3) if v else Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5) if v else Color.WHITE

func set_highlight(v: bool) -> void:
	modulate = Color(1.2, 1.2, 0.8) if v else Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if _disabled:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		else:
			if _dragging:
				card_drag_released.emit(_card, get_global_mouse_position())
			elif _pressing:
				card_clicked.emit(_card)
			_pressing = false
			_dragging = false
	elif event is InputEventMouseMotion and _pressing:
		if not _dragging and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging = true
			card_drag_started.emit(_card, get_global_mouse_position())
		elif _dragging:
			card_drag_moved.emit(_card, get_global_mouse_position())

func _on_mouse_entered() -> void:
	if not _disabled:
		card_hovered.emit(_card)

func _on_mouse_exited() -> void:
	card_unhovered.emit(_card)
