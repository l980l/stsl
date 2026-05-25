# scenes/ui/settings_overlay.gd
extends CanvasLayer

@onready var _lang_opt:     OptionButton = $Panel/LangOpt
@onready var _title_lbl:    Label        = $Panel/Title
@onready var _lang_lbl:     Label        = $Panel/LangLbl
@onready var _btn_close:    Button       = $Panel/BtnClose
@onready var _btn_defaults: Button       = $Panel/Footer/BtnDefaults
@onready var _btn_cancel:   Button       = $Panel/Footer/BtnCancel
@onready var _btn_apply:    Button       = $Panel/Footer/BtnApply

const _CURSOR_SIZES:    Dictionary = {"S": 32, "M": 48, "L": 64, "XL": 96}
const _DEFAULT_KEY   := "M"
const _TABS          := [["sound", "ui.settings.sound"], ["graphics", "ui.settings.graphics"], ["gameplay", "ui.settings.gameplay"], ["language", "ui.settings.language_tab"]]

# multiplier 값 → "x1.0" 형식 라벨 (GDScript 는 %g 미지원 → str() 사용)
static func _x_label(value: float) -> String:
	return "x" + str(value)

# values 배열을 {key: "xVAL"} dict 로 변환
static func _build_x_labels(keys: Array, values: Array) -> Dictionary:
	var out: Dictionary = {}
	for i in keys.size():
		out[keys[i]] = _x_label(values[i])
	return out
const _AUDIO_BUSES   := [["master", "ui.settings.vol_master"], ["music", "ui.settings.vol_music"], ["sfx", "ui.settings.vol_sfx"], ["ui", "ui.settings.vol_ui"]]
const _AUDIO_DEFAULTS := {"master": 1.0, "music": 0.8, "sfx": 1.0, "ui": 1.0}
const _PANEL_W       := 600.0
const _CONTENT_Y     := 112.0
const _CONTENT_H     := 448.0

var _popup_tween: Tween      = null
var _seg_buttons: Dictionary = {}
var _seg_base_styles: Dictionary = {}

var _initial_cursor_px:  int  = 32
var _initial_locale_idx: int  = 0
var _pending_cursor_px:  int  = 32
var _pending_locale_idx: int  = 0
var _applying:           bool = false

var _initial_volumes: Dictionary = {}
var _volume_sliders:  Dictionary = {}
var _volume_labels:   Dictionary = {}

# graphics/gameplay segment 상태 (key: 옵션 그룹 이름, value: { initial, pending, buttons:Dict[key→Button] })
var _seg_groups: Dictionary = {}

var _active_tab:  String     = "sound"
var _tab_btns:    Dictionary = {}
var _tab_panels:  Dictionary = {}

