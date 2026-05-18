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
# 캐릭터 노드의 position.y(slot.y + 184) 에서 발(slot.y + SLOT_H)까지 offset.
# 바닥 VFX(룬링/글리프)를 발밑에 정렬할 때 사용.
const _CHAR_FOOT_Y_OFFSET := float(SLOT_H - 184)
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

# 적 패널 일부 UI 사이드바 (영웅 줌인 시 우측 세로 트윈)
# Layout 은 base panel (SLOT_W=240, SLOT_H=280) 과 동일 — sidebar 내 node offset = base 와 같음.
# 따라서 별도 SIDEBAR_LAYOUT 불필요. sidebar 좌표 = (SIDEBAR_X, SIDEBAR_Y + i*VSPACE) + (node.base - panel.base)
const SIDEBAR_X := 1620.0
const SIDEBAR_Y := 80.0    # turn_queue (y 18~52) 아래, 캐릭터 패널 위
const SIDEBAR_SLOT_VSPACE := 90.0  # row 간 거리
const SIDEBAR_SLOT_HSPACE := 230.0  # col 간 거리 (hp_bar 폭 211 + 19px gap)
const SIDEBAR_SLOTS_PER_ROW := 3   # 위쪽/아래쪽 각 3 슬롯, 우측부터 채움
var _enemy_sidebar_tween: Tween = null
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
var _turn_queue_box: HBoxContainer
var _turn_queue_slots: Array = []  # 각 슬롯: {root: PanelContainer, swatch: ColorRect, label: Label}
const TURN_QUEUE_PREVIEW_COUNT: int = 5

# UI 전용 CanvasLayer — 카메라 zoom 영향 없음 (카드/패널/버튼/라벨 등)
var _ui_layer: CanvasLayer = null

# 덱 보기 기본 탭 — 현재 영웅 없으면 마지막 차례 영웅
var _last_hero_actor_id: String = ""

func _setup_ui_layer() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 5  # 캐릭터/배경 위, SettingsOverlay(10) 아래
	add_child(_ui_layer)

# UI 노드 add_child 헬퍼 — _ui_layer 가 있으면 거기에, 없으면 self 에
func _ui_add(node: Node) -> void:
	if _ui_layer:
		_ui_layer.add_child(node)
	else:
		add_child(node)
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
	"poison_dur", "counter_ratio", "damage_taken",
	"greek_hubris_pending", "norse_ragnarok_fired",
	"daoist_stance", "japanese_turn_count",
	"charge_remaining", "_charge_block_advance"
]

func _trf(key: String, args) -> String:
	var s := tr(key)
	if "%d" in s or "%s" in s or "%f" in s:
		return s % args
	return s

func _ready() -> void:
	# y-sort: 캐릭터·전경 SVG 모두 같은 좌표계 — y 큰(아래) 노드가 위로 자동 정렬
	y_sort_enabled = true
	_setup_ui_layer()  # UI 전용 CanvasLayer 먼저 — _build_ui 가 거기에 add_child
	_build_ui()
	_setup_kill_cam()
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
	_update_camera_sway(delta)
	if _drag_card != null and not _drag_chevrons.is_empty():
		_drag_t_offset = fmod(_drag_t_offset + delta * 0.165, 1.0)
		_update_drag_chevrons()
	_update_enemy_sidebar_positions()

func _build_debug_tooltip() -> void:
	pass  # DebugManager autoload에서 전역 처리

# ─────────────────────────────────────────────
# UI 빌드
# ─────────────────────────────────────────────

func _build_ui() -> void:
	# 배경 — M7.5 v2 SVG 컴포지션 + 무작위 환경(시각/날씨) + critters + weather 입자
	if true:
		var SBG := preload("res://scenes/components/scene_background.gd")
		_scene_bg = SBG.new()
		var act_v: int = GameManager.current_act if GameManager else 1
		_scene_bg.setup(_current_mythology(), act_v, randi(), _build_bg_occupied_rects())
		add_child(_scene_bg)
		# fg specs → self 자식으로 spawn (y_sort_enabled 가 캐릭터와 자동 정렬)
		_spawn_fg_specs(_scene_bg.front_specs, _scene_bg.current_env.get("tint", Color.WHITE))
		# critters (새/별똥별) + weather (비/눈) — env 공유
		var env: Dictionary = _scene_bg.current_env
		var critters_script := preload("res://scenes/components/scene_critters.gd")
		var critters = critters_script.new()
		add_child(critters)
		critters.setup(env)
		var weather_script := preload("res://scenes/components/weather_particles.gd")
		var weather = weather_script.new()
		add_child(weather)
		weather.setup(env.get("weather", "clear"))  # z_index=950 자체 set
	else:
		var bg := ColorRect.new()
		bg.color = SacredPalette.INK_1000
		bg.position = Vector2.ZERO
		bg.size = Vector2(WINDOW_W, WINDOW_H)
		add_child(bg)

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
	_relic_container.size = Vector2(WINDOW_W / 3.0 - 20.0, 144)  # 좌측 1/3, 높이 2배 (relic 많을 때 wrap 공간)
	_relic_container.add_theme_constant_override("h_separation", 6)
	_relic_container.add_theme_constant_override("v_separation", 4)
	_relic_container.mouse_filter = Control.MOUSE_FILTER_PASS  # 자체는 통과, 자식 (relic icon) 만 hover (사이드바 sig_icon 차단 방지)
	add_child(_relic_container)
	_synergy_box = _relic_container
	_refresh_hud()

	_build_turn_queue_widget()

	_active_powers_box = VBoxContainer.new()
	_active_powers_box.position = Vector2(16, 858)
	_active_powers_box.custom_minimum_size = Vector2(200, 0)
	_active_powers_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_active_powers_box)

	# 영웅 슬롯 3개 고정 (초기 숨김)
	for i in range(3):
		_hero_nodes.append(_make_hero_slot(i))
	# 적 슬롯은 _setup_enemies()에서 동적 생성

	# 모든 UI Control 의 z_index = 1000 — fg/캐릭터(z_index 0~1080) 보다 항상 위
	# 카드(z 1000+), 호버 카드(1200), 디버그 overlay(5000) 와 호환
	_apply_ui_z_index_recursive(self, 1500)

	# UI 노드들을 CanvasLayer 로 reparent — 카메라 zoom 영향 제거
	# (영웅/적 패널은 캐릭터 따라가야 해서 self 자식 유지)
	if _ui_layer:
		for n in [banner, end_btn_wrap, deck_wrap, hand_rule, hand_diamond,
				_relic_container, _active_powers_box, _turn_queue_box]:
			if n != null and is_instance_valid(n):
				n.reparent(_ui_layer)

# battle_scene 의 직접 자식 Control z_index set (재귀 X — 캐릭터 안 Body 영향 회피).
# 캐릭터 UI(panel/hp/intent/btn/status) 는 별도로 800 (VFX 900 보다 뒤).
# 화면 UI(end_turn/덱보기/렐릭/배너 등) 는 z (default 1000) — VFX 위.
func _apply_ui_z_index_recursive(_node: Node, z: int) -> void:
	for child in get_children():
		if child is Sprite2D or child is ParallaxBackground or child is CanvasLayer:
			continue
		if child is Control:
			child.z_index = z
	# 캐릭터 UI 차등 z — panel(배경) < hp_bar < 라벨(hp/block/intent/name/status)
	# fg(0~1080) 위, VFX(1300) 아래. 라벨이 hp_bar 자식 bloom 위로 올라오게.
	for entry in _hero_nodes:
		_set_char_entry_z(entry)
	for entry in _enemy_nodes:
		_set_char_entry_z(entry)

func _set_char_entry_z(entry: Dictionary) -> void:
	const Z_PANEL := 1200   # 배경 panel + bracket
	const Z_BAR := 1210     # hp_bar wrapper + bg/fill/bloom/ghost (z_as_relative)
	const Z_LBL := 1220     # 일반 라벨 — bar 위
	const Z_INTENT := 1230  # intent_lbl — btn(1220) 보다 위 (base 시 tooltip hover)
	if entry.has("panel") and is_instance_valid(entry["panel"]):
		entry["panel"].z_index = Z_PANEL
	if entry.has("hp_bar") and is_instance_valid(entry["hp_bar"]):
		entry["hp_bar"].z_index = Z_BAR
	for k in ["name_lbl", "hp_lbl", "block_lbl", "btn", "status_box"]:
		if entry.has(k) and is_instance_valid(entry[k]):
			entry[k].z_index = Z_LBL
	if entry.has("intent_lbl") and is_instance_valid(entry["intent_lbl"]):
		entry["intent_lbl"].z_index = Z_INTENT

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
	intent_lbl.mouse_filter = Control.MOUSE_FILTER_STOP  # tooltip hover

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

	var base_positions := {
		"panel":      panel.position,  # sidebar 계산 기준점 (panel 자체는 이동 X)
		"name_lbl":   name_lbl.position,
		"hp_bar":     hp_bar.position,
		"hp_lbl":     hp_lbl.position,
		"block_lbl":  block_lbl.position,
		"intent_lbl": intent_lbl.position,
		"status_box": status_box.position,
	}
	return { "panel": panel, "intent_lbl": intent_lbl, "btn": btn,
			 "name_lbl": name_lbl, "hp_bar": hp_bar, "hp_lbl": hp_lbl,
			 "block_lbl": block_lbl, "status_box": status_box,
			 "base_positions": base_positions, "sig_icon": null }

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
	# Turn queue UI 갱신 — 차례 전환·큐 변경 시점 (사망/소환/부활 포함)
	BattleManager.turn_queue_changed.connect(_on_turn_queue_changed)
	# VFX 노드 종료 추적 — 임팩트 시점이 아니라 노드가 완전히 free 되는 시점 기준
	self.child_entered_tree.connect(_on_child_entered_vfx_track)
	self.child_exiting_tree.connect(_on_child_exited_vfx_track)
	# 영웅 줌인 옵션 변경 — 즉시 카메라 상태 반영
	GameSettings.hero_zoom_enabled_changed.connect(_on_hero_zoom_setting_changed)
	BattleManager.turn_ended.connect(func(_aid: String): _refresh_turn_queue_widget())
	BattleManager.enemy_died.connect(func(_idx: int): _refresh_turn_queue_widget())
	BattleManager.enemy_spawned.connect(func(_idx: int): _refresh_turn_queue_widget())
	BattleManager.hero_damaged.connect(_on_hero_damaged)
	BattleManager.hero_block_gained.connect(_on_hero_block_gained)
	BattleManager.enemy_damaged.connect(_on_enemy_damaged)
	BattleManager.token_attack_fired.connect(_on_token_attack_fired)
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
	BattleManager.passive_buff_applied.connect(_on_passive_buff_applied)
	BattleManager.hero_turn_skipped.connect(_on_hero_turn_skipped)
	BattleManager.card_vfx_charge_start.connect(_on_card_vfx_start)
	BattleManager.poison_tick_applied.connect(_on_poison_tick)
	BattleManager.signature_fired.connect(_on_signature_fired)
	BattleManager.cards_exhausted_by_enemy.connect(_on_cards_exhausted_by_enemy)
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
		# F6 단독 실행 폴백 — GameManager 미초기화 시 act_mythologies 비어있음
		var act_idx: int = GameManager.current_act - 1
		if act_idx < 0 or act_idx >= GameManager.act_mythologies.size():
			return
		var myth: String = GameManager.act_mythologies[act_idx]
		AudioManager.play_bgm_dynamic("battle", myth)

func _on_boss_phase_changed(enemy_index: int, new_phase: int) -> void:
	if new_phase >= 1 and not _bgm_boss_id.is_empty():
		AudioManager.play_bgm_dynamic("boss", _bgm_boss_id, new_phase)
	# 보스 위치에 phase 전환 VFX + cinematic title (PHASE %d)
	if enemy_index >= 0 and enemy_index < _enemy_char_nodes.size():
		var boss_node: Node2D = _enemy_char_nodes[enemy_index]
		if boss_node and is_instance_valid(boss_node):
			_spawn_boss_phase_change(boss_node.global_position, _foot_pos(boss_node), new_phase + 1)

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
	toast.z_index = 2000  # 시그니처 토스트 — popup 위, debug 아래
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
	# 신화별 cinematic VFX spawn
	_spawn_signature_vfx(enemy_index, signature_name)

# 적 SPECIAL 인텐트가 카드를 이번 전투 동안 exhaust 시켰을 때 — 토스트 알림
func _on_cards_exhausted_by_enemy(card_names: Array) -> void:
	var msg: String = "%s\n%s" % [tr("battle.notify.cards_exhausted"), ", ".join(card_names)]
	var toast := Label.new()
	toast.text = msg
	toast.theme_type_variation = "TitleLabel"
	toast.add_theme_font_size_override("font_size", 26)
	toast.modulate = Color(1.0, 0.6, 0.4)  # 코랄 — 경고
	toast.z_index = 2000
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.position = Vector2(WINDOW_W / 2.0 - 300, 320)
	toast.size = Vector2(600, 80)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.0)
	tw.tween_property(toast, "modulate:a", 0.0, 0.4)
	tw.tween_callback(toast.queue_free)

# 적 시그니처 발동 시 시각 강조 — 사용자 피드백으로 비활성 (큰 주황/보라 사각형이 어색).
# 시그니처 토스트 라벨(_on_signature_fired)이 이미 화면 중앙에 표시되므로 추가 강조 불필요.
func _burst_signature_at_enemy(_enemy_index: int, _color: Color) -> void:
	pass

# 신화 시그니처 아이콘 — 적 panel 우측 상단. 호버 시 툴팁으로 효과 설명.
# 주의: btn 이 panel 과 같은 사이즈로 self 의 자식이라 — panel 자식 Label 은 가려짐.
# 해결: Label 을 self(battle_scene) 의 자식 + 매우 늦게 add (btn 위) + z_index 최상위.
func _attach_signature_icon(panel: ColorRect, mythology) -> Label:
	if panel == null or mythology == null:
		return null
	var info: Dictionary = SIGNATURE_INFO.get(mythology, {})
	if info.is_empty():
		return null
	var existing := get_node_or_null(NodePath("_SigIcon_%s" % str(panel.get_instance_id())))
	if existing != null:
		return existing as Label
	var lbl := Label.new()
	lbl.name = "_SigIcon_%s" % str(panel.get_instance_id())
	lbl.text = info["emoji"]
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl.z_index = 1900
	var pp: Vector2 = panel.position
	lbl.position = pp + Vector2(panel.size.x - 34.0, 4.0)
	lbl.size = Vector2(26, 28)
	add_child(lbl)
	SacredTheme.attach_tooltip(lbl, tr(info["desc_key"]))
	return lbl

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
	var sig_node_spawn: Label = _attach_signature_icon(entry["panel"], enemy.get("mythology"))
	entry["sig_icon"] = sig_node_spawn
	if sig_node_spawn != null:
		entry["base_positions"]["sig_icon"] = sig_node_spawn.position
	var slot_pos: Vector2 = _enemy_slot_pos(enemy_index, total)
	if enemy.character_scene != null:
		var char_node = enemy.character_scene.instantiate()
		char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + 184)
		char_node.scale = Vector2(-1.44, 2.4)
		char_node.z_index = int(slot_pos.y + SLOT_H)
		# 발 그림자
		var foot_pos := Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + SLOT_H - 4)
		_add_ground_shadow(self, foot_pos, 90.0, 16.0, 0.45, int(slot_pos.y + SLOT_H) - 1)
		add_child(char_node)
		_enemy_char_nodes[enemy_index] = char_node
	else:
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.45, 0.45, 0.5, 0.6)
		placeholder.size = Vector2(60, 120)
		placeholder.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 30, slot_pos.y + 40)
		placeholder.z_index = int(slot_pos.y + SLOT_H)
		add_child(placeholder)
		_enemy_char_nodes[enemy_index] = placeholder
	# 새로 만든 적 panel 의 UI Control z_index 갱신
	_apply_ui_z_index_recursive(self, 1500)
	_update_enemy_ui(enemy_index)
	_refresh_enemy_counter(enemy_index)

