# scenes/card/card_scene_v2.gd
# 카드 디자인 modern — 노드 트리는 card_scene_v2.tscn 에 정의 (에디터 2D 뷰에서 직접 편집).
# 기존 CardScene 의 인터페이스 (signals + setup + methods) 와 시그니처 호환 — duck typing 으로 spawn 사이트 swap 가능.
extends Control

# ── 기존 CardScene 인터페이스 (시그니처 호환) ──
signal card_clicked(card)
signal card_drag_started(card, screen_pos)
signal card_drag_moved(card, screen_pos)
signal card_drag_released(card, screen_pos)
signal card_hovered(card)
signal card_unhovered(card)

enum Mode { HAND, REWARD, UPGRADE }
const DRAG_THRESHOLD := 10.0

var _card_res: Resource = null
var _mode: int = Mode.HAND
var _disabled: bool = false
var _owner_dead: bool = false
var _pick_selectable: bool = false
var _target_enemy_index: int = -1
var _press_pos: Vector2
var _pressing: bool = false
var _dragging_input: bool = false

const _HERO_PALETTES := {
	"napoleon":     {"frame": Color("#957421"), "accent": Color("#e8c878"), "base": Color("#1a1f2e"), "art_base": Color("#0f1320")},
	"cleopatra":    {"frame": Color("#c9a447"), "accent": Color("#f0d896"), "base": Color("#1a1812"), "art_base": Color("#0e0c08")},
	"yi_sun_sin":   {"frame": Color("#4a6b6e"), "accent": Color("#6ba89c"), "base": Color("#0e1518"), "art_base": Color("#07090b")},
	"joan_of_arc":  {"frame": Color("#c8c0ad"), "accent": Color("#ebe3d2"), "base": Color("#16161e"), "art_base": Color("#0a0a10")},
	"genghis_khan": {"frame": Color("#8b1a1f"), "accent": Color("#d94a50"), "base": Color("#1a0e0d"), "art_base": Color("#0d0706")},
	"musashi":      {"frame": Color("#2a2a34"), "accent": Color("#d8cfb9"), "base": Color("#0a0a0e"), "art_base": Color("#050507")},
}

const _GEM_COLORS := {
	"common":    {"hi": Color("#ffffff"), "mid": Color("#e5e0d2"), "lo": Color("#8b8676")},
	"uncommon":  {"hi": Color("#d8ecff"), "mid": Color("#4d8edb"), "lo": Color("#112a52")},
	"rare":      {"hi": Color("#e8d4ff"), "mid": Color("#a458d6"), "lo": Color("#3a124f")},
	"legendary": {"hi": Color("#fce6a8"), "mid": Color("#d4a948"), "lo": Color("#6b5418")},
	"divine":    {"hi": Color("#ffd2d4"), "mid": Color("#d94a50"), "lo": Color("#4a0d10")},
}

const _TYPE_ATTACK := preload("res://assets/art/cards/cardtypes/card_type_attack.png")
const _TYPE_SKILL  := preload("res://assets/art/cards/cardtypes/card_type_skill.png")
const _TYPE_POWER  := preload("res://assets/art/cards/cardtypes/card_type_power.png")

# ── 노드 참조 (tscn 노드 트리에서) ──
@onready var _frame:       Panel       = $Frame
@onready var _art_frame:   Panel       = $ArtFrame
@onready var _corner_tl:   Panel       = $CornerTL
@onready var _corner_tr:   Panel       = $CornerTR
@onready var _corner_bl:   Panel       = $CornerBL
@onready var _corner_br:   Panel       = $CornerBR
@onready var _cost_bg:     TextureRect = $CostBg
@onready var _cost_label:  Label       = $CostLabel
@onready var _title_label: Label       = $TitleLabel
@onready var _art_rect:    TextureRect = $ArtRect
@onready var _line_l:      TextureRect = $LineL
@onready var _line_r:      TextureRect = $LineR
@onready var _gem_tr:      TextureRect = $GemTr
@onready var _desc_label:  Label       = $DescLabel
@onready var _type_icon:   TextureRect = $TypeIcon

# 카드 데이터
var _card_name: String = "Card"
var _cost: int = 1
var _card_type: int = 0   # 0=ATTACK 1=SKILL 2=POWER
var _rarity_key: String = "common"
var _hero_key: String = "napoleon"
var _desc: String = ""
var _art_texture: Texture2D = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if _card_res != null:
		_refresh_from_card_res()
	refresh()

# ── 기존 CardScene 호환 API ──
func setup(card: Resource, mode: int) -> void:
	_card_res = card
	_mode = mode
	_refresh_from_card_res()
	if is_inside_tree():
		refresh()