func _ready() -> void:
	# tscn의 LangLbl/LangOpt는 언어 탭 패널로 대체
	_lang_lbl.visible = false
	_lang_opt.visible = false

	var panel := $Panel as Panel
	var mono  := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font

	# 헤더
	_title_lbl.text = tr("ui.settings.title")
	_title_lbl.theme_type_variation = "TitleLabel"
	LabelUtils.fit_text(_title_lbl, 28, 16, _PANEL_W)

	_btn_close.theme_type_variation = "IconButton"
	_btn_close.text = "✕"
	_btn_close.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_btn_close.add_theme_font_size_override("font_size", 20)
	_btn_close.custom_minimum_size = Vector2(40, 40)
	_btn_close.pressed.connect(close)

	_btn_defaults.theme_type_variation = "VowButton"
	_btn_defaults.text = tr("ui.settings.btn_defaults").to_upper()
	_btn_defaults.add_theme_font_override("font", mono)
	_btn_defaults.add_theme_font_size_override("font_size", 11)
	_btn_cancel.theme_type_variation = "VowButton"
	_btn_cancel.text = tr("ui.settings.btn_cancel").to_upper()
	_btn_cancel.add_theme_font_override("font", mono)
	_btn_cancel.add_theme_font_size_override("font_size", 11)
	_btn_apply.text = tr("ui.settings.btn_apply").to_upper()
	_btn_apply.add_theme_font_override("font", mono)
	_btn_apply.add_theme_font_size_override("font_size", 11)
	SacredTheme.animate_button(_btn_apply)
	_btn_cancel.pressed.connect(_on_cancel)
	_btn_apply.pressed.connect(_on_apply)
	_btn_defaults.pressed.connect(_on_defaults)

	# 패널 스타일
	var ps := StyleBoxFlat.new()
	ps.bg_color = SacredPalette.INK_900
	ps.border_color = SacredPalette.BRASS_500
	ps.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", ps)
	SacredTheme.add_corner_brackets(panel)

	var fade_hl := TextureRect.new()
	fade_hl.texture = SacredTheme.make_top_fade_tex()
	fade_hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade_hl.stretch_mode = TextureRect.STRETCH_SCALE
	fade_hl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	fade_hl.offset_bottom = 80.0
	fade_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fade_hl)

	_add_h_line(panel, 67.5, 48.0, _PANEL_W - 48.0)
	_build_tab_bar(panel, mono)
	_add_h_line(panel, _CONTENT_Y - 0.5, 0.0, _PANEL_W)

	# 콘텐츠 패널 컨테이너 생성
	for tab_entry in _TABS:
		var key: String = tab_entry[0]
		var cp := Control.new()
		cp.offset_left   = 0.0
		cp.offset_top    = _CONTENT_Y
		cp.offset_right  = _PANEL_W
		cp.offset_bottom = _CONTENT_Y + _CONTENT_H
		cp.mouse_filter  = Control.MOUSE_FILTER_PASS
		panel.add_child(cp)
		_tab_panels[key] = cp

	_build_sound_panel()
	_build_graphics_panel()
	_build_gameplay_panel()
	_build_language_panel()

	_switch_tab("sound")

func _add_h_line(parent: Control, y: float, x1: float, x2: float) -> void:
	var line := TextureRect.new()
	line.texture = SacredTheme.make_center_bright_h_tex()
	line.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	line.stretch_mode = TextureRect.STRETCH_SCALE
	line.offset_left   = x1
	line.offset_top    = y
	line.offset_right  = x2
	line.offset_bottom = y + 1.0
	line.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _build_tab_bar(panel: Control, mono: Font) -> void:
	var box := HBoxContainer.new()
	box.offset_left   = 0.0
	box.offset_top    = 68.0
	box.offset_right  = _PANEL_W
	box.offset_bottom = _CONTENT_Y
	box.add_theme_constant_override("separation", 0)
	panel.add_child(box)

	for tab_entry in _TABS:
		var key:   String = tab_entry[0]
		var label: String = tab_entry[1]
		var btn := Button.new()
		btn.text = tr(label)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		btn.add_theme_font_override("font", mono)
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(_switch_tab.bind(key))
		box.add_child(btn)
		_tab_btns[key] = btn

func _switch_tab(key: String) -> void:
	_active_tab = key
	var P := SacredPalette

	for k in _tab_btns:
		var btn: Button = _tab_btns[k]
		var active: bool = k == key

		var s := StyleBoxFlat.new()
		s.bg_color           = Color.TRANSPARENT
		s.border_width_top   = 0
		s.border_width_left  = 0
		s.border_width_right = 0
		s.border_width_bottom = 1 if active else 0
		s.border_color = P.BRASS_400 if active else Color.TRANSPARENT
		s.set_content_margin(SIDE_TOP,    12)
		s.set_content_margin(SIDE_BOTTOM, 12)
		s.set_content_margin(SIDE_LEFT,   20)
		s.set_content_margin(SIDE_RIGHT,  20)

		btn.add_theme_stylebox_override("normal",  s)
		btn.add_theme_stylebox_override("hover",   s)
		btn.add_theme_stylebox_override("pressed", s)
		btn.add_theme_stylebox_override("focus",   s)
		btn.add_theme_color_override("font_color",         P.BRASS_300 if active else P.BONE_400)
		btn.add_theme_color_override("font_hover_color",   P.BONE_100)
		btn.add_theme_color_override("font_pressed_color", P.BRASS_300)

	for k in _tab_panels:
		(_tab_panels[k] as Control).visible = k == key