# ─────────────────────────────────────────────
# 배틀 초기화
# ─────────────────────────────────────────────

func _start_battle() -> void:
	if not GameManager.pending_enemies.is_empty():
		BattleManager.turn_interval = 0.4  # base — GameSettings.turn_interval_multiplier 가 곱셈 적용
		BattleManager.setup_battle(GameManager.pending_enemies)
		_setup_heroes()
		_setup_enemies()
		await _play_battle_intro()
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
	await _play_battle_intro()
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
			# 발 위치(=panel 발) 기준 z_index — fg sprite 와 동일 규칙
			char_node.z_index = int(slot_pos.y + SLOT_H)
			# 발 그림자 — 캐릭터 z 보다 1 작음 (캐릭터 아래, fg/bg 위)
			var foot_pos := Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + SLOT_H - 4)
			_add_ground_shadow(self, foot_pos, 90.0, 16.0, 0.45, int(slot_pos.y + SLOT_H) - 1)
			add_child(char_node)
			_hero_char_nodes[hero.hero_id] = char_node

		_hero_status_containers[hero.hero_id] = entry["status_box"]
		_update_hero_ui(hero.hero_id)
	# 적/영웅 panel 의 hp_bar/이름라벨/intent_lbl 등 UI Control z_index 일괄 갱신
	_apply_ui_z_index_recursive(self, 1500)

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
		var sig_node_setup: Label = _attach_signature_icon(entry["panel"], enemy.get("mythology"))
		entry["sig_icon"] = sig_node_setup
		if sig_node_setup != null:
			entry["base_positions"]["sig_icon"] = sig_node_setup.position

		var slot_pos: Vector2 = _enemy_slot_pos(i, total)
		if enemy.character_scene != null:
			var char_node = enemy.character_scene.instantiate()
			char_node.position = Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + 184)
			char_node.scale = Vector2(-1.44, 2.4)
			char_node.z_index = int(slot_pos.y + SLOT_H)
			# 발 그림자
			var foot_pos := Vector2(slot_pos.x + SLOT_W / 2.0, slot_pos.y + SLOT_H - 4)
			_add_ground_shadow(self, foot_pos, 90.0, 16.0, 0.45, int(slot_pos.y + SLOT_H) - 1)
			add_child(char_node)
			_enemy_char_nodes[i] = char_node
		else:
			var placeholder := ColorRect.new()
			placeholder.color = Color(0.45, 0.45, 0.5, 0.6)
			placeholder.size = Vector2(60, 120)
			placeholder.position = Vector2(slot_pos.x + SLOT_W / 2.0 - 30, slot_pos.y + 40)
			placeholder.z_index = int(slot_pos.y + SLOT_H)
			add_child(placeholder)
			_enemy_char_nodes[i] = placeholder

		_update_enemy_ui(i)
		_refresh_enemy_counter(i)
	# 적 panel 의 hp_bar/이름라벨/intent_lbl 등 UI Control z_index 1000 갱신
	_apply_ui_z_index_recursive(self, 1500)

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

func _refresh_token_tiles(_hero_id: String) -> void:
	# 동적 모션 시스템 — 평소엔 토큰 노드 생성 안 함.
	# 발사 시 _on_token_attack_fired 가 spawn → tween → free.
	# 토큰 카운트는 status_box 의 "tokens" status icon 으로 표시됨.
	pass

func _update_enemy_ui(index: int) -> void:
	if index < 0 or index >= _enemy_nodes.size():
		return  # setup_battle 중 PASSIVE relic 트리거 시 _enemy_nodes 비어있음
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

	# 의도 표시 — CHARGE_UP 페이오프 등 한 턴에 여러 효과면 가로로 모두 표시
	var intents: Array = BattleManager.get_enemy_current_intents(index)
	if not intents.is_empty():
		var label_parts: Array[String] = []
		var tip_parts: Array[String] = []
		for it in intents:
			label_parts.append(_format_intent_label(index, it))
			tip_parts.append(_format_intent_tooltip(index, it))
		entry["intent_lbl"].text = "  ".join(label_parts)
		entry["intent_lbl"].modulate = _intent_color(intents[0].action_type)  # 첫 intent 기준 색상
		# 모든 인텐트에 tooltip 부착 (SPECIAL 도 자연스럽게 hover 유도)
		# base 시: btn(SLOT_W x SLOT_H) 이 위에 있어 intent_lbl hover 차단 → btn 에도 동일 tooltip
		# 사이드바 시: btn IGNORE 로 변경됨 → intent_lbl 가 직접 받음
		var intent_tip: String = "\n".join(tip_parts)
		SacredTheme.attach_tooltip(entry["intent_lbl"], intent_tip)
		SacredTheme.attach_tooltip(entry["btn"], intent_tip)

	if not BattleManager.is_enemy_alive(index):
		entry["panel"].modulate = Color(0.3, 0.3, 0.3)
		entry["btn"].disabled = true
		entry["intent_lbl"].text = tr("battle.intent.dead")

	_refresh_status_icons_enemy(index)

func _format_intent_label(enemy_index: int, intent: Resource) -> String:
	# intent 1개의 라벨 문자열 (이모지 또는 ATTACK 수치 포함).
	# 가로 묶음 표시 (multi-intent) 와 단일 표시 양쪽에서 사용.
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			return _trf("battle.intent.attack", BattleManager.get_intent_display_damage(enemy_index, intent))
		IntentRes.ActionType.BUFF:
			match intent.status_type:
				"strength": return _trf("battle.intent.buff.strength", intent.value)
				_:          return _trf("battle.intent.buff.block", intent.value)
		IntentRes.ActionType.DEBUFF:
			match intent.status_type:
				"stun": return tr("battle.intent.debuff.stun")
				_:      return tr("battle.intent.debuff")
		IntentRes.ActionType.PREPARE:    return tr("battle.intent.prepare")
		IntentRes.ActionType.CHARGE_UP:  return tr("battle.intent.charge_up")
		IntentRes.ActionType.HEAL_ALLY:  return _trf("battle.intent.heal_ally", intent.value)
		IntentRes.ActionType.BUFF_ALLY:  return _trf("battle.intent.buff_ally", intent.value)
		IntentRes.ActionType.COUNTER_PREPARE: return _trf("battle.intent.counter_prepare", intent.value)
		IntentRes.ActionType.MARK_TARGET: return tr("battle.intent.mark_target")
		IntentRes.ActionType.SACRIFICE:  return _trf("battle.intent.sacrifice", intent.value)
		IntentRes.ActionType.WARD:       return _trf("battle.intent.ward", intent.value)
		IntentRes.ActionType.SUMMON:     return _trf("battle.intent.summon", max(1, intent.value))
		IntentRes.ActionType.MIMIC:      return _trf("battle.intent.mimic", intent.value)
		IntentRes.ActionType.SPECIAL:    return tr("battle.intent.special")
		_:                                return "?"

func _format_intent_tooltip(enemy_index: int, intent: Resource) -> String:
	# 인텐트 hover 시 표시할 자세한 설명. 모든 action_type 지원.
	# _trf 사용 — 번역 키 누락/specifier 없을 때 args 자동 무시 (% 직접 사용 시 터짐).
	var v: int = intent.value
	var target_all: bool = intent.target == IntentRes.TargetType.ALL
	match intent.action_type:
		IntentRes.ActionType.ATTACK:
			var dmg: int = BattleManager.get_intent_display_damage(enemy_index, intent)
			var line: String = _trf("battle.intent.tooltip.attack", dmg)
			if target_all:
				line += " (" + tr("battle.intent.tooltip.target_all") + ")"
			if intent.damage_type != "":
				line += " · " + _trf("battle.intent.tooltip.element", intent.damage_type)
			return line
		IntentRes.ActionType.BUFF:
			match intent.status_type:
				"strength": return _trf("battle.intent.tooltip.buff_strength", v)
				"block": return _trf("battle.intent.tooltip.buff_block", v)
				"speed_bonus": return _trf("battle.intent.tooltip.buff_speed", [v, intent.duration])
				_: return _trf("battle.intent.tooltip.buff_generic", [intent.status_type, v])
		IntentRes.ActionType.DEBUFF:
			match intent.status_type:
				"weak": return tr("battle.intent.tooltip.debuff_weak")
				"vulnerable": return tr("battle.intent.tooltip.debuff_vulnerable")
				"poison": return _trf("battle.intent.tooltip.debuff_poison", v)
				"charm": return _trf("battle.intent.tooltip.debuff_charm", v)
				"speed_penalty": return _trf("battle.intent.tooltip.debuff_speed", [v, intent.duration])
				_: return _trf("battle.intent.tooltip.debuff_generic", [intent.status_type, v])
		IntentRes.ActionType.PREPARE:
			return tr("battle.intent.tooltip.prepare")
		IntentRes.ActionType.CHARGE_UP:
			return tr("battle.intent.tooltip.charge_up")
		IntentRes.ActionType.HEAL_ALLY:
			return _trf("battle.intent.tooltip.heal_ally", v)
		IntentRes.ActionType.BUFF_ALLY:
			return _trf("battle.intent.tooltip.buff_ally", [intent.status_type, v])
		IntentRes.ActionType.COUNTER_PREPARE:
			return _trf("battle.intent.tooltip.counter_prepare", v)
		IntentRes.ActionType.MARK_TARGET:
			return tr("battle.intent.tooltip.mark_target")
		IntentRes.ActionType.SACRIFICE:
			return _trf("battle.intent.tooltip.sacrifice", v)
		IntentRes.ActionType.WARD:
			return _trf("battle.intent.tooltip.ward", v)
		IntentRes.ActionType.SUMMON:
			return _trf("battle.intent.tooltip.summon", max(1, v))
		IntentRes.ActionType.MIMIC:
			return _trf("battle.intent.tooltip.mimic", v)
		IntentRes.ActionType.SPECIAL:
			match intent.status_type:
				"remove_card": return _trf("battle.intent.tooltip.special_remove_card", max(1, v))
				"summon": return tr("battle.intent.tooltip.special_summon")
				_:
					if intent.status_type != "":
						return _trf("battle.intent.tooltip.special_generic", intent.status_type)
					return tr("battle.intent.tooltip.special_unknown")
		_:
			return tr("battle.intent.tooltip.unknown")

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
		IntentRes.ActionType.CHARGE_UP: return Color(1.0, 0.65, 0.2)  # 의미심장한 주황 — 곧 큰 일
		IntentRes.ActionType.WARD: return Color(0.4, 1.0, 0.8)  # 청록 — 🛡 가 BUFF.block(파랑)과 색으로 구분
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

## ── 좌상단 Turn Queue 미리보기 (ATB 큐) ──
func _build_turn_queue_widget() -> void:
	_turn_queue_box = HBoxContainer.new()
	_turn_queue_box.position = Vector2(20, 18)
	_turn_queue_box.size = Vector2(WINDOW_W - 40, 34)
	_turn_queue_box.add_theme_constant_override("separation", 6)
	add_child(_turn_queue_box)  # _build_ui 끝에서 _ui_layer 로 reparent 됨
	for i in range(TURN_QUEUE_PREVIEW_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(96, 30)
		var sbx := StyleBoxFlat.new()
		sbx.bg_color = Color(0.08, 0.07, 0.05, 0.85)
		sbx.border_color = SacredPalette.BRASS_300
		sbx.set_border_width_all(1)
		sbx.set_corner_radius_all(4)
		sbx.set_content_margin_all(4)
		slot.add_theme_stylebox_override("panel", sbx)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 2)
		slot.add_child(vb)
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(0, 4)
		swatch.color = SacredPalette.BRASS_500
		vb.add_child(swatch)
		var lbl := Label.new()
		lbl.text = ""
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.clip_text = true
		vb.add_child(lbl)
		_turn_queue_box.add_child(slot)
		_turn_queue_slots.append({"root": slot, "swatch": swatch, "label": lbl})
	_refresh_turn_queue_widget()

func _on_turn_queue_changed(_preview: Array) -> void:
	_refresh_turn_queue_widget()

func _refresh_turn_queue_widget() -> void:
	if _turn_queue_slots.is_empty():
		return
	# 현재 차례 액터 + 다음 N-1 차례 미리보기
	# get_turn_queue_preview 는 현재 actor 가 행동 중일 때 첫 결과로 그 actor 를 반환 (큐 카운터 아직 진행 안 됨).
	# 슬롯 0 에 current 를 따로 넣었으니 중복 방지를 위해 첫 항목 skip.
	var preview: Array = []
	var current_aid: String = BattleManager.get_current_actor_id()
	if current_aid != "":
		preview.append(current_aid)
	var next_preview: Array = BattleManager.get_turn_queue_preview(TURN_QUEUE_PREVIEW_COUNT + 1)
	var start_idx: int = 0
	if current_aid != "" and next_preview.size() > 0 and next_preview[0] == current_aid:
		start_idx = 1
	for i in range(start_idx, next_preview.size()):
		if preview.size() >= TURN_QUEUE_PREVIEW_COUNT:
			break
		preview.append(next_preview[i])
	for i in range(_turn_queue_slots.size()):
		var slot: Dictionary = _turn_queue_slots[i]
		if i >= preview.size():
			slot["root"].visible = false
			continue
		slot["root"].visible = true
		var aid: String = preview[i]
		var info: Dictionary = _resolve_actor_info(aid)
		slot["label"].text = info["name"]
		slot["swatch"].color = info["color"]
		# 폰트 크기 자동 조절 — 슬롯 너비 72px (80 - 좌우 4px padding) 안에 맞춤
		LabelUtils.fit_text(slot["label"], 11, 7, 72.0)
		# 현재 차례 = 첫 슬롯 강조 (밝게)
		slot["root"].modulate = Color(1.0, 1.0, 1.0, 1.0) if i == 0 else Color(1.0, 1.0, 1.0, 0.7)

func _resolve_actor_info(actor_id: String) -> Dictionary:
	if actor_id.begins_with("hero:"):
		var hid: String = actor_id.substr(5)
		var nm: String = hid
		if TeamManager != null:
			var hero_res = TeamManager.get_hero(hid)
			if hero_res != null:
				nm = tr(hero_res.hero_name)
		return {"name": nm, "color": SacredPalette.BRASS_500}
	if actor_id.begins_with("enemy:"):
		var idx: int = int(actor_id.substr(6))
		var nm2: String = "enemy"
		var enemy_res: Resource = BattleManager.get_enemy(idx)
		if enemy_res != null:
			nm2 = tr(enemy_res.enemy_name)
		return {"name": nm2, "color": Color(0.7, 0.25, 0.25)}
	return {"name": actor_id, "color": Color(0.5, 0.5, 0.5)}

