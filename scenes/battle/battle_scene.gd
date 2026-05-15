# scenes/battle/battle_scene.gd
extends Node2D

const EffectRes = preload("res://resources/effect_resource.gd")
const IntentRes = preload("res://resources/intent_resource.gd")
const SoldierScene = preload("res://characters/summons/soldier/soldier.tscn")
const CARD_SCENE := preload("res://scenes/card/card_scene.tscn")
const ARROW_CHEVRON_TEX := preload("res://assets/art/ui/arrow_chevron.svg")
const ARROW_HEAD_TEX    := preload("res://assets/art/ui/arrow_head.svg")
const CURSOR_TEX        := preload("res://assets/art/ui/cursor.svg")

const WINDOW_W := 1920
const WINDOW_H := 1080
const SLOT_W := 240
const SLOT_H := 280
const BOTTOM_Y := 840
const CARD_W := 110
const CARD_H := 160
const BASE_CARD_SCALE := 1.4
const FAN_PIVOT_Y_OFFSET := 1200.0
const FAN_ANGLE_PER_CARD := 0.10
const FAN_MAX_TOTAL_ANGLE := 0.9
const HAND_BASE_Y := 960
const MAX_ENEMY_COUNT := 6
const TOKEN_COLS := 6
const TOKEN_ROWS := 1
const TOKEN_TILE_W := 111
const TOKEN_TILE_H := 138
const TOKEN_TILE_GAP := 4

# UI 참조 (Dictionary 배열)
# hero entry: {panel, name_lbl, hp_lbl, block_lbl, hero_id}
# enemy entry: {panel, intent_lbl, btn, name_lbl, hp_lbl, block_lbl}
var _hero_nodes: Array = []
var _enemy_nodes: Array = []
var _signatures_shown_this_turn: Dictionary = {}  # 시그니처 토스트 1회/턴 throttle

# 시그니처 발동 시 적 위치에 표시할 색상 (D — 시각 효과)
const SIGNATURE_COLORS := {
	"hubris":         Color(1.0, 0.45, 0.2),   # 그리스 — 붉은 분노
	"ragnarok":       Color(0.7, 0.25, 0.85),  # 북유럽 — 자주 운명
	"egyptian_curse": Color(0.45, 0.95, 0.4),  # 이집트 — 녹색 저주
	"karma":          Color(1.0, 0.85, 0.3),   # 불교 — 황금
	"yin_yang":       Color(0.85, 0.95, 1.0),  # 도교 — 청백
	"kekkai":         Color(0.3, 0.7, 1.0),    # 일본 — 푸른 결계
}

# 신화 → 시그니처 아이콘 + 툴팁 desc 키 (적 panel 우측 상단 표시)
const SIGNATURE_INFO := {
	"greek":    {"emoji": "⚔",  "desc_key": "battle.signature.hubris.desc"},
	"norse":    {"emoji": "🌪", "desc_key": "battle.signature.ragnarok.desc"},
	"egyptian": {"emoji": "👁", "desc_key": "battle.signature.egyptian_curse.desc"},
	"buddhist": {"emoji": "☸",  "desc_key": "battle.signature.karma.desc"},
	"daoist":   {"emoji": "☯",  "desc_key": "battle.signature.yin_yang.desc"},
	"japanese": {"emoji": "🛡", "desc_key": "battle.signature.kekkai.desc"},
}
var _card_buttons: Array = []
var _hero_char_nodes: Dictionary = {}  # hero_id → Node2D
var _enemy_char_nodes: Array = []      # index → Node2D

var _energy_label: Label
var _end_turn_btn: Button
var _message_label: Label
var _relic_container: FlowContainer
var _selected_card: Resource = null
var _lose_played: bool = false
var _defeat_layer: CanvasLayer = null
var _defeat_awaiting_input: bool = false

var _drag_card: Resource = null
var _drag_no_chevron: bool = false
var _drag_cancel_ready: bool = false
var _drag_chevrons: Array = []
var _drag_arrow_head: Sprite2D = null
var _drag_start_pos: Vector2 = Vector2.ZERO
var _drag_end_pos: Vector2 = Vector2.ZERO
var _drag_t_offset: float = 0.0

var _hero_status_containers: Dictionary = {}
var _enemy_status_containers: Array = []
var _last_card_play_pos: Vector2 = Vector2.ZERO
var _popup_stack: Dictionary = {}
var _grad_cache: Dictionary = {}
var _token_tile_nodes: Dictionary = {}
var _synergy_box: FlowContainer = null
var _active_powers_box: VBoxContainer = null
var _debug_badge: Label = null
var _debug_hp_target_mode: bool = false
var _debug_grid_visible: bool = false
var _debug_grid_nodes: Array = []
var _debug_token_hero_idx: int = 0

var _deck_viewer: CanvasLayer = null
var _deck_group:  Control     = null
var _pick_overlay: CanvasLayer = null
var _picked_card: Resource = null
var _pick_confirm_btn: Button = null
var _card_pick_in_progress: bool = false


const STATUS_EMOJI := {
	"poison_dmg": "☠", "weak": "↓", "vulnerable": "⚡",
	"morale": "★", "charm": "♥", "strength": "↑",
	"taunt": "►", "counter_block": "🛡", "charm_resistance": "💜",
	"invuln": "🛡", "counter_pool": "🔄", "marked_by": "🎯",
	"death_rattle": "💀",
	"sig_greek": "⚔", "sig_norse": "🌪", "sig_egyptian": "👁",
	"sig_buddhist": "☸", "sig_daoist": "☯", "sig_japanese": "🌸",
}

# 내부 시그니처/메커니즘 추적 키 — 의도/상태 UI에 노출 안 함
const STATUS_INTERNAL_KEYS := [
	"poison_dur", "tokens", "counter_ratio", "damage_taken",
	"greek_hubris_pending", "norse_ragnarok_fired",
	"daoist_stance", "japanese_turn_count"
]

func _trf(key: String, args) -> String:
	var s := tr(key)
	if "%d" in s or "%s" in s or "%f" in s:
		return s % args
	return s

func _ready() -> void:
	_build_ui()
	if OS.is_debug_build():
		_build_debug_tooltip()
	BattleManager.team_mgr = TeamManager
	BattleManager.deck_mgr = DeckManager
	_connect_signals()
	_start_battle()
	_play_battle_bgm()
	if OS.is_debug_build():
		_debug_badge = Label.new()
		_debug_badge.position = Vector2(1500, 20)
		_debug_badge.add_theme_font_size_override("font_size", 14)
		_debug_badge.add_theme_color_override("font_color", Color.RED)
		_debug_badge.visible = false
		add_child(_debug_badge)

func _process(delta: float) -> void:
	if _drag_card != null and not _drag_chevrons.is_empty():
		_drag_t_offset = fmod(_drag_t_offset + delta * 0.165, 1.0)
		_update_drag_chevrons()

func _build_debug_tooltip() -> void:
	pass  # DebugManager autoload에서 전역 처리

# ─────────────────────────────────────────────
# UI 빌드
# ─────────────────────────────────────────────

func _build_ui() -> void:
	# 배경
	var bg := ColorRect.new()
	bg.color = SacredPalette.INK_1000
	bg.position = Vector2.ZERO
	bg.size = Vector2(WINDOW_W, WINDOW_H)
	add_child(bg)

	const _BG_MAP := {1: "mediterranean", 2: "eastasia"}
	var bg_id: String = _BG_MAP.get(GameManager.current_chapter, "")
	if bg_id != "":
		var bg_path := "res://assets/art/backgrounds/%s.png" % bg_id
		if ResourceLoader.exists(bg_path):
			var bg_tex := TextureRect.new()
			bg_tex.texture = load(bg_path)
			bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			bg_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			bg_tex.position = Vector2.ZERO
			bg_tex.size = Vector2(WINDOW_W, WINDOW_H)
			bg_tex.modulate = Color(1, 1, 1, 0.55)
			bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(bg_tex)

	# 상단 배너 (eyebrow + 메시지 + gradient 구분선)
	var banner := Control.new()
	banner.position = Vector2(WINDOW_W / 2.0 - 300, 0)
	banner.size = Vector2(600, 72)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	var banner_eyebrow := Label.new()
	banner_eyebrow.theme_type_variation = "EyebrowLabel"
	banner_eyebrow.text = "— ACT %d · FLOOR %d —" % [GameManager.current_act, GameManager.current_floor]
	banner_eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_eyebrow.position = Vector2(0, 6)
	banner_eyebrow.size = Vector2(600, 18)
	banner_eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_eyebrow)

	var msg_bg_grad := Gradient.new()
	msg_bg_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	msg_bg_grad.colors = PackedColorArray([
		Color.TRANSPARENT,
		Color(0.0, 0.0, 0.0, 0.65),
		Color.TRANSPARENT])
	var msg_bg_tex := GradientTexture1D.new()
	msg_bg_tex.gradient = msg_bg_grad
	var msg_bg := TextureRect.new()
	msg_bg.texture = msg_bg_tex
	msg_bg.position = Vector2(0, 18)
	msg_bg.size = Vector2(600, 48)
	msg_bg.stretch_mode = TextureRect.STRETCH_SCALE
	msg_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(msg_bg)

	_message_label = Label.new()
	_message_label.theme_type_variation = "TitleLabel"
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message_label.add_theme_font_size_override("font_size", 26)
	_message_label.position = Vector2(0, 24)
	_message_label.size = Vector2(600, 36)
	banner.add_child(_message_label)

	var banner_grad := Gradient.new()
	banner_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	banner_grad.colors = PackedColorArray([
		Color.TRANSPARENT,
		Color(SacredPalette.BRASS_500.r, SacredPalette.BRASS_500.g, SacredPalette.BRASS_500.b, 0.5),
		Color.TRANSPARENT])
	var banner_grad_tex := GradientTexture1D.new()
	banner_grad_tex.gradient = banner_grad
	var banner_rule := TextureRect.new()
	banner_rule.texture = banner_grad_tex
	banner_rule.position = Vector2(0, 63)
	banner_rule.size = Vector2(600, 2)
	banner_rule.stretch_mode = TextureRect.STRETCH_SCALE
	banner_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_rule)

	var banner_cutout := ColorRect.new()
	banner_cutout.color = SacredPalette.INK_1000
	banner_cutout.size = Vector2(20, 14)
	banner_cutout.position = Vector2(290, 56)
	banner_cutout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_cutout)

	var banner_diamond := Label.new()
	banner_diamond.text = "✦"
	banner_diamond.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	banner_diamond.add_theme_font_size_override("font_size", 10)
	banner_diamond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_diamond.position = Vector2(0, 57)
	banner_diamond.size = Vector2(600, 12)
	banner_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(banner_diamond)

	# 에너지 — 아이콘 + 숫자만, 핸드 구분선 높이에 맞춤
	var energy_hbox := HBoxContainer.new()
	energy_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_hbox.add_theme_constant_override("separation", 14)
	energy_hbox.position = Vector2(WINDOW_W - 200, BOTTOM_Y - 26)
	energy_hbox.size = Vector2(180, 32)
	add_child(energy_hbox)

	var energy_icon := TextureRect.new()
	energy_icon.texture = IconUtils.get_energy_icon()
	energy_icon.custom_minimum_size = Vector2(24, 24)
	energy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	energy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	energy_icon.modulate = SacredPalette.BRASS_300
	energy_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_hbox.add_child(energy_icon)

	_energy_label = Label.new()
	_energy_label.theme_type_variation = "EyebrowLabel"
	_energy_label.add_theme_font_size_override("font_size", 22)
	_energy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_energy_label.text = "0/3"
	energy_hbox.add_child(_energy_label)

	# 턴 종료 버튼 — Control wrapper로 감싸 크기 고정
	var end_btn_wrap := Control.new()
	end_btn_wrap.position = Vector2(WINDOW_W - 214, BOTTOM_Y + 16)
	end_btn_wrap.size = Vector2(200, 54)
	add_child(end_btn_wrap)
	_end_turn_btn = Button.new()
	_end_turn_btn.text = tr("battle.btn_end_turn")
	_end_turn_btn.add_theme_font_size_override("font_size", 18)
	_end_turn_btn.disabled = true
	_end_turn_btn.pressed.connect(_on_end_turn_pressed)
	end_btn_wrap.add_child(_end_turn_btn)
	_end_turn_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LabelUtils.fit_text(_end_turn_btn, 18, 12, 168.0)
	SacredTheme.animate_button(_end_turn_btn)

	# 덱 보기 버튼 — Control wrapper로 감싸 크기 고정
	var deck_wrap := Control.new()
	deck_wrap.position = Vector2(WINDOW_W - 214, BOTTOM_Y + 78)
	deck_wrap.size = Vector2(200, 54)
	add_child(deck_wrap)
	var deck_btn := Button.new()
	deck_btn.text = tr("ui.battle.btn_deck_view")
	deck_btn.add_theme_font_size_override("font_size", 18)
	deck_btn.pressed.connect(_show_deck_viewer_in_battle)
	deck_wrap.add_child(deck_btn)
	deck_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	LabelUtils.fit_text(deck_btn, 18, 12, 168.0)
	SacredTheme.animate_button(deck_btn)

	# 핸드존 구분선 — gradient rule + ✦ 다이아몬드
	var hand_grad := Gradient.new()
	hand_grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	hand_grad.colors = PackedColorArray([
		Color.TRANSPARENT,
		Color(SacredPalette.BRASS_500.r, SacredPalette.BRASS_500.g, SacredPalette.BRASS_500.b, 0.45),
		Color.TRANSPARENT])
	var hand_grad_tex := GradientTexture1D.new()
	hand_grad_tex.gradient = hand_grad
	var hand_rule := TextureRect.new()
	hand_rule.texture = hand_grad_tex
	hand_rule.position = Vector2(60, BOTTOM_Y - 10)
	hand_rule.size = Vector2(WINDOW_W - 320, 2)
	hand_rule.stretch_mode = TextureRect.STRETCH_SCALE
	hand_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_rule)

	var hand_cutout := ColorRect.new()
	hand_cutout.color = SacredPalette.INK_1000
	hand_cutout.size = Vector2(20, 14)
	hand_cutout.position = Vector2(WINDOW_W / 2.0 - 10, BOTTOM_Y - 17)
	hand_cutout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_cutout)

	var hand_diamond := Label.new()
	hand_diamond.text = "✦"
	hand_diamond.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	hand_diamond.add_theme_font_size_override("font_size", 10)
	hand_diamond.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hand_diamond.position = Vector2(0, BOTTOM_Y - 17)
	hand_diamond.size = Vector2(WINDOW_W, 12)
	hand_diamond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hand_diamond)

	# HUD 바 — 시너지 + 릴릭 아이콘, 메시지 레이블 아래
	_relic_container = FlowContainer.new()
	_relic_container.position = Vector2(20, 70)
	_relic_container.size = Vector2(WINDOW_W - 40, 72)
	_relic_container.add_theme_constant_override("h_separation", 6)
	_relic_container.add_theme_constant_override("v_separation", 4)
	add_child(_relic_container)
	_synergy_box = _relic_container
	_refresh_hud()

	_active_powers_box = VBoxContainer.new()
	_active_powers_box.position = Vector2(16, 858)
	_active_powers_box.custom_minimum_size = Vector2(200, 0)
	_active_powers_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_active_powers_box)

	# 영웅 슬롯 3개 고정 (초기 숨김)
	for i in range(3):
		_hero_nodes.append(_make_hero_slot(i))
	# 적 슬롯은 _setup_enemies()에서 동적 생성

func _hero_slot_pos(index: int) -> Vector2:
	return (get_node("HeroSlot%d" % (index + 1)) as Marker2D).position

func _summon_area_pos(index: int) -> Vector2:
	return (get_node("SummonArea%d" % (index + 1)) as Marker2D).position