func open() -> void:
	_initial_cursor_px  = SacredTheme.load_cursor_size()
	_initial_locale_idx = LocaleManager.LOCALES.find(LocaleManager.current_locale)
	_pending_cursor_px  = _initial_cursor_px
	_pending_locale_idx = _initial_locale_idx
	_lang_opt.selected  = _initial_locale_idx
	_applying = false
	_refresh_seg()

	for bus_entry in _AUDIO_BUSES:
		var bkey: String = bus_entry[0]
		var vol := AudioManager.get_bus_volume(bkey)
		_initial_volumes[bkey] = vol
		if _volume_sliders.has(bkey):
			(_volume_sliders[bkey] as HSlider).value = vol

	# graphics/gameplay segment — 현재 GameSettings 값을 initial/pending 으로 동기화
	var current_keys := {
		"particle":         GameSettings.particle_key,
		"vfx_speed":        GameSettings.vfx_speed_key,
		"anim_speed":       GameSettings.anim_speed_key,
		"turn_interval":    GameSettings.turn_interval_key,
		"hero_zoom":        "on" if GameSettings.hero_zoom_enabled else "off",
		"cam_zoom_speed":   GameSettings.cam_zoom_speed_key,
		"kill_cam":         "on" if GameSettings.kill_cam_enabled else "off",
		"card_frame":       GameSettings.card_frame_key,
	}
	for gid in current_keys:
		if _seg_groups.has(gid):
			_seg_groups[gid]["initial"] = current_keys[gid]
			_seg_groups[gid]["pending"] = current_keys[gid]
			_refresh_seg_group(gid)

	if _popup_tween:
		_popup_tween.kill()
	var p := $Panel as Panel
	p.pivot_offset = p.size / 2.0
	p.scale = Vector2(0.9, 0.9)
	p.modulate.a = 0.0
	visible = true
	_popup_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(p, "scale", Vector2.ONE, 0.15)
	_popup_tween.parallel().tween_property(p, "modulate:a", 1.0, 0.15)

func close() -> void:
	if not _applying:
		_revert_pending()
	if _popup_tween:
		_popup_tween.kill()
	var p := $Panel as Panel
	p.pivot_offset = p.size / 2.0
	_popup_tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_popup_tween.tween_property(p, "scale", Vector2(0.9, 0.9), 0.12)
	_popup_tween.parallel().tween_property(p, "modulate:a", 0.0, 0.12)
	_popup_tween.tween_callback(func(): visible = false)

func _on_apply() -> void:
	_applying = true
	SacredTheme.save_cursor_size(_pending_cursor_px)
	GameSettings.save_settings()  # graphics/gameplay segment 저장 (set 은 클릭 시 즉시)
	# 적용된 pending 을 새 initial 로 갱신 — close 시 revert 안 되도록
	for gid in _seg_groups:
		_seg_groups[gid]["initial"] = _seg_groups[gid]["pending"]
	var locale_changed := _pending_locale_idx != _initial_locale_idx
	if locale_changed:
		# LocaleManager 가 locale_changed signal 발산 → 카드/적/상점 등이 자체 라벨 갱신
		LocaleManager.set_locale(LocaleManager.LOCALES[_pending_locale_idx])
	close()
	# 라이브 갱신을 처리한 씬 (BATTLE, SHOP) 은 reload 스킵 — 그 외 씬은 라벨이 tr() 결과를
	# 캐싱하고 있어 reload 없이는 새 locale 반영 안 됨. BATTLE reload 시 전투 상태 초기화 버그 회피.
	if locale_changed:
		var gm := get_node_or_null("/root/GameManager")
		var live_states := [gm.GameState.BATTLE, gm.GameState.SHOP] if gm != null else []
		if gm == null or not (gm.current_state in live_states):
			get_tree().reload_current_scene.call_deferred()

