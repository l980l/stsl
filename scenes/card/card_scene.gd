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
const DEFAULT_ART := "res://assets/art/cards/illustrations/default_art.png"
const HERO_ART_DIR := "res://assets/art/heroes/"

const _CINZEL_FONT := preload("res://assets/fonts/Cinzel-Regular.ttf")
const _GEM_COMMON    := preload("res://assets/art/cards/cardgems/card_rarity_common.png")
const _GEM_UNCOMMON  := preload("res://assets/art/cards/cardgems/card_rarity_uncommon.png")
const _GEM_RARE      := preload("res://assets/art/cards/cardgems/card_rarity_rare.png")
const _GEM_LEGENDARY := preload("res://assets/art/cards/cardgems/card_rarity_legendary.png")
const _GEM_DIVINE    := preload("res://assets/art/cards/cardgems/card_rarity_divine.png")
const _TYPE_ATTACK   := preload("res://assets/art/cards/cardtypes/card_type_attack.png")
const _TYPE_SKILL    := preload("res://assets/art/cards/cardtypes/card_type_skill.png")
const _TYPE_POWER    := preload("res://assets/art/cards/cardtypes/card_type_power.png")
const _DEFAULT_ART   := preload("res://assets/art/cards/illustrations/default_art.png")
const _SAMPLE_FRAME  := preload("res://assets/art/cards/cardframes/sampleframe.png")

static var _art_cache: Dictionary = {}
static var _frame_cache: Dictionary = {}

var _card: CardResource
var _mode: int = Mode.HAND
var _disabled: bool = false
var _owner_dead: bool = false
var _pick_selectable: bool = false
# UI 표시값 — hero buff/debuff + 타겟 vulnerable 반영용. -1 면 타겟 호버 X (hero 만).
var _target_enemy_index: int = -1
var _press_pos: Vector2
var _pressing: bool = false
var _dragging: bool = false
var _glow_rect: ColorRect = null
var _glow_mat: ShaderMaterial = null
var _glow_color: Color = SacredPalette.BRASS_300
var _glow_tween: Tween = null
var _dead_overlay: ColorRect = null

func _ready() -> void:
	$Container/CostLabel.theme_type_variation = "AccentLabel"
	$Container/CostLabel.add_theme_font_override("font", _CINZEL_FONT)
	$Container/CostLabel.add_theme_color_override("font_color", Color.WHITE)
	$Container/CostLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	$Container/CostLabel.add_theme_constant_override("outline_size", 30)
	$Container/TitleLabel.theme_type_variation = "AccentLabel"
	$Container/TitleLabel.add_theme_color_override("font_color", Color.WHITE)
	$Container/TitleLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	$Container/TitleLabel.add_theme_constant_override("outline_size", 16)
	$Container/DescLabel.add_theme_color_override("font_color", Color.WHITE)
	$Container/DescLabel.add_theme_color_override("font_outline_color", Color.BLACK)
	$Container/DescLabel.add_theme_constant_override("outline_size", 16)
	_create_glow_rect()
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if _card != null:
		refresh()

func _create_glow_rect() -> void:
	const PAD   := 12.0  # 카드 외곽 글로우 링 두께
	const INSET := 6.0   # 카드 내부로 밀어 넣어 뾰족한 코어를 가림 (프레임 코너 반경 ≈ 6px)
	const W := 140.0 + PAD * 2.0
	const H := 200.0 + PAD * 2.0
	var glow := ColorRect.new()
	var mat := ShaderMaterial.new()
	var _theme := get_node_or_null("/root/SacredTheme")
	if _theme:
		mat.shader = _theme._get_card_glow_shader()
	mat.set_shader_parameter("opacity", 0.0)
	mat.set_shader_parameter("radius", 0.0)
	mat.set_shader_parameter("edge_uv", Vector2((PAD + INSET) / W, (PAD + INSET) / H))
	mat.set_shader_parameter("glow_color", Vector4(_glow_color.r, _glow_color.g, _glow_color.b, 1.0))
	glow.material = mat
	glow.position = Vector2(-PAD, -PAD)
	glow.size = Vector2(W, H)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 0)
	_glow_rect = glow
	_glow_mat = mat

func show_glow(intensity: float = 1.0) -> void:
	if _glow_mat:
		_glow_mat.set_shader_parameter("opacity", intensity)
		_glow_mat.set_shader_parameter("radius", 1.0)

func hide_glow() -> void:
	if _glow_mat:
		_glow_mat.set_shader_parameter("opacity", 0.0)
		_glow_mat.set_shader_parameter("radius", 0.0)

func set_glow_color(color: Color) -> void:
	_glow_color = color
	if _glow_mat:
		_glow_mat.set_shader_parameter("glow_color", Vector4(color.r, color.g, color.b, 1.0))