func _make_hero_slot(index: int) -> Dictionary:
	var pos := _hero_slot_pos(index)
	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0)
	panel.position = pos
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)
	SacredTheme.add_corner_brackets(panel, SacredPalette.BRASS_500, 16, 2, 1)

	var bar_w: float = 211.0
	var _bar_h: float = 12.0
	var bar_x: float = pos.x + (SLOT_W - bar_w) / 2.0

	var name_lbl := _make_label(Vector2(bar_x, pos.y + 4), Vector2(bar_w, 22), 16)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.theme_type_variation = "AccentLabel"
	name_lbl.z_index = 1
	name_lbl.visible = false

	var hp_bar := _make_hp_bar(Vector2(bar_x, pos.y + 28), bar_w)
	hp_bar.z_index = 1
	hp_bar.visible = false

	var hp_lbl := _make_label(Vector2(bar_x, pos.y + 22), Vector2(bar_w, 24), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.theme_type_variation = "EyebrowLabel"
	hp_lbl.z_index = 1
	hp_lbl.visible = false

	var block_lbl := _make_label(Vector2(bar_x, pos.y + 22), Vector2(bar_w, 24), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	block_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_lbl.theme_type_variation = "EyebrowLabel"
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 2
	block_lbl.visible = false

	var status_box := HBoxContainer.new()
	status_box.position = Vector2(bar_x, pos.y + 42)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	status_box.visible = false
	add_child(status_box)

	return { "panel": panel, "name_lbl": name_lbl, "hp_bar": hp_bar,
			 "hp_lbl": hp_lbl, "block_lbl": block_lbl,
			 "hero_id": "", "status_box": status_box }

func _enemy_slot_pos(index: int, _total: int = 0) -> Vector2:
	return (get_node("EnemySlot%d" % (index + 1)) as Marker2D).position

func _make_enemy_slot(index: int, total: int) -> Dictionary:
	var pos: Vector2 = _enemy_slot_pos(index, total)
	var enemy_res: Resource = BattleManager.get_enemy(index)
	var is_boss: bool = enemy_res != null and enemy_res.grade == EnemyResource.Grade.BOSS

	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0)
	panel.position = pos
	panel.size = Vector2(SLOT_W, SLOT_H)
	panel.visible = false
	add_child(panel)
	SacredTheme.add_corner_brackets(panel, SacredPalette.BRASS_500, 16, 2, 1)

	var bar_w: float = 211.0
	var bar_x: float = pos.x + (SLOT_W - bar_w) / 2.0

	var intent_lbl := _make_label(Vector2(pos.x, pos.y + 4), Vector2(SLOT_W, 22), 18)
	intent_lbl.theme_type_variation = "EyebrowLabel"
	intent_lbl.modulate = Color(1.0, 0.8, 0.2)
	intent_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intent_lbl.z_index = 1

	var btn := Button.new()
	btn.flat = true
	btn.position = pos
	btn.size = Vector2(SLOT_W, SLOT_H)
	btn.text = ""
	btn.visible = false
	btn.set_meta("no_ui_sound", true)
	var captured_index := index
	btn.pressed.connect(func(): _on_enemy_pressed(captured_index))
	add_child(btn)

	var name_lbl := _make_label(Vector2(bar_x, pos.y + 28), Vector2(bar_w, 18), 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.theme_type_variation = "AccentLabel"
	name_lbl.z_index = 1

	var hp_bar := _make_hp_bar(Vector2(bar_x, pos.y + 48), bar_w, is_boss)
	hp_bar.z_index = 1

	var hp_lbl := _make_label(Vector2(bar_x, pos.y + 42), Vector2(bar_w, 24), 12)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.theme_type_variation = "EyebrowLabel"
	hp_lbl.z_index = 1

	var block_lbl := _make_label(Vector2(bar_x, pos.y + 42), Vector2(bar_w, 24), 12)
	block_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	block_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	block_lbl.theme_type_variation = "EyebrowLabel"
	block_lbl.modulate = Color(0.5, 0.8, 1.0)
	block_lbl.z_index = 2

	var status_box := HBoxContainer.new()
	var status_y: float = pos.y + (72.0 if is_boss else 62.0)
	status_box.position = Vector2(bar_x, status_y)
	status_box.size = Vector2(bar_w, 18)
	status_box.z_index = 1
	add_child(status_box)

	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
			 "block_lbl": block_lbl, "status_box": status_box }

func _refresh_hud() -> void:
	if _relic_container == null:
		return
	for child in _relic_container.get_children():
		child.queue_free()
	for s in BattleManager.get_active_synergies():
		var tip: String = "%s\n%s" % [tr(s["name_key"]), tr(s["desc_key"])]
		var tex: Texture2D = IconUtils.get_synergy_icon(s["name_key"])
		if tex != null:
			var rect := TextureRect.new()
			rect.texture = tex
			rect.custom_minimum_size = Vector2(28, 28)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.mouse_filter = Control.MOUSE_FILTER_STOP
			_relic_container.add_child(rect)
			SacredTheme.attach_tooltip(rect, tip)
		else:
			var lbl := Label.new()
			lbl.text = "[%s]" % tr(s["name_key"])
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.modulate = Color(1.0, 0.0, 1.0)
			_relic_container.add_child(lbl)
			SacredTheme.attach_tooltip(lbl, tip)
	if not GameManager or not GameManager.is_inside_tree():
		return
	for relic in GameManager.relics:
		var tip: String = "%s\n%s" % [tr(relic.relic_name), tr(relic.description)]
		var tex: Texture2D = IconUtils.get_relic_icon(relic.relic_name)
		if tex != null:
			var rect := TextureRect.new()
			rect.texture = tex
			rect.custom_minimum_size = Vector2(28, 28)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.mouse_filter = Control.MOUSE_FILTER_STOP
			_relic_container.add_child(rect)
			SacredTheme.attach_tooltip(rect, tip)
		else:
			var lbl := Label.new()
			lbl.text = "[%s]" % tr(relic.relic_name)
			lbl.mouse_filter = Control.MOUSE_FILTER_STOP
			lbl.add_theme_font_size_override("font_size", 13)
			lbl.modulate = Color(1.0, 0.85, 0.3)
			_relic_container.add_child(lbl)
			SacredTheme.attach_tooltip(lbl, tip)

func _refresh_relics() -> void:
	_refresh_hud()

func _make_label(pos: Vector2, sz: Vector2, font_size: int) -> Label:
	var lbl := Label.new()
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_size)
	add_child(lbl)
	return lbl

func _get_gradient_tex(state: String) -> GradientTexture1D:
	if _grad_cache.has(state):
		return _grad_cache[state]
	# Gradient.new()는 기본 2점(0=검정, 1=흰색) — 두 점 모두 덮어써야 흰색 방지
	var g := Gradient.new()
	match state:
		"std_normal":
			g.set_color(0, SacredPalette.BLOOD_700); g.set_offset(0, 0.0)
			g.set_color(1, SacredPalette.BLOOD_400); g.set_offset(1, 1.0)
			g.add_point(0.6, SacredPalette.BLOOD_500)
		"std_low":
			g.set_color(0, SacredPalette.BLOOD_600); g.set_offset(0, 0.0)
			g.set_color(1, SacredPalette.BLOOD_400); g.set_offset(1, 1.0)
		"std_crit":
			g.set_color(0, SacredPalette.BLOOD_500); g.set_offset(0, 0.0)
			g.set_color(1, SacredPalette.BLOOD_300); g.set_offset(1, 1.0)
		"boss":
			g.set_color(0, SacredPalette.BLOOD_700); g.set_offset(0, 0.0)
			g.set_color(1, SacredPalette.BRASS_500); g.set_offset(1, 1.0)
			g.add_point(0.5, SacredPalette.BLOOD_500)
	var tex := GradientTexture1D.new()
	tex.gradient = g
	_grad_cache[state] = tex
	return tex

func _get_highlight_tex() -> GradientTexture2D:
	if _grad_cache.has("highlight"):
		return _grad_cache["highlight"]
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.92, 0.82, 0.20))
	g.set_color(1, Color(1.0, 0.92, 0.82, 0.0))
	g.set_offset(0, 0.0)
	g.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_LINEAR
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 0.5)
	tex.width = 4
	tex.height = 32
	_grad_cache["highlight"] = tex
	return tex

func _get_shield_tex() -> ImageTexture:
	if _grad_cache.has("shield"):
		return _grad_cache["shield"]
	var img := Image.create(12, 12, false, Image.FORMAT_RGBA8)
	var c1: Color = SacredPalette.BONE_300
	var c2: Color = SacredPalette.BONE_400
	for y in range(12):
		for x in range(12):
			var d: int = (x + y) % 6
			img.set_pixel(x, y, c1 if d < 3 else c2)
	var tex := ImageTexture.create_from_image(img)
	_grad_cache["shield"] = tex
	return tex

func _get_bloom_shader() -> Shader:
	if _grad_cache.has("bloom_shader"):
		return _grad_cache["bloom_shader"]
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform float intensity : hint_range(0.0, 1.5) = 0.4;\nuniform vec4 glow_color : source_color = vec4(0.85, 0.16, 0.19, 1.0);\nuniform vec2 inner = vec2(0.18, 0.45);\nvoid fragment() {\n\tvec2 d = abs(UV - vec2(0.5)) - (vec2(0.5) - inner);\n\tfloat outside = step(0.0, max(d.x, d.y));\n\tvec2 dn = max(d, vec2(0.0)) / inner;\n\tfloat t = length(dn);\n\tfloat alpha = smoothstep(1.0, 0.0, t) * intensity * outside;\n\tCOLOR = vec4(glow_color.rgb, alpha);\n}\n"
	_grad_cache["bloom_shader"] = sh
	return sh

func _make_hp_bar(pos: Vector2, width: float, is_boss: bool = false) -> Control:
	var height: float = 14.0
	var P := SacredPalette

	var wrapper := Control.new()
	wrapper.position = pos
	wrapper.size = Vector2(width, height)
	wrapper.clip_contents = false

	var bg := ColorRect.new()
	bg.size = Vector2(width, height)
	bg.color = P.INK_1000
	wrapper.add_child(bg)

	# Fill (베이스 그라데이션)
	var fill := TextureRect.new()
	fill.name = "Fill"
	fill.texture = _get_gradient_tex("boss" if is_boss else "std_normal")
	fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fill.stretch_mode = TextureRect.STRETCH_SCALE
	fill.size = Vector2(width, height)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(fill)

	# Bloom (Fill 자식 — fill width 따라 수축, 8px halo, show_behind_parent로 fill이 no-glow 영역 덮음)
	var bloom := ColorRect.new()
	bloom.name = "Bloom"
	bloom.color = Color.WHITE
	bloom.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bloom.offset_left = -8.0
	bloom.offset_top = -8.0
	bloom.offset_right = 8.0
	bloom.offset_bottom = 8.0
	bloom.show_behind_parent = true
	bloom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bloom_mat := ShaderMaterial.new()
	bloom_mat.shader = _get_bloom_shader()
	bloom_mat.set_shader_parameter("intensity", 0.35)
	bloom_mat.set_shader_parameter("glow_color", Color(P.BLOOD_400.r, P.BLOOD_400.g, P.BLOOD_400.b, 1.0))
	bloom_mat.set_shader_parameter("inner", Vector2(8.0 / (width + 16.0), 8.0 / (height + 16.0)))
	bloom.material = bloom_mat
	fill.add_child(bloom)

	# Highlight (Fill 위쪽 절반 — Fill 자식이라 Fill width 따라감)
	var highlight := TextureRect.new()
	highlight.name = "Highlight"
	highlight.texture = _get_highlight_tex()
	highlight.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	highlight.stretch_mode = TextureRect.STRETCH_SCALE
	highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fill.add_child(highlight)

	# Ghost (최근 데미지 트레일)
	var ghost := ColorRect.new()
	ghost.name = "Ghost"
	ghost.color = Color(P.BLOOD_300.r, P.BLOOD_300.g, P.BLOOD_300.b, 0.35)
	ghost.position = Vector2(0, 0)
	ghost.size = Vector2(0, height)
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(ghost)

	# Shield (체력 오른쪽에 붙는 본 색 줄무늬 오버레이)
	var shield := TextureRect.new()
	shield.name = "Shield"
	shield.texture = _get_shield_tex()
	shield.stretch_mode = TextureRect.STRETCH_TILE
	shield.position = Vector2(0, 0)
	shield.size = Vector2(0, height)
	shield.visible = false
	shield.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrapper.add_child(shield)

	# 노치
	var notch_percents: Array = [16.66, 33.33, 50.0, 66.66, 83.33] if not is_boss else [25.0, 50.0, 75.0]
	var notch_color: Color = Color(0.91, 0.78, 0.47, 0.4) if is_boss else Color(0, 0, 0, 0.6)
	for pct in notch_percents:
		var n := ColorRect.new()
		n.position = Vector2(width * pct / 100.0, 0)
		n.size = Vector2(1, height)
		n.color = notch_color
		n.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrapper.add_child(n)

	# 테두리
	var border := Panel.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	border.z_index = 10
	var bstyle := StyleBoxFlat.new()
	bstyle.bg_color = Color(0, 0, 0, 0)
	bstyle.border_color = P.BRASS_500 if is_boss else P.BRASS_700
	bstyle.set_border_width_all(1)
	border.add_theme_stylebox_override("panel", bstyle)
	wrapper.add_child(border)

	add_child(wrapper)
	return wrapper

func _apply_hp_state(bar: Control, fill: TextureRect, ratio: float, is_boss: bool) -> void:
	if bar.has_meta("pulse_tween"):
		var old: Tween = bar.get_meta("pulse_tween")
		if is_instance_valid(old):
			old.kill()
		bar.remove_meta("pulse_tween")
	fill.modulate = Color.WHITE

	var bloom: ColorRect = fill.get_node("Bloom") as ColorRect
	var bloom_mat := bloom.material as ShaderMaterial

	# 사망(HP 0) 시 bloom 완전히 끔
	if ratio <= 0.0:
		bloom_mat.set_shader_parameter("intensity", 0.0)
		return

	# fill width 변화에 맞춰 inner 동기화 (split 방지)
	var fw: float = max(fill.size.x, 0.001)
	var fh: float = max(fill.size.y, 0.001)
	bloom_mat.set_shader_parameter("inner", Vector2(8.0 / (fw + 16.0), 8.0 / (fh + 16.0)))

	var P := SacredPalette
	var glow_col: Color = P.BLOOD_400

	# 상태별 그라데이션·글로우 색상
	if is_boss:
		fill.texture = _get_gradient_tex("boss")
	elif ratio > 0.40:
		fill.texture = _get_gradient_tex("std_normal")
	elif ratio > 0.15:
		fill.texture = _get_gradient_tex("std_low")
		glow_col = P.BLOOD_400
	else:
		fill.texture = _get_gradient_tex("std_crit")
		glow_col = P.BLOOD_300

	bloom_mat.set_shader_parameter("glow_color", Color(glow_col.r, glow_col.g, glow_col.b, 1.0))

	# 펄스 — bloom intensity만 (fill alpha 건드리면 하위 레이어 가로줄이 비침)
	var dur: float = 0.0
	var lo_intensity: float = 0.0
	var hi_intensity: float = 0.0
	if ratio <= 0.15:
		dur = 0.9
		lo_intensity = 0.35
		hi_intensity = 1.2
	elif ratio <= 0.40:
		dur = 1.6
		lo_intensity = 0.30
		hi_intensity = 0.85
	else:
		# 정상 HP — 블룸 완전히 끔 (임계치 미만에서만 브리딩)
		bloom_mat.set_shader_parameter("intensity", 0.0)
		return

	bloom_mat.set_shader_parameter("intensity", lo_intensity)
	var tw := create_tween().set_loops()
	tw.tween_method(func(v: float): bloom_mat.set_shader_parameter("intensity", v), lo_intensity, hi_intensity, dur * 0.5).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float): bloom_mat.set_shader_parameter("intensity", v), hi_intensity, lo_intensity, dur * 0.5).set_ease(Tween.EASE_IN_OUT)
	bar.set_meta("pulse_tween", tw)

func _apply_hp_change(bar: Control, new_ratio: float) -> void:
	var ghost: ColorRect = bar.get_node("Ghost") as ColorRect
	var bw: float = bar.size.x
	var prev: float = bar.get_meta("prev_ratio", new_ratio)
	bar.set_meta("prev_ratio", new_ratio)

	if bar.has_meta("ghost_tween"):
		var old: Tween = bar.get_meta("ghost_tween")
		if is_instance_valid(old):
			old.kill()
		bar.remove_meta("ghost_tween")

	# 회복·동일 → ghost 즉시 숨김
	if new_ratio >= prev - 0.0005:
		ghost.size.x = 0.0
		return

	ghost.position.x = bw * new_ratio
	ghost.size.x = bw * (prev - new_ratio)
	ghost.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(0.24)
	tw.tween_property(ghost, "size:x", 0.0, 0.88).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	bar.set_meta("ghost_tween", tw)

func _apply_shield(bar: Control, hp_ratio: float, block: int, max_hp: int) -> void:
	var shield: TextureRect = bar.get_node("Shield") as TextureRect
	if block <= 0 or max_hp <= 0:
		shield.visible = false
		return
	var s_ratio: float = clamp(float(block) / float(max_hp), 0.0, 1.0)
	if s_ratio <= 0.001:
		shield.visible = false
		return
	shield.visible = true
	var bw: float = bar.size.x
	var available: float = 1.0 - hp_ratio
	if s_ratio <= available:
		# 빈 공간 안에 들어옴 — fill 끝에서 오른쪽으로
		shield.position.x = bw * hp_ratio
	else:
		# 넘침 — 바 오른쪽 끝에 달라붙어 fill 위로 침범
		shield.position.x = bw * (1.0 - s_ratio)
	shield.size.x = bw * s_ratio

# ─────────────────────────────────────────────
# 시그널 연결 (스텁 — Task 3~5에서 채움)
# ─────────────────────────────────────────────

func _connect_signals() -> void:
	DeckManager.hand_changed.connect(_refresh_hand)
	DeckManager.energy_changed.connect(_on_energy_changed)
	DeckManager.card_played.connect(_on_card_played)
	BattleManager.player_turn_started.connect(_on_player_turn_started)
	BattleManager.enemy_turn_started.connect(_on_enemy_turn_started)
	BattleManager.hero_damaged.connect(_on_hero_damaged)
	BattleManager.hero_block_gained.connect(_on_hero_block_gained)
	BattleManager.enemy_damaged.connect(_on_enemy_damaged)
	TeamManager.hero_healed.connect(_on_hero_healed)
	BattleManager.enemy_died.connect(_on_enemy_died)
	BattleManager.battle_won.connect(_on_battle_won)
	BattleManager.battle_lost.connect(_on_battle_lost)
	TeamManager.hero_died.connect(_on_hero_died)
	TeamManager.hero_revived.connect(_on_hero_revived)
	BattleManager.status_applied.connect(_on_status_applied)
	BattleManager.morale_changed.connect(_on_morale_changed)
	BattleManager.active_powers_changed.connect(_on_active_powers_changed)
	BattleManager.enemy_counter_changed.connect(_on_enemy_counter_changed)
	BattleManager.card_pick_requested.connect(_on_card_pick_requested)
	BattleManager.boss_phase_changed.connect(_on_boss_phase_changed)
	BattleManager.enemy_spawned.connect(_on_enemy_spawned)
	# VFX 차지 시작 — 적 인텐트/영웅 카드 출처 모두 임팩트 시점에 데미지·SFX 동기
	BattleManager.intent_vfx_charge_start.connect(_on_intent_vfx_start)
	BattleManager.card_vfx_charge_start.connect(_on_card_vfx_start)
	BattleManager.poison_tick_applied.connect(_on_poison_tick)
	BattleManager.signature_fired.connect(_on_signature_fired)
	BattleManager.pending_damage_changed.connect(_on_pending_damage_changed)

var _bgm_boss_id: String = ""

func _play_battle_bgm() -> void:
	var enemies := GameManager.pending_enemies
	var first = enemies[0] if not enemies.is_empty() else null
	var EnemyRes = load("res://resources/enemy_resource.gd")
	if first != null and first.grade == EnemyRes.Grade.BOSS:
		_bgm_boss_id = first.enemy_name.split(".")[-1]
		AudioManager.play_bgm_dynamic("boss", _bgm_boss_id, 0)
	else:
		var myth: String = GameManager.act_mythologies[GameManager.current_act - 1]
		AudioManager.play_bgm_dynamic("battle", myth)

func _on_boss_phase_changed(_enemy_index: int, new_phase: int) -> void:
	if new_phase >= 1 and not _bgm_boss_id.is_empty():
		AudioManager.play_bgm_dynamic("boss", _bgm_boss_id, new_phase)