func _refresh_from_card_res() -> void:
	if _card_res == null:
		return
	_card_name = tr(_card_res.card_name)
	_cost = _card_res.cost
	_card_type = _card_res.card_type
	_rarity_key = _rarity_to_key(_card_res.rarity)
	_hero_key = _card_res.owner_id if _card_res.owner_id != "" else "napoleon"
	_desc = _build_desc()
	_art_texture = _card_res.art if _card_res.art != null else null

func _rarity_to_key(r: int) -> String:
	match r:
		CardResource.Rarity.UNCOMMON: return "uncommon"
		CardResource.Rarity.RARE:     return "rare"
		CardResource.Rarity.LEGENDARY:return "legendary"
		CardResource.Rarity.DIVINE:   return "divine"
		_: return "common"

func _build_desc() -> String:
	if _card_res == null:
		return _desc
	var lines: Array = []
	for eff in _card_res.effects:
		if _mode == Mode.HAND and eff.effect_type == EffectResource.EffectType.DAMAGE:
			var bm := get_node_or_null("/root/BattleManager")
			var v: int = bm.estimate_effect_damage(eff, _card_res.owner_id, _target_enemy_index) if bm else int(eff.value)
			lines.append(eff.display_text(v))
		else:
			lines.append(eff.display_text())
	var tags: Array = []
	if _card_res.is_exhaust:  tags.append("[%s]" % tr("card.tag.exhaust"))
	if _card_res.is_ethereal: tags.append("[%s]" % tr("card.tag.ethereal"))
	if _card_res.is_retain:   tags.append("[%s]" % tr("card.tag.retain"))
	if _card_res.is_innate:   tags.append("[%s]" % tr("card.tag.innate"))
	if tags.size() > 0:
		lines.append(" ".join(tags))
	return " ".join(lines)

func set_target_enemy_index(idx: int) -> void:
	if _target_enemy_index == idx:
		return
	_target_enemy_index = idx
	if _card_res != null:
		_desc = _build_desc()
		if _desc_label != null:
			_desc_label.text = _desc

func set_disabled(v: bool) -> void:
	_disabled = v
	if _owner_dead:
		return
	if _mode == Mode.HAND:
		if _cost_label != null:
			_cost_label.modulate = Color(1.0, 0.3, 0.3) if v else Color.WHITE
	else:
		modulate = Color(0.5, 0.5, 0.5) if v else Color.WHITE

func set_owner_dead(v: bool) -> void:
	_owner_dead = v
	if v:
		modulate = Color(0.75, 0.05, 0.05, 0.85)
	else:
		modulate = Color.WHITE
		set_disabled(_disabled)

func set_highlight(v: bool) -> void:
	modulate = Color(1.2, 1.2, 0.8) if v else Color.WHITE

func set_pick_selectable(v: bool) -> void:
	_pick_selectable = v

# Glow 관련 — v2 단순화 (no-op). classic 의 화려한 glow 효과는 modern 디자인 미반영.
func show_glow(_intensity: float = 1.0) -> void: pass
func hide_glow() -> void: pass
func set_glow_color(_color: Color) -> void: pass
func start_glow_pulse(_a: Color, _b: Color, _period: float = 1.2) -> void: pass
func stop_glow_pulse() -> void: pass
func tween_glow(_alpha: float, _duration: float) -> void: pass

func _gui_input(event: InputEvent) -> void:
	if (_disabled or _owner_dead) and not _pick_selectable:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		else:
			if _dragging_input:
				card_drag_released.emit(_card_res, get_global_mouse_position())
			elif _pressing:
				card_clicked.emit(_card_res)
			_pressing = false
			_dragging_input = false
	elif event is InputEventMouseMotion and _pressing:
		if not _dragging_input and event.position.distance_to(_press_pos) > DRAG_THRESHOLD:
			_dragging_input = true
			card_drag_started.emit(_card_res, get_global_mouse_position())
		elif _dragging_input:
			card_drag_moved.emit(_card_res, get_global_mouse_position())

func _on_mouse_entered() -> void:
	card_hovered.emit(_card_res)

func _on_mouse_exited() -> void:
	card_unhovered.emit(_card_res)