func _on_cancel() -> void:
	close()

func _on_defaults() -> void:
	_set_pending_cursor(_CURSOR_SIZES[_DEFAULT_KEY])
	_pending_locale_idx = _initial_locale_idx
	_lang_opt.selected  = _initial_locale_idx
	for bkey in _AUDIO_DEFAULTS:
		var dv: float = _AUDIO_DEFAULTS[bkey]
		AudioManager.set_bus_volume(bkey, dv)
		if _volume_sliders.has(bkey):
			(_volume_sliders[bkey] as HSlider).value = dv
	# graphics/gameplay segment — 각 그룹의 default 키로 복원
	var defaults := {
		"particle":         GameSettings.PARTICLE_DEFAULT,
		"vfx_speed":        GameSettings.VFX_SPEED_DEFAULT,
		"anim_speed":       GameSettings.ANIM_SPEED_DEFAULT,
		"turn_interval":    GameSettings.TURN_INTERVAL_DEFAULT,
		"hero_zoom":        "on" if GameSettings.HERO_ZOOM_DEFAULT else "off",
		"cam_zoom_speed":   GameSettings.CAM_ZOOM_SPEED_DEFAULT,
		"kill_cam":         "on" if GameSettings.KILL_CAM_DEFAULT else "off",
		"card_frame":       GameSettings.CARD_FRAME_DEFAULT,
	}
	for gid in defaults:
		if not _seg_groups.has(gid):
			continue
		var grp: Dictionary = _seg_groups[gid]
		var key: String = defaults[gid]
		grp["pending"] = key
		(grp["on_select"] as Callable).call(key)
		_refresh_seg_group(gid)

func _set_pending_cursor(px: int) -> void:
	_pending_cursor_px = px
	SacredTheme.apply_cursor_size(px)
	_refresh_seg()

func _revert_pending() -> void:
	SacredTheme.apply_cursor_size(_initial_cursor_px)
	for bkey in _initial_volumes:
		AudioManager.set_bus_volume(bkey, _initial_volumes[bkey])
	# graphics/gameplay segment — initial 키로 GameSettings 복원
	for gid in _seg_groups:
		var grp: Dictionary = _seg_groups[gid]
		var initial_key: String = grp["initial"]
		grp["pending"] = initial_key
		(grp["on_select"] as Callable).call(initial_key)

func _on_locale_selected(idx: int) -> void:
	_pending_locale_idx = idx

func _refresh_seg() -> void:
	var nearest := _DEFAULT_KEY
	var best    := INF
	for k in _CURSOR_SIZES:
		var d := absf(_pending_cursor_px - _CURSOR_SIZES[k])
		if d < best:
			best = d
			nearest = k
	for k in _seg_buttons:
		_apply_seg_style(_seg_buttons[k] as Button, k == nearest)

func _apply_seg_style(btn: Button, is_active: bool) -> void:
	var hl: Node = btn.get_node_or_null("_hl")
	if hl:
		hl.visible = is_active
	if is_active:
		var s := StyleBoxFlat.new()
		s.bg_color    = Color(SacredPalette.BRASS_700.r, SacredPalette.BRASS_700.g, SacredPalette.BRASS_700.b, 0.35)
		s.border_color = SacredPalette.BRASS_400
		s.set_border_width_all(1)
		btn.add_theme_stylebox_override("normal", s)
		btn.add_theme_stylebox_override("hover",  s)
		btn.add_theme_color_override("font_color", SacredPalette.BONE_100)
	else:
		var base: StyleBox = _seg_base_styles.get(btn) as StyleBox
		if base:
			btn.add_theme_stylebox_override("normal", base)
		else:
			btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_color_override("font_color")

# ─── 탭 패널 컨텐츠 ───