func tween_glow(alpha: float, duration: float) -> void:
	if not _glow_mat:
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	var entering := alpha > 0.0
	var _theme2 := get_node_or_null("/root/SacredTheme")
	if _theme2:
		_glow_tween = _theme2.tween_glow_material(self, _glow_mat, alpha, 1.0 if entering else 0.0, duration, not entering)

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
	$Container/ArtRect.texture = _card.art if _card.art != null else _resolve_art_texture(_card.owner_id)
	$Container/RarityGem.texture = _resolve_gem_texture(_card.rarity)
	$Container/TypeIcon.texture = _resolve_type_icon(_card.card_type)
	$Container/DescLabel.text = _build_desc()


func set_target_enemy_index(idx: int) -> void:
	# battle_scene 이 드래그 호버 중인 적 인덱스 갱신. 변경 시에만 refresh (불필요한 재빌드 회피).
	if _target_enemy_index == idx:
		return
	_target_enemy_index = idx
	if _card != null:
		$Container/DescLabel.text = _build_desc()

func _build_desc() -> String:
	var lines: Array = []
	# autoload 는 글로벌 — get_node 대신 직접 참조 (tree 진입 전 호출 시 에러 회피).
	# card_scene 은 battle 외 (shop/event) 에서도 쓰이므로 BattleManager 사용 여부는 mode 로 판단.
	for eff in _card.effects:
		# 데미지 effect 면 hero strength/weak (+ 호버 시 타겟 vulnerable) 반영한 값 표시.
		# 그 외 effect 는 raw value.
		if _mode == Mode.HAND and eff.effect_type == EffectResource.EffectType.DAMAGE:
			var v: int = BattleManager.estimate_effect_damage(eff, _card.owner_id, _target_enemy_index)
			lines.append(eff.display_text(v))
		else:
			lines.append(eff.display_text())
	var tags: Array = []
	if _card.is_exhaust:  tags.append("[%s]" % tr("card.tag.exhaust"))
	if _card.is_ethereal: tags.append("[%s]" % tr("card.tag.ethereal"))
	if _card.is_retain:   tags.append("[%s]" % tr("card.tag.retain"))
	if _card.is_innate:   tags.append("[%s]" % tr("card.tag.innate"))
	if tags.size() > 0:
		lines.append(" ".join(tags))
	return " ".join(lines)

func _resolve_gem_texture(rarity: int) -> Texture2D:
	match rarity:
		CardResource.Rarity.UNCOMMON:  return _GEM_UNCOMMON
		CardResource.Rarity.RARE:      return _GEM_RARE
		CardResource.Rarity.LEGENDARY: return _GEM_LEGENDARY
		CardResource.Rarity.DIVINE:    return _GEM_DIVINE
		_: return _GEM_COMMON

func _resolve_type_icon(card_type: int) -> Texture2D:
	match card_type:
		CardResource.CardType.SKILL: return _TYPE_SKILL
		CardResource.CardType.POWER: return _TYPE_POWER
		_: return _TYPE_ATTACK

func _resolve_art_texture(owner_id: String) -> Texture2D:
	if not _art_cache.has(owner_id):
		var hero_path := "%s%s.png" % [HERO_ART_DIR, owner_id]
		_art_cache[owner_id] = load(hero_path) if ResourceLoader.exists(hero_path) else _DEFAULT_ART
	return _art_cache[owner_id]

func _resolve_frame_texture(owner_id: String) -> Texture2D:
	if not _frame_cache.has(owner_id):
		var hero_path := "%s%s_frame.png" % [FRAME_DIR, owner_id]
		_frame_cache[owner_id] = load(hero_path) if ResourceLoader.exists(hero_path) else _SAMPLE_FRAME
	return _frame_cache[owner_id]

func set_disabled(v: bool) -> void:
	_disabled = v
	if _owner_dead:
		return
	if _mode == Mode.HAND:
		$Container/CostLabel.modulate = Color(1.0, 0.3, 0.3) if v else Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5) if v else Color.WHITE

func set_owner_dead(v: bool) -> void:
	_owner_dead = v
	if v:
		if _dead_overlay == null:
			_dead_overlay = ColorRect.new()
			_dead_overlay.color = Color(0.75, 0.05, 0.05, 0.55)
			_dead_overlay.position = Vector2.ZERO
			_dead_overlay.size = Vector2(140, 200)
			_dead_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_dead_overlay)
		_dead_overlay.show()
	else:
		if _dead_overlay != null:
			_dead_overlay.hide()
		modulate = Color.WHITE
		set_disabled(_disabled)

func set_highlight(v: bool) -> void:
	modulate = Color(1.2, 1.2, 0.8) if v else Color.WHITE

func set_pick_selectable(v: bool) -> void:
	_pick_selectable = v

func _gui_input(event: InputEvent) -> void:
	if (_disabled or _owner_dead) and not _pick_selectable:
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
	card_hovered.emit(_card)

func _on_mouse_exited() -> void:
	card_unhovered.emit(_card)