# 신화 시그니처 발동 시 화면 중앙에 짧은 토스트 표시 (~1.5초 페이드)
# Throttle: 같은 시그니처는 1턴에 1회만 (다중 적 동시 발동 시 중복 방지)
func _on_pending_damage_changed(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_nodes.size():
		return
	if _enemy_nodes[enemy_index].is_empty():
		return
	_update_enemy_ui(enemy_index)

func _on_signature_fired(enemy_index: int, signature_name: String) -> void:
	if _signatures_shown_this_turn.has(signature_name):
		return
	_signatures_shown_this_turn[signature_name] = true
	# 토스트 라벨 (화면 중앙 페이드)
	var color: Color = SIGNATURE_COLORS.get(signature_name, Color(1.0, 0.85, 0.3))
	var toast := Label.new()
	toast.text = tr("battle.signature.%s.toast" % signature_name)
	toast.theme_type_variation = "TitleLabel"
	toast.add_theme_font_size_override("font_size", 32)
	toast.modulate = color
	toast.z_index = 100
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.position = Vector2(WINDOW_W / 2.0 - 200, 280)
	toast.size = Vector2(400, 60)
	add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(1.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.35)
	tw.tween_callback(toast.queue_free)
	# 적 위치에 색상 플래시 (시그니처 색상)
	_burst_signature_at_enemy(enemy_index, color)

# 적 시그니처 발동 시 시각 강조 — 사용자 피드백으로 비활성 (큰 주황/보라 사각형이 어색).
# 시그니처 토스트 라벨(_on_signature_fired)이 이미 화면 중앙에 표시되므로 추가 강조 불필요.
func _burst_signature_at_enemy(_enemy_index: int, _color: Color) -> void:
	pass

# 신화 시그니처 아이콘 — 적 panel 우측 상단. 호버 시 툴팁으로 효과 설명.
# 주의: btn 이 panel 과 같은 사이즈로 self 의 자식이라 — panel 자식 Label 은 가려짐.
# 해결: Label 을 self(battle_scene) 의 자식 + 매우 늦게 add (btn 위) + z_index 최상위.
func _attach_signature_icon(panel: ColorRect, mythology) -> void:
	if panel == null or mythology == null:
		return
	var info: Dictionary = SIGNATURE_INFO.get(mythology, {})
	if info.is_empty():
		return
	var existing := get_node_or_null(NodePath("_SigIcon_%s" % str(panel.get_instance_id())))
	if existing != null:
		return
	var lbl := Label.new()
	lbl.name = "_SigIcon_%s" % str(panel.get_instance_id())
	lbl.text = info["emoji"]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.z_index = 100
	var pp: Vector2 = panel.position
	lbl.position = pp + Vector2(panel.size.x - 34.0, 4.0)
	lbl.size = Vector2(26, 28)
	add_child(lbl)
	SacredTheme.attach_tooltip(lbl, tr(info["desc_key"]))

# T3-SUMMON: 런타임에 spawn된 적의 UI 패널 + 캐릭터 노드 추가
func _on_enemy_spawned(enemy_index: int) -> void:
	var enemy: Resource = BattleManager.get_enemy(enemy_index)
	if enemy == null:
		return
	var total: int = enemy_index + 1  # 신규 적 포함 총 슬롯 수
	var entry: Dictionary = _make_enemy_slot(enemy_index, total)
	_enemy_nodes.append(entry)
	_enemy_char_nodes.append(null)
	_enemy_status_containers.append(entry["status_box"])
	entry["panel"].visible = true
	entry["btn"].visible = true
	entry["btn"].disabled = false
	entry["name_lbl"].text = tr(enemy.get("enemy_name")) if enemy.get("enemy_name") != null else "적"
	_attach_signature_icon(entry["panel"], enemy.get("mythology"))
	var slot_pos: Vector2 = _enemy_slot_pos(enemy_index, total)
	if enemy.character_scene != null:
		var char_node = enemy.character_scene.instantiate()
		char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + 184)
		char_node.scale = Vector2(-1.44, 2.4)
		add_child(char_node)
		_enemy_char_nodes[enemy_index] = char_node
	else:
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.45, 0.45, 0.5, 0.6)
		placeholder.size = Vector2(60, 120)
		placeholder.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 30, slot_pos.y + 40)
		add_child(placeholder)
		_enemy_char_nodes[enemy_index] = placeholder
	_update_enemy_ui(enemy_index)
	_refresh_enemy_counter(enemy_index)

# ─────────────────────────────────────────────
# 배틀 초기화
# ─────────────────────────────────────────────

func _start_battle() -> void:
	if not GameManager.pending_enemies.is_empty():
		BattleManager.turn_interval = 0.4  # base — GameSettings.monster_interval_multiplier 가 곱셈 적용
		BattleManager.setup_battle(GameManager.pending_enemies)
		_setup_heroes()
		_setup_enemies()
		BattleManager.start_player_turn()
	else:
		_start_test_battle()  # GameManager 없이 단독 실행 시 폴백

func _start_test_battle() -> void:
	var HeroRes = load("res://resources/hero_resource.gd")
	var EnemyRes = load("res://resources/enemy_resource.gd")
	var CardRes = load("res://resources/card_resource.gd")

	# 영웅 설정
	TeamManager.clear()
	var napoleon = HeroRes.new()
	napoleon.hero_id = "napoleon"
	napoleon.hero_name = "hero.napoleon.name"
	napoleon.max_hp = 70
	napoleon.character_scene = load("res://characters/heroes/napoleon/napoleon.tscn")
	TeamManager.add_hero(napoleon)

	# 덱 설정 (스트라이크 3장 + 디펜드 2장)
	DeckManager.clear()
	for _i in range(3):
		var card = CardRes.new()
		card.card_name = "card.napoleon.strike.name"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "attack"
		var eff = EffectRes.new()
		eff.effect_type = EffectRes.EffectType.DAMAGE
		eff.value = 6
		eff.target = "SINGLE"
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)
	for _i in range(2):
		var card = CardRes.new()
		card.card_name = "card.napoleon.defend.name"
		card.owner_id = "napoleon"
		card.cost = 1
		card.play_animation = "idle"
		var eff = EffectRes.new()
		eff.effect_type = EffectRes.EffectType.BLOCK
		eff.value = 5
		eff.target = "SELF"
		card.effects = [eff]
		DeckManager.add_card_to_deck(card)

	# 적 설정
	var IntentResClass = load("res://resources/intent_resource.gd")
	var satyr = EnemyRes.new()
	satyr.enemy_name = "enemy.greek.satyr"
	satyr.max_hp = 30
	satyr.character_scene = load("res://characters/enemies/satyr/satyr.tscn")
	var intent = IntentResClass.new()
	intent.action_type = IntentResClass.ActionType.ATTACK
	intent.value = 6
	intent.target = IntentResClass.TargetType.RANDOM
	satyr.intent_pattern = [intent]

	BattleManager.turn_interval = 0.4
	BattleManager.setup_battle([satyr])
	_setup_heroes()
	_setup_enemies()
	BattleManager.start_player_turn()

# ─────────────────────────────────────────────
# 영웅/적 표시 (Task 2에서 구현)
# ─────────────────────────────────────────────

func _setup_heroes() -> void:
	# 기존 캐릭터 노드 정리
	for char_node in _hero_char_nodes.values():
		char_node.queue_free()
	_hero_char_nodes.clear()
	for entry in _hero_nodes:
		entry["panel"].visible = false
		entry["name_lbl"].visible = false
		entry["hp_bar"].visible = false
		entry["hp_lbl"].visible = false
		entry["block_lbl"].visible = false
		entry["status_box"].visible = false
		entry["hero_id"] = ""
	# 기존 병사 타일 정리
	for tiles in _token_tile_nodes.values():
		for tile in tiles:
			tile.queue_free()
	_token_tile_nodes.clear()

	var heroes := TeamManager.heroes
	for i in range(min(heroes.size(), 3)):
		var hero: Resource = heroes[i]
		var entry: Dictionary = _hero_nodes[i]
		entry["panel"].visible = true
		entry["name_lbl"].visible = true
		entry["hp_bar"].visible = true
		entry["hp_lbl"].visible = true
		entry["block_lbl"].visible = true
		entry["status_box"].visible = true
		entry["hero_id"] = hero.hero_id
		entry["name_lbl"].text = tr(hero.get("hero_name")) if hero.get("hero_name") != null else hero.hero_id

		if hero.character_scene != null:
			var char_node = hero.character_scene.instantiate()
			var slot_pos := _hero_slot_pos(i)
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + 184)
			char_node.scale = Vector2(1.44, 2.4)
			add_child(char_node)
			_hero_char_nodes[hero.hero_id] = char_node

		_hero_status_containers[hero.hero_id] = entry["status_box"]
		_update_hero_ui(hero.hero_id)

func _setup_enemies() -> void:
	# 기존 노드 전부 파괴
	for char_node in _enemy_char_nodes:
		if char_node != null:
			char_node.queue_free()
	_enemy_char_nodes.clear()
	for entry in _enemy_nodes:
		entry["panel"].queue_free()
		entry["intent_lbl"].queue_free()
		entry["btn"].queue_free()
		entry["name_lbl"].queue_free()
		entry["hp_bar"].queue_free()
		entry["hp_lbl"].queue_free()
		entry["block_lbl"].queue_free()
		entry["status_box"].queue_free()
	_enemy_nodes.clear()
	_enemy_status_containers.clear()

	var total: int = 0
	while total < MAX_ENEMY_COUNT and BattleManager.get_enemy(total) != null:
		total += 1

	for i in range(total):
		var entry: Dictionary = _make_enemy_slot(i, total)
		_enemy_nodes.append(entry)
		_enemy_char_nodes.append(null)
		_enemy_status_containers.append(entry["status_box"])

		var enemy: Resource = BattleManager.get_enemy(i)
		entry["panel"].visible = true
		entry["btn"].visible = true
		entry["btn"].disabled = false
		entry["name_lbl"].text = tr(enemy.get("enemy_name")) if enemy.get("enemy_name") != null else "적"

		# 신화 시그니처 아이콘 + 툴팁 — panel 우측 상단
		_attach_signature_icon(entry["panel"], enemy.get("mythology"))

		var slot_pos: Vector2 = _enemy_slot_pos(i, total)
		if enemy.character_scene != null:
			var char_node = enemy.character_scene.instantiate()
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + 184)
			char_node.scale = Vector2(-1.44, 2.4)
			add_child(char_node)
			_enemy_char_nodes[i] = char_node
		else:
			var placeholder := ColorRect.new()
			placeholder.color = Color(0.45, 0.45, 0.5, 0.6)
			placeholder.size = Vector2(60, 120)
			placeholder.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 30, slot_pos.y + 40)
			add_child(placeholder)
			_enemy_char_nodes[i] = placeholder

		_update_enemy_ui(i)
		_refresh_enemy_counter(i)

func _update_hero_ui(hero_id: String) -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		var hero: Resource = TeamManager.get_hero(hero_id)
		if hero == null:
			return
		var cur_hp: int = TeamManager.get_current_hp(hero_id)
		var block: int = BattleManager.get_hero_block(hero_id)
		var status: Dictionary = BattleManager.get_hero_status(hero_id)
		var morale: int = status.get("morale", 0)
		var _bar: Control = entry["hp_bar"]
		var _ratio: float = float(cur_hp) / float(hero.max_hp) if hero.max_hp > 0 else 0.0
		var _fill: TextureRect = _bar.get_node("Fill")
		_fill.size.x = _bar.size.x * _ratio
		_apply_hp_state(_bar, _fill, _ratio, false)
		_apply_hp_change(_bar, _ratio)
		_apply_shield(_bar, _ratio, block, hero.max_hp)
		entry["hp_lbl"].text = "%d / %d" % [cur_hp, hero.max_hp]
		var block_str: String = "🛡%d " % block if block > 0 else ""
		var morale_str: String = "★%d" % morale if morale > 0 else ""
		entry["block_lbl"].text = block_str + morale_str
		if not TeamManager.is_alive(hero_id):
			entry["panel"].modulate = Color(0.4, 0.4, 0.4)
		_refresh_status_icons_hero(hero_id)
		_refresh_token_tiles(hero_id)
		return

func _refresh_token_tiles(hero_id: String) -> void:
	if _token_tile_nodes.has(hero_id):
		for node in _token_tile_nodes[hero_id]:
			node.queue_free()
	_token_tile_nodes[hero_id] = []

	if not TeamManager.is_alive(hero_id):
		return

	var token_count: int = BattleManager.get_hero_status(hero_id).get("tokens", 0)
	if token_count <= 0:
		return

	var hero_idx: int = -1
	for i in range(_hero_nodes.size()):
		if _hero_nodes[i]["hero_id"] == hero_id:
			hero_idx = i
			break
	if hero_idx < 0:
		return

	var area_pos := _summon_area_pos(hero_idx)
	var max_tokens: int = TOKEN_COLS * TOKEN_ROWS

	for t in range(min(token_count, max_tokens)):
		var col: int = int(t / float(TOKEN_ROWS))
		var row: int = t % TOKEN_ROWS
		var tile_x: int = int(area_pos.x) + col * (TOKEN_TILE_W + TOKEN_TILE_GAP)
		var tile_y: int = int(area_pos.y) + row * (TOKEN_TILE_H + TOKEN_TILE_GAP)

		# 병사 캐릭터 씬 (2배 스케일)
		var char_node = SoldierScene.instantiate()
		char_node.scale = Vector2(2.0, 2.0)
		char_node.position = Vector2(tile_x + TOKEN_TILE_W / 2.0 - 40.0, tile_y + TOKEN_TILE_H / 4.0)
		add_child(char_node)
		_token_tile_nodes[hero_id].append(char_node)

func _update_enemy_ui(index: int) -> void:
	var entry: Dictionary = _enemy_nodes[index]
	var enemy: Resource = BattleManager.get_enemy(index)
	if enemy == null:
		return
	var cur_hp: int = BattleManager.get_enemy_hp(index)
	var block: int = BattleManager.get_enemy_block(index)
	var is_boss_enemy: bool = enemy.grade == EnemyResource.Grade.BOSS
	var _bar: Control = entry["hp_bar"]
	var _ratio: float = float(cur_hp) / float(enemy.max_hp) if enemy.max_hp > 0 else 0.0
	var _fill: TextureRect = _bar.get_node("Fill")
	_fill.size.x = _bar.size.x * _ratio
	_apply_hp_state(_bar, _fill, _ratio, is_boss_enemy)
	_apply_hp_change(_bar, _ratio)
	_apply_shield(_bar, _ratio, block, enemy.max_hp)
	# 차지 중 카드의 예측 데미지 — 사망 예정 표시 + btn 비활성화 + panel dim
	var pending: int = BattleManager.get_pending_dmg(index)
	var doomed: bool = BattleManager.is_enemy_doomed(index)
	if pending > 0:
		entry["hp_lbl"].text = "%d / %d  (-%d)" % [cur_hp, enemy.max_hp, pending]
	else:
		entry["hp_lbl"].text = "%d / %d" % [cur_hp, enemy.max_hp]
	entry["block_lbl"].text = "🛡%d" % block if block > 0 else ""
	if doomed:
		entry["panel"].modulate = Color(0.5, 0.5, 0.5, 1.0)
		entry["btn"].disabled = true
	else:
		entry["panel"].modulate = Color.WHITE
		# btn 의 enable 상태는 다른 경로(turn 변화 등)가 결정 — 사망 예정 해제 시는 유지

	# 의도 표시
	var intent: Resource = BattleManager.get_enemy_current_intent(index)
	if intent != null:
		entry["intent_lbl"].modulate = _intent_color(intent.action_type)
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				entry["intent_lbl"].text = _trf("battle.intent.attack", intent.value)
			IntentRes.ActionType.BUFF:
				match intent.status_type:
					"strength": entry["intent_lbl"].text = _trf("battle.intent.buff.strength", intent.value)
					_:          entry["intent_lbl"].text = _trf("battle.intent.buff.block", intent.value)
			IntentRes.ActionType.DEBUFF:
				entry["intent_lbl"].text = tr("battle.intent.debuff")
			IntentRes.ActionType.PREPARE:
				entry["intent_lbl"].text = tr("battle.intent.prepare")
			IntentRes.ActionType.HEAL_ALLY:
				entry["intent_lbl"].text = _trf("battle.intent.heal_ally", intent.value)
			IntentRes.ActionType.BUFF_ALLY:
				entry["intent_lbl"].text = _trf("battle.intent.buff_ally", intent.value)
			IntentRes.ActionType.COUNTER_PREPARE:
				entry["intent_lbl"].text = _trf("battle.intent.counter_prepare", intent.value)
			IntentRes.ActionType.MARK_TARGET:
				entry["intent_lbl"].text = tr("battle.intent.mark_target")
			IntentRes.ActionType.SACRIFICE:
				entry["intent_lbl"].text = _trf("battle.intent.sacrifice", intent.value)
			IntentRes.ActionType.WARD:
				entry["intent_lbl"].text = _trf("battle.intent.ward", intent.value)
			IntentRes.ActionType.SUMMON:
				entry["intent_lbl"].text = _trf("battle.intent.summon", max(1, intent.value))
			IntentRes.ActionType.MIMIC:
				entry["intent_lbl"].text = _trf("battle.intent.mimic", intent.value)
			IntentRes.ActionType.SPECIAL:
				entry["intent_lbl"].text = tr("battle.intent.special")
			_:
				entry["intent_lbl"].text = "?"

	if not BattleManager.is_enemy_alive(index):
		entry["panel"].modulate = Color(0.3, 0.3, 0.3)
		entry["btn"].disabled = true
		entry["intent_lbl"].text = tr("battle.intent.dead")

	_refresh_status_icons_enemy(index)

func _drag_hint_text() -> String:
	if _drag_card == null:
		return ""
	match _card_target_type(_drag_card):
		"enemy":    return tr("battle.drag_enemy")
		"ally":     return tr("battle.drag_ally")
		"dead_ally": return tr("battle.drag_dead_ally")
		_:          return tr("battle.drag_release")

func _intent_color(action_type: int) -> Color:
	match action_type:
		IntentRes.ActionType.ATTACK:  return Color(1.0, 0.35, 0.35)
		IntentRes.ActionType.BUFF:    return Color(0.4, 0.85, 1.0)
		IntentRes.ActionType.DEBUFF:  return Color(0.75, 0.4, 1.0)
		IntentRes.ActionType.PREPARE: return Color(0.75, 0.75, 0.75)
		_:                            return Color(1.0, 0.8, 0.2)