func _refresh_hand() -> void:
	for n in _card_buttons:
		if is_instance_valid(n):
			n.queue_free()
	_card_buttons.clear()

	# 본인 차례 영웅의 핸드만 표시 (적 차례 / 차례 사이엔 빈 핸드)
	var hid: String = BattleManager.get_current_hero_id()
	var hand: Array = DeckManager.get_hand(hid) if hid != "" else []
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
		node.z_index = 1500 + i  # 카드 — UI 와 같은 영역
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
		_ui_add(node)  # CanvasLayer 자식 — 카메라 zoom 영향 없음
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
	_cam_on_drag_started()

func _on_card_drag_moved(_card: Resource, screen_pos: Vector2) -> void:
	# 우클릭 등으로 이미 cleanup 됐으면 — 라벨 덮어쓰지 않음
	if _drag_card == null:
		return
	_drag_end_pos = screen_pos
	_update_drag_arrow(screen_pos)
	_message_label.text = tr("battle.cancel_use") if _drag_cancel_ready and screen_pos.y >= BOTTOM_Y else _drag_hint_text()
	# enemy 타겟 카드일 때 — 호버 중인 적 인덱스 검출 → 카드 데미지 표시에 target vulnerable 반영
	if _card_target_type(_drag_card) == "enemy":
		var hover_idx: int = -1
		for i in range(_enemy_nodes.size()):
			var panel: ColorRect = _enemy_nodes[i]["panel"]
			if not panel.visible or not BattleManager.is_enemy_alive(i):
				continue
			if panel.get_global_rect().has_point(screen_pos):
				hover_idx = i
				break
		_set_drag_card_target(hover_idx)

func _set_drag_card_target(enemy_index: int) -> void:
	for btn in _card_buttons:
		if is_instance_valid(btn) and btn.get_meta("_card_res", null) == _drag_card and btn.has_method("set_target_enemy_index"):
			btn.set_target_enemy_index(enemy_index)
			break

func _on_card_drag_released(_card: Resource, screen_pos: Vector2) -> void:
	if _drag_card != null:
		_finish_drag(screen_pos)
	# 드래그 종료 — 카드가 사용되면 _on_card_played 가 VFX_PLAYING 으로 전환했을 것.
	# 여전히 DRAGGING 이면 = 취소 → 영웅 줌인 복귀.
	_cam_on_drag_canceled()

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
			btn.z_index = 1700  # 호버 카드 — 다른 카드 위
		else:
			var dist: int = idx - hover_idx
			var sign_x: float = 1.0 if dist > 0 else -1.0
			var falloff: float = maxf(0.0, 1.0 - abs(dist) / 4.0)
			tw.tween_property(btn, "position", base_pos + Vector2(sign_x * 35.0 * falloff, 0), 0.12)
			tw.tween_property(btn, "rotation", base_rot, 0.12)
			tw.tween_property(btn, "scale", Vector2(BASE_CARD_SCALE, BASE_CARD_SCALE), 0.12)
			btn.z_index = 1500 + idx

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
		btn.z_index = 1500 + idx

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
	# 현재 영웅 이름 표시 (개체 차례 시스템)
	var cur_hid: String = BattleManager.get_current_hero_id()
	var hero_name: String = cur_hid
	if cur_hid != "" and TeamManager != null:
		var hero_res = TeamManager.get_hero(cur_hid)
		if hero_res != null:
			hero_name = tr(hero_res.hero_name)
	_message_label.text = "%s — %s" % [hero_name, tr("battle.msg_player_turn")]
	# 본인 영웅 에너지 표시
	_energy_label.text = "%d/%d" % [DeckManager.get_energy(cur_hid), DeckManager.MAX_ENERGY]
	# 본인 영웅 핸드 표시 (start_hero_turn 가 드로우 완료)
	_refresh_hand()
	_refresh_turn_queue_widget()
	# 영웅 블록 UI 갱신
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
	# 영웅 줌인 (영구 큐 본인 차례 카메라)
	if cur_hid != "":
		_last_hero_actor_id = cur_hid  # 덱 보기 기본 탭 추적
		_cam_on_hero_turn_start(cur_hid)

func _on_enemy_turn_started() -> void:
	_end_turn_btn.disabled = true
	_selected_card = null
	# 현재 적 이름 표시
	var cur_aid: String = BattleManager.get_current_actor_id()
	var enemy_label: String = tr("battle.msg_enemy_turn")
	if cur_aid.begins_with("enemy:"):
		var idx: int = int(cur_aid.substr(6))
		var ename: Resource = BattleManager.get_enemy(idx)
		if ename != null:
			enemy_label = "%s — %s" % [tr(ename.enemy_name), tr("battle.msg_enemy_turn")]
	_message_label.text = enemy_label
	_last_card_play_pos = Vector2.ZERO
	_signatures_shown_this_turn.clear()  # 시그니처 토스트 throttle 리셋 (1회/턴)
	# 적 차례 — 본인 영웅 핸드 숨김
	_refresh_hand()
	_refresh_turn_queue_widget()
	# 적 클릭 버튼 비활성
	for entry in _enemy_nodes:
		if entry["panel"].visible and not entry["btn"].disabled:
			entry["btn"].disabled = true
	# 적 차례 — 전체 보기 (멀리)
	_cam_on_enemy_turn_start()

func _on_energy_changed(new_energy: int) -> void:
	_energy_label.text = "%d / %d" % [new_energy, DeckManager.MAX_ENERGY]
	# 카드 노드 활성/비활성 갱신 — 본인 차례 영웅 핸드 기준
	var hid: String = BattleManager.get_current_hero_id()
	var hand: Array = DeckManager.get_hand(hid) if hid != "" else []
	for i in range(min(_card_buttons.size(), hand.size())):
		_apply_card_state(_card_buttons[i], hand[i])

func _on_card_played(card: Resource) -> void:
	call_deferred("_refresh_all_hero_ui")
	_cam_on_card_played()  # VFX 재생 상태 진입 (이미 줌아웃 — VFX 끝나면 영웅 복귀)
	# EXHAUST 카드 (POWER 카드 포함 — DeckManager 와 동일 조건) → 카드 위치에 burn VFX
	if card != null and (card.get("is_exhaust") == true or card.get("card_type") == 2):
		_spawn_card_exhaust_for(card)
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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
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
	"speed_bonus":   ["Haste",         Color(0.55, 0.88, 1.00)],   # rgba(140,225,255) 부드러운 청록 (가속)
	"speed_penalty": ["Slow",          Color(0.65, 0.72, 0.85)],   # rgba(166,184,217) 차분한 청회 (둔화)
	"stun":          ["Stun",          Color(1.00, 0.85, 0.45)],   # rgba(255,217,115) 부드러운 황금 (마비 별)
	"tokens":        ["Soldiers",      Color(0.85, 0.78, 1.00)],   # rgba(217,199,255) 부드러운 라일락 (소환)
}

func _spawn_popup(base_pos: Vector2, text: String, color: Color, font_size: int, stack_key: String) -> void:
	var count: int = _popup_stack.get(stack_key, 0)
	_popup_stack[stack_key] = count + 1
	var tint: Color = _popup_text_color(color)
	var container := Node2D.new()
	container.z_index = 1800  # popup — 호버 카드(1700) 위, 토스트(2000) 아래
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
	container.z_index = 1800  # popup — 호버 카드(1700) 위, 토스트(2000) 아래
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
const _VFX_SUMMON_BURST := preload("res://scenes/vfx/summon_burst.gd")
const _VFX_STUN_STARS := preload("res://scenes/vfx/stun_stars.gd")
const _VFX_POWER_UP := preload("res://scenes/vfx/power_up.gd")
const _VFX_SUMMON_CIRCLE := preload("res://scenes/vfx/summon_circle.gd")
const _VFX_SPEED_BUFF := preload("res://scenes/vfx/speed_buff.gd")
const _VFX_SLOW_DEBUFF := preload("res://scenes/vfx/slow_debuff.gd")
const _VFX_TARGET_MARKING := preload("res://scenes/vfx/target_marking.gd")
const _VFX_MIMIC := preload("res://scenes/vfx/mimic.gd")
const _VFX_SACRIFICE := preload("res://scenes/vfx/sacrifice.gd")
const _VFX_COUNTER_PREPARE := preload("res://scenes/vfx/counter_prepare.gd")
const _VFX_STEAL_CARD := preload("res://scenes/vfx/steal_card.gd")
const _VFX_PURGE_STATUS := preload("res://scenes/vfx/purge_status.gd")
const _VFX_MORALE_BOOST := preload("res://scenes/vfx/morale_boost.gd")
const _VFX_PREPARE := preload("res://scenes/vfx/prepare.gd")
const _VFX_BOSS_PHASE := preload("res://scenes/vfx/boss_phase_changed.gd")
const _VFX_SIG_HUBRIS := preload("res://scenes/vfx/sig_hubris.gd")
const _VFX_SIG_RAGNAROK := preload("res://scenes/vfx/sig_ragnarok.gd")
const _VFX_SIG_KARMA := preload("res://scenes/vfx/sig_karma.gd")
const _VFX_SIG_YIN_YANG := preload("res://scenes/vfx/sig_yin_yang.gd")
const _VFX_SIG_EGYPTIAN_CURSE := preload("res://scenes/vfx/sig_egyptian_curse.gd")
const _VFX_SIG_KEKKAI := preload("res://scenes/vfx/sig_kekkai.gd")
const _VFX_TAUNT := preload("res://scenes/vfx/taunt.gd")
const _VFX_CARD_EXHAUST := preload("res://scenes/vfx/card_exhaust.gd")
const _VFX_BOSS_DEATH := preload("res://scenes/vfx/boss_death.gd")

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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	fx.set_ground_anchor(pos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
	fx.play(pos, pos)

# 보스 전용 사망 VFX — 거대 폭발 cinematic + 왕관 추락 + slate
func _spawn_boss_death(pos: Vector2, foot_pos: Vector2) -> void:
	var fx: Node2D = _VFX_BOSS_DEATH.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx("impact_explosive")
	)
	fx.play(pos, pos)

# 카드 EXHAUST VFX — 카드 노드 위에 burn sweep + 잿불 + 재 + EXHAUST stamp
func _spawn_card_exhaust_for(card: Resource) -> void:
	var card_node: Control = null
	for n in _card_buttons:
		if is_instance_valid(n) and n.get_meta("_card_res", null) == card:
			card_node = n
			break
	if card_node == null:
		return
	var center: Vector2 = card_node.global_position + card_node.size * 0.5
	var fx: Node2D = _VFX_CARD_EXHAUST.new()
	_ui_add(fx)  # CanvasLayer (카드와 같은 좌표계)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if fx.has_method("set_card_size"):
		fx.set_card_size(card_node.size)
	fx.play(center, center)