func _build_sound_panel() -> void:
	var p := _tab_panels["sound"] as Control
	for i in _AUDIO_BUSES.size():
		var bkey:    String = _AUDIO_BUSES[i][0]
		var display: String = _AUDIO_BUSES[i][1]
		var row_y := 24.0 + i * 44.0

		var lbl := Label.new()
		lbl.text = tr(display)
		lbl.theme_type_variation = "SubLabel"
		lbl.offset_left   = 32.0
		lbl.offset_top    = row_y
		lbl.offset_right  = 170.0
		lbl.offset_bottom = row_y + 36.0
		p.add_child(lbl)
		LabelUtils.fit_text(lbl, 16, 11)

		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step      = 0.01
		slider.value     = AudioManager.get_bus_volume(bkey)
		slider.offset_left   = 180.0
		slider.offset_top    = row_y + 8.0
		slider.offset_right  = 520.0
		slider.offset_bottom = row_y + 36.0
		_style_slider(slider)
		slider.value_changed.connect(_on_volume_changed.bind(bkey))
		p.add_child(slider)
		_volume_sliders[bkey] = slider

		var val_lbl := Label.new()
		val_lbl.text = "%d%%" % roundi(slider.value * 100.0)
		val_lbl.theme_type_variation = "SubLabel"
		val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_lbl.offset_left   = 528.0
		val_lbl.offset_top    = row_y
		val_lbl.offset_right  = 580.0
		val_lbl.offset_bottom = row_y + 36.0
		p.add_child(val_lbl)
		_volume_labels[bkey] = val_lbl

func _build_graphics_panel() -> void:
	var p := _tab_panels["graphics"] as Control
	var mono := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font

	# Row 1: 커서 크기 (기존 cursor segment)
	_build_cursor_seg_row(p, mono, 24.0)

	# Row 2: 파티클 갯수 (graphics) — 라벨도 "xVAL" 형식 (x0.25/x0.5/x1.0)
	_build_seg_row(p, mono, 80.0, tr("ui.settings.particle_quality"), "particle",
		GameSettings.PARTICLE_KEYS,
		_build_x_labels(GameSettings.PARTICLE_KEYS, GameSettings.PARTICLE_VALUES),
		GameSettings.particle_key,
		func(k: String) -> void: GameSettings.set_particle_quality(k))

	# Row 3: 카드 프레임 (classic / modern) — 전투/상점 포함 라이브 swap
	_build_seg_row(p, mono, 136.0, tr("ui.settings.card_frame"), "card_frame",
		GameSettings.CARD_FRAME_KEYS,
		{"classic": tr("ui.settings.card_frame.classic"), "modern": tr("ui.settings.card_frame.modern")},
		GameSettings.card_frame_key,
		func(k: String) -> void: GameSettings.set_card_frame(k))