# ─────────────────────────────────────────────
# 카드 핸드 (Task 3에서 구현)
# ─────────────────────────────────────────────

func _apply_card_state(node: CardScene, card_res: Resource) -> void:
	if not TeamManager.is_alive(card_res.owner_id):
		node.set_owner_dead(true)
	else:
		node.set_owner_dead(false)
		node.set_disabled(not DeckManager.can_play(card_res))

func _refresh_hand() -> void:
	for n in _card_buttons:
		if is_instance_valid(n):
			n.queue_free()
	_card_buttons.clear()

	var hand: Array = DeckManager.hand
	if hand.is_empty():
		return

	var n_cards: int = hand.size()
	var step: float = FAN_ANGLE_PER_CARD if n_cards <= 1 else \
		minf(FAN_ANGLE_PER_CARD, FAN_MAX_TOTAL_ANGLE / float(n_cards - 1))
	var fan_pivot := Vector2(WINDOW_W / 2.0, HAND_BASE_Y + FAN_PIVOT_Y_OFFSET)
	var half_card := Vector2(70, 100) * BASE_CARD_SCALE

	for i in range(n_cards):
		var card: Resource = hand[i]
		var node: CardScene = CARD_SCENE.instantiate()
		var angle: float = (i - (n_cards - 1) / 2.0) * step
		var arc_pos: Vector2 = fan_pivot + Vector2(sin(angle), -cos(angle)) * FAN_PIVOT_Y_OFFSET
		node.position = arc_pos - half_card
		node.rotation = angle
		node.pivot_offset = Vector2(70, 100)
		node.scale = Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE)
		node.z_index = 10 + i
		node.set_meta("_fan_pos", node.position)
		node.set_meta("_fan_rot", node.rotation)
		node.set_meta("_fan_idx", i)
		node.set_meta("_fan_center", arc_pos)
		node.set_meta("_fan_title_pos", arc_pos + Vector2(0, -70.0 * BASE_CARD_SCALE).rotated(angle))
		node.set_meta("_card_res", card)
		node.setup(card, node.Mode.HAND)
		_apply_card_state(node, card)
		node.card_clicked.connect(_on_card_clicked)
		node.card_drag_started.connect(_on_card_drag_started)
		node.card_drag_moved.connect(_on_card_drag_moved)
		node.card_drag_released.connect(_on_card_drag_released)
		var captured_node := node
		node.card_hovered.connect(func(c: Resource): _on_card_hovered(c, captured_node))
		node.card_unhovered.connect(_on_card_unhovered)
		add_child(node)
		_card_buttons.append(node)

# ─────────────────────────────────────────────
# 인터랙션 핸들러 (Task 4~5에서 구현)
# ─────────────────────────────────────────────

func _on_card_clicked(card: Resource) -> void:
	if not _card_pick_in_progress:
		return
	for node in _card_buttons:
		if is_instance_valid(node):
			node.hide_glow()
	_picked_card = card
	for node in _card_buttons:
		if is_instance_valid(node) and node.get_meta("_card_res", null) == card:
			node.set_glow_color(SacredPalette.BRASS_500)
			node.show_glow(2.2)
			break
	if _pick_confirm_btn != null:
		_pick_confirm_btn.disabled = false

func _on_card_drag_started(card: Resource, screen_pos: Vector2) -> void:
	if _card_pick_in_progress:
		return
	if not BattleManager.is_player_turn or not DeckManager.can_play(card):
		return
	_drag_start_pos = screen_pos
	_drag_no_chevron = _card_target_type(card) == "none"
	for btn in _card_buttons:
		if is_instance_valid(btn) and btn.get_meta("_card_res", null) == card:
			_drag_start_pos = btn.get_meta("_fan_center", screen_pos)
			btn.modulate = Color(1.0, 1.0, 1.0, 0.4)
			break
	_drag_cancel_ready = false
	get_tree().create_timer(0.25).timeout.connect(func(): _drag_cancel_ready = true)
	_start_drag(card)
	_create_drag_arrow(screen_pos)

func _on_card_drag_moved(_card: Resource, screen_pos: Vector2) -> void:
	_drag_end_pos = screen_pos
	_update_drag_arrow(screen_pos)
	_message_label.text = tr("battle.cancel_use") if _drag_cancel_ready and screen_pos.y >= BOTTOM_Y else _drag_hint_text()

func _on_card_drag_released(_card: Resource, screen_pos: Vector2) -> void:
	if _drag_card != null:
		_finish_drag(screen_pos)

func _on_card_hovered(_card: Resource, card_node: CardScene) -> void:
	if _drag_card != null:
		return
	AudioManager.play_sfx("card_hover")
	var hover_idx: int = card_node.get_meta("_fan_idx", -1)
	if hover_idx < 0:
		return
	for btn in _card_buttons:
		if not is_instance_valid(btn):
			continue
		var idx: int = btn.get_meta("_fan_idx", 0)
		var base_pos: Vector2 = btn.get_meta("_fan_pos")
		var base_rot: float = btn.get_meta("_fan_rot")
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		if idx == hover_idx:
			var hover_scale := BASE_CARD_SCALE * 1.4
			# 호버 후 카드 하단 y = base_pos.y + hover_scale * 100 + 100
			var card_bottom := base_pos.y + hover_scale * 100.0 + 100.0
			var lift := maxf(60.0, card_bottom - (WINDOW_H - 20.0))
			tw.tween_property(btn, "scale", Vector2(hover_scale, hover_scale), 0.12)
			tw.tween_property(btn, "position", base_pos + Vector2(0, -lift), 0.12)
			tw.tween_property(btn, "rotation", 0.0, 0.12)
			btn.z_index = 200
		else:
			var dist: int = idx - hover_idx
			var sign_x: float = 1.0 if dist > 0 else -1.0
			var falloff: float = maxf(0.0, 1.0 - abs(dist) / 4.0)
			tw.tween_property(btn, "position", base_pos + Vector2(sign_x * 35.0 * falloff, 0), 0.12)
			tw.tween_property(btn, "rotation", base_rot, 0.12)
			tw.tween_property(btn, "scale", Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE), 0.12)
			btn.z_index = 10 + idx

func _on_card_unhovered(_card: Resource) -> void:
	_reset_hand_fan()

func _reset_hand_fan() -> void:
	for btn in _card_buttons:
		if not is_instance_valid(btn):
			continue
		var idx: int = btn.get_meta("_fan_idx", 0)
		var tw := create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(btn, "position", btn.get_meta("_fan_pos"), 0.12)
		tw.tween_property(btn, "rotation", btn.get_meta("_fan_rot"), 0.12)
		tw.tween_property(btn, "scale", Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE), 0.12)
		btn.z_index = idx

func _on_enemy_pressed(index: int) -> void:
	if _debug_hp_target_mode and OS.is_debug_build():
		_debug_hp_target_mode = false
		_open_enemy_hp_dialog(index)
		return

func _open_enemy_hp_dialog(index: int) -> void:
	var current_hp: int = BattleManager._enemy_hp[index] if index < BattleManager._enemy_hp.size() else 0
	var dlg := AcceptDialog.new()
	dlg.title = "적[%d] HP 설정 (현재: %d)" % [index, current_hp]
	dlg.add_cancel_button("취소")
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = 2147483647
	spin.value = current_hp
	spin.step = 1
	dlg.add_child(spin)
	dlg.min_size = Vector2i(320, 100)
	dlg.confirmed.connect(func():
		BattleManager.debug_set_enemy_hp(index, int(spin.value))
		_message_label.text = "[DEBUG] 적[%d] HP → %d" % [index, int(spin.value)]
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
	spin.get_line_edit().grab_focus()
	spin.get_line_edit().select_all()

func _open_hero_slot_hp_dialog(hero_id: String) -> void:
	var cur_hp: int = TeamManager.get_current_hp(hero_id)
	var hero_res = TeamManager.get_hero(hero_id)
	var max_hp: int = hero_res.max_hp if hero_res else 9999
	var hero_name: String = tr(hero_res.hero_name) if hero_res else hero_id
	var dlg := AcceptDialog.new()
	dlg.title = "%s HP 설정 (현재: %d / %d)" % [hero_name, cur_hp, max_hp]
	dlg.add_cancel_button("취소")
	var spin := SpinBox.new()
	spin.min_value = 0
	spin.max_value = max_hp
	spin.value = cur_hp
	spin.step = 1
	dlg.add_child(spin)
	dlg.min_size = Vector2i(340, 100)
	dlg.confirmed.connect(func():
		var val: int = int(spin.value)
		if val <= 0:
			if TeamManager.is_alive(hero_id):
				TeamManager.take_damage(hero_id, TeamManager.get_current_hp(hero_id))
		elif not TeamManager.is_alive(hero_id):
			TeamManager.revive(hero_id, val)
		else:
			TeamManager._hero_hp[hero_id] = val
			TeamManager.hero_healed.emit(hero_id, 0)
		_message_label.text = "[DEBUG] %s HP → %d" % [hero_name, val]
		dlg.queue_free()
	)
	dlg.canceled.connect(func(): dlg.queue_free())
	add_child(dlg)
	dlg.popup_centered()
	spin.get_line_edit().grab_focus()
	spin.get_line_edit().select_all()

func _on_end_turn_pressed() -> void:
	if _card_pick_in_progress:
		return
	_selected_card = null
	_message_label.text = ""
	_end_turn_btn.disabled = true
	BattleManager.end_player_turn()

func _on_player_turn_started() -> void:
	AudioManager.play_sfx("card_draw")
	_end_turn_btn.disabled = false
	_message_label.text = tr("battle.msg_player_turn")
	_energy_label.text = "%d/%d" % [DeckManager.current_energy, DeckManager.MAX_ENERGY]
	# 영웅 블록 UI 갱신 (start_player_turn이 블록 초기화했으므로)
	for entry in _hero_nodes:
		var hid: String = entry["hero_id"]
		if hid != "":
			_update_hero_ui(hid)
	# 적 의도 갱신
	for i in range(_enemy_nodes.size()):
		if _enemy_nodes[i]["panel"].visible:
			_update_enemy_ui(i)
	# 살아있는 적 클릭 버튼 재활성
	for i in range(_enemy_nodes.size()):
		if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
			_enemy_nodes[i]["btn"].disabled = false
	_refresh_synergy_hud()

func _on_enemy_turn_started() -> void:
	_end_turn_btn.disabled = true
	_selected_card = null
	_message_label.text = tr("battle.msg_enemy_turn")
	_last_card_play_pos = Vector2.ZERO
	_signatures_shown_this_turn.clear()  # 시그니처 토스트 throttle 리셋 (1회/턴)
	# 적 클릭 버튼 비활성
	for entry in _enemy_nodes:
		if entry["panel"].visible and not entry["btn"].disabled:
			entry["btn"].disabled = true

func _on_energy_changed(new_energy: int) -> void:
	_energy_label.text = "%d / %d" % [new_energy, DeckManager.MAX_ENERGY]
	# 카드 노드 활성/비활성 갱신
	var hand: Array = DeckManager.hand
	for i in range(min(_card_buttons.size(), hand.size())):
		_apply_card_state(_card_buttons[i], hand[i])

func _on_card_played(card: Resource) -> void:
	call_deferred("_refresh_all_hero_ui")
	# VFX (DAMAGE/BLOCK/HEAL/APPLY_STATUS) 는 BattleManager.card_vfx_charge_start → _on_card_vfx_start 가 처리.
	# 여기서는 영웅 attack 애니메이션만 (anim_speed_multiplier 적용).
	var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
	var anim_name: String = card.get("play_animation") if card.get("play_animation") != null else ""
	if anim_name == "":
		return
	var char_node = _hero_char_nodes.get(owner_id)
	if char_node == null or not char_node.has_node("AnimationPlayer"):
		return
	var anim_player: AnimationPlayer = char_node.get_node("AnimationPlayer")
	var gs := get_node_or_null("/root/GameSettings")
	anim_player.speed_scale = gs.anim_speed_multiplier if gs else 1.0
	if anim_player.has_animation(anim_name):
		anim_player.play(anim_name)

func _refresh_all_hero_ui() -> void:
	for entry in _hero_nodes:
		if entry["hero_id"] != "":
			_update_hero_ui(entry["hero_id"])

func _play_hit_flash(node: Node2D) -> void:
	if node == null: return
	if node.has_method("flash"):
		node.flash(Color(1.0, 0.2, 0.2, 1.0), 0.18)

# ice 명중 시 타겟이 잠시 푸르게 얼어붙음 (HTML .target.frozen 필터 근사)
func _apply_frozen_tint(node: Node2D) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(0.66, 0.82, 1.3), 0.15)
	tw.tween_interval(1.5)
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.45)

# fire 명중 시 타겟이 잠시 그을림 (HTML .target.scorched 근사) — 잔불 시간 동안 유지
func _apply_scorched_tint(node: Node2D) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(0.55, 0.4, 0.32), 0.2)
	tw.tween_interval(1.5)
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.8)

# poison 명중 시 타겟이 잠시 독성 녹색으로 물듦 (HTML .target.poisoned 근사)
func _apply_poisoned_tint(node: Node2D) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(0.72, 1.05, 0.55), 0.25)
	tw.tween_interval(2.0)
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.7)

# 디버프 적용 시 타겟이 잠시 칙칙하게 약화됨 (HTML .target.weakened 근사)
func _apply_weakened_tint(node: Node2D) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(0.62, 0.55, 0.7), 0.25)
	tw.tween_interval(1.3)
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.7)

# 매혹 적용 시 타겟이 잠시 분홍빛으로 물듦 (HTML .target.charmed 근사)
func _apply_charmed_tint(node: Node2D) -> void:
	if node == null: return
	var tw := node.create_tween()
	tw.tween_property(node, "modulate", Color(1.25, 0.78, 1.05), 0.25)
	tw.tween_interval(1.5)
	tw.tween_property(node, "modulate", Color(1, 1, 1), 0.7)

# 상태이상(디버프/매혹) VFX 발동 — 같은 타겟·종류 연속 적용은 0.5초 디바운스
func _spawn_status_vfx(target: String, kind: String, beam_script: GDScript, sfx: String) -> void:
	var cd_key := target + "/" + kind
	var now := Time.get_ticks_msec()
	if now - int(_status_vfx_cd.get(cd_key, 0)) < 500:
		return
	_status_vfx_cd[cd_key] = now
	var char_node: Node2D = null
	if target.begins_with("enemy_"):
		var idx := target.substr(6).to_int()
		char_node = _enemy_char_nodes[idx] if idx < _enemy_char_nodes.size() else null
	else:
		char_node = _hero_char_nodes.get(target)
	if char_node == null:
		return
	var target_pos: Vector2 = char_node.global_position
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_shake()
		AudioManager.play_sfx(sfx)
	)
	fx.play(_resolve_caster_pos(BattleManager._vfx_caster, target_pos), target_pos)
	if kind == "hex":
		_apply_weakened_tint(char_node)
	elif kind == "charm":
		_apply_charmed_tint(char_node)

func _play_status_flash(node: Node2D, status_color: Color) -> void:
	if node == null: return
	if node.has_method("flash"):
		node.flash(Color(status_color.r, status_color.g, status_color.b, 0.85), 0.45)

func _play_hit_shake(node: Node2D, amount: int) -> void:
	if node == null or amount <= 0: return
	if node.has_meta("_shake_tween"):
		var prev: Tween = node.get_meta("_shake_tween")
		if prev and prev.is_valid():
			prev.kill()
			node.position = node.get_meta("_shake_orig_pos") if node.has_meta("_shake_orig_pos") else node.position
	var mag: float = 6.0
	if amount >= 100: mag = 20.0
	elif amount >= 30: mag = 12.0
	var orig: Vector2 = node.position
	node.set_meta("_shake_orig_pos", orig)
	var tw := create_tween()
	tw.tween_property(node, "position", orig + Vector2(-mag, 0), 0.04)
	tw.tween_property(node, "position", orig + Vector2(mag * 0.7, 0), 0.06)
	tw.tween_property(node, "position", orig + Vector2(-mag * 0.4, 0), 0.06)
	tw.tween_property(node, "position", orig, 0.08)
	node.set_meta("_shake_tween", tw)


const _POPUP_FONT := preload("res://assets/fonts/Cinzel-Bold.ttf")
var _popup_main_ls: Dictionary = {}  # font_size → 메인 LabelSettings
# 글로우 halo — outline 크기별 캐시. "{size}_{outline}" → LabelSettings
var _popup_halo_ls: Dictionary = {}

func _get_popup_main_ls(font_size: int) -> LabelSettings:
	if not _popup_main_ls.has(font_size):
		var ls := LabelSettings.new()
		ls.font = _POPUP_FONT
		ls.font_size = font_size
		_popup_main_ls[font_size] = ls
	return _popup_main_ls[font_size]

# halo Label 의 LabelSettings — outline 만으로 글자 윤곽 글로우 (font_color 는 modulate 로 조절)
func _get_popup_halo_ls(font_size: int, outline_size: int, color: Color) -> LabelSettings:
	var key := "%d_%d_%08x" % [font_size, outline_size, color.to_rgba32()]
	if not _popup_halo_ls.has(key):
		var ls := LabelSettings.new()
		ls.font = _POPUP_FONT
		ls.font_size = font_size
		# font 자체는 거의 안 보이게 (alpha 0) — outline 만 표시
		ls.font_color = Color(color.r, color.g, color.b, 0.0)
		ls.outline_color = color
		ls.outline_size = outline_size
		_popup_halo_ls[key] = ls
	return _popup_halo_ls[key]

# 본 글씨는 거의 흰색 — 타입 색 15% 만 섞음
func _popup_text_color(color: Color) -> Color:
	return Color.WHITE.lerp(color, 0.15)

# halo 레이어 N장 — 각 outline 점점 작게, alpha 점점 진하게 → 글자 윤곽 부드러운 글로우
const _POPUP_HALO_LAYERS := [
	{"outline": 48, "alpha": 0.05},
	{"outline": 36, "alpha": 0.08},
	{"outline": 26, "alpha": 0.13},
	{"outline": 18, "alpha": 0.20},
	{"outline": 11, "alpha": 0.28},
	{"outline":  6, "alpha": 0.40},
]

func _add_popup_halo(container: Node2D, text: String, font_size: int, color: Color) -> void:
	for layer in _POPUP_HALO_LAYERS:
		var halo := Label.new()
		halo.text = text
		halo.label_settings = _get_popup_halo_ls(font_size, layer["outline"], color)
		halo.modulate.a = layer["alpha"]
		container.add_child(halo)
		halo.reset_size()
		halo.position = -halo.size / 2.0