# 부활 VFX — 부활 대상 위치에 빛기둥·고리·빛 입자
func _spawn_revive_blessing(pos: Vector2) -> void:
	var fx := _VFX_REVIVE_BLESSING.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	fx.set_ground_anchor(pos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
	fx.play(pos, pos)

# 회복 VFX — 회복 대상 위치에 나뭇잎·반짝임·고리·십자
# screen_effect 시점(차지 끝)에 heal SFX 발동
func _spawn_heal_blessing(pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx := _VFX_HEAL_BLESSING.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("heal")
	)
	fx.play(pos, pos)

# 신성 버프 VFX — Joan 의 POWER 카드 발동 시 시전자 위치에 룬링·빛기둥·황금 깃털
# "buff" SFX 자원 없음 → impact_divine 재활용 (신성·강력 톤)
func _spawn_holy_buff(pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx := _VFX_HOLY_BUFF.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(pos, pos)

# 전사 버프 VFX — Joan 외 영웅의 POWER 카드 발동 시 분노/주황 가시링·오라·잔불
# "buff" SFX 자원 없음 → impact_blunt 재활용 (분노·강한 충격 톤)
func _spawn_warrior_buff(pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx := _VFX_WARRIOR_BUFF.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
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

# 첫 살아있는 영웅의 발치 좌표 — egyptian_curse ground anchor 용
func _first_living_hero_foot() -> Vector2:
	for entry in _hero_nodes:
		var hid: String = entry["hero_id"]
		if hid == "" or not TeamManager.is_alive(hid):
			continue
		var hnode: Node2D = _hero_char_nodes.get(hid)
		if hnode:
			return _foot_pos(hnode)
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
func _on_passive_buff_applied(enemy_index: int, status_type: String, _value: int) -> void:
	# phase_buffs / 시그너처 등 intent 외 자동 BUFF — warrior_buff/defense_buff VFX spawn.
	# spawn 함수 내부에서 fx.screen_effect.connect 로 vfx_impact_resolved emit — battle_manager 가 await 로 동기화.
	if enemy_index < 0 or enemy_index >= _enemy_char_nodes.size():
		BattleManager.vfx_impact_resolved.emit()  # 적 무효 → 즉시 resolve
		return
	var caster_node: Node2D = _enemy_char_nodes[enemy_index]
	if caster_node == null:
		BattleManager.vfx_impact_resolved.emit()
		return
	var caster_pos: Vector2 = caster_node.global_position
	var caster_foot: Vector2 = _foot_pos(caster_node)
	if status_type == "block":
		_spawn_defense_buff(caster_pos, caster_foot)
	elif status_type == "speed_bonus":
		_spawn_speed_buff(caster_pos, caster_foot)
	elif _is_holy_enemy(enemy_index):
		_spawn_holy_buff(caster_pos, caster_foot)
	else:
		_spawn_warrior_buff(caster_pos, caster_foot)

# 스턴 등으로 영웅 차례 자동 종료 — 토스트 + 머리 위 별 표시
func _on_hero_turn_skipped(hero_id: String) -> void:
	var hero_node: Node2D = _hero_char_nodes.get(hero_id)
	if hero_node:
		_spawn_stun_stars(hero_node.global_position)
	var hero_name: String = hero_id
	if TeamManager != null:
		var hero_res = TeamManager.get_hero(hero_id)
		if hero_res != null and hero_res.get("display_name_key") != null:
			hero_name = tr(hero_res.display_name_key)
	var toast := Label.new()
	toast.text = _trf("battle.toast.stunned", hero_name)
	toast.theme_type_variation = "TitleLabel"
	toast.add_theme_font_size_override("font_size", 28)
	toast.modulate = Color(1.0, 0.85, 0.3)
	toast.z_index = 2000
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast.position = Vector2(WINDOW_W / 2.0 - 250, 300)
	toast.size = Vector2(500, 50)
	add_child(toast)
	var tw := create_tween()
	tw.tween_property(toast, "modulate:a", 1.0, 0.15)
	tw.tween_interval(0.8)
	tw.tween_property(toast, "modulate:a", 0.0, 0.3)
	tw.tween_callback(toast.queue_free)

func _on_intent_vfx_start(enemy_index: int, intent: Resource, target_hero_id: String) -> void:
	if enemy_index < 0 or enemy_index >= _enemy_char_nodes.size():
		return
	var caster_node: Node2D = _enemy_char_nodes[enemy_index]
	if caster_node == null:
		return
	var caster_pos: Vector2 = caster_node.global_position
	var caster_foot: Vector2 = _foot_pos(caster_node)
	var ir = BattleManager.IntentRes
	match intent.action_type:
		ir.ActionType.ATTACK:
			var dtype: String = intent.damage_type
			if intent.target == ir.TargetType.ALL:
				for hpos in _all_living_hero_positions():
					_spawn_attack_beam_simple(dtype, caster_pos, hpos + _impact_jitter(), hpos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
			else:
				var hpos: Vector2 = _hero_pos_or_first(target_hero_id)
				if hpos != Vector2.ZERO:
					_spawn_attack_beam_simple(dtype, caster_pos, hpos + _impact_jitter(), hpos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
		ir.ActionType.BUFF:
			if intent.status_type == "block":
				_spawn_defense_buff(caster_pos, caster_foot)
			elif intent.status_type == "speed_bonus":
				_spawn_speed_buff(caster_pos, caster_foot)
			elif _is_holy_enemy(enemy_index):
				_spawn_holy_buff(caster_pos, caster_foot)
			else:
				_spawn_warrior_buff(caster_pos, caster_foot)
		ir.ActionType.DEBUFF:
			var stype: String = intent.status_type
			# speed_penalty 는 빔 VFX 가 아니라 발치 효과 — slow_debuff spawn 별도 처리
			if stype == "speed_penalty":
				if intent.target == ir.TargetType.ALL:
					for hpos in _all_living_hero_positions():
						_spawn_slow_debuff(hpos, hpos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
				else:
					var hpos2: Vector2 = _hero_pos_or_first(target_hero_id)
					if hpos2 != Vector2.ZERO:
						_spawn_slow_debuff(hpos2, hpos2 + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
			elif stype == "taunt":
				# 도발 — 시전 적 위치에 chest impact + 영웅 화살표 + stamp
				if intent.target == ir.TargetType.ALL:
					for hpos_t in _all_living_hero_positions():
						_spawn_taunt(caster_pos, caster_foot, hpos_t)
				else:
					var thpos: Vector2 = _hero_pos_or_first(target_hero_id)
					_spawn_taunt(caster_pos, caster_foot, thpos)
			else:
				var fx_script: GDScript = _debuff_script_for_status(stype)
				if fx_script:
					if intent.target == ir.TargetType.ALL:
						for hpos in _all_living_hero_positions():
							_spawn_debuff_beam_simple(fx_script, caster_pos, hpos, stype, hpos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
					else:
						var hpos: Vector2 = _hero_pos_or_first(target_hero_id)
						if hpos != Vector2.ZERO:
							_spawn_debuff_beam_simple(fx_script, caster_pos, hpos, stype, hpos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
		ir.ActionType.CHARGE_UP:
			_spawn_power_up(caster_pos, caster_foot)
		ir.ActionType.SUMMON:
			_spawn_summon_circle(caster_pos, caster_foot)
		ir.ActionType.WARD:
			# 1턴 무적 — defense_buff 재사용 + 청록 modulate (BUFF.block 파랑과 구분)
			_spawn_ward_dome(caster_pos, caster_foot)
		ir.ActionType.MARK_TARGET:
			# 영웅 1명 마킹 — target_hero_id 위치에 reticle + bracket + mark glyph
			var mt_pos: Vector2 = _hero_pos_or_first(target_hero_id)
			if mt_pos != Vector2.ZERO:
				_spawn_target_marking(caster_pos, mt_pos, mt_pos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
		ir.ActionType.MIMIC:
			# 영웅(반사 원본) ↔ 적(시전자) 사이 mirror arc + ripple + 황동 burst
			var mim_pos: Vector2 = _hero_pos_or_first(target_hero_id)
			if mim_pos != Vector2.ZERO:
				_spawn_mimic(caster_pos, mim_pos, mim_pos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
		ir.ActionType.SACRIFICE:
			# 자해 강화 — 시전자(적) 위치에 자해 VFX
			_spawn_sacrifice(caster_pos, caster_foot)
		ir.ActionType.COUNTER_PREPARE:
			# 반사 준비 — 시전자(적) 위치에 hex shield 조립 VFX
			_spawn_counter_prepare(caster_pos, caster_foot)
		ir.ActionType.SPECIAL:
			# remove_card variant 만 steal_card VFX (영웅 ↔ 적)
			var sp_v: String = intent.status_type
			if sp_v == "" or sp_v == "weak" or sp_v == "remove_card":
				var st_pos: Vector2 = _first_living_hero_pos()
				if st_pos != Vector2.ZERO:
					_spawn_steal_card(caster_pos, st_pos)
		ir.ActionType.PREPARE:
			# 효과 없는 빈 턴 — 절제된 차분 VFX (가슴 orb + 발치 ring + 머리 위 glyph)
			_spawn_prepare(caster_pos, caster_foot)
		ir.ActionType.HEAL_ALLY:
			# 동료 1마리 회복 — 가장 HP 낮은 적 위치에 heal_blessing
			var ally_idx: int = EnemyInteractionSystem.pick_lowest_hp_ally(BattleManager, enemy_index)
			if ally_idx >= 0 and ally_idx < _enemy_char_nodes.size():
				var ally_node: Node2D = _enemy_char_nodes[ally_idx]
				if ally_node:
					_spawn_heal_blessing(ally_node.global_position, _foot_pos(ally_node))
		ir.ActionType.BUFF_ALLY:
			# 동료 1마리 강화 — status_type=="block" 이면 defense_buff, 그 외 warrior_buff
			var b_ally_idx: int = EnemyInteractionSystem.pick_lowest_hp_ally(BattleManager, enemy_index) if intent.target == ir.TargetType.LOWEST_HP else EnemyInteractionSystem.pick_random_ally(BattleManager, enemy_index)
			if b_ally_idx >= 0 and b_ally_idx < _enemy_char_nodes.size():
				var b_ally_node: Node2D = _enemy_char_nodes[b_ally_idx]
				if b_ally_node:
					var b_foot: Vector2 = _foot_pos(b_ally_node)
					if intent.status_type == "block":
						_spawn_defense_buff(b_ally_node.global_position, b_foot)
					else:
						_spawn_warrior_buff(b_ally_node.global_position, b_foot)

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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	fx.set_ground_anchor(pos + Vector2(0.0, _CHAR_FOOT_Y_OFFSET))
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
func _on_card_vfx_start(card: Resource, target_enemy_index: int, target_hero_id: String) -> void:
	var owner_id: String = card.get("owner_id") if card.get("owner_id") != null else ""
	var owner_node: Node2D = _hero_char_nodes.get(owner_id)
	if owner_node == null:
		return
	var caster_pos: Vector2 = owner_node.global_position
	var caster_foot: Vector2 = _foot_pos(owner_node)
	# 카드의 모든 effect 에 대해 적절한 VFX 시작 — 단, 같은 효과군은 한 번만 표시.
	# damage_type 이 명시된 effect 는 모두 ATTACK 처리 (CONDITIONAL_DMG, DAMAGE_PER_*, SACRIFICE_PAYOFF 등)
	# 차지 시간 동기화는 첫 effect 기준 (_card_vfx_impact_delay) — 다른 VFX 는 자체 타이밍.
	# 여러 효과군 (예: BUFF + DEBUFF) 은 순차 spawn — VFX 사이 짧은 delay.
	const _VFX_STEP_DELAY: float = 0.25
	var _vfx_spawn_count: int = 0
	var did_attack: bool = false   # ATTACK 빔 한 번만 (모래폭풍 = DMG ALL curse + WEAK ALL → 빔 중복 방지)
	var did_buff: bool = false     # POWER 버프 한 번만
	var did_self_aoe: bool = false # heal/block 한 번만
	var did_debuff: bool = false   # 디버프 빔 한 번만 (ATTACK 이 이미 있으면 status 추가 표시 안 함)
	for effect in card.effects:
		var spawned_this: bool = false
		if effect.damage_type != "":
			if did_attack:
				continue
			did_attack = true
			# ATTACK 이 발동되면 같은 카드의 status 빔(weak/vulnerable 등)은 중복으로 안 띄움
			did_debuff = true
			spawned_this = true
			var dtype: String = effect.damage_type
			if effect.target == "ALL":
				for i in range(_enemy_char_nodes.size()):
					if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
						_spawn_attack_beam_simple(dtype, caster_pos, _enemy_char_nodes[i].global_position + _impact_jitter(), _foot_pos(_enemy_char_nodes[i]))
			elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
				_spawn_attack_beam_simple(dtype, caster_pos, _enemy_char_nodes[target_enemy_index].global_position + _impact_jitter(), _foot_pos(_enemy_char_nodes[target_enemy_index]))
		else:
			var et = effect.effect_type
			if et == EffectResource.EffectType.APPLY_STATUS:
				if effect.status_type.begins_with("power."):
					if not did_buff:
						if owner_id == "joan_of_arc":
							_spawn_holy_buff(caster_pos, caster_foot)
						else:
							_spawn_warrior_buff(caster_pos, caster_foot)
						did_buff = true
						spawned_this = true
				else:
					# 도발 — 시전 영웅(caster_pos) 에서 chest impact + 영웅→적 화살표
					if effect.status_type == "taunt":
						if not did_debuff:
							did_debuff = true
							spawned_this = true
							if effect.target == "ALL":
								for i in range(_enemy_char_nodes.size()):
									if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
										_spawn_taunt(caster_pos, caster_foot, _enemy_char_nodes[i].global_position)
							elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
								_spawn_taunt(caster_pos, caster_foot, _enemy_char_nodes[target_enemy_index].global_position)
					elif not did_debuff:
						var fx_script: GDScript = _debuff_script_for_status(effect.status_type)
						if fx_script:
							did_debuff = true
							spawned_this = true
							if effect.target == "ALL":
								for i in range(_enemy_char_nodes.size()):
									if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
										_spawn_debuff_beam_simple(fx_script, caster_pos, _enemy_char_nodes[i].global_position, effect.status_type, _foot_pos(_enemy_char_nodes[i]))
							elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
								_spawn_debuff_beam_simple(fx_script, caster_pos, _enemy_char_nodes[target_enemy_index].global_position, effect.status_type, _foot_pos(_enemy_char_nodes[target_enemy_index]))
			elif et == EffectResource.EffectType.CHARM:
				if not did_debuff:
					did_debuff = true
					spawned_this = true
					var charm_stacks: int = effect.value
					if effect.target == "ALL":
						for i in range(_enemy_char_nodes.size()):
							if BattleManager.is_enemy_alive(i) and _enemy_char_nodes[i]:
								_spawn_charm_or_infatuation(caster_pos, _enemy_char_nodes[i].global_position, i, charm_stacks, _foot_pos(_enemy_char_nodes[i]))
					elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
						_spawn_charm_or_infatuation(caster_pos, _enemy_char_nodes[target_enemy_index].global_position, target_enemy_index, charm_stacks, _foot_pos(_enemy_char_nodes[target_enemy_index]))
			elif et == EffectResource.EffectType.HEAL or et == EffectResource.EffectType.HEAL_ALL:
				if not did_self_aoe:
					_spawn_heal_blessing(caster_pos, caster_foot)
					did_self_aoe = true
					spawned_this = true
			elif et == EffectResource.EffectType.BLOCK or et == EffectResource.EffectType.BLOCK_ALL:
				if not did_self_aoe:
					_spawn_defense_buff(caster_pos, caster_foot)
					did_self_aoe = true
					spawned_this = true
			elif et == EffectResource.EffectType.SUMMON_TOKEN:
				if not did_self_aoe:
					_spawn_summon_burst(owner_id, caster_pos, effect.value)
					did_self_aoe = true
					spawned_this = true
			elif et == EffectResource.EffectType.BUFF_SPEED:
				if not did_buff:
					# 대상 영웅 위치마다 spawn. SELF(card.owner) / ALLY(target_hero_id) / ALL_ALLIES
					var bs_targets: Array = []
					if effect.target == "ALL_ALLIES":
						for h in TeamManager.get_living_heroes():
							bs_targets.append(h.hero_id)
					elif effect.target == "ALLY":
						bs_targets.append(target_hero_id if target_hero_id != "" else owner_id)
					else:
						bs_targets.append(owner_id)
					for bs_hid in bs_targets:
						var bs_node: Node2D = _hero_char_nodes.get(bs_hid)
						if bs_node:
							_spawn_speed_buff(bs_node.global_position, _foot_pos(bs_node))
					did_buff = true
					spawned_this = true
			elif et == EffectResource.EffectType.SACRIFICE_HP:
				# 잔다르크 순교 카드 — 시전자 위치에 자해 강화 VFX (POWER buff 와 함께 자주 묶임)
				if not did_buff:
					_spawn_sacrifice(caster_pos, caster_foot)
					did_buff = true
					spawned_this = true
			elif et == EffectResource.EffectType.GAIN_MORALE:
				# 사기 진작 (이순신·나폴레옹·칭기즈칸) — 시전자 위치에 깃발 + trumpet VFX
				if not did_buff:
					_spawn_morale_boost(caster_pos, caster_foot)
					did_buff = true
					spawned_this = true
			elif et == EffectResource.EffectType.PURGE_STATUS:
				# 디버프 정화 — SELF / ALL (ALL_ALLIES) 대상별 spawn. self_aoe 그룹 차지
				if not did_self_aoe:
					var pg_targets: Array = []
					if effect.target == "ALL" or effect.target == "ALL_ALLIES":
						for h in TeamManager.get_living_heroes():
							pg_targets.append(h.hero_id)
					else:
						pg_targets.append(owner_id)
					for pg_hid in pg_targets:
						var pg_node: Node2D = _hero_char_nodes.get(pg_hid)
						if pg_node:
							_spawn_purge_status(pg_node.global_position, _foot_pos(pg_node))
					did_self_aoe = true
					spawned_this = true
			elif et == EffectResource.EffectType.DEBUFF_SPEED:
				if not did_debuff:
					# 대상 적 위치마다 spawn. SINGLE(target_enemy_index) / ALL
					var ds_targets: Array = []
					if effect.target == "ALL":
						for i in range(_enemy_char_nodes.size()):
							if BattleManager.is_enemy_alive(i):
								ds_targets.append(i)
					elif target_enemy_index >= 0 and target_enemy_index < _enemy_char_nodes.size() and BattleManager.is_enemy_alive(target_enemy_index):
						ds_targets.append(target_enemy_index)
					for ds_ei in ds_targets:
						var ds_node: Node2D = _enemy_char_nodes[ds_ei]
						if ds_node:
							_spawn_slow_debuff(ds_node.global_position, _foot_pos(ds_node))
					did_debuff = true
					spawned_this = true
		# 순차 spawn — 첫 spawn 은 즉시, 이후 spawn 은 _VFX_STEP_DELAY 만큼 지연
		if spawned_this:
			_vfx_spawn_count += 1
			if _vfx_spawn_count < 4:  # 최대 4 종 (attack/buff/debuff/self_aoe). 마지막엔 delay 불필요하지만 단순화.
				await get_tree().create_timer(_VFX_STEP_DELAY).timeout

# 살아있는 적 인덱스 카운트 (target=ALL 영웅 카드의 visible 적 갯수)
func _enemy_alive_visible() -> int:
	var n: int = 0
	for i in range(_enemy_char_nodes.size()):
		if _enemy_char_nodes[i] != null and BattleManager.is_enemy_alive(i):
			n += 1
	return n

# 신성 적 판정 — ATTACK intent 의 damage_type 이 holy_* 인 게 하나라도 있으면 신성.
# phase_patterns 까지 검사. BUFF intent vfx 분기 (warrior_buff vs holy_buff) 용.
func _is_holy_enemy(enemy_index: int) -> bool:
	var er: Resource = BattleManager.get_enemy(enemy_index)
	if er == null:
		return false
	for intent in er.intent_pattern:
		if intent.damage_type != "" and intent.damage_type.begins_with("holy_"):
			return true
	for phase in er.phase_patterns:
		for intent in phase:
			if intent.damage_type != "" and intent.damage_type.begins_with("holy_"):
				return true
	return false

# 디버프 status_type → VFX 스크립트
func _debuff_script_for_status(stype: String) -> GDScript:
	if stype == "weak" or stype == "vulnerable":
		return _VFX_DEBUFF_HEX
	elif stype == "charm":
		return _VFX_CHARM_KISS
	elif stype == "enthrall":
		return _VFX_INFATUATION
	elif stype == "poison":
		return _VFX_POISON_SPLASH
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
		_:             return "impact_default"

# status_type → SFX 키. 디버프/매혹 전용 SFX 가 없으면 curse/divine 재활용.
func _sfx_for_status(stype: String) -> String:
	match stype:
		"weak", "vulnerable":   return "impact_curse"
		"charm", "enthrall":    return "impact_divine"
		_:                       return "impact_curse"

# 단순 빔 spawn — screen_effect 시점에 SFX/flash/shake 발동
# 캐릭터 노드의 발 좌표 (바닥 VFX anchor 용).
func _foot_pos(char_node: Node2D) -> Vector2:
	if char_node == null:
		return Vector2.ZERO
	return char_node.global_position + Vector2(0.0, _CHAR_FOOT_Y_OFFSET)

func _spawn_attack_beam_simple(dtype: String, caster_pos: Vector2, target_pos: Vector2, target_foot: Vector2 = Vector2.ZERO) -> void:
	var beam_script := _caster_beam_script(dtype)
	if beam_script == null:
		return
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	# 바닥 글리프 가진 vfx (holy_strike 등) 만 발 위치로 anchor
	if target_foot != Vector2.ZERO and fx.has_method("set_ground_anchor"):
		fx.set_ground_anchor(target_foot)
	var sfx_key: String = _sfx_for_dtype(dtype)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx(sfx_key)
	)
	fx.play(caster_pos, target_pos)

# 매혹 카드용 — 이 적이 charm 누적으로 enthrall 발동할지 판정 후 charm_kiss / infatuation 분기
func _spawn_charm_or_infatuation(caster_pos: Vector2, target_pos: Vector2, enemy_index: int, charm_stacks: int, target_foot: Vector2 = Vector2.ZERO) -> void:
	if BattleManager.will_enthrall_enemy(enemy_index, charm_stacks):
		_spawn_debuff_beam_simple(_VFX_INFATUATION, caster_pos, target_pos, "enthrall", target_foot)
	else:
		_spawn_debuff_beam_simple(_VFX_CHARM_KISS, caster_pos, target_pos, "charm", target_foot)

# 단순 디버프 spawn — screen_effect 시점에 SFX
func _spawn_debuff_beam_simple(beam_script: GDScript, caster_pos: Vector2, target_pos: Vector2, stype: String, target_foot: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = beam_script.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	if target_foot != Vector2.ZERO and fx.has_method("set_ground_anchor"):
		fx.set_ground_anchor(target_foot)
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
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	# bullet 은 전용 SFX 파일이 없어 projectile SFX 로 폴백
	var _sfx_key: String = "impact_projectile" if dtype == "bullet" else "impact_" + dtype
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx(_sfx_key)
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

func _on_hero_block_gained(hero_id: String, _amount: int) -> void:
	# defense_buff VFX 가 screen_effect 시점에 SFX 직접 발동 (이중 호출 방지)
	# 단 UI 는 갱신해야 block_lbl 텍스트가 표시됨
	_update_hero_ui(hero_id)

# 방어도 버프 VFX — BLOCK 획득 시 6각 dome + barrier + 룬링
# screen_effect 시점(차지 끝)에 block SFX 발동
func _spawn_defense_buff(pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx := _VFX_DEFENSE_BUFF.new()
	add_child(fx)
	fx.z_index = 1300  # VFX — 캐릭터 UI(1200) 위, 화면 UI(1500) 아래
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("block")
	)
	fx.play(pos, pos)

# 병사 소환 VFX — 영웅 위치 callRing + 새 토큰 슬롯들에 spawnPillar + 병사 등장 모션
# count = 이번 카드로 소환되는 토큰 수. 현재 토큰 수 다음 슬롯부터 배치.
# 만석(현재 + count > max_stack)이라 추가될 병사가 없으면 VFX·모션 모두 skip.
# (battle_manager 의 _await_vfx_impact 는 fallback timer 가 있어 hang 없음.)
func _spawn_summon_burst(hero_id: String, caster_pos: Vector2, count: int) -> void:
	if count <= 0:
		return
	var hero_node: Node2D = _hero_char_nodes.get(hero_id)
	if hero_node == null:
		return
	var cur: int = BattleManager._hero_status.get(hero_id, {}).get("tokens", 0)
	var max_stack: int = BattleManager.TOKEN_MAX_STACK
	var effective_count: int = mini(count, max_stack - cur)
	if effective_count <= 0:
		return  # 만석 — VFX·모션 skip
	var soldier_spawn_positions: Array = []  # 병사 노드 좌상단 spawn 위치 (_animate_token_shot 와 동일)
	var pillar_positions: Array = []         # VFX pillar 발치 위치 (병사 발치)
	var area_pos := _summon_area_pos(_SHARED_TOKEN_GRID_AREA_IDX)
	for i in range(effective_count):
		var idx: int = cur + i
		@warning_ignore("integer_division")
		var col: int = int(idx / TOKEN_ROWS)
		var row: int = idx % TOKEN_ROWS
		var tile_x: int = int(area_pos.x) + col * (TOKEN_TILE_W + TOKEN_TILE_GAP)
		var tile_y: int = int(area_pos.y) + row * (TOKEN_TILE_H + TOKEN_TILE_GAP)
		var soldier_pos := Vector2(tile_x + TOKEN_TILE_W / 2.0 - 40.0, tile_y + TOKEN_TILE_H / 4.0)
		soldier_spawn_positions.append(soldier_pos)
		# pillar 발치 = 병사 스프라이트 중심 X + 발 Y (sprite 40x50 × scale 2.0)
		pillar_positions.append(soldier_pos + Vector2(40.0, 100.0))
	var fx := _VFX_SUMMON_BURST.new()
	fx.set_spawn_positions(pillar_positions)
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
		for i in range(effective_count):
			_animate_soldier_summon_motion(hero_node, soldier_spawn_positions[i])
	)
	fx.play(caster_pos, pillar_positions[0])

# 병사 등장 모션 — 영웅 위치에서 페이드인+이동으로 슬롯에 도착,
# 잠시 머문 뒤 영웅으로 페이드아웃 복귀 (영구 토큰 그리드 폐기 정책 일관성).
func _animate_soldier_summon_motion(hero_node: Node2D, grid_pos: Vector2) -> void:
	var soldier = SoldierScene.instantiate()
	soldier.scale = Vector2(2.0, 2.0)
	soldier.position = hero_node.position
	soldier.modulate.a = 0.0
	soldier.z_index = hero_node.z_index + 1
	add_child(soldier)
	var tw := create_tween()
	tw.tween_property(soldier, "modulate:a", 1.0, 0.18)
	tw.parallel().tween_property(soldier, "position", grid_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(soldier, "modulate:a", 0.0, 0.25)
	tw.parallel().tween_property(soldier, "position", hero_node.position, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(soldier.queue_free)

# 보스 phase 전환 — 보스 위치 build-up → core erupt + 6겹 shockwave + 화면 flash·shake + cinematic title + letterbox
func _spawn_boss_phase_change(target_pos: Vector2, foot_pos: Vector2, phase_num: int) -> void:
	var fx: Node2D = _VFX_BOSS_PHASE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		_play_screen_shake()
		AudioManager.play_sfx("impact_explosive")
	)
	fx.play(target_pos, target_pos)
	# build 단계 rumble — 0.1s 간격으로 약한 shake 4회 (긴장감)
	for i in range(4):
		await get_tree().create_timer(0.1).timeout
		if is_inside_tree():
			_play_screen_shake()
	# cinematic letterbox + title toast
	_spawn_boss_phase_cinematic(phase_num)

# cinematic letterbox bars + "PHASE %d" 큰 텍스트 (페이드인/아웃)
func _spawn_boss_phase_cinematic(phase_num: int) -> void:
	# letterbox 위 띠
	var bar_top := ColorRect.new()
	bar_top.color = Color(0, 0, 0, 1.0)
	bar_top.size = Vector2(WINDOW_W, 0)
	bar_top.position = Vector2(0, 0)
	bar_top.z_index = 2100
	bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_top)
	# letterbox 아래 띠
	var bar_bot := ColorRect.new()
	bar_bot.color = Color(0, 0, 0, 1.0)
	bar_bot.size = Vector2(WINDOW_W, 0)
	bar_bot.position = Vector2(0, WINDOW_H)
	bar_bot.z_index = 2100
	bar_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar_bot)
	# letterbox 슬라이드 인 (위·아래에서)
	var bar_h: float = WINDOW_H * 0.09
	var tw_bars := create_tween().set_parallel(true)
	tw_bars.tween_property(bar_top, "size:y", bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_bars.tween_property(bar_bot, "size:y", bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw_bars.tween_property(bar_bot, "position:y", WINDOW_H - bar_h, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# title text (build 후 등장 — 약 0.55s 대기)
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	# title 컨테이너 (eyebrow + 큰 PHASE + sub)
	var title := Label.new()
	title.text = "— PHASE %d —" % phase_num
	title.add_theme_font_size_override("font_size", 92)
	title.add_theme_color_override("font_color", Color(1.0, 0.843, 0.415))  # 황금
	title.add_theme_color_override("font_outline_color", Color(0.290, 0.050, 0.062))  # 검빨 outline
	title.add_theme_constant_override("outline_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.size = Vector2(WINDOW_W, 140)
	title.position = Vector2(0, WINDOW_H * 0.32)
	title.z_index = 2200
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.modulate = Color(1, 1, 1, 0)
	title.scale = Vector2(0.7, 0.7)
	title.pivot_offset = title.size / 2.0
	add_child(title)
	var tw_title := create_tween()
	tw_title.tween_property(title, "modulate:a", 1.0, 0.25)
	tw_title.parallel().tween_property(title, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw_title.tween_interval(1.0)
	tw_title.tween_property(title, "modulate:a", 0.0, 0.45)
	tw_title.parallel().tween_property(title, "scale", Vector2(1.05, 1.05), 0.45)
	tw_title.tween_callback(title.queue_free)
	# letterbox 페이드아웃 (title 사라진 후)
	await get_tree().create_timer(1.6).timeout
	if not is_inside_tree():
		return
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(bar_top, "size:y", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_out.tween_property(bar_bot, "size:y", 0.0, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_out.tween_property(bar_bot, "position:y", WINDOW_H, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw_out.chain().tween_callback(bar_top.queue_free)
	tw_out.tween_callback(bar_bot.queue_free)

# 적 PREPARE intent — 자기 위치에 작은 orb + 발치 ring + 머리 위 glyph (절제된 차분 VFX)
func _spawn_prepare(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_PREPARE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	# PREPARE 는 효과 없는 빈 턴 — vfx_impact_resolved 동기화 불필요 (battle_manager 그대로 진행)
	fx.play(target_pos, target_pos)

# 영웅 카드 GAIN_MORALE — 자기 위치에 깃대 + flag + 3겹 trumpet ring + 머리 위 sigil
func _spawn_morale_boost(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_MORALE_BOOST.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(target_pos, target_pos)

# 영웅 카드 PURGE_STATUS — 자기/팀 위치에 정화 core + 3겹 wave + 머리 위 halo
func _spawn_purge_status(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_PURGE_STATUS.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(target_pos, target_pos)

# 적 SPECIAL remove_card — 영웅 손 빨간 mark → 카드 비행 영웅→적 → 적 catch + hook sigil
func _spawn_steal_card(caster_pos: Vector2, target_pos: Vector2) -> void:
	var fx: Node2D = _VFX_STEAL_CARD.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_curse")
	)
	fx.play(caster_pos, target_pos)

# 적 COUNTER_PREPARE — 자기 위치에 황동 hex shield 조립 + 발치 ring + 머리 위 sigil
func _spawn_counter_prepare(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_COUNTER_PREPARE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("block")
	)
	fx.play(target_pos, target_pos)

# 적 SACRIFICE intent + 영웅(잔다르크) SACRIFICE_HP 카드 — 자기 위치에 자해 강화 VFX
func _spawn_sacrifice(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SACRIFICE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_shake()
		AudioManager.play_sfx("impact_slash")
	)
	fx.play(target_pos, target_pos)

# 적 MIMIC — 시전자(적) ↔ 영웅(반사 원본) mirror arc + 적 ripple + 황동 burst
func _spawn_mimic(caster_pos: Vector2, target_pos: Vector2, target_foot: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_MIMIC.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if target_foot != Vector2.ZERO:
		fx.set_ground_anchor(target_foot)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(caster_pos, target_pos)

# 적 MARK_TARGET — 시전자→영웅 tracer + reticle travel + corner brackets + 머리 위 mark glyph
func _spawn_target_marking(caster_pos: Vector2, target_pos: Vector2, target_foot: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_TARGET_MARKING.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if target_foot != Vector2.ZERO:
		fx.set_ground_anchor(target_foot)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_shake()
		AudioManager.play_sfx("impact_curse")
	)
	fx.play(caster_pos, target_pos)

# 적 WARD (1턴 무적) — defense_buff 재사용 + 청록 modulate (BUFF.block 파랑과 구분)
func _spawn_ward_dome(pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx := _VFX_DEFENSE_BUFF.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	fx.modulate = Color(0.4, 1.0, 0.8)  # 청록 — 결계 컨셉
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("block")
	)
	fx.play(pos, pos)

# speed_penalty 부여 시 — 타겟 위치에 goop puddle + 역chevron ring + spiral motes (감속).
func _spawn_slow_debuff(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SLOW_DEBUFF.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("impact_curse")
	)
	fx.play(target_pos, target_pos)

# speed_bonus 부여 시 — 타겟 위치에 chevron ring + sonic shock + sparks (캐릭터 뒤/앞 분리).
func _spawn_speed_buff(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SPEED_BUFF.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(target_pos, target_pos)

# 적 SUMMON intent — 시전자 발치에 마법진 + 빛기둥 + 솟는 motes/rune. peak 시 SFX/플래시.
func _spawn_summon_circle(caster_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SUMMON_CIRCLE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(caster_pos, caster_pos)

# 적 CHARGE_UP intent — 외곽에서 적으로 inflow + 발치 aura + 솟구치는 streak. peak 시 SFX/플래시.
# foot_pos 는 캐릭터 발 위치 (바닥 aura·dust 가 발 밑 + 캐릭터 뒤로 렌더링되게 z anchor).
func _spawn_power_up(caster_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_POWER_UP.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void: BattleManager.vfx_impact_resolved.emit(), CONNECT_ONE_SHOT)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(caster_pos, caster_pos)

# 신화 시그너처 VFX 디스패치 — _on_signature_fired 가 호출.
# 신화별 spawn 위치·SFX·screen effect 분기.
func _spawn_signature_vfx(enemy_index: int, signature_name: String) -> void:
	var caster_node: Node2D = null
	if enemy_index >= 0 and enemy_index < _enemy_char_nodes.size():
		caster_node = _enemy_char_nodes[enemy_index]
	var caster_pos: Vector2 = caster_node.global_position if caster_node else Vector2(WINDOW_W / 2.0, WINDOW_H / 2.0)
	var foot_pos: Vector2 = _foot_pos(caster_node) if caster_node else caster_pos + Vector2(0.0, 60.0)
	match signature_name:
		"hubris": _spawn_sig_hubris(caster_pos, foot_pos)
		"ragnarok": _spawn_sig_ragnarok()
		"karma": _spawn_sig_karma(caster_pos, foot_pos)
		"yin_yang": _spawn_sig_yin_yang(caster_pos, foot_pos)
		"egyptian_curse": _spawn_sig_egyptian_curse(_first_living_hero_pos(), _first_living_hero_foot())
		"kekkai": _spawn_sig_kekkai(caster_pos, foot_pos)

# 그리스 휴브리스 — 적 위치에 황금 halo + zigzag 번개
func _spawn_sig_hubris(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SIG_HUBRIS.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_lightning")
	)
	fx.play(target_pos, target_pos)

# 북유럽 라그나로크 — 살아있는 모든 적 위치에 각자 좁은 범위 ember + 그라데이션 spawn
func _spawn_sig_ragnarok() -> void:
	var first := true
	for i in range(_enemy_char_nodes.size()):
		if not BattleManager.is_enemy_alive(i):
			continue
		var node: Node2D = _enemy_char_nodes[i]
		if node == null:
			continue
		var pos: Vector2 = node.global_position
		var foot: Vector2 = _foot_pos(node)
		var fx: Node2D = _VFX_SIG_RAGNAROK.new()
		add_child(fx)
		fx.z_index = 1300
		fx.position = Vector2.ZERO
		fx.set_ground_anchor(foot)
		# screen flash/shake/SFX 는 첫 인스턴스만 — 중복 방지
		if first:
			first = false
			fx.screen_effect.connect(func() -> void:
				_play_screen_flash()
				_play_screen_shake()
				AudioManager.play_sfx("impact_explosive")
			)
		fx.play(pos, pos)

# 불교 인과응보 — 시체(적)→모든 영웅 다중 빔
func _spawn_sig_karma(caster_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SIG_KARMA.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	var heroes: Array = _all_living_hero_positions()
	if heroes.is_empty():
		heroes = [_first_living_hero_pos()]
	fx.set_hero_positions(heroes)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(caster_pos, heroes[0])

# 도교 음양 — 적 위치 머리 위 회전 태극 (짧고 가벼움, SFX 없음 — 매 턴 발동)
func _spawn_sig_yin_yang(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SIG_YIN_YANG.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.play(target_pos, target_pos)

# 이집트 저주 — 피해 입은 영웅 머리 위 호루스의 눈 stamp.
# 3연발은 VFX 내부 (STAMP_COUNT) — screen_effect 가 stamp 마다 emit 되어 SFX 도 3번.
func _spawn_sig_egyptian_curse(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	if target_pos == Vector2.ZERO:
		return
	var fx: Node2D = _VFX_SIG_EGYPTIAN_CURSE.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		AudioManager.play_sfx("impact_curse")
	)
	fx.play(target_pos, target_pos)

# 일본 결계 — 적 위치에 4 ofuda + 6각 hex barrier + 結 kanji
func _spawn_sig_kekkai(target_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_SIG_KEKKAI.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_divine")
	)
	fx.play(target_pos, target_pos)

# 도발 VFX — 시전 적 가슴에서 chest impact + shockwave + glyph + 한글 word + 파티클.
# foot_pos: ground crack + dust 위치 anchor (정확한 발 위치).
# target_pos: 도발 대상 영웅 위치 — 시전자→영웅 화살표 + 영웅 머리 위 stamp.
func _spawn_taunt(caster_pos: Vector2, foot_pos: Vector2 = Vector2.ZERO, target_pos: Vector2 = Vector2.ZERO) -> void:
	var fx: Node2D = _VFX_TAUNT.new()
	add_child(fx)
	fx.z_index = 1280
	fx.position = Vector2.ZERO
	if foot_pos != Vector2.ZERO:
		fx.set_ground_anchor(foot_pos)
	fx.screen_effect.connect(func() -> void:
		_play_screen_flash()
		AudioManager.play_sfx("impact_blunt")
	)
	fx.play(caster_pos, target_pos)

func _on_hero_damaged(hero_id: String, amount: int, dtype: String = "") -> void:
	# VFX 는 _on_intent_vfx_start / _on_card_vfx_start 가 이미 차지 시작.
	# 데미지 시그널은 임팩트 시점이므로 — 피격 피드백 즉시 (UI·팝업·플래시·틴트·hurt 애니).
	# 빔이 없는 dtype (slash 등 impact-only) 은 별도 _spawn_impact_particles.
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

const _SHARED_TOKEN_GRID_AREA_IDX := 1  # SummonArea2 (중앙) 공유

func _on_token_attack_fired(hero_id: String, token_index: int, enemy_index: int) -> void:
	# 병사 토큰 동적 모션 — 영웅에서 spawn → 공유 그리드 → bullet → 영웅 복귀 → free
	if enemy_index < 0 or enemy_index >= _enemy_char_nodes.size():
		return
	var target_node = _enemy_char_nodes[enemy_index]
	if not is_instance_valid(target_node):
		return
	if not _hero_char_nodes.has(hero_id):
		return
	var hero_node: Node2D = _hero_char_nodes[hero_id]
	if not is_instance_valid(hero_node):
		return
	# 카메라 줌아웃 (적이 화면 밖에 있으면 bullet 안 보임) — VFX 종료 시 자동 복귀
	if _cam_state == CamState.HERO_FOCUS:
		_cam_state = CamState.VFX_PLAYING
		_cam_zoom_out()
		_start_enemy_sidebar_transition(0.0)
	# 토큰 노드 spawn (영웅 위치, 영웅 뒤 z)
	var soldier = SoldierScene.instantiate()
	soldier.scale = Vector2(2.0, 2.0)
	soldier.position = hero_node.position
	soldier.z_index = hero_node.z_index - 1
	add_child(soldier)
	# 공유 그리드 슬롯 좌표 (SummonArea2 기준)
	var area_pos := _summon_area_pos(_SHARED_TOKEN_GRID_AREA_IDX)
	@warning_ignore("integer_division")
	var col: int = int(token_index / TOKEN_ROWS)
	var row: int = token_index % TOKEN_ROWS
	var tile_x: int = int(area_pos.x) + col * (TOKEN_TILE_W + TOKEN_TILE_GAP)
	var tile_y: int = int(area_pos.y) + row * (TOKEN_TILE_H + TOKEN_TILE_GAP)
	var grid_pos := Vector2(tile_x + TOKEN_TILE_W / 2.0 - 40.0, tile_y + TOKEN_TILE_H / 4.0)
	# 모션: 영웅 → 그리드 (0.15s, 그 후 z 앞으로) → bullet 발사 → 대기 → 영웅 복귀 → free
	var tw := create_tween()
	tw.tween_property(soldier, "position", grid_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		soldier.z_index = hero_node.z_index + 1
		# 발사 위치 = 병사 스프라이트 중앙 (origin 좌상단 → scale 2.0 적용 시 +40, +50 offset)
		var muzzle_pos: Vector2 = soldier.global_position + Vector2(40, 50)
		_spawn_caster_beam(_VFX_BULLET_SHOT, muzzle_pos, target_node.global_position, "bullet", func(): pass)
	)
	tw.tween_interval(0.25)
	tw.tween_property(soldier, "position", hero_node.position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(soldier.queue_free)

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
	# bullet 분기 — token_attack_fired signal 에서 처리 (각 병사 타일 위치 + SFX 분산)

# ── 킬캠 + parallax sway (M7.5 깊이감) ──────────────────────────────
# 킬캠: 처치/사망 시 슬로우 + 카메라 줌인. GameSettings.kill_cam_enabled 옵션.
# parallax sway: ParallaxBackground.scroll_offset 직접 변경 — 카메라 미사용 → UI/캐릭터 안 흔들림
var _camera: Camera2D = null
const _KC_HOME_POS := Vector2(960, 540)
var _kill_cam_active: bool = false
var _scene_bg: Node2D = null  # SceneBackground (Node2D, _back/_front 두 ParallaxBackground 보유)
const WIND_SHADER := preload("res://assets/shaders/wind_sway.gdshader")

# ── 차례 카메라 줌 시스템 (영웅 차례 줌인 / 드래그·VFX 줌아웃 / 적 차례 멀리) ──
enum CamState { IDLE_FAR, HERO_FOCUS, DRAGGING, VFX_PLAYING }
var _cam_state: int = CamState.IDLE_FAR
const CAM_ZOOM_HERO := Vector2(1.3, 1.3)
const CAM_ZOOM_FAR := Vector2.ONE
const CAM_TWEEN_TIME := 0.3
const CAM_VFX_TIMEOUT := 3.0  # VFX 카운터 fallback (모든 VFX 가 가장 오래 가도 3s 안에 끝남)
var _cam_tween: Tween = null
var _active_vfx_count: int = 0

func _is_vfx_node(node: Node) -> bool:
	var script = node.get_script()
	return script != null and script.resource_path.contains("scenes/vfx/")

func _on_child_entered_vfx_track(node: Node) -> void:
	if _is_vfx_node(node):
		_active_vfx_count += 1

func _on_child_exited_vfx_track(node: Node) -> void:
	if not _is_vfx_node(node):
		return
	_active_vfx_count -= 1
	if _active_vfx_count <= 0:
		_active_vfx_count = 0
		# 모든 VFX 노드 종료 — 카메라 복귀 시도 (DRAGGING 으로 전환됐으면 _cam_on_vfx_ended 안에서 skip)
		_cam_on_vfx_ended()

func _cam_tween_time() -> float:
	# 시간 = base / speed_multiplier (값이 클수록 빨라짐)
	var gs := get_node_or_null("/root/GameSettings")
	var mul: float = gs.cam_zoom_speed_multiplier if gs else 1.0
	if mul <= 0.0:
		mul = 1.0
	return CAM_TWEEN_TIME / mul

func _hero_zoom_disabled() -> bool:
	var gs := get_node_or_null("/root/GameSettings")
	return gs != null and not gs.hero_zoom_enabled

func _cam_zoom_to_hero(hid: String) -> void:
	if _kill_cam_active or _camera == null:
		return
	# 영웅 줌인 옵션 off — 줌아웃 유지
	if _hero_zoom_disabled():
		_cam_zoom_out()
		return
	if not _hero_char_nodes.has(hid):
		return
	var node: Node2D = _hero_char_nodes[hid]
	if not is_instance_valid(node):
		return
	if _cam_tween:
		_cam_tween.kill()
	var t: float = _cam_tween_time()
	_cam_tween = create_tween().set_parallel(true)
	_cam_tween.tween_property(_camera, "zoom", CAM_ZOOM_HERO, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_cam_tween.tween_property(_camera, "position", node.global_position, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _cam_zoom_out() -> void:
	if _kill_cam_active or _camera == null:
		return
	if _cam_tween:
		_cam_tween.kill()
	var t: float = _cam_tween_time()
	_cam_tween = create_tween().set_parallel(true)
	_cam_tween.tween_property(_camera, "zoom", CAM_ZOOM_FAR, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_cam_tween.tween_property(_camera, "position", _KC_HOME_POS, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _cam_on_hero_turn_start(hid: String) -> void:
	_cam_state = CamState.HERO_FOCUS
	_cam_zoom_to_hero(hid)
	_start_enemy_sidebar_transition(0.0 if _hero_zoom_disabled() else 1.0)

func _cam_on_enemy_turn_start() -> void:
	_cam_state = CamState.IDLE_FAR
	_cam_zoom_out()
	_start_enemy_sidebar_transition(0.0)

func _cam_on_drag_started() -> void:
	# VFX 중에 새 드래그 시작 — DRAGGING 우선 (VFX 종료 후 영웅 복귀 안 됨)
	_cam_state = CamState.DRAGGING
	_cam_zoom_out()
	_start_enemy_sidebar_transition(0.0)

func _cam_on_drag_canceled() -> void:
	# 카드 사용 안 됐을 때 — DRAGGING 상태일 때만 영웅 복귀
	if _cam_state != CamState.DRAGGING:
		return
	var hid: String = BattleManager.get_current_hero_id()
	if hid != "":
		_cam_state = CamState.HERO_FOCUS
		_cam_zoom_to_hero(hid)
		_start_enemy_sidebar_transition(0.0 if _hero_zoom_disabled() else 1.0)
	else:
		_cam_state = CamState.IDLE_FAR
		_cam_zoom_out()
		_start_enemy_sidebar_transition(0.0)

func _cam_on_card_played() -> void:
	# 카드 사용 직후 — VFX 재생 상태로 전환 (이미 줌아웃 유지)
	_cam_state = CamState.VFX_PLAYING
	# 짧은 fallback — VFX 가 아예 생성 안 되는 카드 (POWER 등) 대비. 0.5s 후 카운터 0 이면 복귀.
	get_tree().create_timer(0.5).timeout.connect(_cam_check_vfx_complete, CONNECT_ONE_SHOT)

func _cam_check_vfx_complete() -> void:
	# VFX 카운터가 0 이고 아직 VFX_PLAYING 이면 즉시 복귀 (비-VFX 카드 사용 후)
	if _active_vfx_count == 0 and _cam_state == CamState.VFX_PLAYING:
		_cam_try_return_to_hero()

func _cam_on_vfx_ended() -> void:
	# 모든 VFX 노드 종료 — VFX_PLAYING 상태일 때만 복귀 (DRAGGING 우선)
	if _cam_state == CamState.VFX_PLAYING:
		_cam_try_return_to_hero()

func _cam_try_return_to_hero() -> void:
	# 아직 VFX 진행 중이면 skip (child_exited 가 종료 시 다시 호출)
	if _active_vfx_count > 0:
		return
	# DRAGGING 으로 전환됐으면 skip — 새 드래그 우선
	if _cam_state != CamState.VFX_PLAYING:
		return
	var hid: String = BattleManager.get_current_hero_id()
	if hid != "":
		_cam_state = CamState.HERO_FOCUS
		_cam_zoom_to_hero(hid)
		_start_enemy_sidebar_transition(0.0 if _hero_zoom_disabled() else 1.0)
	else:
		_cam_state = CamState.IDLE_FAR
		_cam_zoom_out()
		_start_enemy_sidebar_transition(0.0)

# ── 적 패널 일부 UI 사이드바 트윈 (영웅 줌인 시) ──
# 화면 좌표 → self(BattleScene) 좌표 — 카메라 zoom/position 역변환
func _screen_to_self(screen_pos: Vector2) -> Vector2:
	if _camera == null:
		return screen_pos
	var vp_center := Vector2(WINDOW_W, WINDOW_H) * 0.5
	return (screen_pos - vp_center) / _camera.zoom + _camera.position

func _update_enemy_sidebar_positions() -> void:
	if _kill_cam_active:
		return  # 킬캠 중에는 사이드바 갱신 정지 (마지막 위치 freeze)
	for i in range(_enemy_nodes.size()):
		var entry: Dictionary = _enemy_nodes[i]
		if entry.is_empty() or not entry.has("base_positions"):
			continue
		_apply_enemy_sidebar_to_entry(entry, i)

func _apply_enemy_sidebar_to_entry(entry: Dictionary, slot_idx: int) -> void:
	var bp: Dictionary = entry["base_positions"]
	var panel_base: Vector2 = bp.get("panel", Vector2.ZERO)
	# 적별 transition_t — visible 적은 0 유지 (base), 안 보이는 적만 1 (사이드바)
	var t: float = entry.get("transition_t", 0.0)
	# 사이드바 활성 시 적 base panel/btn 의 mouse hit 차단 비활성 (사이드바 노드 hover 위해)
	var sidebar_mode: bool = t > 0.5
	var panel_node = entry.get("panel")
	if panel_node != null and is_instance_valid(panel_node):
		panel_node.mouse_filter = Control.MOUSE_FILTER_IGNORE if sidebar_mode else Control.MOUSE_FILTER_STOP
	var btn_node = entry.get("btn")
	if btn_node != null and is_instance_valid(btn_node):
		btn_node.mouse_filter = Control.MOUSE_FILTER_IGNORE if sidebar_mode else Control.MOUSE_FILTER_STOP
	# sidebar 2x3 grid 위치 — 사이드바 가는 적의 sequential 인덱스 (entry["sidebar_slot_idx"]) 우선.
	# 빈칸 없이 우측 위→아래→중 위→중 아래→좌 위→좌 아래 순.
	var sb_idx: int = entry.get("sidebar_slot_idx", slot_idx)
	@warning_ignore("integer_division")
	var col: int = sb_idx / 2
	var row: int = sb_idx % 2
	var sidebar_panel_screen := Vector2(SIDEBAR_X - col * SIDEBAR_SLOT_HSPACE, SIDEBAR_Y + row * SIDEBAR_SLOT_VSPACE)
	var inv_zoom: Vector2 = Vector2.ONE
	if _camera != null and abs(_camera.zoom.x) > 0.001:
		inv_zoom = Vector2.ONE / _camera.zoom
	var scale_now: Vector2 = Vector2.ONE.lerp(inv_zoom, t)
	for key in ["name_lbl", "hp_bar", "hp_lbl", "block_lbl", "intent_lbl", "status_box", "sig_icon"]:
		var node = entry.get(key)
		if node == null or not is_instance_valid(node):
			continue
		if not bp.has(key):
			continue
		var base_pos: Vector2 = bp[key]
		# sidebar 에서 node 위치 = sidebar_panel + (node.base - panel.base)
		var sb_screen: Vector2 = sidebar_panel_screen + (base_pos - panel_base)
		var sb_self: Vector2 = _screen_to_self(sb_screen)
		node.position = base_pos.lerp(sb_self, t)
		# sig_icon 만 scale 1.0 (작은 Label hover hit area 보존). 나머지는 sidebar 시 1.0.
		if key == "sig_icon":
			node.scale = Vector2.ONE
		else:
			node.scale = scale_now

func _start_enemy_sidebar_transition(target_t_global: float) -> void:
	if _enemy_sidebar_tween != null:
		_enemy_sidebar_tween.kill()
	var dur: float = _cam_tween_time()
	_enemy_sidebar_tween = create_tween().set_parallel(true)
	var hero_pos: Vector2 = _get_current_hero_world_pos()
	var sidebar_slot_counter: int = 0  # 사이드바 가는 적 sequential 카운터 (빈칸 없이 우측 위→아래 순)
	for i in range(_enemy_nodes.size()):
		var entry: Dictionary = _enemy_nodes[i]
		var target_t: float = target_t_global
		# 줌인 활성 시도 + 적이 화면 안 fully visible → base 유지 (사이드바 X)
		if target_t_global > 0.5 and _is_enemy_visible_after_zoom(entry, hero_pos):
			target_t = 0.0
		if target_t > 0.5:
			entry["sidebar_slot_idx"] = sidebar_slot_counter
			sidebar_slot_counter += 1
		var captured_idx: int = i
		_enemy_sidebar_tween.tween_method(
			func(v: float): _enemy_nodes[captured_idx]["transition_t"] = v,
			float(entry.get("transition_t", 0.0)), target_t, dur
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _get_current_hero_world_pos() -> Vector2:
	var hid: String = BattleManager.get_current_hero_id()
	if hid == "" or not _hero_char_nodes.has(hid):
		return _KC_HOME_POS
	var node: Node2D = _hero_char_nodes[hid]
	return node.global_position if is_instance_valid(node) else _KC_HOME_POS

# 영웅 줌인 후 카메라 가정 (hero 위치 + zoom 1.3) 으로 적 panel 이 화면 안 fully visible
func _is_enemy_visible_after_zoom(entry: Dictionary, hero_pos: Vector2) -> bool:
	var bp: Dictionary = entry["base_positions"]
	var panel_base: Vector2 = bp.get("panel", Vector2.ZERO)
	var center_self: Vector2 = panel_base + Vector2(SLOT_W, SLOT_H) / 2.0
	var vp_center := Vector2(WINDOW_W, WINDOW_H) * 0.5
	var center_screen: Vector2 = (center_self - hero_pos) * CAM_ZOOM_HERO + vp_center
	var half_w: float = SLOT_W * CAM_ZOOM_HERO.x * 0.5
	var half_h: float = SLOT_H * CAM_ZOOM_HERO.y * 0.5
	return (center_screen.x - half_w >= 0.0
			and center_screen.x + half_w <= WINDOW_W
			and center_screen.y - half_h >= 0.0
			and center_screen.y + half_h <= WINDOW_H)

# 설정 변경 즉시 반영 — 영웅 줌인 옵션 on/off
func _on_hero_zoom_setting_changed(enabled: bool) -> void:
	if not enabled:
		# 줌인 → 줌아웃 (현재 상태와 무관하게)
		_cam_zoom_out()
		_start_enemy_sidebar_transition(0.0)
		return
	# 줌아웃 → 영웅 차례 중이면 즉시 줌인
	var hid: String = BattleManager.get_current_hero_id()
	if hid != "" and _cam_state == CamState.HERO_FOCUS:
		_cam_zoom_to_hero(hid)
		_start_enemy_sidebar_transition(1.0)

func _setup_kill_cam() -> void:
	_camera = Camera2D.new()
	_camera.position = _KC_HOME_POS
	_camera.zoom = Vector2.ONE
	add_child(_camera)
	_camera.make_current()  # tree 에 attach 후 호출

# 배틀 인트로 — 1초 줌아웃 유지 + 타이틀 라벨에 "전투!" 표시
func _play_battle_intro() -> void:
	if _message_label:
		_message_label.text = tr("battle.msg_intro")
	await get_tree().create_timer(1.0).timeout
	if _message_label:
		_message_label.text = ""

# Shift+Y 디버그 — 모든 fg sprite + 캐릭터 노드 박스 + (x,y,z) 라벨 표시/숨김
var _bg_debug_overlay: Node2D = null

func toggle_bg_debug() -> void:
	if _bg_debug_overlay and is_instance_valid(_bg_debug_overlay):
		_bg_debug_overlay.queue_free()
		_bg_debug_overlay = null
		return
	_bg_debug_overlay = Node2D.new()
	_bg_debug_overlay.z_index = 5000
	add_child(_bg_debug_overlay)
	# 재귀로 모든 Sprite2D 잡기 — fg(직접 자식) + _back ParallaxLayer 안 SVG(large/medium) 도 포함
	# critter(bird) 는 제외 — Sprite2D 지만 _critters Node2D 자식 (재귀로 잡지만 라벨 구분)
	_collect_bg_sprites(self)
	# 캐릭터 노드들
	for hero_id in _hero_char_nodes:
		var n: Node2D = _hero_char_nodes[hero_id]
		if is_instance_valid(n):
			_draw_bg_debug_box(n, "HERO_%s" % hero_id, Color(0.4, 0.85, 1.0))
	for i in _enemy_char_nodes.size():
		var en: Node2D = _enemy_char_nodes[i]
		if is_instance_valid(en):
			_draw_bg_debug_box(en, "ENEMY_%d" % i, Color(1.0, 0.4, 0.4))

# 재귀로 모든 Sprite2D 수집 — debug overlay/critter sprite 자체는 제외
func _collect_bg_sprites(node: Node) -> void:
	for child in node.get_children():
		if child == _bg_debug_overlay:
			continue
		if child is Sprite2D:
			# SVG 오브젝트만 표시 (texture path 가 backgrounds/objects/ 이거나 직접 자식 fg)
			var spr := child as Sprite2D
			var tex_path := ""
			if spr.texture and spr.texture.resource_path:
				tex_path = spr.texture.resource_path
			if tex_path.contains("backgrounds/objects"):
				var tag := "BG"
				if child.get_parent() == self:
					tag = "FG"
				_draw_bg_debug_box(child, tag, Color(1.0, 0.85, 0.2))
		# 재귀 (CanvasLayer, Node2D, ParallaxBackground/Layer 등)
		if child.get_child_count() > 0:
			_collect_bg_sprites(child)

# 노드의 시각 박스 그리기 — Sprite2D 는 get_rect()(centered/offset 자동 보정) 사용,
# 그 외 Node2D 는 추정 박스 (panel 영역).
func _draw_bg_debug_box(node: Node2D, label: String, color: Color) -> void:
	var r: Rect2
	if node is Sprite2D:
		var lr: Rect2 = (node as Sprite2D).get_rect()  # local (centered/offset 적용)
		r = Rect2(node.global_position + lr.position * node.scale, lr.size * node.scale)
	else:
		# Node2D — 예상 박스 (영웅/적 panel 240×280 가정, 발 = position.y + 96)
		r = Rect2(node.global_position - Vector2(60, 96), Vector2(120, 192))
	# 외곽선 Line2D
	var line := Line2D.new()
	line.points = PackedVector2Array([
		r.position, Vector2(r.end.x, r.position.y),
		r.end, Vector2(r.position.x, r.end.y), r.position,
	])
	line.default_color = color
	line.width = 2.0
	_bg_debug_overlay.add_child(line)
	# 라벨 — 상단에 (x, y, z, foot)
	var foot_y := int(r.end.y)
	var lbl := Label.new()
	lbl.text = "%s\nx=%d  pos.y=%d  z=%d  foot=%d" % [
		label, int(node.global_position.x), int(node.global_position.y), node.z_index, foot_y,
	]
	lbl.position = Vector2(r.position.x, r.position.y - 50)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 14)
	_bg_debug_overlay.add_child(lbl)

# 캐릭터 영역 Rect2 array — fg 충돌 검사용 (UI 는 z_index 1000 이라 fg 가 가릴 수 없음 → 제외).
# anchor_y < rect.end.y 인 sprite 는 캐릭터 뒤(z 작음)라 어차피 안 가려서 통과됨.
func _build_bg_occupied_rects() -> Array:
	var rects: Array = []
	for i in 3:
		var p: Vector2 = (get_node("HeroSlot%d" % (i + 1)) as Marker2D).position
		rects.append(Rect2(p.x, p.y, SLOT_W, SLOT_H))
	for i in 6:
		var p: Vector2 = (get_node("EnemySlot%d" % (i + 1)) as Marker2D).position
		rects.append(Rect2(p.x, p.y, SLOT_W, SLOT_H))
	return rects

# 전경 SVG 오브젝트 — battle_scene 자체 자식으로 spawn.
# y_sort 가 reliable 하지 않아 z_index = int(position.y) 로 강제 (큰 y → 위로).
# UI Control 들은 z_index 1000+ 라 fg 보다 항상 위.
func _spawn_fg_specs(specs: Array, tint: Color) -> void:
	for spec_v in specs:
		var spec: Dictionary = spec_v
		var svg_id: String = spec.get("svg_id", "")
		var anchor: Vector2 = spec["pos"]
		var sc: float = spec["scale"]
		var z_main: int = int(anchor.y)
		# 발 그림자 — 코드 동적 생성. 모두 식생 수준 크기 (콘텐츠 폭 50%), 구조물만 살짝 짙음.
		var is_soft: bool = SceneBackground._wind_eligible(svg_id) if svg_id != "" else false
		var is_altar: bool = svg_id.begins_with("altar")
		var size_w: float = SceneBackground.OBJECT_SIZE.get(svg_id, Vector2(120, 240)).x
		var soft_shadow: bool = is_soft and not is_altar
		var shadow_w: float = size_w * sc * 0.50
		var shadow_h: float = max(4.0, size_w * sc * 0.05)
		var shadow_alpha: float = 0.30 if soft_shadow else 0.40
		_add_ground_shadow(self, anchor, shadow_w, shadow_h, shadow_alpha, z_main - 1)
		# split spawn — base(정지) + sway 부분(shader). 나무: trunk/leaves. altar: base/flame.
		# z 순서: 식생 (cypress 류) 는 trunk 가 위 (잎이 발까지 덮는 디자인이라 trunk 보이도록).
		# altar 는 flame 이 위 (base 가 받침). 식생 vs altar 분기.
		if spec.get("split", false):
			var suffixes: Array = spec.get("split_suffixes", ["_trunk", "_leaves"])
			var spec_path: String = spec["path"]
			var base_path: String = spec_path.replace(".svg", "%s.svg" % suffixes[0])
			var sway_path: String = spec_path.replace(".svg", "%s.svg" % suffixes[1])
			var sway_mat := ShaderMaterial.new()
			sway_mat.shader = WIND_SHADER
			sway_mat.set_shader_parameter("amplitude", float(spec.get("wind_amp", 4.0)))
			sway_mat.set_shader_parameter("speed", float(spec.get("wind_speed", 1.0)))
			sway_mat.set_shader_parameter("phase", float(spec.get("wind_phase", 0.0)))
			var is_tree: bool = suffixes[0] == "_trunk"
			if is_tree:
				# 식생: leaves(아래) + trunk(위) — trunk 가 잎 사이로 보임
				_spawn_tree_part(sway_path, anchor, sc, tint, z_main, sway_mat)
				_spawn_tree_part(base_path, anchor, sc, tint, z_main + 1, null)
			else:
				# altar: base(아래) + flame(위)
				_spawn_tree_part(base_path, anchor, sc, tint, z_main, null)
				_spawn_tree_part(sway_path, anchor, sc, tint, z_main + 1, sway_mat)
			continue
		# 일반 fg sprite (구조물 또는 grass/flower 통째)
		var path: String = spec["path"]
		if not ResourceLoader.exists(path):
			continue
		var spr := Sprite2D.new()
		spr.texture = load(path)
		spr.scale = Vector2(sc, sc)
		spr.position = anchor
		spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
		spr.modulate = tint
		spr.z_index = z_main
		if spec.get("wind", false):
			var mat := ShaderMaterial.new()
			mat.shader = WIND_SHADER
			mat.set_shader_parameter("amplitude", float(spec.get("wind_amp", 4.0)))
			mat.set_shader_parameter("speed", float(spec.get("wind_speed", 1.0)))
			mat.set_shader_parameter("phase", float(spec.get("wind_phase", 0.0)))
			spr.material = mat
		add_child(spr)

# split tree 의 trunk/leaves 한 조각 spawn. mat 가 null 이 아니면 ShaderMaterial 적용.
func _spawn_tree_part(path: String, anchor: Vector2, sc: float, tint: Color, z_idx: int, mat: ShaderMaterial) -> void:
	if not ResourceLoader.exists(path):
		return
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.scale = Vector2(sc, sc)
	spr.position = anchor
	spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
	spr.modulate = tint
	spr.z_index = z_idx
	if mat != null:
		spr.material = mat
	add_child(spr)

# 타원 그림자 (Polygon2D 24각형). target 의 자식으로 추가.
func _add_ground_shadow(target: Node, pos: Vector2, rx: float, ry: float, alpha: float, z_idx: int) -> void:
	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, alpha)
	var pts := PackedVector2Array()
	for i in 24:
		var a: float = TAU * float(i) / 24.0
		pts.append(pos + Vector2(cos(a) * rx, sin(a) * ry))
	shadow.polygon = pts
	shadow.z_index = z_idx
	target.add_child(shadow)


# 현재 act 의 신화 키 (parallax 배경 팔레트용)
func _current_mythology() -> String:
	var gm := get_node_or_null("/root/GameManager")
	if gm == null:
		return "greek"
	var act_idx: int = gm.current_act - 1
	var pool: Array = gm.act_mythologies
	if act_idx >= 0 and act_idx < pool.size():
		return pool[act_idx]
	return "greek"

func _update_camera_sway(_delta: float) -> void:
	# parallax 보정 비활성화 — 캐릭터/바닥은 안 움직이는데 fg/bg 만 움직이면 어색.
	# 평상시 sway X, shake 시 모든 자식 같이 이동 (battle_scene.position 변경 효과).
	pass

# 디버그용 — kill_cam_enabled 설정 무관하게 강제 실행 (Shift+K 단축키)
func debug_play_kill_cam(target_pos: Vector2) -> void:
	if _kill_cam_active or _camera == null:
		return
	_run_kill_cam(target_pos)

func _play_kill_cam(target_pos: Vector2) -> void:
	# autoload 안전 접근 (CLI 테스트 환경 회피)
	var gs := get_node_or_null("/root/GameSettings")
	if gs == null or not gs.kill_cam_enabled:
		return
	if _kill_cam_active or _camera == null:
		return
	_run_kill_cam(target_pos)

func _run_kill_cam(target_pos: Vector2) -> void:
	_kill_cam_active = true
	var prev_scale := Engine.time_scale
	Engine.time_scale = 0.3
	# 균일 줌 — 2D parallax 만으로 dolly 효과 흉내는 ground/sky 좌표계 변형 야기. HD-2D 까지 가야 함.
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(_camera, "zoom", Vector2(1.6, 1.6), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.tween_property(_camera, "position", target_pos, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw_in.finished
	# slowmo 유지 (scaled 0.18s ≈ unscaled 0.6s)
	await get_tree().create_timer(0.18).timeout
	# 줌아웃 — 정상 속도로 복귀
	Engine.time_scale = prev_scale
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_camera, "zoom", Vector2.ONE, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw_out.tween_property(_camera, "position", _KC_HOME_POS, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw_out.finished
	_kill_cam_active = false

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
	var char_node = _enemy_char_nodes[index] if index < _enemy_char_nodes.size() else null
	var enemy_res: Resource = BattleManager.get_enemy(index)
	var is_boss: bool = enemy_res != null and enemy_res.grade == EnemyResource.Grade.BOSS
	var death_fx := func() -> void:
		AudioManager.play_sfx("enemy_death")
		_update_enemy_ui(index)
		if char_node:
			if is_boss:
				_spawn_boss_death(char_node.global_position, _foot_pos(char_node))
			else:
				_spawn_death_dissolve(char_node.global_position)
			if char_node.has_node("AnimationPlayer"):
				var ap: AnimationPlayer = char_node.get_node("AnimationPlayer")
				if ap.has_animation("death"):
					ap.play("death")
		# 처치 순간 킬캠 (옵션 켜져있으면)
		if char_node:
			_play_kill_cam(char_node.global_position)
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
			# 영웅 사망 순간 킬캠 (옵션 켜져있으면)
			_play_kill_cam(char_node.global_position)
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

# 적 enemy_index → 한글 적 이름 (tooltip 표시용). 적이 사망/이상 시 "?" 폴백.
func _get_enemy_name_for_tooltip(enemy_index: int) -> String:
	var er: Resource = BattleManager.get_enemy(enemy_index)
	if er == null:
		return "?"
	var name_key: String = er.enemy_name
	return tr(name_key) if name_key != "" else "?"

# 영웅 hero_id → 한글 영웅 이름 (tooltip 표시용).
func _get_hero_name_for_tooltip(hero_id: String) -> String:
	if TeamManager == null:
		return hero_id
	for hero in TeamManager.heroes:
		if hero.hero_id == hero_id:
			return tr(hero.hero_name) if hero.hero_name != "" else hero_id
	return hero_id

func _make_status_label(key: String, val: int, status: Dictionary) -> Control:
	var tex: Texture2D = IconUtils.get_status_icon(key)
	var tooltip: String = _trf("status.%s.desc" % key, val)
	# speed_bonus / speed_penalty — 각 instance 별 "+N/M턴" list tooltip
	if key in ["speed_bonus", "speed_penalty"] and typeof(status.get(key, null)) == TYPE_ARRAY:
		var lines: Array[String] = []
		var sign_str: String = "+" if key == "speed_bonus" else "-"
		for ins in status[key]:
			lines.append("%s%d / %d턴" % [sign_str, int(ins.get("value", 0)), int(ins.get("dur", 0))])
		tooltip = "%s\n  " % _trf("status.%s.desc" % key, val) + "\n  ".join(lines)
	# taunt — 부여자(source) 에 따라 tooltip 의 이름 분기.
	# - 영웅 status 에 적용: source = enemy_index (int) → 적 이름 표시
	# - 적 status 에 적용: source = hero_id (string) → 영웅 이름 표시
	# 양쪽 다 "X 의 도발 — 시전자만 공격 가능" 의미. 게이머 UI 통일.
	elif key == "taunt":
		var src = status.get("taunt_source", null)
		var src_name: String = ""
		if typeof(src) == TYPE_STRING and src != "":
			src_name = _get_hero_name_for_tooltip(src)
		elif typeof(src) == TYPE_INT and src >= 0:
			src_name = _get_enemy_name_for_tooltip(src)
		if src_name != "":
			tooltip = tr("status.taunt.desc.locked") % src_name
		else:
			tooltip = tr("status.taunt.desc")

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
		# speed_bonus / speed_penalty — Array of {value, dur}. 합산값으로 label 생성
		if key in ["speed_bonus", "speed_penalty"] and typeof(status[key]) == TYPE_ARRAY:
			var total: int = 0
			for ins in status[key]:
				total += int(ins.get("value", 0))
			if total > 0:
				box.add_child(_make_status_label(key, total, status))
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
		# speed_bonus / speed_penalty — Array 합산
		if key in ["speed_bonus", "speed_penalty"] and typeof(status[key]) == TYPE_ARRAY:
			var total: int = 0
			for ins in status[key]:
				total += int(ins.get("value", 0))
			if total > 0:
				box.add_child(_make_status_label(key, total, status))
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
		var owner_id: String = power.get("owner_id", "")
		_active_powers_box.add_child(_make_power_item(base_key, v, owner_id))
	# strength_player 변경 시 카드 데미지 표시 갱신
	_refresh_hand_card_damage()

func _make_power_item(base_key: String, v: int, owner_id: String = "") -> Control:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 4)
	hbox.custom_minimum_size = Vector2(0, 24)
	hbox.mouse_filter = Control.MOUSE_FILTER_STOP
	# tooltip — 시전자(영웅) 이름. 옆 라벨이 이미 효과 설명이라 desc 중복은 제거.
	# __global__ 같은 비-영웅 owner 는 부착 안 함.
	if owner_id != "" and TeamManager.has_hero(owner_id):
		var hero: Resource = TeamManager.get_hero(owner_id)
		SacredTheme.attach_tooltip(hbox, tr(hero.hero_name))

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
		# strength/weak/counter_pool 등 변경 시 intent 표시값 갱신
		_update_enemy_ui(idx)
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
	# 카드 데미지 표시는 hero strength/weak (자기) + 적 vulnerable (드래그 호버 시) 반영.
	if status_type in ["weak", "vulnerable", "strength"]:
		_refresh_hand_card_damage()
	# 스턴 — 영웅에게 부여 시 머리 위 별 즉발 (디버프 빔과 별개 — 임팩트 동기화 X)
	if status_type == "stun" and not target.begins_with("enemy_"):
		var hero_node: Node2D = _hero_char_nodes.get(target)
		if hero_node:
			_spawn_stun_stars(hero_node.global_position)

func _spawn_stun_stars(pos: Vector2) -> void:
	var fx: Node2D = _VFX_STUN_STARS.new()
	add_child(fx)
	fx.z_index = 1300
	fx.position = Vector2.ZERO
	fx.play(pos, pos)

func _refresh_hand_card_damage() -> void:
	for btn in _card_buttons:
		if is_instance_valid(btn) and btn.has_method("refresh"):
			btn.refresh()

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
	# 카드 드래그 중 우클릭 → 사용 취소 (핸드 드랍과 동일 처리)
	if _drag_card != null and event is InputEventMouseButton \
			and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_cleanup_drag()
		get_viewport().set_input_as_handled()
		return
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

	# 영웅별 탭 — 각 탭 = 그 영웅의 draw / discard / exhaust 3 컬럼
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 탭 라벨 폰트/색 — _add_deck_column 헤더 라벨 (AccentLabel) 과 통일
	var accent_font: Font = SacredTheme.theme.get_font("font", "AccentLabel") if SacredTheme.theme else null
	if accent_font:
		tabs.add_theme_font_override("font", accent_font)
	tabs.add_theme_font_size_override("font_size", 15)
	tabs.add_theme_color_override("font_selected_color", SacredPalette.BRASS_400)
	tabs.add_theme_color_override("font_unselected_color", SacredPalette.BRASS_700)
	tabs.add_theme_color_override("font_hovered_color", SacredPalette.BRASS_300)
	# 선택/미선택 탭 stylebox 통일 — 크기 일관성 + 배경색은 패널과 동일 (INK_900)
	# 선택 탭만 위쪽 BRASS_400 2px 라인 추가
	const _TAB_PAD_X := 16.0
	const _TAB_PAD_Y := 8.0
	var _tab_sel := StyleBoxFlat.new()
	_tab_sel.bg_color = SacredPalette.INK_900
	_tab_sel.border_color = SacredPalette.BRASS_400
	_tab_sel.set_border_width_all(0)
	_tab_sel.border_width_top = 2
	_tab_sel.content_margin_left = _TAB_PAD_X
	_tab_sel.content_margin_right = _TAB_PAD_X
	_tab_sel.content_margin_top = _TAB_PAD_Y
	_tab_sel.content_margin_bottom = _TAB_PAD_Y
	tabs.add_theme_stylebox_override("tab_selected", _tab_sel)
	var _tab_unsel := StyleBoxFlat.new()
	_tab_unsel.bg_color = Color.TRANSPARENT
	_tab_unsel.set_border_width_all(0)
	_tab_unsel.content_margin_left = _TAB_PAD_X
	_tab_unsel.content_margin_right = _TAB_PAD_X
	_tab_unsel.content_margin_top = _TAB_PAD_Y
	_tab_unsel.content_margin_bottom = _TAB_PAD_Y
	tabs.add_theme_stylebox_override("tab_unselected", _tab_unsel)
	var _tab_hov := _tab_unsel.duplicate()
	tabs.add_theme_stylebox_override("tab_hovered", _tab_hov)
	vbox.add_child(tabs)

	# 기본 활성 탭 — 현재 영웅 / 없으면 마지막 차례 영웅 / 둘 다 없으면 첫 영웅
	var hero_ids: Array = DeckManager._heroes.keys()
	var focus_hid: String = BattleManager.get_current_hero_id()
	if focus_hid == "":
		focus_hid = _last_hero_actor_id
	var default_tab: int = hero_ids.find(focus_hid)
	if default_tab < 0:
		default_tab = 0

	for hid in hero_ids:
		var hero_name: String = hid
		if TeamManager != null:
			var hero_res = TeamManager.get_hero(hid)
			if hero_res != null:
				hero_name = tr(hero_res.hero_name)
		var page := Control.new()
		page.name = hero_name
		tabs.add_child(page)

		var page_columns := HBoxContainer.new()
		page_columns.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page_columns.add_theme_constant_override("separation", 8)
		page.add_child(page_columns)

		var draw_h: Array = (DeckManager._heroes[hid]["draw"] as Array).duplicate()
		draw_h.shuffle()
		var discard_h: Array = (DeckManager._heroes[hid]["discard"] as Array).duplicate()
		var exhaust_h: Array = (DeckManager._heroes[hid]["exhaust"] as Array).duplicate()

		_add_deck_column(page_columns, tr("ui.battle.deck_viewer.draw")    + " (%d)" % draw_h.size(),    draw_h)
		_add_v_divider(page_columns)
		_add_deck_column(page_columns, tr("ui.battle.deck_viewer.discard") + " (%d)" % discard_h.size(), discard_h)
		_add_v_divider(page_columns)
		_add_deck_column(page_columns, tr("ui.battle.deck_viewer.exhaust") + " (%d)" % exhaust_h.size(), exhaust_h)
	tabs.current_tab = default_tab

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

	var card_w := 194.0
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
			# 현재 차례 영웅에게 1장 draw (개체 차례 시스템)
			var cur_hid: String = BattleManager.get_current_hero_id()
			if cur_hid != "":
				DeckManager.draw_cards_h(cur_hid, 1)
			else:
				DeckManager.draw_cards(1)  # fallback — 첫 영웅
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

	# 소환물 공유 그리드 (노란색) — SummonArea2 1곳만
	var ap := _summon_area_pos(_SHARED_TOKEN_GRID_AREA_IDX)
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
			EffectRes.EffectType.BUFF_SPEED:
				if effect.target == "ALLY":
					return "ally"
			EffectRes.EffectType.DEBUFF_SPEED:
				if effect.target == "SINGLE":
					return "enemy"
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
			if btn.has_method("set_target_enemy_index"):
				btn.set_target_enemy_index(-1)
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
			chev.z_index = 1550  # 카드 드래그 arrow chevron
			_ui_add(chev)  # CanvasLayer — 카메라 zoom 영향 없음
			_drag_chevrons.append(chev)

	_drag_arrow_head = Sprite2D.new()
	_drag_arrow_head.texture = ARROW_HEAD_TEX
	_drag_arrow_head.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_drag_arrow_head.scale = Vector2(0.5, 0.5)
	_drag_arrow_head.modulate = Color.WHITE
	_drag_arrow_head.z_index = 1551  # 화살표 머리 — chevron 위
	_ui_add(_drag_arrow_head)  # CanvasLayer — 카메라 zoom 영향 없음

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