func refresh() -> void:
	var pal: Dictionary = _HERO_PALETTES.get(_hero_key, _HERO_PALETTES["napoleon"])
	var frame_col: Color = pal["frame"]
	var base_col: Color = pal["base"]
	var art_base_col: Color = pal["art_base"]
	# Frame bg + border — tscn 의 alpha/디자인 유지, RGB hue 만 영웅별 교체
	var fsb: StyleBoxFlat = _frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	fsb.bg_color = base_col
	fsb.border_color = Color(frame_col.r, frame_col.g, frame_col.b, fsb.border_color.a)
	_frame.add_theme_stylebox_override("panel", fsb)
	# Corner ticks — tscn alpha 유지
	for c in [_corner_tl, _corner_tr, _corner_bl, _corner_br]:
		var csb: StyleBoxFlat = c.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		csb.border_color = Color(frame_col.r, frame_col.g, frame_col.b, csb.border_color.a)
		c.add_theme_stylebox_override("panel", csb)
	# Art frame bg
	var asb: StyleBoxFlat = _art_frame.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	asb.bg_color = art_base_col
	_art_frame.add_theme_stylebox_override("panel", asb)
	# Gem 라인 fade 색
	_apply_line_color(_line_l, frame_col, true)
	_apply_line_color(_line_r, frame_col, false)
	# Cost circle — highlight_strength 0.25 (HTML rgba alpha 0.18 매칭)
	_cost_bg.texture = _make_circle_texture(
		Color(0.96, 0.94, 0.90, 1.0), Color("#070710"), Color("#070710"),
		frame_col, 0.04, 64, 0.25
	)
	# Gem — highlight_strength 0.65 (보석 highlight 보이되 과하지 않게)
	var col: Dictionary = _GEM_COLORS.get(_rarity_key, _GEM_COLORS["common"])
	_gem_tr.texture = _make_circle_texture(
		col["hi"], col["mid"], col["lo"], frame_col, 0.08, 64, 0.65
	)
	# 텍스트 + 일러스트
	_cost_label.text = str(_cost)
	_title_label.text = _card_name
	# 제목 폰트 자동 조절 — 긴 텍스트는 폭에 맞춰 축소 (기존 card_scene 패턴)
	LabelUtils.fit_text(_title_label, 9, 6)
	_desc_label.text = _desc
	_art_rect.texture = _art_texture
	# Type icon
	match _card_type:
		1: _type_icon.texture = _TYPE_SKILL
		2: _type_icon.texture = _TYPE_POWER
		_: _type_icon.texture = _TYPE_ATTACK

func _apply_line_color(rect: TextureRect, fc: Color, _left_side: bool) -> void:
	# 라인 RGB 만 영웅별 교체 — tscn 의 alpha (fade 방향) / offsets / width 유지.
	# 매번 새 GradientTexture1D + Gradient 생성 (sub_resource 가 instance 간 공유될 수 있어
	# tex.gradient 만 교체하면 다른 카드 인스턴스에 영향. 텍스처 자체를 instance별로 분리).
	var src_tex: GradientTexture1D = rect.texture as GradientTexture1D
	if src_tex == null or src_tex.gradient == null:
		return
	var src_g: Gradient = src_tex.gradient
	var new_g := Gradient.new()
	new_g.offsets = src_g.offsets.duplicate()
	var new_colors := PackedColorArray()
	for i in src_g.colors.size():
		var orig: Color = src_g.colors[i]
		new_colors.append(Color(fc.r, fc.g, fc.b, orig.a))
	new_g.colors = new_colors
	var new_tex := GradientTexture1D.new()
	new_tex.gradient = new_g
	new_tex.width = src_tex.width
	rect.texture = new_tex

# 원형 텍스처 직접 생성 — 셰이더 의존 X.
func _make_circle_texture(hi: Color, mid: Color, lo: Color, ring: Color,
		ring_width_ratio: float = 0.08, size: int = 64,
		highlight_strength: float = 0.65) -> ImageTexture:
	# highlight_strength: 0 = highlight 없음 (hi → mid 완전 동일), 1 = full hi.
	# HTML 의 hi 알파 / 강도 매핑 — cost rgba(...,0.18) ≈ 0.25, gem solid ≈ 0.65.
	var soft_hi := mid.lerp(hi, highlight_strength)
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var s := float(size)
	var center := Vector2(s * 0.5, s * 0.5)
	var outer_r := s * 0.5
	var hi_pos := Vector2(s * 0.35, s * 0.30)
	var ring_w := s * ring_width_ratio
	var inner_edge := outer_r - ring_w
	var max_d := inner_edge + center.distance_to(hi_pos)
	for y in size:
		for x in size:
			var p := Vector2(x, y)
			var dc := p.distance_to(center)
			if dc > outer_r:
				continue
			var aa := 1.0
			if dc > outer_r - 1.0:
				aa = outer_r - dc
			if dc > inner_edge:
				img.set_pixel(x, y, Color(ring.r, ring.g, ring.b, ring.a * aa))
			else:
				var dh := p.distance_to(hi_pos)
				var t: float = clampf(dh / max_d, 0.0, 1.0)
				var c: Color
				if t < 0.5:
					c = soft_hi.lerp(mid, t / 0.5)
				else:
					c = mid.lerp(lo, (t - 0.5) / 0.5)
				img.set_pixel(x, y, Color(c.r, c.g, c.b, c.a * aa))
	return ImageTexture.create_from_image(img)

func set_demo_data(card_name: String, cost: int, card_type: int, rarity_key: String,
		desc: String, hero_key: String, art: Texture2D = null) -> void:
	_card_name = card_name
	_cost = cost
	_card_type = card_type
	_rarity_key = rarity_key
	_hero_key = hero_key
	_desc = desc
	_art_texture = art
	if is_inside_tree():
		refresh()