# 색은 VFX HTML 톤 — 채도 낮춤 + 밝기 ↑ (촌스러운 원색 회피)
const _STATUS_POPUP_INFO := {
	"weak":          ["Weak",          Color(1.00, 0.65, 0.30)],   # rgba(255,166,77)  부드러운 오렌지
	"vulnerable":    ["Vulnerable",    Color(0.75, 0.50, 1.00)],   # rgba(191,128,255) 라벤더 보라
	"poison":        ["Poison",        Color(0.71, 1.00, 0.35)],   # rgba(180,255,90)  라임
	"strength":      ["Strength",      Color(1.00, 0.92, 0.62)],   # rgba(255,235,160) 따뜻한 골드
	"charm":         ["Charm",         Color(1.00, 0.60, 0.85)],   # rgba(255,153,217) 로즈핑크
	"enthrall":      ["Enthralled",    Color(0.70, 0.55, 1.00)],   # rgba(179,140,255) 라일락
	"taunt":         ["Taunt",         Color(1.00, 0.62, 0.32)],   # rgba(255,158,82)  코랄
	"morale":        ["Morale",        Color(1.00, 0.95, 0.65)],   # rgba(255,242,166) 옅은 골드
	"counter_block": ["Counter Block", Color(0.60, 0.85, 1.00)],   # rgba(153,217,255) 부드러운 하늘
}

func _spawn_popup(base_pos: Vector2, text: String, color: Color, font_size: int, stack_key: String) -> void:
	var count: int = _popup_stack.get(stack_key, 0)
	_popup_stack[stack_key] = count + 1
	var tint: Color = _popup_text_color(color)
	var container := Node2D.new()
	container.z_index = 20
	add_child(container)
	# 글로우 halo — N장 outline 겹침 (글자 윤곽 부드럽게 퍼짐)
	_add_popup_halo(container, text, font_size, color)
	# 메인 Label — 흰 톤 + 작은 outline
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = tint * 1.4
	lbl.label_settings = _get_popup_main_ls(font_size)
	container.add_child(lbl)
	lbl.reset_size()
	lbl.position = -lbl.size / 2.0
	# 위치 — base_pos 를 중심으로
	var spawn_pos := Vector2(base_pos.x + randf_range(-15.0, 15.0), base_pos.y + count * 32.0)
	container.position = spawn_pos
	container.scale = Vector2.ZERO
	# scale punch + 등장 하이라이트 + 부동/페이드 (모두 container 의 property)
	var tw := create_tween()
	tw.tween_property(container, "scale", Vector2(1.3, 1.3), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(container, "scale", Vector2(1.0, 1.0), 0.08)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "modulate", tint, 0.12)
	tw.tween_property(container, "position:y", spawn_pos.y - 60.0, 0.7)
	tw.tween_property(container, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(func() -> void:
		container.queue_free()
		_popup_stack[stack_key] = max(0, _popup_stack.get(stack_key, 1) - 1)
	)

func _spawn_damage_popup(world_pos: Vector2, amount: int, fully_blocked: bool, stack_key: String) -> void:
	if fully_blocked:
		_spawn_popup(world_pos, "Block", Color(0.55, 0.78, 1.00), 36, stack_key)   # rgba(140,200,255)
	else:
		_spawn_popup(world_pos, str(amount), Color(1.00, 0.31, 0.31), 36, stack_key)  # rgba(255,80,80)

func _spawn_heal_popup(world_pos: Vector2, amount: int, stack_key: String) -> void:
	_spawn_popup(world_pos, "+" + str(amount), Color(0.71, 1.00, 0.35), 36, stack_key)  # rgba(180,255,90) lime

func _spawn_status_popup(world_pos: Vector2, status_type: String, stack_key: String) -> void:
	if not _STATUS_POPUP_INFO.has(status_type):
		return
	var info: Array = _STATUS_POPUP_INFO[status_type]
	var count: int = _popup_stack.get(stack_key, 0)
	_popup_stack[stack_key] = count + 1
	var status_color: Color = info[1]
	var tint: Color = _popup_text_color(status_color)
	var container := Node2D.new()
	container.z_index = 20
	add_child(container)
	_add_popup_halo(container, info[0], 32, status_color)
	var lbl := Label.new()
	lbl.text = info[0]
	lbl.modulate = tint * 1.4
	lbl.label_settings = _get_popup_main_ls(32)
	container.add_child(lbl)
	lbl.reset_size()
	lbl.position = -lbl.size / 2.0
	var spawn_pos := Vector2(world_pos.x + randf_range(-15.0, 15.0), world_pos.y + count * 32.0)
	container.position = spawn_pos
	container.scale = Vector2.ZERO
	var tw := create_tween()
	tw.tween_property(container, "scale", Vector2(1.3, 1.3), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(container, "scale", Vector2(1.0, 1.0), 0.08)
	tw.chain().set_parallel(true)
	tw.tween_property(lbl, "modulate", tint, 0.12)
	tw.tween_property(container, "position:y", spawn_pos.y - 55.0, 0.7)
	tw.tween_property(container, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(func() -> void:
		container.queue_free()
		_popup_stack[stack_key] = max(0, _popup_stack.get(stack_key, 1) - 1)
	)

func _start_target_bloom(panel: ColorRect, bloom_color: Color) -> void:
	var panel_center := panel.size * 0.5
	for child in panel.get_children():
		if not child.get_meta("_corner_bracket", false):
			continue
		var br: ColorRect = child
		var is_h: bool = br.size.x > br.size.y
		var dir := ((br.position + br.size * 0.5) - panel_center).normalized()
		var orig_pos := br.position
		br.pivot_offset = br.size * 0.5
		br.set_meta("_bloom_orig_pos", orig_pos)
		# 색 깜빡임: 원래 brass 색 ↔ 타겟 색
		var tw_c := br.create_tween().set_loops()
		tw_c.tween_property(br, "modulate", bloom_color, 0.35).set_trans(Tween.TRANS_SINE)
		tw_c.tween_property(br, "modulate", Color.WHITE,  0.35).set_trans(Tween.TRANS_SINE)
		br.set_meta("_bloom_tween_c", tw_c)
		# 간격 진동: 코너 바깥으로 5px 왕복
		var tw_p := br.create_tween().set_loops()
		tw_p.tween_property(br, "position", orig_pos + dir * 5.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_p.tween_property(br, "position", orig_pos,              0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		br.set_meta("_bloom_tween_p", tw_p)
		# 두께 2배 진동: H-bar는 y축, V-bar는 x축으로 scale
		var fat_scale := Vector2(1.0, 3.0) if is_h else Vector2(3.0, 1.0)
		var tw_s := br.create_tween().set_loops()
		tw_s.tween_property(br, "scale", fat_scale,      0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw_s.tween_property(br, "scale", Vector2.ONE,    0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		br.set_meta("_bloom_tween_s", tw_s)

func _stop_target_bloom(panel: ColorRect) -> void:
	for child in panel.get_children():
		if not child.get_meta("_corner_bracket", false):
			continue
		var br: ColorRect = child
		for key in ["_bloom_tween_c", "_bloom_tween_p", "_bloom_tween_s"]:
			if br.has_meta(key):
				var tw: Tween = br.get_meta(key)
				if tw and tw.is_valid(): tw.kill()
				br.remove_meta(key)
		br.modulate = Color.WHITE
		br.scale = Vector2.ONE
		if br.has_meta("_bloom_orig_pos"):
			br.position = br.get_meta("_bloom_orig_pos")
			br.remove_meta("_bloom_orig_pos")


const _VFX_SCENES: Dictionary = {
	"slash":      preload("res://scenes/vfx/slash_particle.tscn"),
	"divine":     preload("res://scenes/vfx/divine_particle.tscn"),
	# curse 는 _caster_beam_script 에서 debuff_hex 빔으로 처리
}
const _VFX_DEFAULT: PackedScene = preload("res://scenes/vfx/default_particle.tscn")
# lightning/ice/fire/poison/projectile/explosive은 시전자→타겟 빔 타입 — 별도 경로 (_spawn_caster_beam)
const _VFX_LIGHTNING_BEAM := preload("res://scenes/vfx/lightning_beam.gd")
const _VFX_ICE_SHARDS := preload("res://scenes/vfx/ice_shards.gd")
const _VFX_FIRE_BLAST := preload("res://scenes/vfx/fire_blast.gd")
const _VFX_POISON_SPLASH := preload("res://scenes/vfx/poison_splash.gd")
const _VFX_ARROW_SHOT := preload("res://scenes/vfx/arrow_shot.gd")
const _VFX_EXPLOSION_BLAST := preload("res://scenes/vfx/explosion_blast.gd")
const _VFX_BLUNT_SMASH := preload("res://scenes/vfx/blunt_smash.gd")
const _VFX_BULLET_SHOT := preload("res://scenes/vfx/bullet_shot.gd")
const _VFX_HOLY_STRIKE := preload("res://scenes/vfx/holy_strike.gd")
const _VFX_HOLY_SLASH := preload("res://scenes/vfx/holy_slash.gd")
const _VFX_HOLY_ARROW := preload("res://scenes/vfx/holy_arrow.gd")
const _VFX_HOLY_FIRE := preload("res://scenes/vfx/holy_fire.gd")
const _VFX_HOLY_BLUNT := preload("res://scenes/vfx/holy_blunt.gd")
# 사망/부활 VFX — 빔이 아니라 대상 위치에서만 발동
const _VFX_DEATH_DISSOLVE := preload("res://scenes/vfx/death_dissolve.gd")
const _VFX_REVIVE_BLESSING := preload("res://scenes/vfx/revive_blessing.gd")
# slash 명중 시 기존 베기 파티클에 더해 발동하는 피 분출
const _VFX_BLOOD_SPRAY := preload("res://scenes/vfx/blood_spray.gd")
const _VFX_DEBUFF_HEX := preload("res://scenes/vfx/debuff_hex.gd")
const _VFX_CHARM_KISS := preload("res://scenes/vfx/charm_kiss.gd")
const _VFX_INFATUATION := preload("res://scenes/vfx/infatuation.gd")
const _VFX_POISON_TICK := preload("res://scenes/vfx/poison_tick.gd")
const _VFX_HEAL_BLESSING := preload("res://scenes/vfx/heal_blessing.gd")
const _VFX_HOLY_BUFF := preload("res://scenes/vfx/holy_buff.gd")
const _VFX_WARRIOR_BUFF := preload("res://scenes/vfx/warrior_buff.gd")
const _VFX_BLOCK: PackedScene = preload("res://scenes/vfx/block_particle.tscn")
const _VFX_DEFENSE_BUFF := preload("res://scenes/vfx/defense_buff.gd")

# lightning으로 죽는 적/영웅 — 사망 연출을 빔 임팩트 시점까지 지연하기 위한 빔 참조
# key: "enemy_%d" 또는 hero_id → lightning_beam 인스턴스
var _lit_death_beam: Dictionary = {}

# 상태이상 VFX(디버프/매혹) — 같은 타겟·종류 연속 적용 시 중복 발동 방지
# key: "target/kind" → 마지막 발동 ticks_msec
var _status_vfx_cd: Dictionary = {}

func _spawn_self_particles(pos: Vector2, scene: PackedScene) -> void:
	var fx: Node2D = scene.instantiate()
	fx.autostart = false
	fx.repeat = false
	add_child(fx)
	fx.global_position = pos
	fx.burst()
	var shield := fx.get_node_or_null("ShieldIcon")
	if shield:
		shield.play_shield()

func _spawn_impact_particles(pos: Vector2, amount: int, flipped: bool = false, dtype: String = "") -> void:
	if amount <= 0:
		return
	var scene: PackedScene = _VFX_SCENES.get(dtype, _VFX_DEFAULT)
	var fx: Node2D = scene.instantiate()
	if "autostart" in fx:
		fx.autostart = false
	if "repeat" in fx:
		fx.repeat = false
	add_child(fx)
	fx.global_position = pos
	fx.scale.x = -1.0 if flipped else 1.0
	var slash_rot := randf_range(0.0, TAU)
	if dtype == "slash":
		fx.rotation = slash_rot
	fx.burst()
	AudioManager.play_sfx("impact_" + (dtype if dtype != "" else "default"))
	# slash는 기존 베기 파티클에 더해 피 분출을 추가로 발동 (베기 방향으로 분출)
	if dtype == "slash":
		_spawn_blood_spray(pos, slash_rot)

# slash 명중 시 피 분출 — 기존 slash_particle.tscn 과 별개로 추가 발동
func _spawn_blood_spray(pos: Vector2, dir_angle: float = INF) -> void:
	var fx := _VFX_BLOOD_SPRAY.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.play(pos, pos, dir_angle)

# ── 번개 빔 VFX (시전자→타겟) ──────────────────────────────
# caster: BattleManager._vfx_caster — int(적 인덱스) / String(hero_id) / null
func _resolve_caster_pos(caster, target_pos: Vector2) -> Vector2:
	if caster is int:
		if caster >= 0 and caster < _enemy_char_nodes.size():
			var n = _enemy_char_nodes[caster]
			if is_instance_valid(n):
				return n.global_position
	elif caster is String:
		var n = _hero_char_nodes.get(caster)
		if is_instance_valid(n):
			return n.global_position
	# 공격자 노드 무효 — 타겟 위쪽에서 내리꽂는 fallback
	return target_pos + Vector2(0.0, -350.0)

# 사망 VFX — 죽는 대상 위치에 핏물·재·영혼 분출
func _spawn_death_dissolve(pos: Vector2) -> void:
	var fx := _VFX_DEATH_DISSOLVE.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.play(pos, pos)

# 부활 VFX — 부활 대상 위치에 빛기둥·고리·빛 입자
func _spawn_revive_blessing(pos: Vector2) -> void:
	var fx := _VFX_REVIVE_BLESSING.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.play(pos, pos)

# 회복 VFX — 회복 대상 위치에 나뭇잎·반짝임·고리·십자
# screen_effect 시점(차지 끝)에 heal SFX 발동
func _spawn_heal_blessing(pos: Vector2) -> void:
	var fx := _VFX_HEAL_BLESSING.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("heal")
	)
	fx.play(pos, pos)

# 신성 버프 VFX — Joan 의 POWER 카드 발동 시 시전자 위치에 룬링·빛기둥·황금 깃털
# "buff" SFX 자원 없음 → impact_divine 재활용 (신성·강력 톤)
func _spawn_holy_buff(pos: Vector2) -> void:
	var fx := _VFX_HOLY_BUFF.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(pos, pos)

# 전사 버프 VFX — Joan 외 영웅의 POWER 카드 발동 시 분노/주황 가시링·오라·잔불
# "buff" SFX 자원 없음 → impact_blunt 재활용 (분노·강한 충격 톤)
func _spawn_warrior_buff(pos: Vector2) -> void:
	var fx := _VFX_WARRIOR_BUFF.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_blunt")
	)
	fx.play(pos, pos)

# 임팩트 위치를 약간 흔들어 두 발 이상의 VFX 가 같은 점에 겹치지 않게
func _impact_jitter() -> Vector2:
	return Vector2(randf_range(-20.0, 20.0), randf_range(-30.0, 30.0))

# 첫 살아있는 영웅의 char_node 좌표 — 단일 타겟 적 인텐트의 시각적 대표
func _first_living_hero_pos() -> Vector2:
	for entry in _hero_nodes:
		var hid: String = entry["hero_id"]
		if hid == "" or not TeamManager.is_alive(hid):
			continue
		var hnode: Node2D = _hero_char_nodes.get(hid)
		if hnode:
			return hnode.global_position
	return Vector2.ZERO

# 모든 살아있는 영웅의 char_node 좌표
func _all_living_hero_positions() -> Array:
	var out: Array = []
	for entry in _hero_nodes:
		var hid: String = entry["hero_id"]
		if hid == "" or not TeamManager.is_alive(hid):
			continue
		var hnode: Node2D = _hero_char_nodes.get(hid)
		if hnode:
			out.append(hnode.global_position)
	return out

# 적 인텐트 차지 시작 — battle_manager 가 미리 결정한 target_hero_id 사용.
# VFX 의 screen_effect 시점이 데미지 시그널 emit 시점과 일치 (임팩트 동기화).
func _on_intent_vfx_start(enemy_index: int, intent: Resource, target_hero_id: String) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_char_nodes.size():
		return
	var caster_node: Node2D = _enemy_char_nodes[enemy_index]
	if caster_node == null:
		return
	var caster_pos: Vector2 = caster_node.global_position
	var IntentRes = BattleManager.IntentRes
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dtype: String = intent.damage_type
			if intent.target == IntentRes.TargetType.ALL:
				for hpos in _all_living_hero_positions():
					_spawn_attack_beam_simple(dtype, caster_pos, hpos + _impact_jitter())
			else:
				var hpos: Vector2 = _hero_pos_or_first(target_hero_id)
				if hpos != Vector2.ZERO:
					_spawn_attack_beam_simple(dtype, caster_pos, hpos + _impact_jitter())
		IntentRes.ActionType.BUFF:
			if intent.status_type == "block":
				_spawn_defense_buff(caster_pos)
			else:
				_spawn_warrior_buff(caster_pos)
		IntentRes.ActionType.DEBUFF:
			var stype: String = intent.status_type
			var fx_script: GDScript = _debuff_script_for_status(stype)
			if fx_script:
				if intent.target == IntentRes.TargetType.ALL:
					for hpos in _all_living_hero_positions():
						_spawn_debuff_beam_simple(fx_script, caster_pos, hpos, stype)
				else:
					var hpos: Vector2 = _hero_pos_or_first(target_hero_id)
					if hpos != Vector2.ZERO:
						_spawn_debuff_beam_simple(fx_script, caster_pos, hpos, stype)

# 독 DoT tick — 가스 VFX + impact_poison SFX
func _on_poison_tick(target: String, _amount: int) -> void:
	var pos: Vector2 = Vector2.ZERO
	if target.begins_with("enemy_"):
		var idx: int = target.substr(6).to_int()
		if idx >= 0 and idx < _enemy_char_nodes.size() and _enemy_char_nodes[idx]:
			pos = _enemy_char_nodes[idx].global_position
	else:
		var hnode: Node2D = _hero_char_nodes.get(target)
		if hnode:
			pos = hnode.global_position
	if pos == Vector2.ZERO:
		return
	var fx := _VFX_POISON_TICK.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("impact_poison")
	)
	fx.play(pos, pos)

# target_hero_id 의 영웅 좌표 — 사망/미지정 시 첫 살아있는 영웅 fallback
func _hero_pos_or_first(hero_id: String) -> Vector2:
	if hero_id != "":
		var node: Node2D = _hero_char_nodes.get(hero_id)
		if node and TeamManager.is_alive(hero_id):
			return node.global_position
	return _first_living_hero_pos()

# 영웅 카드 차지 시작 — battle_manager 가 차지 끝나기까지 await 후 효과 적용.
func _on_card_vfx_start(card: Resource, target_enemy_index: int, _target_hero_id: String) -> void:
	var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
	var owner_node: Node2D = _hero_char_nodes.get(owner_id)
	if owner_node == null:
		return
	var caster_pos: Vector2 = owner_node.global_position
	# 카드의 모든 effect 에 대해 적절한 VFX 시작 — 단, 같은 효과군은 한 번만 표시.
	# damage_type 이 명시된 effect 는 모두 ATTACK 처리 (CONDITIONAL_DMG, DAMAGE_PER_*, SACRIFICE_PAYOFF 등)
	# 차지 시간 동기화는 첫 effect 기준 (_card_vfx_impact_delay) — 다른 VFX 는 자체 타이밍.
	var did_attack: bool = false   # ATTACK 빔 한 번만 (모래폭풍 = DMG ALL curse + WEAK ALL → 빔 중복 방지)
	var did_buff: bool = false     # POWER 버프 한 번만
	var did_self_aoe: bool = false # heal/block 한 번만
	var did_debuff: bool = false   # 디버프 빔 한 번만 (ATTACK 이 이미 있으면 status 추가 표시 안 함)
	for effect in card.effects:
		if effect.damage_type != "":
			if did_attack:
				continue
			did_attack = true
			# ATTACK 이 발동되면 같은 카드의 status 빔(weak/vulnerable 등)은 중복으로 안 띄움
			did_debuff = true
			var dtype: String = effect.damage_type
			if effect.target == "ALL":
				for i in range(_enemy_char_nodes.size()):
					if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
						_spawn_attack_beam_simple(dtype, caster_pos, _enemy_char_nodes[i].global_position + _impact_jitter())
			elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
				_spawn_attack_beam_simple(dtype, caster_pos, _enemy_char_nodes[target_enemy_index].global_position + _impact_jitter())
			continue
		var et = effect.effect_type
		if et == EffectResource.EffectType.APPLY_STATUS:
			if effect.status_type.begins_with("power."):
				if not did_buff:
					if owner_id == "joan_of_arc":
						_spawn_holy_buff(caster_pos)
					else:
						_spawn_warrior_buff(caster_pos)
					did_buff = true
			else:
				if did_debuff:
					continue
				var fx_script: GDScript = _debuff_script_for_status(effect.status_type)
				if fx_script:
					did_debuff = true
					if effect.target == "ALL":
						for i in range(_enemy_char_nodes.size()):
							if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
								_spawn_debuff_beam_simple(fx_script, caster_pos, _enemy_char_nodes[i].global_position, effect.status_type)
					elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
						_spawn_debuff_beam_simple(fx_script, caster_pos, _enemy_char_nodes[target_enemy_index].global_position, effect.status_type)
		elif et == EffectResource.EffectType.CHARM:
			# Cleopatra 매혹 카드 — 적별로 enthrall 임계치 도달 여부 판정 → infatuation 또는 charm_kiss
			if did_debuff:
				continue
			did_debuff = true
			var charm_stacks: int = effect.value
			if effect.target == "ALL":
				for i in range(_enemy_char_nodes.size()):
					if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
						_spawn_charm_or_infatuation(caster_pos, _enemy_char_nodes[i].global_position, i, charm_stacks)
			elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
				_spawn_charm_or_infatuation(caster_pos, _enemy_char_nodes[target_enemy_index].global_position, target_enemy_index, charm_stacks)
		elif et == EffectResource.EffectType.HEAL or et == EffectResource.EffectType.HEAL_ALL:
			if not did_self_aoe:
				_spawn_heal_blessing(caster_pos)
				did_self_aoe = true
		elif et == EffectResource.EffectType.BLOCK or et == EffectResource.EffectType.BLOCK_ALL:
			if not did_self_aoe:
				_spawn_defense_buff(caster_pos)
				did_self_aoe = true

# 살아있는 적 인덱스 카운트 (target=ALL 영웅 카드의 visible 적 갯수)
func _enemy_alive_visible() -> int:
	var n: int = 0
	for i in range(_enemy_char_nodes.size()):
		if _enemy_char_nodes[i] != null and BattleManager.is_enemy_alive(i):
			n += 1
	return n

# 디버프 status_type → VFX 스크립트
func _debuff_script_for_status(stype: String) -> GDScript:
	if stype == "weak" or stype == "vulnerable":
		return _VFX_DEBUFF_HEX
	elif stype == "charm":
		return _VFX_CHARM_KISS
	elif stype == "enthrall":
		return _VFX_INFATUATION
	return null

# dtype → 적절한 SFX 키. 등록되지 않은 holy_* 는 기본 계열 SFX 재활용.
func _sfx_for_dtype(dtype: String) -> String:
	match dtype:
		"lightning":   return "impact_lightning"
		"ice":         return "impact_ice"
		"fire":        return "impact_fire"
		"holy_fire":   return "impact_fire"
		"poison":      return "impact_poison"
		"projectile":  return "impact_projectile"
		"holy_bolt":   return "impact_projectile"
		"explosive":   return "impact_explosive"
		"blunt":       return "impact_blunt"
		"holy_blunt":  return "impact_blunt"
		"holy_strike": return "impact_blunt"
		"bullet":      return "impact_projectile"
		"slash":       return "impact_slash"
		"holy_slash":  return "impact_slash"
		"curse":       return "impact_curse"
		"divine":      return "impact_divine"
		_:             return "impact_default"

# status_type → SFX 키. 디버프/매혹 전용 SFX 가 없으면 curse/divine 재활용.
func _sfx_for_status(stype: String) -> String:
	match stype:
		"weak", "vulnerable":   return "impact_curse"
		"charm", "enthrall":    return "impact_divine"
		_:                       return "impact_curse"

# 단순 빔 spawn — screen_effect 시점에 SFX/flash/shake 발동
func _spawn_attack_beam_simple(dtype: String, caster_pos: Vector2, target_pos: Vector2) -> void:
	var beam_script := _caster_beam_script(dtype)
	if beam_script == null:
		return
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	var sfx_key: String = _sfx_for_dtype(dtype)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx(sfx_key)
	)
	fx.play(caster_pos, target_pos)

# 매혹 카드용 — 이 적이 charm 누적으로 enthrall 발동할지 판정 후 charm_kiss / infatuation 분기
func _spawn_charm_or_infatuation(caster_pos: Vector2, target_pos: Vector2, enemy_index: int, charm_stacks: int) -> void:
	if BattleManager.will_enthrall_enemy(enemy_index, charm_stacks):
		_spawn_debuff_beam_simple(_VFX_INFATUATION, caster_pos, target_pos, "enthrall")
	else:
		_spawn_debuff_beam_simple(_VFX_CHARM_KISS, caster_pos, target_pos, "charm")

# 단순 디버프 spawn — screen_effect 시점에 SFX
func _spawn_debuff_beam_simple(beam_script: GDScript, caster_pos: Vector2, target_pos: Vector2, stype: String) -> void:
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	var sfx_key: String = _sfx_for_status(stype)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_shake()
		AudioManager.play_sfx(sfx_key)
	)
	fx.play(caster_pos, target_pos)

# lightning/ice 등 시전자→타겟 빔 VFX 공통 생성기 (구버전 — beam 동적 사망 지연용으로 일부 코드에서 유지).
# 빔이 명중을 알리는 screen_effect 시점에 화면 효과·SFX·피격 피드백을 동기화한다.
func _spawn_caster_beam(beam_script: GDScript, caster_pos: Vector2, target_pos: Vector2,
		dtype: String, on_impact: Callable) -> Node2D:
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx("impact_" + dtype)
		on_impact.call()
	)
	fx.play(caster_pos, target_pos)
	return fx

# dtype에 대응하는 시전자→타겟 빔 스크립트 (없으면 null)
func _caster_beam_script(dtype: String) -> GDScript:
	match dtype:
		"lightning":
			return _VFX_LIGHTNING_BEAM
		"ice":
			return _VFX_ICE_SHARDS
		"fire":
			return _VFX_FIRE_BLAST
		"poison":
			return _VFX_POISON_SPLASH
		"projectile":
			return _VFX_ARROW_SHOT
		"explosive":
			return _VFX_EXPLOSION_BLAST
		"blunt":
			return _VFX_BLUNT_SMASH
		"bullet":
			return _VFX_BULLET_SHOT
		"holy_strike":
			return _VFX_HOLY_STRIKE
		"holy_slash":
			return _VFX_HOLY_SLASH
		"holy_bolt":
			return _VFX_HOLY_ARROW
		"holy_fire":
			return _VFX_HOLY_FIRE
		"holy_blunt":
			return _VFX_HOLY_BLUNT
		"curse":
			return _VFX_DEBUFF_HEX  # curse 공격 = debuff hex 빔 (시각만 통일, 실제 데미지는 그대로)
		_:
			return null

func _play_screen_flash() -> void:
	# 비활성화 — 매 스킬마다 전체 화면 번쩍임이 너무 강함 (사용자 피드백)
	pass

func _play_screen_shake() -> void:
	if has_meta("_lit_shake"):
		var prev = get_meta("_lit_shake")
		if prev is Tween and prev.is_valid():
			prev.kill()
		position = get_meta("_lit_shake_orig", position)
	var orig := position
	set_meta("_lit_shake_orig", orig)
	var tw := create_tween()
	for i in range(8):
		var mag := 6.0 * (1.0 - float(i) / 8.0)
		tw.tween_property(self, "position",
			orig + Vector2(randf_range(-mag, mag), randf_range(-mag, mag)), 0.045)
	tw.tween_property(self, "position", orig, 0.045)
	set_meta("_lit_shake", tw)

func _on_hero_healed(hero_id: String, amount: int) -> void:
	_update_hero_ui(hero_id)
	for entry in _hero_nodes:
		if entry["hero_id"] == hero_id and entry["panel"].visible:
			var panel: ColorRect = entry["panel"]
			var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
			_spawn_heal_popup(popup_pos, amount, hero_id)
			break
	# heal_blessing VFX 가 screen_effect 시점에 SFX 직접 발동 (이중 호출 방지)

func _on_hero_block_gained(_hero_id: String, _amount: int) -> void:
	# defense_buff VFX 가 screen_effect 시점에 SFX 직접 발동 (이중 호출 방지)
	pass

# 방어도 버프 VFX — BLOCK 획득 시 6각 dome + barrier + 룬링
# screen_effect 시점(차지 끝)에 block SFX 발동
func _spawn_defense_buff(pos: Vector2) -> void:
	var fx := _VFX_DEFENSE_BUFF.new()
	add_child(fx)
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("block")
	)
	fx.play(pos, pos)