func _build_gameplay_panel() -> void:
	var p := _tab_panels["gameplay"] as Control
	var mono := load("res://assets/fonts/SpaceMono-Regular.ttf") as Font

	# 각 segment 라벨은 multiplier 값 기반 ("x1.0" 형식)
	_build_seg_row(p, mono, 24.0, tr("ui.settings.vfx_speed"), "vfx_speed",
		GameSettings.VFX_SPEED_KEYS,
		_build_x_labels(GameSettings.VFX_SPEED_KEYS, GameSettings.VFX_SPEED_VALUES),
		GameSettings.vfx_speed_key,
		func(k: String) -> void: GameSettings.set_vfx_speed(k))

	_build_seg_row(p, mono, 80.0, tr("ui.settings.anim_speed"), "anim_speed",
		GameSettings.ANIM_SPEED_KEYS,
		_build_x_labels(GameSettings.ANIM_SPEED_KEYS, GameSettings.ANIM_SPEED_VALUES),
		GameSettings.anim_speed_key,
		func(k: String) -> void: GameSettings.set_anim_speed(k))

	_build_seg_row(p, mono, 136.0, tr("ui.settings.turn_interval"), "turn_interval",
		GameSettings.TURN_INTERVAL_KEYS,
		_build_x_labels(GameSettings.TURN_INTERVAL_KEYS, GameSettings.TURN_INTERVAL_VALUES),
		GameSettings.turn_interval_key,
		func(k: String) -> void: GameSettings.set_turn_interval(k))

	# 킬캠 (처치/사망 시 슬로우 + 카메라 줌인)
	_build_seg_row(p, mono, 192.0, tr("ui.settings.kill_cam"), "kill_cam",
		["off", "on"],
		{"off": tr("ui.settings.off"), "on": tr("ui.settings.on")},
		"on" if GameSettings.kill_cam_enabled else "off",
		func(k: String) -> void: GameSettings.set_kill_cam_enabled(k == "on"))

	# 영웅 차례 카메라 줌인 (개체 차례 시스템)
	_build_seg_row(p, mono, 248.0, tr("ui.settings.hero_zoom"), "hero_zoom",
		["off", "on"],
		{"off": tr("ui.settings.off"), "on": tr("ui.settings.on")},
		"on" if GameSettings.hero_zoom_enabled else "off",
		func(k: String) -> void: GameSettings.set_hero_zoom_enabled(k == "on"))

	# 카메라 줌 전환 속도
	_build_seg_row(p, mono, 304.0, tr("ui.settings.cam_zoom_speed"), "cam_zoom_speed",
		GameSettings.CAM_ZOOM_SPEED_KEYS,
		_build_x_labels(GameSettings.CAM_ZOOM_SPEED_KEYS, GameSettings.CAM_ZOOM_SPEED_VALUES),
		GameSettings.cam_zoom_speed_key,
		func(k: String) -> void: GameSettings.set_cam_zoom_speed(k))