func _on_hero_damaged(hero_id: String, amount: int, dtype: String = "") -> void:
	# VFX 는 _on_intent_vfx_start / _on_card_vfx_start 가 이미 차지 시작.
	# 데미지 시그널은 임팩트 시점이므로 — 피격 피드백 즉시 (UI·팝업·플래시·틴트·hurt 애니).
	# 빔이 없는 dtype (divine 등 impact-only) 은 별도 _spawn_impact_particles.
	_update_hero_ui(hero_id)
	for entry in _hero_nodes:
		if entry["hero_id"] == hero_id and entry["panel"].visible:
			var panel: ColorRect = entry["panel"]
			var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
			_spawn_damage_popup(popup_pos, amount, amount == 0, hero_id)
			break
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node:
		_play_hit_flash(char_node)
		_play_hit_shake(char_node, amount)
		if dtype == "ice":
			_apply_frozen_tint(char_node)
		elif dtype == "fire":
			_apply_scorched_tint(char_node)
		elif dtype == "poison":
			_apply_poisoned_tint(char_node)
		elif dtype == "explosive":
			_apply_scorched_tint(char_node)
		if char_node.has_node("AnimationPlayer"):
			var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
			if ap.has_animation("hurt"):
				ap.play("hurt")
	# 빔 VFX 가 없는 dtype 은 impact-only 파티클로 보강
	if amount > 0 and char_node and _caster_beam_script(dtype) == null:
		var hero_spark_pos: Vector2 = char_node.global_position + _impact_jitter()
		_spawn_impact_particles(hero_spark_pos, amount, true, dtype)

func _on_enemy_damaged(index: int, amount: int, dtype: String = "") -> void:
	_update_enemy_ui(index)
	if index < _enemy_nodes.size() and _enemy_nodes[index]["panel"].visible:
		var panel: ColorRect = _enemy_nodes[index]["panel"]
		var popup_pos := panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0)
		_spawn_damage_popup(popup_pos, amount, amount == 0, "enemy_%d" % index)
	var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
	if char_node:
		_play_hit_flash(char_node)
		_play_hit_shake(char_node, amount)
		if dtype == "ice":
			_apply_frozen_tint(char_node)
		elif dtype == "fire":
			_apply_scorched_tint(char_node)
		elif dtype == "poison":
			_apply_poisoned_tint(char_node)
		elif dtype == "explosive":
			_apply_scorched_tint(char_node)
		if char_node.has_node("AnimationPlayer"):
			var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
			if ap.has_animation("hurt"):
				ap.play("hurt")
	if amount > 0 and char_node and _caster_beam_script(dtype) == null:
		var spark_pos: Vector2 = char_node.global_position + _impact_jitter()
		_spawn_impact_particles(spark_pos, amount, false, dtype)

# lightning 빔을 사망 연출 지연용으로 등록 — 빔이 사라지면 자동 정리
func _register_lit_death_beam(key: String, beam: Node2D) -> void:
	_lit_death_beam[key] = beam
	beam.tree_exited.connect(func() -> void:
		if _lit_death_beam.get(key) == beam:
			_lit_death_beam.erase(key))

# lightning으로 죽은 경우 사망 연출을 빔 임팩트 시점까지 지연, 아니면 즉시 실행
func _run_or_defer_death(key: String, death_fx: Callable) -> void:
	var beam = _lit_death_beam.get(key)
	if is_instance_valid(beam):
		beam.screen_effect.connect(death_fx)
	else:
		death_fx.call()

func _on_enemy_died(index: int) -> void:
	var death_fx := func() -> void:
		AudioManager.play_sfx("enemy_death")
		_update_enemy_ui(index)
		var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
		if char_node:
			_spawn_death_dissolve(char_node.global_position)
			if char_node.has_node("AnimationPlayer"):
				var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
				if ap.has_animation("death"):
					ap.play("death")
	_run_or_defer_death("enemy_%d" % index, death_fx)

func _on_hero_died(hero_id: String) -> void:
	var death_fx := func() -> void:
		AudioManager.play_sfx("hero_death")
		_update_hero_ui(hero_id)
		var hand: Array = DeckManager.hand
		for i in range(min(_card_buttons.size(), hand.size())):
			if hand[i].owner_id == hero_id:
				_card_buttons[i].set_owner_dead(true)
		# 패널 흰 섬광 → 회색 페이드
		for entry in _hero_nodes:
			if entry["hero_id"] != hero_id:
				continue
			var panel: ColorRect = entry["panel"]
			panel.modulate = Color(1.5, 1.5, 1.5)
			var tw := panel.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(panel, "modulate", Color(0.4, 0.4, 0.4), 0.5)
			break
		# 스프라이트: death 애니메이션 없으면 코드 페이드아웃
		var char_node = _hero_char_nodes.get(hero_id)
		if char_node:
			_spawn_death_dissolve(char_node.global_position)
			if char_node.has_node("AnimationPlayer"):
				var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
				if ap.has_animation("death"):
					ap.play("death")
					return
			var tw2: Tween = char_node.create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tw2.tween_property(char_node, "modulate:a", 0.0, 0.6)
	_run_or_defer_death(hero_id, death_fx)

func _on_hero_revived(hero_id: String) -> void:
	# 해당 영웅 슬롯을 다시 표시하고 HP/상태 갱신
	for entry in _hero_nodes:
		if entry["hero_id"] != hero_id:
			continue
		entry["panel"].visible = true
		entry["panel"].modulate = Color(1.0, 1.0, 1.0)  # 사망 시 회색화 복원
		entry["name_lbl"].visible = true
		entry["hp_bar"].visible = true
		entry["hp_lbl"].visible = true
		entry["block_lbl"].visible = true
		entry["status_box"].visible = true
		_update_hero_ui(hero_id)
		break
	# 스프라이트 복원 (death 애니메이션 트랙 리셋 후 idle 재생)
	var char_node = _hero_char_nodes.get(hero_id)
	if char_node != null:
		char_node.visible = true
		char_node.modulate = Color(1, 1, 1)  # 사망 페이드아웃 복원
		_spawn_revive_blessing(char_node.global_position)
		if char_node.has_node("AnimationPlayer"):
			var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
			ap.stop()
			if ap.has_animation("idle"):
				ap.play("idle")

func _on_battle_won() -> void:
	_message_label.text = tr("battle.msg_victory")
	_end_turn_btn.disabled = true
	_selected_card = null
	# 드래그 중 전투 종료 시 마우스 hidden 잔존 방지 — 드래그 정리
	if _drag_card != null:
		_cleanup_drag()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for entry in _enemy_nodes:
		entry["btn"].disabled = true
	# 마지막 적 사망 연출(death_dissolve)·VFX 임팩트·SFX 보여주고 종료 화면 전환
	await get_tree().create_timer(1.5).timeout
	if not is_inside_tree():
		return
	# 1.5s 대기 중 새 드래그 시도로 mouse HIDDEN 됐을 수 있음 — 씬 전환 직전 보험
	if _drag_card != null:
		_cleanup_drag()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.complete_battle(true)

func _on_battle_lost() -> void:
	if _lose_played:
		return
	_lose_played = true
	# 드래그 중 전투 종료 시 마우스 hidden 잔존 방지
	if _drag_card != null:
		_cleanup_drag()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_end_turn_btn.disabled = true
	_selected_card = null
	for entry in _enemy_nodes:
		entry["btn"].disabled = true
	# 영웅 사망 트윈이 보이도록 대기
	await get_tree().create_tween().tween_interval(0.6).finished
	# 화면 어두워지기 + 패배 라벨 페이드인
	await _play_defeat_overlay()
	# 라벨 잠시 머무름
	await get_tree().create_tween().tween_interval(0.6).finished
	# 세이브·상태 정리 (씬 전환 제외)
	GameManager.pending_enemies.clear()
	GameManager.run_won = false
	GameManager.run_ended.emit(false)
	var sm = get_node_or_null("/root/SaveManager")
	if sm:
		sm.clear_save()
	GameManager.change_state(GameManager.GameState.GAME_OVER)
	# 힌트 라벨 추가 후 입력 대기
	_show_defeat_continue_hint()
	_defeat_awaiting_input = true

func _play_defeat_overlay() -> Signal:
	var layer := CanvasLayer.new()
	layer.layer = 100
	layer.name = "_DefeatOverlay"
	add_child(layer)
	_defeat_layer = layer

	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.0)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(dim)

	var lbl := Label.new()
	lbl.text = tr("battle.msg_defeat")
	lbl.theme_type_variation = "TitleLabel"
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.add_theme_color_override("font_color", SacredPalette.BLOOD_300)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	lbl.offset_left  = -400.0
	lbl.offset_right =  400.0
	lbl.offset_top   =  -60.0
	lbl.offset_bottom =  60.0
	lbl.modulate.a = 0.0
	lbl.scale = Vector2(1.2, 1.2)
	layer.add_child(lbl)

	var tw := layer.create_tween().set_parallel(true)
	tw.tween_property(dim, "color:a", 0.65, 0.6)
	tw.tween_property(lbl, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tw.tween_property(lbl, "scale", Vector2(1.0, 1.0), 0.5) \
		.set_delay(0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return tw.finished

func _show_defeat_continue_hint() -> void:
	if not is_instance_valid(_defeat_layer):
		return
	var hint := Label.new()
	hint.text = tr("ui.defeat.continue_hint")
	hint.add_theme_font_size_override("font_size", 20)
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	hint.offset_left  = -300.0
	hint.offset_right =  300.0
	hint.offset_top   =   60.0
	hint.offset_bottom = 100.0
	hint.modulate.a = 0.0
	_defeat_layer.add_child(hint)
	hint.create_tween().tween_property(hint, "modulate:a", 0.7, 0.6)

func _go_to_main_menu() -> void:
	_defeat_awaiting_input = false
	SceneTransition.go("res://scenes/main_menu/main_menu_scene.tscn")

# ─────────────────────────────────────────────
# 카드 효과 텍스트 헬퍼
# ─────────────────────────────────────────────

func _signature_still_active(myth: String, enemy_status: Dictionary) -> bool:
	# 1회성 시그니처는 발동 후 숨김 (norse 라그나로크). 나머지는 alive 동안 항상 활성.
	match myth:
		"norse":
			return not enemy_status.get("norse_ragnarok_fired", false)
		_:
			return true

func _format_death_rattle_tooltip(dt: Resource) -> String:
	# 동적 툴팁: death_trigger IntentResource 효과 설명
	var prefix: String = tr("status.death_rattle.prefix")
	var v: int = dt.value
	var target_all: bool = dt.target == IntentRes.TargetType.ALL
	match dt.action_type:
		IntentRes.ActionType.DEBUFF:
			var sname: String = tr("status.%s.name" % dt.status_type)
			var tgt: String = tr("battle.target.all_hero") if target_all else tr("battle.target.hero")
			return "%s %s %s +%d" % [prefix, tgt, sname, v]
		IntentRes.ActionType.ATTACK:
			var tgt2: String = tr("battle.target.all_hero") if target_all else tr("battle.target.hero")
			return "%s %s %d %s" % [prefix, tgt2, v, tr("battle.damage")]
		IntentRes.ActionType.BUFF_ALLY:
			var sname2: String = tr("status.%s.name" % dt.status_type)
			return "%s %s %s +%d" % [prefix, tr("battle.target.ally"), sname2, v]
		_:
			return tr("status.death_rattle.desc")

func _make_status_label(key: String, val: int, status: Dictionary) -> Control:
	var tex: Texture2D = IconUtils.get_status_icon(key)
	var tooltip: String = _trf("status.%s.desc" % key, val)

	if tex != null:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 1)
		hbox.custom_minimum_size = Vector2(0, 20)
		hbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.mouse_filter = Control.MOUSE_FILTER_STOP
		SacredTheme.attach_tooltip(hbox, tooltip)

		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon)

		var lbl := Label.new()
		if key == "poison_dmg":
			var dur: int = status.get("poison_dur", 0)
			lbl.text = "%d/%d" % [val * 10, dur]
		else:
			lbl.text = "%d" % val
		lbl.theme_type_variation = "EyebrowLabel"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(lbl)

		return hbox

	# 아이콘 없으면 이모지 fallback
	var fallback_lbl := Label.new()
	if key == "poison_dmg":
		var dur: int = status.get("poison_dur", 0)
		fallback_lbl.text = "☠%d/%d" % [val * 10, dur]
	else:
		fallback_lbl.text = "%s%d" % [STATUS_EMOJI.get(key, key), val]
	fallback_lbl.theme_type_variation = "EyebrowLabel"
	SacredTheme.attach_tooltip(fallback_lbl, tooltip)
	fallback_lbl.add_theme_font_size_override("font_size", 12)
	fallback_lbl.custom_minimum_size = Vector2(0, 18)
	fallback_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fallback_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fallback_lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	return fallback_lbl

func _refresh_status_icons_hero(hero_id: String) -> void:
	var box: HBoxContainer = _hero_status_containers.get(hero_id)
	if box == null:
		return
	for child in box.get_children():
		child.queue_free()
	var status: Dictionary = BattleManager.get_hero_status(hero_id)
	# T3-MARK: marked_by Array — 비어있지 않으면 마커 아이콘 별도 표시
	var marked_by: Array = status.get("marked_by", [])
	if marked_by.size() > 0:
		box.add_child(_make_status_label("marked_by", marked_by.size(), status))
	for key in status:
		if key in STATUS_INTERNAL_KEYS or key == "marked_by":
			continue
		if typeof(status[key]) != TYPE_INT:
			continue
		var val: int = status[key]
		if val <= 0:
			continue
		box.add_child(_make_status_label(key, val, status))

func _refresh_status_icons_enemy(index: int) -> void:
	if index >= _enemy_status_containers.size():
		return
	var box: HBoxContainer = _enemy_status_containers[index]
	if box == null:
		return
	for child in box.get_children():
		child.queue_free()
	# 카드 카운터를 먼저 표시 (발동 순서 고정)
	var cinfo: Dictionary = BattleManager.get_enemy_counter(index)
	if not cinfo.is_empty():
		var hbox := HBoxContainer.new()
		hbox.custom_minimum_size = Vector2(0, 18)
		hbox.mouse_filter = Control.MOUSE_FILTER_STOP
		SacredTheme.attach_tooltip(hbox, _counter_tooltip_text(cinfo))
		var icon_tex := IconUtils.get_counter_icon()
		if icon_tex != null:
			var icon := TextureRect.new()
			icon.texture = icon_tex
			icon.custom_minimum_size = Vector2(20, 20)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.modulate = Color(1.0, 0.75, 0.3)
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon)
		var lbl := Label.new()
		lbl.text = _trf("battle.counter.label", [cinfo["count"], cinfo["threshold"]])
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.modulate = Color(1.0, 0.75, 0.3)
		hbox.add_child(lbl)
		box.add_child(hbox)
	var status: Dictionary = BattleManager.get_enemy_status(index)
	# DEATH-RATTLE 보유 + 신화 시그니처 활성 표시 (살아있을 때만)
	var enemy_res: Resource = BattleManager.get_enemy(index)
	if enemy_res != null and BattleManager.is_enemy_alive(index):
		# DEATH-RATTLE: 사망 시 1회 발동 (사망하면 enemy 자체가 dim 처리됨)
		if enemy_res.get("death_trigger") != null:
			var dr_lbl: Control = _make_status_label("death_rattle", 1, {})
			SacredTheme.attach_tooltip(dr_lbl, _format_death_rattle_tooltip(enemy_res.death_trigger))
			box.add_child(dr_lbl)
		# 신화 시그니처: signatures_enabled + 1회성 시그니처는 발동 후 숨김
		if enemy_res.get("signatures_enabled") and enemy_res.mythology != "" and _signature_still_active(enemy_res.mythology, status):
			var sig_key: String = "sig_" + enemy_res.mythology
			var sig_lbl: Control = _make_status_label(sig_key, 1, {})
			SacredTheme.attach_tooltip(sig_lbl, _trf("signature.%s.desc" % enemy_res.mythology, 0))
			box.add_child(sig_lbl)
	for key in status:
		if key in STATUS_INTERNAL_KEYS:
			continue
		if typeof(status[key]) != TYPE_INT:
			continue
		var val: int = status[key]
		if val <= 0:
			continue
		box.add_child(_make_status_label(key, val, status))

func _on_morale_changed(hero_id: String, _new_value: int) -> void:
	_update_hero_ui(hero_id)

func _on_active_powers_changed() -> void:
	if _active_powers_box == null:
		return
	for child in _active_powers_box.get_children():
		child.queue_free()
	var powers: Dictionary = BattleManager.get_all_active_powers()
	for power_key in powers:
		var power: Dictionary = powers[power_key]
		var base_key: String = power_key.split(":")[0] if ":" in power_key else power_key
		var v: int = power.get("value", 0)
		_active_powers_box.add_child(_make_power_item(base_key, v))

func _make_power_item(base_key: String, v: int) -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.custom_minimum_size = Vector2(0, 24)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	var desc_fmt: String = tr(base_key + ".desc")
	if desc_fmt != base_key + ".desc":
		SacredTheme.attach_tooltip(hbox, desc_fmt % v if desc_fmt.contains("%d") else desc_fmt)

	var tex: Texture2D = IconUtils.get_power_icon(base_key)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hbox.add_child(icon)

	var lbl := Label.new()
	var label_fmt: String = tr(base_key + ".label")
	lbl.text = label_fmt % v if label_fmt.contains("%") else label_fmt
	lbl.theme_type_variation = "EyebrowLabel"
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lbl.modulate = Color(0.75, 0.45, 1.0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(lbl)
	return hbox

func _on_status_applied(target: String, status_type: String, _stacks: int) -> void:
	var flash_color: Color = Color.WHITE
	if _STATUS_POPUP_INFO.has(status_type):
		flash_color = _STATUS_POPUP_INFO[status_type][1]
	if target.begins_with("enemy_"):
		var idx := target.substr(6).to_int()
		_refresh_status_icons_enemy(idx)
		if idx < _enemy_nodes.size() and _enemy_nodes[idx]["panel"].visible:
			var panel: ColorRect = _enemy_nodes[idx]["panel"]
			_spawn_status_popup(panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0), status_type, target)
		var char_node: Node2D = _enemy_char_nodes[idx] if idx < _enemy_char_nodes.size() else null
		if flash_color != Color.WHITE:
			_play_status_flash(char_node, flash_color)
	else:
		_refresh_status_icons_hero(target)
		for entry in _hero_nodes:
			if entry["hero_id"] == target and entry["panel"].visible:
				var panel: ColorRect = entry["panel"]
				_spawn_status_popup(panel.position + Vector2(SLOT_W / 2.0 - 20.0, SLOT_H / 3.0), status_type, target)
				break
		var char_node: Node2D = _hero_char_nodes.get(target)
		if flash_color != Color.WHITE:
			_play_status_flash(char_node, flash_color)
	# weak/vulnerable/charm/enthrall VFX 는 _on_intent_vfx_start / _on_card_vfx_start 가 차지 시작.
	# 여기서는 상태 아이콘 갱신·status_popup·tint flash 만 (임팩트 시점 동기).

func _refresh_debug_badge() -> void:
	if _debug_badge == null:
		return
	var parts: Array[String] = []
	if BattleManager.debug_hero_invincible:
		parts.append("INV")
	if DeckManager.debug_unlimited_energy:
		parts.append("E∞")
	if _debug_grid_visible:
		parts.append("GRID")
	if parts.is_empty():
		_debug_badge.visible = false
	else:
		_debug_badge.text = "[DEBUG: " + ", ".join(parts) + "]"
		_debug_badge.visible = true


func _refresh_synergy_hud() -> void:
	_refresh_hud()

func _input(event: InputEvent) -> void:
	# 패배 화면 입력 대기 → 메인메뉴
	if _defeat_awaiting_input:
		var accepted := false
		if event is InputEventMouseButton and event.pressed:
			accepted = true
		elif event is InputEventKey and event.pressed and not event.echo:
			accepted = true
		if accepted:
			get_viewport().set_input_as_handled()
			_go_to_main_menu()
			return
	# [DEBUG] 히어로 패널 클릭 → HP 설정
	if _debug_hp_target_mode and OS.is_debug_build() \
			and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for entry in _hero_nodes:
			var panel: ColorRect = entry["panel"]
			if panel.get_global_rect().has_point(event.global_position):
				_debug_hp_target_mode = false
				_message_label.text = ""
				_open_hero_slot_hp_dialog(entry["hero_id"])
				get_viewport().set_input_as_handled()
				return
	# 드래그 처리는 card_scene 시그널(_on_card_drag_*)로 위임됨
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		if _deck_viewer != null:
			_close_deck_viewer()

# ─────────────────────────────────────────────
# 덱뷰어 (전투 중)
# ─────────────────────────────────────────────

func _show_deck_viewer_in_battle() -> void:
	if _deck_viewer != null:
		return

	var canvas := CanvasLayer.new()
	canvas.layer = 10
	add_child(canvas)

	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var bg_rect := ColorRect.new()
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = Color(0.0, 0.0, 0.0, 0.72)
	bg_rect.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_close_deck_viewer()
	)
	overlay.add_child(bg_rect)

	const _DECK_W := 1300.0
	const _DECK_H := 680.0
	var panel_x: float = (WINDOW_W - _DECK_W) / 2.0
	var panel_y: float = (WINDOW_H - _DECK_H) / 2.0

	var group := Control.new()
	group.set_anchors_preset(Control.PRESET_FULL_RECT)
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.pivot_offset = Vector2(960, 540)
	group.scale = Vector2(0.9, 0.9)
	group.modulate.a = 0.0
	overlay.add_child(group)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(_DECK_W, _DECK_H)
	panel.position = Vector2(panel_x, panel_y)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = SacredPalette.INK_900
	panel_style.border_color = SacredPalette.BRASS_700
	panel_style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", panel_style)
	group.add_child(panel)

	# 코너 브라켓은 group 위 별도 Control에 올려 PanelContainer 레이아웃 간섭 방지
	var bracket_host := Control.new()
	bracket_host.position = Vector2(panel_x, panel_y)
	bracket_host.size = Vector2(_DECK_W, _DECK_H)
	bracket_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(bracket_host)
	SacredTheme.add_corner_brackets(bracket_host, SacredPalette.BRASS_700, 20, 8, 2)

	var hl := TextureRect.new()
	hl.texture = SacredTheme.make_top_fade_tex()
	hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hl.stretch_mode = TextureRect.STRETCH_SCALE
	hl.position = Vector2(panel_x, panel_y)
	hl.size = Vector2(_DECK_W, 80)
	hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hl)

	var hdiv := TextureRect.new()
	hdiv.texture = SacredTheme.make_center_bright_h_tex()
	hdiv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hdiv.stretch_mode = TextureRect.STRETCH_SCALE
	hdiv.position = Vector2(panel_x + 24, panel_y + 58)
	hdiv.size = Vector2(_DECK_W - 48, 2)
	hdiv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_child(hdiv)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.clip_children = Control.CLIP_CHILDREN_ONLY
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title_lbl := Label.new()
	title_lbl.text = tr("ui.battle.btn_deck_view")
	title_lbl.theme_type_variation = "TitleLabel"
	title_lbl.add_theme_font_size_override("font_size", 22)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var close_btn := Button.new()
	close_btn.theme_type_variation = "IconButton"
	close_btn.text = "✕"
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.custom_minimum_size = Vector2(40, 40)
	close_btn.pressed.connect(_close_deck_viewer)
	group.add_child(close_btn)
	close_btn.position = Vector2(panel_x + _DECK_W - 56, panel_y + 16)
	close_btn.size     = Vector2(40, 40)
	SacredTheme.animate_button(close_btn)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 8)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(columns)

	var draw_cards := DeckManager.draw_pile.duplicate()
	draw_cards.shuffle()
	var discard_cards  := DeckManager.discard_pile.duplicate()
	var exhaust_cards  := DeckManager.exhaust_pile.duplicate()

	_add_deck_column(columns, tr("ui.battle.deck_viewer.draw")    + " (%d)" % draw_cards.size(),    draw_cards)
	_add_v_divider(columns)
	_add_deck_column(columns, tr("ui.battle.deck_viewer.discard") + " (%d)" % discard_cards.size(), discard_cards)
	_add_v_divider(columns)
	_add_deck_column(columns, tr("ui.battle.deck_viewer.exhaust") + " (%d)" % exhaust_cards.size(), exhaust_cards)

	_deck_group  = group
	_deck_viewer = canvas
	var tw := create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(group, "scale", Vector2.ONE, 0.15)
	tw.parallel().tween_property(group, "modulate:a", 1.0, 0.15)


func _add_v_divider(parent: HBoxContainer) -> void:
	var div := TextureRect.new()
	div.texture = SacredTheme.make_center_bright_v_tex()
	div.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	div.stretch_mode = TextureRect.STRETCH_SCALE
	div.custom_minimum_size = Vector2(2, 0)
	div.size_flags_vertical = Control.SIZE_EXPAND_FILL
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(div)