# 일반 segment row 빌더 — 라벨 + N개 버튼. group_id 로 _seg_groups 등록.
func _build_seg_row(parent: Control, mono: Font, row_y: float, label_text: String,
		group_id: String, keys: Array, label_map: Dictionary, current_key: String,
		on_select: Callable) -> void:
	var lbl := Label.new()
	lbl.text = label_text
	lbl.theme_type_variation = "SubLabel"
	lbl.offset_left   = 32.0
	lbl.offset_top    = row_y
	lbl.offset_right  = 170.0
	lbl.offset_bottom = row_y + 36.0
	parent.add_child(lbl)
	LabelUtils.fit_text(lbl, 16, 11)

	var seg_box := HBoxContainer.new()
	seg_box.offset_left   = 180.0
	seg_box.offset_top    = row_y
	seg_box.offset_right  = 520.0
	seg_box.offset_bottom = row_y + 30.0
	seg_box.add_theme_constant_override("separation", 0)
	parent.add_child(seg_box)

	var buttons: Dictionary = {}
	for i in keys.size():
		var key: String = keys[i]
		var btn := Button.new()
		btn.text = label_map.get(key, key)
		btn.custom_minimum_size = Vector2(0, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", mono)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_on_seg_pressed.bind(group_id, key, on_select))

		var base_style := StyleBoxFlat.new()
		base_style.bg_color     = Color(SacredPalette.INK_900.r, SacredPalette.INK_900.g, SacredPalette.INK_900.b, 0.8)
		base_style.border_color = SacredPalette.BRASS_700
		base_style.border_width_top    = 1
		base_style.border_width_bottom = 1
		base_style.border_width_left   = 1 if i == 0 else 0
		base_style.border_width_right  = 1
		btn.add_theme_stylebox_override("normal", base_style)
		btn.add_theme_stylebox_override("focus",  base_style)
		_seg_base_styles[btn] = base_style

		seg_box.add_child(btn)
		buttons[key] = btn

		var hl := TextureRect.new()
		hl.name = "_hl"
		hl.texture = SacredTheme.make_top_fade_tex(SacredPalette.BRASS_300, 0.30)
		hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hl.stretch_mode = TextureRect.STRETCH_SCALE
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hl.visible = false
		btn.add_child(hl)
		hl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_seg_groups[group_id] = {"initial": current_key, "pending": current_key, "buttons": buttons, "on_select": on_select}
	_refresh_seg_group(group_id)

func _on_seg_pressed(group_id: String, key: String, on_select: Callable) -> void:
	if not _seg_groups.has(group_id):
		return
	_seg_groups[group_id]["pending"] = key
	on_select.call(key)  # 즉시 적용 (cancel 시 revert)
	_refresh_seg_group(group_id)

func _refresh_seg_group(group_id: String) -> void:
	var grp: Dictionary = _seg_groups[group_id]
	var pending: String = grp["pending"]
	var buttons: Dictionary = grp["buttons"]
	for k in buttons:
		_apply_seg_style(buttons[k] as Button, k == pending)

# 기존 커서 크기 segment (cursor 만 별도 — _CURSOR_SIZES 의 px 값 직접 사용)
func _build_cursor_seg_row(parent: Control, mono: Font, row_y: float) -> void:
	var lbl := Label.new()
	lbl.text = tr("ui.settings.cursor_size")
	lbl.theme_type_variation = "SubLabel"
	lbl.offset_left   = 32.0
	lbl.offset_top    = row_y
	lbl.offset_right  = 170.0
	lbl.offset_bottom = row_y + 36.0
	parent.add_child(lbl)
	LabelUtils.fit_text(lbl, 16, 11)

	var seg_box := HBoxContainer.new()
	seg_box.offset_left   = 180.0
	seg_box.offset_top    = row_y
	seg_box.offset_right  = 520.0
	seg_box.offset_bottom = row_y + 30.0
	seg_box.add_theme_constant_override("separation", 0)
	parent.add_child(seg_box)

	var keys: Array = _CURSOR_SIZES.keys()
	for i in keys.size():
		var key: String = keys[i]
		var btn := Button.new()
		btn.text = key
		btn.custom_minimum_size = Vector2(0, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.focus_mode = Control.FOCUS_NONE
		btn.add_theme_font_override("font", mono)
		btn.add_theme_font_size_override("font_size", 11)
		btn.pressed.connect(_set_pending_cursor.bind(_CURSOR_SIZES[key]))

		var base_style := StyleBoxFlat.new()
		base_style.bg_color     = Color(SacredPalette.INK_900.r, SacredPalette.INK_900.g, SacredPalette.INK_900.b, 0.8)
		base_style.border_color = SacredPalette.BRASS_700
		base_style.border_width_top    = 1
		base_style.border_width_bottom = 1
		base_style.border_width_left   = 1 if i == 0 else 0
		base_style.border_width_right  = 1
		btn.add_theme_stylebox_override("normal", base_style)
		btn.add_theme_stylebox_override("focus",  base_style)
		_seg_base_styles[btn] = base_style

		seg_box.add_child(btn)
		_seg_buttons[key] = btn

		var hl := TextureRect.new()
		hl.name = "_hl"
		hl.texture = SacredTheme.make_top_fade_tex(SacredPalette.BRASS_300, 0.30)
		hl.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		hl.stretch_mode = TextureRect.STRETCH_SCALE
		hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hl.visible = false
		btn.add_child(hl)
		hl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_refresh_seg()

func _build_language_panel() -> void:
	var p := _tab_panels["language"] as Control

	var lbl := Label.new()
	lbl.text = tr("ui.settings.language")
	lbl.theme_type_variation = "SubLabel"
	lbl.offset_left   = 32.0
	lbl.offset_top    = 24.0
	lbl.offset_right  = 170.0
	lbl.offset_bottom = 60.0
	p.add_child(lbl)
	LabelUtils.fit_text(lbl, 16, 11)

	var opt := OptionButton.new()
	opt.offset_left   = 180.0
	opt.offset_top    = 22.0
	opt.offset_right  = 520.0
	opt.offset_bottom = 62.0
	opt.add_theme_font_size_override("font_size", 18)
	p.add_child(opt)

	# @onready 참조를 새로 생성한 버튼으로 교체
	_lang_opt = opt
	for code in LocaleManager.LOCALES:
		_lang_opt.add_item(LocaleManager.get_display_name(code))
	_lang_opt.item_selected.connect(_on_locale_selected)
	_style_option_button()

func _style_option_button() -> void:
	var P := SacredPalette

	var normal := StyleBoxFlat.new()
	normal.bg_color = P.INK_900
	normal.border_color = P.BRASS_700
	normal.set_border_width_all(1)
	normal.set_content_margin(SIDE_LEFT,   10)
	normal.set_content_margin(SIDE_RIGHT,  10)
	normal.set_content_margin(SIDE_TOP,     6)
	normal.set_content_margin(SIDE_BOTTOM,  6)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = P.BRASS_500
	hover.bg_color = Color(P.INK_900.r, P.INK_900.g, P.INK_900.b, 0.9)

	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = P.BRASS_500

	_lang_opt.add_theme_stylebox_override("normal",  normal)
	_lang_opt.add_theme_stylebox_override("hover",   hover)
	_lang_opt.add_theme_stylebox_override("pressed", hover)
	_lang_opt.add_theme_stylebox_override("focus",   focus)
	_lang_opt.add_theme_color_override("font_color",         P.BONE_100)
	_lang_opt.add_theme_color_override("font_hover_color",   P.BRASS_300)
	_lang_opt.add_theme_color_override("font_pressed_color", P.BRASS_300)

	var popup := _lang_opt.get_popup()
	var pp := StyleBoxFlat.new()
	pp.bg_color = P.INK_1000
	pp.border_color = P.BRASS_700
	pp.set_border_width_all(1)
	popup.add_theme_stylebox_override("panel", pp)

	var ph := StyleBoxFlat.new()
	ph.bg_color = Color(P.BRASS_700.r, P.BRASS_700.g, P.BRASS_700.b, 0.35)
	ph.border_color = Color.TRANSPARENT
	ph.set_border_width_all(0)
	popup.add_theme_stylebox_override("hover", ph)

	popup.add_theme_color_override("font_color",       P.BONE_100)
	popup.add_theme_color_override("font_hover_color", P.BRASS_300)
	popup.add_theme_font_size_override("font_size", 14)

func _style_slider(slider: HSlider) -> void:
	var P := SacredPalette

	var track := StyleBoxFlat.new()
	track.bg_color = Color(P.INK_900.r, P.INK_900.g, P.INK_900.b, 0.8)
	track.border_color = P.BRASS_700
	track.set_border_width_all(1)
	track.set_corner_radius_all(2)
	slider.add_theme_stylebox_override("slider", track)

	var fill := StyleBoxFlat.new()
	fill.bg_color = P.BRASS_600
	fill.set_corner_radius_all(2)
	slider.add_theme_stylebox_override("grabber_area", fill)

	slider.add_theme_constant_override("grabber_offset", 0)
	slider.add_theme_icon_override("grabber",           _make_grabber_icon())
	slider.add_theme_icon_override("grabber_highlight", _make_grabber_icon(true))

func _make_grabber_icon(highlight: bool = false) -> ImageTexture:
	var P := SacredPalette
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var fill_col := P.BRASS_300 if highlight else P.BONE_100
	for x in 16:
		for y in 16:
			var dx := x - 7.5
			var dy := y - 7.5
			var r2 := dx * dx + dy * dy
			if r2 <= 49.0:
				img.set_pixel(x, y, P.BRASS_500 if r2 >= 36.0 else fill_col)
	return ImageTexture.create_from_image(img)

func _on_volume_changed(value: float, bus_key: String) -> void:
	AudioManager.set_bus_volume(bus_key, value)
	if _volume_labels.has(bus_key):
		(_volume_labels[bus_key] as Label).text = "%d%%" % roundi(value * 100.0)

func _unhandled_input(ev: InputEvent) -> void:
	if visible and ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