func _add_deck_column(parent: HBoxContainer, header: String, cards: Array) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 6)
	parent.add_child(col)

	var lbl := Label.new()
	lbl.text = header
	lbl.theme_type_variation = "AccentLabel"
	lbl.add_theme_font_size_override("font_size", 15)
	col.add_child(lbl)

	var clip_box := Control.new()
	clip_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip_box.clip_children = Control.CLIP_CHILDREN_ONLY
	col.add_child(clip_box)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode   = ScrollContainer.SCROLL_MODE_AUTO
	clip_box.add_child(scroll)
	SacredTheme.style_sacred_scrollbar(scroll)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)

	if cards.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = tr("ui.battle.deck_viewer.empty")
		empty_lbl.theme_type_variation = "SubLabel"
		empty_lbl.add_theme_font_size_override("font_size", 15)
		grid.add_child(empty_lbl)
		return

	var card_w := 197.0
	var card_scale := card_w / 140.0
	var card_h := 200.0 * card_scale
	var base_scale := Vector2(card_scale, card_scale)
	# pivot(70,200) 기준 스케일로 비주얼이 래퍼 좌·상단 밖으로 밀리는 만큼 보정
	var base_pos := Vector2(70.0 * (card_scale - 1.0), 200.0 * (card_scale - 1.0))

	for card_res in cards:
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(card_w, card_h)
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(wrapper)

		var card_node: CardScene = CARD_SCENE.instantiate()
		card_node.position     = base_pos
		card_node.pivot_offset = Vector2(70.0, 200.0)
		card_node.scale        = base_scale
		card_node.setup(card_res, CardScene.Mode.REWARD)
		wrapper.add_child(card_node)

func _close_deck_viewer() -> void:
	if _deck_viewer != null:
		var viewer := _deck_viewer
		var group  := _deck_group
		_deck_viewer = null
		_deck_group  = null
		if is_instance_valid(group):
			var tw := create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
			tw.tween_property(group, "scale", Vector2(0.9, 0.9), 0.12)
			tw.parallel().tween_property(group, "modulate:a", 0.0, 0.12)
			tw.tween_callback(func(): if is_instance_valid(viewer): viewer.queue_free())
		else:
			if is_instance_valid(viewer): viewer.queue_free()


# ─────────────────────────────────────────────
# 버리기 카드 선택 모달
# ─────────────────────────────────────────────

func _on_card_pick_requested(_action: String, _draw_count: int) -> void:
	if _card_pick_in_progress or DeckManager.hand.is_empty():
		return
	_card_pick_in_progress = true
	_picked_card = null
	for node in _card_buttons:
		if is_instance_valid(node):
			node.set_disabled(false)
			node.set_pick_selectable(true)
	_show_discard_pick_overlay()

func _show_discard_pick_overlay() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(root)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	root.add_child(vbox)
	vbox.position = Vector2(WINDOW_W / 2.0 - 100.0, BOTTOM_Y - 360.0)

	var lbl := Label.new()
	lbl.text = tr("ui.battle.modal.discard_pick.title")
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", SacredPalette.BRASS_300)
	lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl)

	var btn := Button.new()
	btn.text = tr("ui.battle.modal.discard_pick.confirm")
	btn.theme_type_variation = "PrimaryButton"
	btn.custom_minimum_size = Vector2(200, 44)
	btn.disabled = true
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)
	SacredTheme.animate_button(btn)
	btn.pressed.connect(_on_pick_confirmed)

	_pick_confirm_btn = btn
	_pick_overlay = canvas

func _on_pick_confirmed() -> void:
	if _picked_card == null:
		return
	var picked := _picked_card
	_close_discard_pick_overlay()
	BattleManager.resolve_pending_discard_pick(picked)

func _close_discard_pick_overlay() -> void:
	_card_pick_in_progress = false
	_picked_card = null
	_pick_confirm_btn = null
	for node in _card_buttons:
		if is_instance_valid(node):
			node.set_pick_selectable(false)
			node.hide_glow()
	if _pick_overlay != null:
		var overlay := _pick_overlay
		_pick_overlay = null
		if is_instance_valid(overlay):
			overlay.queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.pressed and not event.echo:
		if event.keycode == KEY_Q and event.shift_pressed:
			BattleManager.debug_instant_win()
		elif event.keycode == KEY_I and event.shift_pressed:
			BattleManager.debug_hero_invincible = not BattleManager.debug_hero_invincible
			_refresh_debug_badge()
		elif event.keycode == KEY_E and event.shift_pressed:
			DeckManager.debug_unlimited_energy = not DeckManager.debug_unlimited_energy
			_refresh_debug_badge()
		elif event.keycode == KEY_D and event.shift_pressed:
			DeckManager.draw_cards(1)
		elif event.keycode == KEY_H and event.shift_pressed:
			_debug_hp_target_mode = not _debug_hp_target_mode
			if _debug_hp_target_mode:
				_message_label.text = "[DEBUG] 적 또는 영웅 슬롯을 클릭해 HP를 설정하세요 (다시 Shift+H 취소)"
			else:
				_message_label.text = ""
		elif event.keycode == KEY_G and event.shift_pressed:
			_debug_grid_visible = not _debug_grid_visible
			_refresh_debug_grid()
			_refresh_debug_badge()
		elif event.keycode == KEY_O and event.shift_pressed:
			if BattleManager.debug_add_dummy_enemy(MAX_ENEMY_COUNT):
				_setup_enemies()
		elif event.keycode == KEY_S and event.shift_pressed:
			var living := TeamManager.get_living_heroes()
			if not living.is_empty():
				_debug_token_hero_idx = _debug_token_hero_idx % living.size()
				var hero_id: String = living[_debug_token_hero_idx].hero_id
				BattleManager.debug_add_dummy_token(hero_id)
				_refresh_token_tiles(hero_id)
				_debug_token_hero_idx += 1

func _refresh_debug_grid() -> void:
	for node in _debug_grid_nodes:
		node.queue_free()
	_debug_grid_nodes.clear()
	if not _debug_grid_visible:
		return

	# 영웅 슬롯 외곽선 (파란색)
	for i in range(_hero_nodes.size()):
		var sp := _hero_slot_pos(i)
		for border in _make_border_rects(int(sp.x), int(sp.y), SLOT_W, SLOT_H, Color(0.3, 0.6, 1.0, 0.8)):
			add_child(border)
			_debug_grid_nodes.append(border)

	# 소환물 그리드 (노란색)
	for i in range(3):
		var ap := _summon_area_pos(i)
		for r in range(TOKEN_ROWS):
			for c in range(TOKEN_COLS):
				var cx: int = int(ap.x) + c * (TOKEN_TILE_W + TOKEN_TILE_GAP)
				var cy: int = int(ap.y) + r * (TOKEN_TILE_H + TOKEN_TILE_GAP)
				var cell := ColorRect.new()
				cell.color = Color(0.8, 0.8, 0.2, 0.12)
				cell.size = Vector2(TOKEN_TILE_W, TOKEN_TILE_H)
				cell.position = Vector2(cx, cy)
				cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(cell)
				_debug_grid_nodes.append(cell)
				for border in _make_border_rects(cx, cy, TOKEN_TILE_W, TOKEN_TILE_H, Color(0.9, 0.9, 0.3, 0.6)):
					add_child(border)
					_debug_grid_nodes.append(border)

	# 적 슬롯 외곽선 (빨간색)
	var total: int = _enemy_nodes.size()
	for i in range(total):
		var pos: Vector2 = _enemy_slot_pos(i, total)
		for border in _make_border_rects(int(pos.x), int(pos.y), SLOT_W, SLOT_H, Color(1.0, 0.3, 0.3, 0.8)):
			add_child(border)
			_debug_grid_nodes.append(border)

func _on_enemy_counter_changed(enemy_index: int) -> void:
	_refresh_enemy_counter(enemy_index)

func _refresh_enemy_counter(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_nodes.size():
		return
	_refresh_status_icons_enemy(enemy_index)

func _counter_tooltip_text(info: Dictionary) -> String:
	var tkey: String = info.get("tooltip_key", "")
	if tkey != "":
		return tr(tkey)
	# tooltip_key 없는 경우 동적 생성 (fallback)
	var card_type: int = info.get("card_type", -1)
	var threshold: int = info.get("threshold", 0)
	var intent: Resource = info.get("intent")
	var card_name: String
	match card_type:
		CardResource.CardType.ATTACK: card_name = tr("card_type.attack.name")
		CardResource.CardType.SKILL:  card_name = tr("card_type.skill.name")
		CardResource.CardType.POWER:  card_name = tr("card_type.power.name")
		_: card_name = "?"
	var effect_desc: String = "?"
	if intent != null:
		var target_str: String
		match int(intent.target):
			IntentRes.TargetType.ALL:       target_str = tr("battle.target.all_ally")
			IntentRes.TargetType.LOWEST_HP: target_str = tr("battle.target.lowest_hp_ally")
			IntentRes.TargetType.RANDOM:    target_str = tr("battle.target.random_ally")
			_:                              target_str = tr("battle.target.ally")
		match intent.action_type:
			IntentRes.ActionType.ATTACK:
				effect_desc = _trf("battle.counter.effect.attack", [target_str, intent.value])
			IntentRes.ActionType.DEBUFF:
				var sname: String = tr("status.%s.name" % intent.status_type)
				effect_desc = _trf("battle.counter.effect.debuff", [target_str, sname, intent.value])
			IntentRes.ActionType.BUFF:
				var sname: String = tr("status.%s.name" % intent.status_type)
				effect_desc = _trf("battle.counter.effect.buff", [sname, intent.value])
	return _trf("battle.counter.tooltip.format", [card_name, threshold, effect_desc])

func _make_border_rects(x: int, y: int, w: int, h: int, color: Color) -> Array:
	var rects: Array = []
	var thickness: int = 1
	for data in [[x, y, w, thickness], [x, y+h-thickness, w, thickness],
				  [x, y, thickness, h], [x+w-thickness, y, thickness, h]]:
		var r := ColorRect.new()
		r.color = color
		r.position = Vector2(data[0], data[1])
		r.size = Vector2(data[2], data[3])
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rects.append(r)
	return rects

func _card_target_type(card: Resource) -> String:
	# "enemy" / "ally" / "none"
	if card.card_type == CardResource.CardType.POWER:
		return "none"
	for effect in card.effects:
		match effect.effect_type:
			EffectRes.EffectType.DAMAGE:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.APPLY_STATUS:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.CHARM:
				if effect.target == "SINGLE":
					return "enemy"
			EffectRes.EffectType.COUNTER_BLOCK, \
			EffectRes.EffectType.CONSUME_MORALE, \
			EffectRes.EffectType.POISON_BURST, \
			EffectRes.EffectType.CONDITIONAL_DMG, \
			EffectRes.EffectType.DAMAGE_PER_BLOCK, \
			EffectRes.EffectType.DAMAGE_PER_HAND_SIZE, \
			EffectRes.EffectType.DAMAGE_PER_DEAD_ALLY, \
			EffectRes.EffectType.ENERGY_TO_DAMAGE, \
			EffectRes.EffectType.DAMAGE_PER_TOKEN:
				return "enemy"
			EffectRes.EffectType.STATUS_DOUBLE:
				if effect.target != "ALL":
					return "enemy"
			EffectRes.EffectType.HEAL:
				if effect.target == "SINGLE":
					return "ally"
			EffectRes.EffectType.REVIVE:
				return "dead_ally"
	return "none"

func _start_drag(card: Resource) -> void:
	if _card_pick_in_progress:
		return
	# 전투 종료 중(승리·패배 연출 1.5s 대기) 새 드래그 차단 — mouse HIDDEN 잔존 방지
	if not BattleManager.is_battle_active or not BattleManager.is_player_turn:
		return
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_reset_hand_fan()
	_drag_card = card
	_selected_card = null
	match _card_target_type(card):
		"enemy":
			_message_label.text = tr("battle.drag_enemy")
			for i in range(_enemy_nodes.size()):
				if _enemy_nodes[i]["panel"].visible and BattleManager.is_enemy_alive(i):
					_start_target_bloom(_enemy_nodes[i]["panel"], Color(2.0, 0.6, 0.3))
		"ally":
			_message_label.text = tr("battle.drag_ally")
			for entry in _hero_nodes:
				if entry["panel"].visible:
					_start_target_bloom(entry["panel"], Color(0.4, 2.0, 0.6))
		"dead_ally":
			_message_label.text = tr("battle.drag_dead_ally")
			for entry in _hero_nodes:
				if entry["panel"].visible and not TeamManager.is_alive(entry["hero_id"]):
					_start_target_bloom(entry["panel"], Color(1.0, 0.4, 2.0))
		"none":
			_message_label.text = tr("battle.drag_release")

func _finish_drag(drop_pos: Vector2) -> void:
	if drop_pos.y >= BOTTOM_Y:
		_cleanup_drag()
		return
	match _card_target_type(_drag_card):
		"enemy":
			for i in range(_enemy_nodes.size()):
				var panel: ColorRect = _enemy_nodes[i]["panel"]
				if not panel.visible or not BattleManager.is_enemy_alive(i):
					continue
				if panel.get_global_rect().has_point(drop_pos):
					_last_card_play_pos = drop_pos
					BattleManager.play_card(_drag_card, i)
					_cleanup_drag()
					return
			_cleanup_drag()
		"ally":
			for entry in _hero_nodes:
				if not entry["panel"].visible:
					continue
				var hero_id: String = entry["hero_id"]
				if not TeamManager.is_alive(hero_id):
					continue
				if entry["panel"].get_global_rect().has_point(drop_pos):
					_last_card_play_pos = drop_pos
					BattleManager.play_card(_drag_card, -1, hero_id)
					_cleanup_drag()
					return
			_cleanup_drag()
		"dead_ally":
			for entry in _hero_nodes:
				if not entry["panel"].visible:
					continue
				var hero_id: String = entry["hero_id"]
				if TeamManager.is_alive(hero_id):
					continue
				if entry["panel"].get_global_rect().has_point(drop_pos):
					_last_card_play_pos = drop_pos
					BattleManager.play_card(_drag_card, -1, hero_id)
					_cleanup_drag()
					return
			_cleanup_drag()
		"none":
			BattleManager.play_card(_drag_card, -1)
			_cleanup_drag()

func _cleanup_drag() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for spr in _drag_chevrons:
		if is_instance_valid(spr):
			spr.queue_free()
	_drag_chevrons.clear()
	if _drag_arrow_head != null:
		_drag_arrow_head.queue_free()
		_drag_arrow_head = null
	_drag_t_offset = 0.0
	for btn in _card_buttons:
		if is_instance_valid(btn):
			var card_res: Resource = btn.get_meta("_card_res", null)
			if card_res != null:
				_apply_card_state(btn, card_res)
	_drag_card = null
	_selected_card = null
	_message_label.text = tr("battle.msg_player_turn") if BattleManager.is_player_turn else ""
	for entry in _enemy_nodes:
		if entry["panel"].visible:
			_stop_target_bloom(entry["panel"])
	for entry in _hero_nodes:
		if entry["panel"].visible:
			_stop_target_bloom(entry["panel"])

func _create_drag_arrow(start_pos: Vector2) -> void:
	_drag_end_pos = start_pos
	_drag_t_offset = 0.0

	if not _drag_no_chevron:
		for i in range(8):
			var chev := Sprite2D.new()
			chev.texture = ARROW_CHEVRON_TEX
			chev.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			chev.scale = Vector2(0.15 if i % 2 == 0 else -0.15, 0.15)
			chev.modulate = Color(1.0, 1.0, 1.0, 0.0)
			chev.z_index = 5
			add_child(chev)
			_drag_chevrons.append(chev)

	_drag_arrow_head = Sprite2D.new()
	_drag_arrow_head.texture = ARROW_HEAD_TEX
	_drag_arrow_head.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_drag_arrow_head.scale = Vector2(0.5, 0.5)
	_drag_arrow_head.modulate = Color.WHITE
	_drag_arrow_head.z_index = 6
	add_child(_drag_arrow_head)

	_update_drag_arrow(start_pos)

const _ARROW_GOLD := Color(0.788, 0.659, 0.298)   # #c9a84c
const _ARROW_GRAY := Color(0.45, 0.45, 0.45)

func _drag_arrow_color(pos: Vector2) -> Color:
	if _drag_card == null:
		return _ARROW_GOLD
	if pos.y >= BOTTOM_Y:
		return _ARROW_GRAY
	match _card_target_type(_drag_card):
		"enemy":
			for i in range(_enemy_nodes.size()):
				var panel: ColorRect = _enemy_nodes[i]["panel"]
				if panel.visible and BattleManager.is_enemy_alive(i) \
						and panel.get_global_rect().has_point(pos):
					return _ARROW_GOLD
			return _ARROW_GRAY
		"ally":
			for entry in _hero_nodes:
				if entry["panel"].visible and TeamManager.is_alive(entry["hero_id"]) \
						and entry["panel"].get_global_rect().has_point(pos):
					return _ARROW_GOLD
			return _ARROW_GRAY
		"dead_ally":
			for entry in _hero_nodes:
				if entry["panel"].visible and not TeamManager.is_alive(entry["hero_id"]) \
						and entry["panel"].get_global_rect().has_point(pos):
					return _ARROW_GOLD
			return _ARROW_GRAY
		"none":
			return _ARROW_GOLD
	return _ARROW_GOLD

func _update_drag_arrow(end_pos: Vector2) -> void:
	if _drag_arrow_head == null:
		return
	var start := _drag_start_pos
	var _ctrl := (start + end_pos) * 0.5 + Vector2(0, -200.0)
	var base := _drag_arrow_color(end_pos)
	_drag_arrow_head.position = end_pos.round()

	_drag_arrow_head.modulate = base

func _update_drag_chevrons() -> void:
	if _drag_chevrons.is_empty():
		return
	var start := _drag_start_pos
	var end_pos := _drag_end_pos
	var ctrl := (start + end_pos) * 0.5 + Vector2(0, -200.0)
	var base := _drag_arrow_color(end_pos)
	var n := _drag_chevrons.size()
	for i in range(n):
		var t_raw: float = fmod(_drag_t_offset + float(i) / float(n), 1.0)
		var t: float = t_raw * 0.88
		var p: Vector2 = (1.0-t)*(1.0-t)*start + 2.0*(1.0-t)*t*ctrl + t*t*end_pos
		var tangent: Vector2 = (2.0*(1.0-t)*(ctrl - start) + 2.0*t*(end_pos - ctrl)).normalized()
		var alpha: float = t_raw
		var scale_factor: float = lerp(0.08, 0.5, t_raw)
		var chev: Sprite2D = _drag_chevrons[i]
		chev.position = p.round()
		chev.rotation = tangent.angle()
		chev.scale = Vector2(scale_factor, scale_factor)
		chev.modulate = Color(base.r, base.g, base.b, alpha)
