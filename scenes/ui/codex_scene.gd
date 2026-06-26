# scenes/ui/codex_scene.gd
# 도감 — 카드/렐릭 탭. 전체를 자동 집계(CardCatalog/RelicCatalog)해 그룹·정렬·필터·검색으로 열람.
# 수집/잠금: ProgressManager.is_card/relic_discovered. 미발견은 흑백/카드백으로 표시.
# 카드 렌더는 실제 CardScene 재사용(classic/modern). 렐릭은 아이콘+이름+설명 셀.
# 오버레이(CanvasLayer) — 메인메뉴/맵/배틀/상점 위에 열리고 닫으면 원래 씬으로 복귀.
# 필터/정렬/그룹/검색 상태는 static 으로 세션 내 유지 (탭별 독립, 다시 열어도 보존).
extends CanvasLayer

const CARD_SCENE_CLASSIC := preload("res://scenes/card/card_scene.tscn")
const CARD_SCENE_MODERN  := preload("res://scenes/card/card_scene_v2.tscn")
const CardRes      := preload("res://resources/card_resource.gd")
const RelicRes     := preload("res://resources/relic_resource.gd")
# CardCatalog/RelicCatalog/MonsterCatalog/HeroRegistry/MuseumMatFrame 는 class_name 전역 클래스 — 직접 사용 (const preload 시 shadow 경고)

const RARITY_KEYS := ["common", "uncommon", "rare", "legendary", "divine"]
const TYPE_KEYS   := ["attack", "skill", "power"]
const RELIC_CELL_W := 212.0
const RELIC_ICON   := 84.0
const ENEMY_ART_DIR := "res://assets/art/enemies/"
# 배틀씬 적 스프라이트 영역 비율(= 외부 scale 1.44:2.4 = 0.6) + cover-crop + 좌우 반전 + museum mat 프레임 재현.
# 내부 art = 프레임 - MAT_INSET*2(=8). 내부 120×200(0.6) → 프레임 128×208.
const MON_FRAME_W := 128.0
const MON_FRAME_H := 208.0
const MONSTER_CELL_W := 156.0
const MON_THUMB_MAX := 320  # 몬스터 일러스트 썸네일 최장변 (원본 거대 → VRAM/디코드 절감)
const FONT_SCALE := 1.25  # 도감 라벨 글자 고정 배율 (가독성)

# 모던 카드(card_scene_v2)와 동일한 희귀도 보석 색 — 도감 필터 보석 칩에 사용
const _GEM_COLORS := {
	"common":    {"hi": Color("#ffffff"), "mid": Color("#e5e0d2"), "lo": Color("#8b8676")},
	"uncommon":  {"hi": Color("#d8ecff"), "mid": Color("#4d8edb"), "lo": Color("#112a52")},
	"rare":      {"hi": Color("#e8d4ff"), "mid": Color("#a458d6"), "lo": Color("#3a124f")},
	"legendary": {"hi": Color("#fce6a8"), "mid": Color("#d4a948"), "lo": Color("#6b5418")},
	"divine":    {"hi": Color("#ffd2d4"), "mid": Color("#d94a50"), "lo": Color("#4a0d10")},
}
const TARGET_CARD_W := 132.0  # 도감 카드 표시 폭 (classic/modern 공통, 비율 0.7 동일)
const CELL_W := 150.0

# 발견(관측, 미보유) 카드 흑백 — 카드 각 자식에 use_parent_material 로 적용
const _GRAY_SHADER := """
shader_type canvas_item;
void fragment() {
	float g = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	COLOR.rgb = vec3(g) * 0.7;
}
"""

# 영웅 강조색 (참고 디자인)
const HERO_ACCENT := {
	"napoleon":     Color("e8c878"),
	"cleopatra":    Color("f0d896"),
	"yi_sun_sin":   Color("6ba89c"),
	"joan_of_arc":  Color("ebe3d2"),
	"genghis_khan": Color("d94a50"),
	"musashi":      Color("d8cfb9"),
}

var _all: Array = []

static var _tab: String = "card"   # "card" | "relic" — 세션 내 유지

# 카드 탭 필터 상태 — static 으로 세션 내 유지 (도감 다시 열어도 보존)
static var _f_rarity: Array = []   # int
static var _f_type: Array = []     # int
static var _f_cost: Array = []     # int
static var _f_hero: Array = []     # String
static var _f_coll: Array = []     # "owned"/"seen"
static var _search: String = ""
static var _sort: String = "cost"
static var _dir: int = 1
static var _group: String = "hero"

# 렐릭 탭 필터 상태 (탭별 독립)
static var _rf_owner: Array = []   # String ("" 공용 / hero id)
static var _rf_cursed: Array = []  # "cursed"
static var _rf_coll: Array = []    # "owned"/"seen"
static var _r_search: String = ""
static var _r_sort: String = "name"
static var _r_dir: int = 1
static var _r_group: String = "owner"

# 몬스터 탭 필터 상태 (탭별 독립)
static var _mf_myth: Array = []    # String (mythology)
static var _m_search: String = ""
static var _m_sort: String = "name"
static var _m_dir: int = 1
static var _m_group: String = "myth"

const SETTINGS_OVERLAY := preload("res://scenes/ui/settings_overlay.tscn")

var _gray_mat: ShaderMaterial = null
var _all_chips: Array = []
var _dir_btn: Button = null
var _dd_closers: Array = []  # 열린 드롭다운들을 서로 닫기 위한 close 콜백 모음
var _ui_root: Control = null  # 본문 UI 루트 — 언어 변경 시 이 노드만 재생성 (설정 자식은 보존)
var _cell_cache: Dictionary = {}  # card_key → 카드 셀. 정렬/필터 시 재인스턴스화 없이 reparent 만
var _scroll: ScrollContainer = null  # 가상 스크롤 가시성 판정용
var _realize_pending: bool = false   # 점진 realize 중복 예약 방지
# 몬스터 일러스트 썸네일 캐시 (path → 다운스케일 ImageTexture). static — 세션 내 재사용.
static var _mon_thumb: Dictionary = {}
# 비동기 썸네일 로딩 (WorkerThreadPool) — 스크롤 끊김 방지
var _thumb_mutex := Mutex.new()
var _thumb_ready: Dictionary = {}     # path → Image (워커 완료, 메인에서 텍스처화 대기). mutex 보호.
var _thumb_inflight: Dictionary = {}  # path → task_id (진행 중)
var _thumb_waiters: Dictionary = {}   # path → Array[TextureRect] (텍스처 대기 중인 대상)
var _locale_dirty: bool = false  # 도감 열린 동안 언어 변경됨 → 닫을 때 밑 씬 reload
var _grid_host: VBoxContainer
var _result_lbl: Label
var _tally_num: Label
var _tally_bar: ColorRect
var _search_edit: LineEdit

func _ready() -> void:
	layer = 50  # 설정 버튼(9)/설정 오버레이(10) 위
	var sh := Shader.new()
	sh.code = _GRAY_SHADER
	_gray_mat = ShaderMaterial.new()
	_gray_mat.shader = sh
	_load_all()
	_build_ui()
	_render()
	LocaleManager.locale_changed.connect(_rebuild)

func _load_all() -> void:
	match _tab:
		"relic":   _all = RelicCatalog.get_all_relics()
		"monster": _all = MonsterCatalog.get_all_monsters()
		_:         _all = CardCatalog.get_all_cards()

# 본문 UI 전체 재생성 (탭 전환/언어 변경 공용) — 설정 오버레이 자식은 보존
func _rebuild_view() -> void:
	if is_instance_valid(_ui_root):
		_ui_root.queue_free()  # 트리 내 셀은 함께 free
	_free_orphan_cells()       # 트리 밖 캐시 셀 정리
	_cell_cache.clear()
	_all_chips.clear()
	_dd_closers.clear()
	_build_ui()
	_render()

# 언어 변경 시 본문 라벨 라이브 갱신. 밑 씬은 도감 닫을 때 reload (그 전엔 안 보임).
func _rebuild(_locale: String = "") -> void:
	_locale_dirty = true
	if not is_instance_valid(_ui_root):
		return
	_rebuild_view()

func _switch_tab(tab: String) -> void:
	if tab == _tab:
		return
	_tab = tab
	_load_all()
	_rebuild_view()

# ── 탭별 상태 접근 (현재 탭에 맞는 static var 반환/설정) ──
func _cur_sort() -> String:
	match _tab:
		"relic": return _r_sort
		"monster": return _m_sort
		_: return _sort
func _cur_dir() -> int:
	match _tab:
		"relic": return _r_dir
		"monster": return _m_dir
		_: return _dir
func _cur_group() -> String:
	match _tab:
		"relic": return _r_group
		"monster": return _m_group
		_: return _group
func _cur_search() -> String:
	match _tab:
		"relic": return _r_search
		"monster": return _m_search
		_: return _search

func _set_sort(k: String) -> void:
	match _tab:
		"relic": _r_sort = k
		"monster": _m_sort = k
		_: _sort = k

func _flip_dir() -> void:
	match _tab:
		"relic": _r_dir *= -1
		"monster": _m_dir *= -1
		_: _dir *= -1

func _set_group(k: String) -> void:
	match _tab:
		"relic": _r_group = k
		"monster": _m_group = k
		_: _group = k

func _set_search(t: String) -> void:
	match _tab:
		"relic": _r_search = t
		"monster": _m_search = t
		_: _search = t

# ── 아이템(카드/렐릭/몬스터) 공통 접근 ──
func _item_key(item) -> String:
	match _tab:
		"relic": return RelicCatalog.relic_key(item)
		"monster": return MonsterCatalog.monster_key(item)
		_: return CardCatalog.card_key(item)

func _item_owner(item) -> String:
	match _tab:
		"relic": return item.owner_hero_id
		"monster": return item.mythology
		_: return item.owner_id

func _item_name(item) -> String:
	match _tab:
		"relic": return tr(item.relic_name)
		"monster": return tr(item.enemy_name)
		_: return tr(item.card_name)

func _group_order() -> Array:
	match _tab:
		"relic": return RelicCatalog.OWNER_ORDER
		"monster": return MonsterCatalog.MYTH_ORDER
		_: return CardCatalog.HERO_ORDER

# 도감 글자 크기 — 고정 배율(가독성). 모든 라벨 폰트가 이 배율을 거침.
func _fs(base: int) -> int:
	return maxi(1, int(round(base * FONT_SCALE)))

# 발견(미보유) 카드 흑백 처리 — 루트에 머티리얼, 전 자식 use_parent_material
func _apply_grayscale(root: CanvasItem) -> void:
	root.material = _gray_mat
	_set_use_parent_mat(root)

func _set_use_parent_mat(node: Node) -> void:
	for c in node.get_children():
		if c is CanvasItem:
			c.use_parent_material = true
			_set_use_parent_mat(c)

# card_frame 설정 분기 — 게임 내 카드 렌더와 동일 (classic/modern)
func _new_card() -> Control:
	return CARD_SCENE_MODERN.instantiate() if GameSettings.card_frame_key == "modern" else CARD_SCENE_CLASSIC.instantiate()

# 모던 카드 보석 텍스처 생성 (card_scene_v2._make_circle_texture 미러, ring = lo 색)
func _make_gem_tex(rarity_key: String) -> ImageTexture:
	var col: Dictionary = _GEM_COLORS.get(rarity_key, _GEM_COLORS["common"])
	var hi: Color = col["hi"]
	var mid: Color = col["mid"]
	var lo: Color = col["lo"]
	var ring: Color = lo
	var soft_hi := mid.lerp(hi, 0.65)
	var size := 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var s := float(size)
	var center := Vector2(s * 0.5, s * 0.5)
	var outer_r := s * 0.5
	var hi_pos := Vector2(s * 0.35, s * 0.30)
	var ring_w := s * 0.08
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

# ─────────────────────────── UI ───────────────────────────
func _build_ui() -> void:
	var P := SacredPalette

	# 본문 UI 루트 — 언어 변경 시 이 노드만 재생성 (설정 오버레이 자식과 분리)
	_ui_root = Control.new()
	_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_ui_root)
	move_child(_ui_root, 0)  # 설정 오버레이 자식보다 아래에 그려지도록

	var bg := ColorRect.new()
	bg.color = P.INK_1000
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP  # 하단 씬 입력 차단
	_ui_root.add_child(bg)

	# 격자 무늬 — 맵/메인메뉴와 동일한 crosshatch 오버레이
	var crosshatch := SacredTheme.make_crosshatch_overlay()
	crosshatch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui_root.add_child(crosshatch)

	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	_ui_root.add_child(root)

	root.add_child(_build_header())
	_add_h_line(root)
	root.add_child(_build_tab_bar())
	_add_h_line(root)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 0)
	root.add_child(body)

	body.add_child(_build_rail())

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 0)
	body.add_child(main)

	main.add_child(_build_toolbar())

	_result_lbl = Label.new()
	_result_lbl.theme_type_variation = "EyebrowLabel"
	_result_lbl.add_theme_color_override("font_color", P.BONE_400)
	_result_lbl.add_theme_font_size_override("font_size", _fs(11))
	var rmc := MarginContainer.new()
	rmc.add_theme_constant_override("margin_left", 40)
	rmc.add_theme_constant_override("margin_top", 10)
	rmc.add_child(_result_lbl)
	main.add_child(rmc)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_child(scroll)
	_scroll = scroll
	# 스크롤: 사용자 스크롤(value_changed)은 레이아웃 정착 후이므로 즉시 평가.
	# 리사이즈는 정착 대기 후 평가(레이아웃 중 셀이 (0,0)으로 잡혀 전부 realize 되는 것 방지).
	scroll.get_v_scroll_bar().value_changed.connect(func(_v: float) -> void: _update_visible_cells())
	scroll.resized.connect(_update_visible_deferred)

	_grid_host = VBoxContainer.new()
	_grid_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid_host.add_theme_constant_override("separation", 30)
	var gmc := MarginContainer.new()
	gmc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gmc.add_theme_constant_override("margin_left", 40)
	gmc.add_theme_constant_override("margin_right", 40)
	gmc.add_theme_constant_override("margin_top", 18)
	gmc.add_theme_constant_override("margin_bottom", 60)
	gmc.add_child(_grid_host)
	scroll.add_child(gmc)

	# 설정 버튼 — 다른 씬과 동일한 우상단 코너 위치 (본문 위에 그림)
	_ui_root.add_child(_make_settings_button())

# 카드/렐릭 탭 바 (확장 가능 — 향후 시너지/몬스터 추가)
func _build_tab_bar() -> Control:
	var P := SacredPalette
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_BEGIN  # 좌측 정렬
	row.add_theme_constant_override("separation", 8)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 40)
	mc.add_theme_constant_override("margin_top", 10)
	mc.add_theme_constant_override("margin_bottom", 10)
	mc.add_child(row)
	for entry in [["card", "ui.codex.tab.card"], ["relic", "ui.codex.tab.relic"], ["monster", "ui.codex.tab.monster"]]:
		var key: String = entry[0]
		var active := (key == _tab)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.text = tr(entry[1])
		b.custom_minimum_size = Vector2(132, 36)
		b.add_theme_font_size_override("font_size", _fs(14))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(P.BRASS_500.r, P.BRASS_500.g, P.BRASS_500.b, 0.18) if active else Color(0.03, 0.03, 0.04, 0.4)
		sb.border_color = P.BRASS_400 if active else P.BRASS_700
		sb.set_border_width_all(1)
		sb.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", P.BONE_100 if active else P.BONE_400)
		b.add_theme_color_override("font_hover_color", P.BONE_100)
		b.pressed.connect(func() -> void: _switch_tab(key))
		row.add_child(b)
	return mc

func _build_header() -> Control:
	var P := SacredPalette
	var hb := HBoxContainer.new()
	hb.custom_minimum_size = Vector2(0, 96)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 40)
	mc.add_theme_constant_override("margin_right", 40)
	mc.add_theme_constant_override("margin_top", 24)
	mc.add_theme_constant_override("margin_bottom", 16)
	mc.add_child(hb)

	# 뒤로 (좌측) — title 을 화면 중앙에 두기 위해 좌/우 래퍼를 동일 비율로 확장
	var left_wrap := HBoxContainer.new()
	left_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_wrap.alignment = BoxContainer.ALIGNMENT_BEGIN
	var back := Button.new()
	back.theme_type_variation = "VowButton"
	back.text = "‹  " + tr("ui.codex.back")
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(_on_back)
	SacredTheme.animate_button(back)
	left_wrap.add_child(back)
	hb.add_child(left_wrap)

	# 타이틀 (가운데)
	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var ico_row := HBoxContainer.new()
	ico_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ico_row.add_theme_constant_override("separation", 10)
	var ico := TextureRect.new()
	ico.texture = load("res://assets/art/ui/icon_codex.svg") as Texture2D
	ico.custom_minimum_size = Vector2(28, 28)
	ico.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ico_row.add_child(ico)
	var title := Label.new()
	title.theme_type_variation = "TitleLabel"
	title.add_theme_font_size_override("font_size", _fs(36))
	title.add_theme_color_override("font_color", P.BONE_100)
	title.text = tr("ui.codex.title")
	ico_row.add_child(title)
	title_box.add_child(ico_row)
	hb.add_child(title_box)

	# tally + 설정 (우측) — left_wrap 과 동일 비율 확장으로 title 중앙 정렬 보장
	var right_wrap := HBoxContainer.new()
	right_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_wrap.alignment = BoxContainer.ALIGNMENT_END
	right_wrap.add_theme_constant_override("separation", 16)
	var tally := VBoxContainer.new()
	tally.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tally.alignment = BoxContainer.ALIGNMENT_CENTER
	_tally_num = Label.new()
	_tally_num.theme_type_variation = "TitleLabel"
	_tally_num.add_theme_font_size_override("font_size", _fs(24))
	_tally_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tally.add_child(_tally_num)
	var tlbl := Label.new()
	tlbl.theme_type_variation = "EyebrowLabel"
	tlbl.add_theme_color_override("font_color", P.BRASS_400)
	tlbl.add_theme_font_size_override("font_size", _fs(9))
	tlbl.text = tr("ui.codex.tally")
	tlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tally.add_child(tlbl)
	var bar_bg := ColorRect.new()
	bar_bg.color = P.INK_600
	bar_bg.custom_minimum_size = Vector2(168, 3)
	_tally_bar = ColorRect.new()
	_tally_bar.color = P.BRASS_400
	_tally_bar.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	_tally_bar.anchor_right = 0.0  # 갱신 시 설정
	bar_bg.add_child(_tally_bar)
	tally.add_child(bar_bg)
	right_wrap.add_child(tally)

	# 우상단 코너 설정 버튼과 겹치지 않도록 tally 를 왼쪽으로 미는 스페이서
	var corner_pad := Control.new()
	corner_pad.custom_minimum_size = Vector2(32, 0)
	right_wrap.add_child(corner_pad)

	hb.add_child(right_wrap)
	return mc

# 설정 버튼 (아이콘) — 표준 settings_button.tscn 과 동일한 우상단 코너 위치
func _make_settings_button() -> Button:
	var b := Button.new()
	b.theme_type_variation = "IconButton"
	b.focus_mode = Control.FOCUS_NONE
	b.expand_icon = true
	b.anchor_left = 1.0
	b.anchor_top = 0.0
	b.anchor_right = 1.0
	b.anchor_bottom = 0.0
	b.offset_left = -50.0
	b.offset_top = 10.0
	b.offset_right = -10.0
	b.offset_bottom = 50.0
	b.icon = load("res://assets/art/ui/icon_settings.svg") as Texture2D
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	b.modulate = SacredPalette.BRASS_300
	b.tooltip_text = tr("ui.settings.title")
	b.pressed.connect(_on_settings)
	SacredTheme.animate_button(b)
	return b

# 설정 오버레이 — 도감 자식으로 띄우고 layer 를 도감(50) 위로 올려 가림 방지
func _on_settings() -> void:
	var overlay := get_node_or_null("SettingsOverlay")
	if overlay == null:
		overlay = SETTINGS_OVERLAY.instantiate()
		overlay.name = "SettingsOverlay"
		overlay.layer = 60  # 도감(50) 위
		add_child(overlay)
	# 언어 변경 시 밑 씬 reload 로 도감이 파괴되지 않도록 — 도감은 자체 재번역(_rebuild),
	# 밑 씬 reload 는 도감 닫을 때(_on_back) 직접 처리
	overlay.skip_scene_reload = true
	overlay.open()

func _build_rail() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(256, 0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var rail := VBoxContainer.new()
	rail.custom_minimum_size = Vector2(256, 0)
	rail.add_theme_constant_override("separation", 22)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 24)
	mc.add_theme_constant_override("margin_right", 20)
	mc.add_theme_constant_override("margin_top", 22)
	mc.add_theme_constant_override("margin_bottom", 40)
	mc.add_child(rail)
	scroll.add_child(mc)

	# reset
	var reset := Button.new()
	reset.theme_type_variation = "VowButton"
	reset.text = "✕  " + tr("ui.codex.reset")
	reset.add_theme_font_size_override("font_size", _fs(10))
	reset.pressed.connect(_on_reset)
	rail.add_child(reset)

	match _tab:
		"relic":   _build_relic_facets(rail)
		"monster": _build_monster_facets(rail)
		_:         _build_card_facets(rail)
	return scroll

func _build_monster_facets(rail: VBoxContainer) -> void:
	# mythology — 신화별
	rail.add_child(_facet_head(tr("ui.codex.facet.myth")))
	var myth_box := VBoxContainer.new()
	myth_box.add_theme_constant_override("separation", 4)
	for m in MonsterCatalog.MYTH_ORDER:
		myth_box.add_child(_make_chip(tr("ui.codex.myth.%s" % m), _mf_myth, m, SacredPalette.BRASS_400, true))
	rail.add_child(myth_box)

func _build_card_facets(rail: VBoxContainer) -> void:
	# rarity
	rail.add_child(_facet_head(tr("ui.codex.facet.rarity")))
	var rarity_box := _chip_flow()
	for i in RARITY_KEYS.size():
		var gem := _make_gem_tex(RARITY_KEYS[i])
		var accent: Color = _GEM_COLORS[RARITY_KEYS[i]]["mid"]
		rarity_box.add_child(_make_chip(tr("ui.reward.rarity.%s" % RARITY_KEYS[i]), _f_rarity, i, accent, false, gem))
	rail.add_child(rarity_box)

	# type
	rail.add_child(_facet_head(tr("ui.codex.facet.type")))
	var type_box := _chip_flow()
	for i in TYPE_KEYS.size():
		var ticon := load("res://assets/art/cards/cardtypes/card_type_%s.png" % TYPE_KEYS[i]) as Texture2D
		type_box.add_child(_make_chip(tr("card_type.%s.name" % TYPE_KEYS[i]), _f_type, i, SacredPalette.BRASS_500, false, ticon))
	rail.add_child(type_box)

	# cost
	rail.add_child(_facet_head(tr("ui.codex.facet.cost")))
	var cost_box := _chip_flow()
	var costs: Array = []
	for c in _all:
		if c.cost not in costs:
			costs.append(c.cost)
	costs.sort()
	for cv in costs:
		var chip := _make_chip(str(cv), _f_cost, cv)
		chip.custom_minimum_size = Vector2(38, 0)  # 비용 칩 동일 크기
		chip.alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_box.add_child(chip)
	rail.add_child(cost_box)

	# hero
	rail.add_child(_facet_head(tr("ui.codex.facet.hero")))
	var hero_box := VBoxContainer.new()
	hero_box.add_theme_constant_override("separation", 4)
	for hid in CardCatalog.HERO_ORDER:
		var disp: Dictionary = HeroRegistry.get_display_info(hid)
		var nm: String = tr(disp.get("name", hid))
		hero_box.add_child(_make_chip(nm, _f_hero, hid, HERO_ACCENT.get(hid), true))
	rail.add_child(hero_box)

	# collection — 보유함 / 발견
	_build_collection_facet(rail, _f_coll)

func _build_relic_facets(rail: VBoxContainer) -> void:
	# hero — 공용 + 영웅별 ("영웅" 라벨로 표기)
	rail.add_child(_facet_head(tr("ui.codex.facet.hero")))
	var owner_box := VBoxContainer.new()
	owner_box.add_theme_constant_override("separation", 4)
	for oid in RelicCatalog.OWNER_ORDER:
		var nm: String
		var accent: Color
		if oid == "":
			nm = tr("ui.codex.relic.common")
			accent = SacredPalette.BRASS_400
		else:
			nm = tr(HeroRegistry.get_display_info(oid).get("name", oid))
			accent = HERO_ACCENT.get(oid, SacredPalette.BRASS_400)
		owner_box.add_child(_make_chip(nm, _rf_owner, oid, accent, true))
	rail.add_child(owner_box)

	# cursed — 저주
	rail.add_child(_facet_head(tr("ui.codex.facet.cursed")))
	var curse_box := _chip_flow()
	curse_box.add_child(_make_chip(tr("ui.codex.cursed"), _rf_cursed, "cursed", Color("d94a50")))
	rail.add_child(curse_box)

	# collection — 보유함 / 발견
	_build_collection_facet(rail, _rf_coll)

func _build_collection_facet(rail: VBoxContainer, coll: Array) -> void:
	rail.add_child(_facet_head(tr("ui.codex.facet.collection")))
	var coll_box := _chip_flow()
	coll_box.add_child(_make_chip(tr("ui.codex.collection.owned"), coll, "owned", Color("6ba89c")))
	coll_box.add_child(_make_chip(tr("ui.codex.collection.seen"), coll, "seen", Color("c8a24a")))
	rail.add_child(coll_box)

func _build_toolbar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 40)
	mc.add_theme_constant_override("margin_right", 40)
	mc.add_theme_constant_override("margin_top", 16)
	mc.add_theme_constant_override("margin_bottom", 12)
	mc.add_child(bar)

	# group — 드롭다운 (카드/렐릭: 영웅별 / 몬스터: 신화별)
	bar.add_child(_tool_label(tr("ui.codex.group")))
	var group_key: String
	var group_lbl: String
	match _tab:
		"monster": group_key = "myth"; group_lbl = tr("ui.codex.group.myth")
		"relic":   group_key = "owner"; group_lbl = tr("ui.codex.group.hero")
		_:         group_key = "hero"; group_lbl = tr("ui.codex.group.hero")
	var group_map := {group_key: group_lbl, "none": tr("ui.codex.group.flat")}
	bar.add_child(_make_dropdown([group_key, "none"], group_map, _cur_group(), 112.0,
		func(k: String) -> void:
			_set_group(k)
			_render()))

	# sort — 드롭다운(정렬 키 2개 이상일 때만) + 방향 버튼. 렐릭/몬스터는 이름 정렬만.
	bar.add_child(_tool_label(tr("ui.codex.sort")))
	var sort_keys: Array
	var sort_map: Dictionary
	match _tab:
		"relic", "monster":
			sort_keys = ["name"]
			sort_map = {"name": tr("ui.codex.sort.name")}
		_:
			sort_keys = ["cost", "rarity", "type", "name"]
			sort_map = {"cost": tr("ui.codex.sort.cost"), "rarity": tr("ui.codex.sort.rarity"), "type": tr("ui.codex.sort.type"), "name": tr("ui.codex.sort.name")}
	if sort_keys.size() > 1:
		bar.add_child(_make_dropdown(sort_keys, sort_map, _cur_sort(), 112.0,
			func(k: String) -> void:
				_set_sort(k)
				_render()))
	_dir_btn = _make_dir_button()
	bar.add_child(_dir_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	# search — 자체 스타일 LineEdit
	bar.add_child(_make_search_edit())

	return mc

# 툴바 라벨 (group/sort)
func _tool_label(text: String) -> Label:
	var P := SacredPalette
	var lbl := Label.new()
	lbl.theme_type_variation = "EyebrowLabel"
	lbl.add_theme_color_override("font_color", P.BONE_400)
	lbl.add_theme_font_size_override("font_size", _fs(9))
	lbl.text = text
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return lbl

# 오름/내림차순 토글 버튼 — sort 와 분리
func _make_dir_button() -> Button:
	var P := SacredPalette
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(34, 30)
	b.add_theme_font_size_override("font_size", _fs(13))
	var normal := StyleBoxFlat.new()
	normal.bg_color = P.INK_900
	normal.border_color = P.BRASS_700
	normal.set_border_width_all(1)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = P.BRASS_500
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_color_override("font_color", P.BRASS_300)
	b.add_theme_color_override("font_hover_color", P.BONE_100)
	b.add_theme_color_override("font_pressed_color", P.BONE_100)
	b.tooltip_text = tr("ui.codex.sort.dir")
	_refresh_dir_button(b)
	b.pressed.connect(func() -> void:
		_flip_dir()
		_refresh_dir_button(b)
		_render())
	return b

func _refresh_dir_button(b: Button) -> void:
	b.text = "↑" if _cur_dir() > 0 else "↓"

# 자체 드롭다운 — 팝업을 CanvasLayer 루트에 띄워 컨테이너 클리핑/배틀씬 회색 이슈 회피
func _make_dropdown(keys: Array, label_map: Dictionary, current: String, min_w: float, on_select: Callable) -> Button:
	var P := SacredPalette
	var btn := Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(min_w, 30)
	btn.add_theme_font_size_override("font_size", _fs(11))
	btn.text = label_map.get(current, current)
	var normal := StyleBoxFlat.new()
	normal.bg_color = P.INK_900
	normal.border_color = P.BRASS_700
	normal.set_border_width_all(1)
	normal.set_content_margin(SIDE_LEFT, 10)
	normal.set_content_margin(SIDE_RIGHT, 24)
	normal.set_content_margin(SIDE_TOP, 5)
	normal.set_content_margin(SIDE_BOTTOM, 5)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = P.BRASS_500
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override("font_color", P.BONE_100)
	btn.add_theme_color_override("font_hover_color", P.BRASS_300)
	btn.add_theme_color_override("font_pressed_color", P.BRASS_300)

	var arrow := Label.new()
	arrow.text = "▼"
	arrow.add_theme_color_override("font_color", P.BRASS_300)
	arrow.add_theme_font_size_override("font_size", _fs(9))
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn.add_child(arrow)
	arrow.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	arrow.offset_left = -20.0
	arrow.offset_right = -8.0

	# 외부 클릭 닫기용 catcher (팝업 아래)
	var catcher := Control.new()
	catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	catcher.visible = false
	catcher.z_index = 99
	_ui_root.add_child(catcher)

	# 팝업 패널
	var popup := PanelContainer.new()
	popup.visible = false
	popup.z_index = 100
	var dd_sb := StyleBoxFlat.new()
	dd_sb.bg_color = P.INK_1000
	dd_sb.border_color = P.BRASS_700
	dd_sb.set_border_width_all(1)
	popup.add_theme_stylebox_override("panel", dd_sb)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	popup.add_child(vbox)
	_ui_root.add_child(popup)

	var close := func() -> void:
		popup.visible = false
		catcher.visible = false
		arrow.text = "▼"
	_dd_closers.append(close)
	catcher.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			close.call())

	for key in keys:
		var item := Button.new()
		item.text = label_map.get(key, key)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT
		item.focus_mode = Control.FOCUS_NONE
		item.custom_minimum_size = Vector2(min_w, 28)
		item.add_theme_font_size_override("font_size", _fs(11))
		var i_normal := StyleBoxFlat.new()
		i_normal.bg_color = Color.TRANSPARENT
		i_normal.set_content_margin(SIDE_LEFT, 10)
		i_normal.set_content_margin(SIDE_RIGHT, 10)
		i_normal.set_content_margin(SIDE_TOP, 4)
		i_normal.set_content_margin(SIDE_BOTTOM, 4)
		var i_hover := i_normal.duplicate() as StyleBoxFlat
		i_hover.bg_color = Color(P.BRASS_700.r, P.BRASS_700.g, P.BRASS_700.b, 0.35)
		item.add_theme_stylebox_override("normal", i_normal)
		item.add_theme_stylebox_override("hover", i_hover)
		item.add_theme_stylebox_override("pressed", i_hover)
		item.add_theme_color_override("font_color", P.BONE_100)
		item.add_theme_color_override("font_hover_color", P.BRASS_300)
		var k: String = key
		item.pressed.connect(func() -> void:
			btn.text = label_map.get(k, k)
			close.call()
			on_select.call(k))
		vbox.add_child(item)

	btn.pressed.connect(func() -> void:
		if popup.visible:
			close.call()
			return
		for c in _dd_closers:
			if c != close:
				c.call()
		var r := btn.get_global_rect()
		popup.position = Vector2(r.position.x, r.position.y + r.size.y + 2.0)
		popup.custom_minimum_size = Vector2(r.size.x, 0)
		popup.size = Vector2(r.size.x, 0)
		catcher.visible = true
		popup.visible = true
		arrow.text = "▲")
	return btn

# 검색 LineEdit — 자체 StyleBox 적용 (테마 통일)
func _make_search_edit() -> LineEdit:
	var P := SacredPalette
	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "⌕  " + tr("ui.codex.search")
	_search_edit.text = _cur_search()  # 유지된 검색어 복원
	_search_edit.custom_minimum_size = Vector2(190, 30)
	_search_edit.size_flags_horizontal = Control.SIZE_SHRINK_END
	_search_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_search_edit.add_theme_font_size_override("font_size", _fs(11))
	_search_edit.clear_button_enabled = true
	_search_edit.keep_editing_on_text_submit = true  # 엔터 후에도 포커스 유지 → 이어서 입력
	_search_edit.caret_blink = true                   # 포커스 시 커서 깜빡임
	var normal := StyleBoxFlat.new()
	normal.bg_color = P.INK_900
	normal.border_color = P.BRASS_700
	normal.set_border_width_all(1)
	normal.set_content_margin(SIDE_LEFT, 10)
	normal.set_content_margin(SIDE_RIGHT, 10)
	normal.set_content_margin(SIDE_TOP, 5)
	normal.set_content_margin(SIDE_BOTTOM, 5)
	var focus := normal.duplicate() as StyleBoxFlat
	focus.border_color = P.BRASS_400
	_search_edit.add_theme_stylebox_override("normal", normal)
	_search_edit.add_theme_stylebox_override("focus", focus)
	_search_edit.add_theme_color_override("font_color", P.BONE_100)
	_search_edit.add_theme_color_override("font_placeholder_color", P.BONE_400)
	_search_edit.add_theme_color_override("caret_color", P.BRASS_300)
	_search_edit.text_changed.connect(func(t: String) -> void:
		_set_search(t.strip_edges().to_lower())
		_render())
	return _search_edit

# ─────────────────────────── 칩/헤더 헬퍼 ───────────────────────────
func _facet_head(text: String) -> Control:
	var P := SacredPalette
	var lbl := Label.new()
	lbl.theme_type_variation = "EyebrowLabel"
	lbl.add_theme_color_override("font_color", P.BRASS_400)
	lbl.add_theme_font_size_override("font_size", _fs(9))
	lbl.text = text
	return lbl

func _chip_flow() -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", 6)
	f.add_theme_constant_override("v_separation", 6)
	return f

func _make_chip(label: String, target: Array, value, accent: Color = SacredPalette.BRASS_500, full_width: bool = false, icon: Texture2D = null) -> Button:
	var P := SacredPalette
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	if icon != null:
		# 아이콘 칩 (희귀도 보석 / 카드 타입) — 텍스트/툴팁 없이 아이콘만. 정사각으로 왜곡 방지
		b.icon = icon
		b.expand_icon = true
		b.custom_minimum_size = Vector2(40, 40)
	else:
		b.text = label
		b.add_theme_font_size_override("font_size", _fs(11))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if full_width else Control.SIZE_SHRINK_BEGIN
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.03, 0.03, 0.04, 0.4)
	normal.border_color = P.BRASS_700
	normal.set_border_width_all(1)
	normal.set_content_margin(SIDE_LEFT, 10)
	normal.set_content_margin(SIDE_RIGHT, 10)
	normal.set_content_margin(SIDE_TOP, 6)
	normal.set_content_margin(SIDE_BOTTOM, 6)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(accent.r, accent.g, accent.b, 0.18)
	pressed.border_color = accent
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("hover_pressed", pressed)
	b.add_theme_color_override("font_color", P.BONE_400)
	b.add_theme_color_override("font_pressed_color", P.BONE_100)
	b.add_theme_color_override("font_hover_color", P.BONE_200)
	b.toggled.connect(func(on: bool) -> void:
		if on:
			if value not in target:
				target.append(value)
		else:
			target.erase(value)
		_render())
	b.set_pressed_no_signal(value in target)  # 유지된 필터 상태 반영
	_all_chips.append(b)
	return b

func _add_h_line(parent: Control) -> void:
	var line := ColorRect.new()
	line.color = SacredPalette.BRASS_700
	line.custom_minimum_size = Vector2(0, 1)
	parent.add_child(line)

# ─────────────────────────── 툴바 핸들러 ───────────────────────────
func _on_reset() -> void:
	match _tab:
		"relic": _rf_owner.clear(); _rf_cursed.clear(); _rf_coll.clear()
		"monster": _mf_myth.clear()
		_: _f_rarity.clear(); _f_type.clear(); _f_cost.clear(); _f_hero.clear(); _f_coll.clear()
	_set_search("")
	if _search_edit:
		_search_edit.text = ""
	for c in _all_chips:
		(c as Button).set_pressed_no_signal(false)
	_render()

func _on_back() -> void:
	# 도감 열린 동안 언어가 바뀌었고 밑 씬이 라이브 갱신을 안 하는 경우(메뉴/맵 등) 닫으면서 reload
	# — 전투/상점은 자체 재번역하므로 reload 불필요(상태 보존). reload 가 도감도 함께 정리.
	if _locale_dirty:
		var gm := get_node_or_null("/root/GameManager")
		var live: bool = gm != null and (gm.current_state in [gm.GameState.BATTLE, gm.GameState.SHOP])
		if not live:
			get_tree().reload_current_scene()
			return
	queue_free()  # 오버레이 닫기 → 하단 씬으로 복귀

# ─────────────────────────── 필터/정렬 ───────────────────────────
func _is_discovered(item) -> bool:
	var pm = get_node_or_null("/root/ProgressManager")
	if pm == null:
		return false
	match _tab:
		"relic": return pm.is_relic_discovered(_item_key(item))
		"monster": return pm.is_monster_discovered(_item_key(item))
		_: return pm.is_card_discovered(_item_key(item))

func _is_seen(item) -> bool:
	var pm = get_node_or_null("/root/ProgressManager")
	if pm == null:
		return false
	match _tab:
		"relic": return pm.is_relic_seen(_item_key(item))
		"monster": return pm.is_monster_seen(_item_key(item))
		_: return pm.is_card_seen(_item_key(item))

func _passes(item) -> bool:
	match _tab:
		"relic": return _passes_relic(item)
		"monster": return _passes_monster(item)
		_: return _passes_card(item)

func _passes_monster(mon) -> bool:
	if _mf_myth.size() and mon.mythology not in _mf_myth:
		return false
	if _m_search != "":
		if not _is_seen(mon):  # 미조우는 검색 제외 (이름 노출 방지)
			return false
		if _m_search not in tr(mon.enemy_name).to_lower():
			return false
	return true

func _passes_card(card) -> bool:
	if _f_rarity.size() and card.rarity not in _f_rarity:
		return false
	if _f_type.size() and card.card_type not in _f_type:
		return false
	if _f_cost.size() and card.cost not in _f_cost:
		return false
	if _f_hero.size() and card.owner_id not in _f_hero:
		return false
	if not _passes_collection(card, _f_coll):
		return false
	if _search != "":
		if not _is_seen(card):  # 미발견은 검색 제외 (이름 노출 방지)
			return false
		var nm := tr(card.card_name).to_lower()
		var ds := tr(card.description).to_lower() if card.description != "" else ""
		if _search not in nm and _search not in ds:
			return false
	return true

func _passes_relic(relic) -> bool:
	if _rf_owner.size() and relic.owner_hero_id not in _rf_owner:
		return false
	if _rf_cursed.size() and not relic.is_cursed:
		return false
	if not _passes_collection(relic, _rf_coll):
		return false
	if _r_search != "":
		if not _is_seen(relic):  # 미발견은 검색 제외 (이름 노출 방지)
			return false
		var nm := tr(relic.relic_name).to_lower()
		var ds := tr(relic.description).to_lower() if relic.description != "" else ""
		if _r_search not in nm and _r_search not in ds:
			return false
	return true

# "owned" = 보유, "seen" = 발견(미보유). 빈 필터면 통과.
func _passes_collection(item, coll: Array) -> bool:
	if coll.is_empty():
		return true
	var owned := _is_discovered(item)
	var seen := _is_seen(item)
	return (("owned" in coll) and owned) or (("seen" in coll) and seen and not owned)

# 정렬 1차 키 (sort 모드별). 동일 모드 내 a/b 는 같은 타입 반환.
func _sort_primary(item):
	if _tab == "relic":
		return tr(item.relic_name)
	if _tab == "monster":
		return tr(item.enemy_name)
	match _sort:
		"rarity": return item.rarity
		"type":   return item.card_type
		"name":   return tr(item.card_name)
		_:        return item.cost

# 결정적 전순서 — 1차 키는 dir 적용, 동점은 항상 동일 순서로 깨서
# 필터 개수에 따라 배열이 흔들리지 않게 한다.
func _cmp(a, b) -> bool:
	var dir := _cur_dir()
	var pa = _sort_primary(a)
	var pb = _sort_primary(b)
	if pa != pb:
		return (pa < pb) if dir > 0 else (pa > pb)
	if _tab == "card" and a.cost != b.cost:
		return a.cost < b.cost
	var na := _item_name(a)
	var nb := _item_name(b)
	if na != nb:
		return na < nb
	return _item_key(a) < _item_key(b)

# ─────────────────────────── 렌더 ───────────────────────────
func _render() -> void:
	# 캐시된 카드 셀을 먼저 떼어내 컨테이너 free 시 함께 삭제되지 않게 함 (재인스턴스화 회피)
	for cell in _cell_cache.values():
		if is_instance_valid(cell) and cell.get_parent() != null:
			cell.get_parent().remove_child(cell)
	for c in _grid_host.get_children():
		c.queue_free()  # 헤더·플로우 등 경량 컨테이너만 재생성

	var list: Array = _all.filter(_passes)
	list.sort_custom(_cmp)

	_update_tally()
	var noun: String
	match _tab:
		"relic": noun = tr("ui.codex.relics")
		"monster": noun = tr("ui.codex.monsters")
		_: noun = tr("ui.codex.cards")
	_result_lbl.text = "%d / %d  %s" % [list.size(), _all.size(), noun]

	if list.is_empty():
		var empty := Label.new()
		empty.theme_type_variation = "SubLabel"
		empty.add_theme_color_override("font_color", SacredPalette.BONE_400)
		empty.text = "—  " + tr("ui.codex.empty") + "  —"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_grid_host.add_child(empty)
		return

	if _cur_group() != "none":
		for gid in _group_order():
			var items: Array = list.filter(func(it): return _item_owner(it) == gid)
			if items.is_empty():
				continue
			_grid_host.add_child(_group_header(gid, items))
			_grid_host.add_child(_grid_of(items))
	else:
		_grid_host.add_child(_grid_of(list))

	_update_visible_deferred()  # 레이아웃 후 가시 셀만 생성 (가상 스크롤)

func _group_header(gid: String, items: Array) -> Control:
	var P := SacredPalette
	var accent: Color
	var group_name: String
	if _tab == "monster":  # 몬스터 — 신화 그룹
		accent = P.BRASS_400
		group_name = tr("ui.codex.myth.%s" % gid)
	elif gid == "":  # 렐릭 공용
		accent = P.BRASS_400
		group_name = tr("ui.codex.relic.common")
	else:
		accent = HERO_ACCENT.get(gid, P.BRASS_400)
		group_name = tr(HeroRegistry.get_display_info(gid).get("name", gid))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)

	var crest := ColorRect.new()
	crest.color = accent
	crest.custom_minimum_size = Vector2(9, 9)
	crest.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(crest)

	var name_lbl := Label.new()
	name_lbl.theme_type_variation = "TitleLabel"
	name_lbl.add_theme_font_size_override("font_size", _fs(24))
	name_lbl.add_theme_color_override("font_color", P.BONE_100)
	name_lbl.text = group_name
	row.add_child(name_lbl)

	var have := 0
	for c in items:
		if _is_discovered(c):
			have += 1
	var meta := Label.new()
	meta.theme_type_variation = "EyebrowLabel"
	meta.add_theme_color_override("font_color", P.BONE_400)
	meta.add_theme_font_size_override("font_size", _fs(10))
	meta.text = "%d / %d" % [have, items.size()]
	meta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(meta)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(row)
	var ln := ColorRect.new()
	ln.color = Color(accent.r, accent.g, accent.b, 0.26)
	ln.custom_minimum_size = Vector2(0, 1)
	box.add_child(ln)
	return box

func _grid_of(cards: Array) -> Control:
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 18)
	flow.add_theme_constant_override("v_separation", 26)
	for c in cards:
		flow.add_child(_get_cell(c))
	return flow

# 셀 — 한 번만 인스턴스화해 캐시. 정렬/필터 재렌더 시 재사용.
func _get_cell(item) -> Control:
	var key: String = _item_key(item)
	if _cell_cache.has(key) and is_instance_valid(_cell_cache[key]):
		return _cell_cache[key]
	var cell := _make_cell(item)
	_cell_cache[key] = cell
	return cell

func _make_cell(item) -> Control:
	match _tab:
		"relic": return _make_relic_cell(item)
		"monster": return _make_monster_cell(item)
		_: return _make_card_cell(item)

# 트리에 붙지 않은(필터로 빠진) 캐시 셀 해제 — 고아 노드 누수 방지
func _free_orphan_cells() -> void:
	for cell in _cell_cache.values():
		if is_instance_valid(cell) and cell.get_parent() == null:
			cell.free()

func _exit_tree() -> void:
	# 진행 중 워커가 freed self 에 접근하지 않도록 완료 대기 (queue_free 시 잠깐 블록)
	for tid in _thumb_inflight.values():
		WorkerThreadPool.wait_for_task_completion(tid)
	_thumb_inflight.clear()
	_free_orphan_cells()

# 셀 프레임 — 크기는 미리 확정(레이아웃·스크롤 정확). 보유/발견 카드 비주얼은
# 뷰포트에 들어올 때 _realize_cell 로 지연 생성(가상 스크롤). 미발견 카드백은 경량이라 즉시.
func _make_card_cell(card) -> Control:
	var P := SacredPalette
	var owned := _is_discovered(card)
	var seen := _is_seen(card)
	# classic(140×200)·modern(196×280) 모두 비율 0.7 → disp 동일
	var disp := Vector2(TARGET_CARD_W, TARGET_CARD_W / 0.7)

	var holder := Control.new()
	holder.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	holder.custom_minimum_size = disp
	if not (owned or seen):
		holder.add_child(_card_back(disp))  # 미발견 — 즉시

	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(CELL_W, disp.y + 26.0)
	cell.add_theme_constant_override("separation", 9)
	cell.add_child(holder)

	# 캡션 (희귀도 · 타입) — 보유/발견 시 노출 (미발견은 가림)
	var cap := Label.new()
	cap.theme_type_variation = "EyebrowLabel"
	cap.add_theme_font_size_override("font_size", _fs(8))
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_color_override("font_color", P.BONE_400)
	if owned or seen:
		cap.text = "%s · %s" % [tr("ui.reward.rarity.%s" % RARITY_KEYS[card.rarity]), tr("card_type.%s.name" % TYPE_KEYS[card.card_type])]
	else:
		cap.text = "— — —"
	cell.add_child(cap)

	# 지연 생성 메타 — 보유/발견만 (미발견은 이미 채워짐)
	cell.set_meta("kind", "card")
	cell.set_meta("card", card)
	cell.set_meta("holder", holder)
	cell.set_meta("lazy", owned or seen)
	cell.set_meta("realized", not (owned or seen))
	return cell

# 셀의 실제 비주얼 생성 — 뷰포트 진입 시 1회 (가상 스크롤). kind 별 분기.
func _realize_cell(cell: Control) -> void:
	if cell.get_meta("realized", true):
		return
	cell.set_meta("realized", true)
	match cell.get_meta("kind", "card"):
		"relic": _realize_relic_cell(cell)
		"monster": _realize_monster_cell(cell)
		_: _realize_card_cell(cell)

func _realize_card_cell(cell: Control) -> void:
	var card = cell.get_meta("card")
	var holder: Control = cell.get_meta("holder")
	var owned := _is_discovered(card)
	var cs := _new_card()
	var native: Vector2 = cs.custom_minimum_size
	if native.x <= 0.0:
		native = Vector2(140, 200)
	var scl: float = TARGET_CARD_W / native.x
	cs.scale = Vector2(scl, scl)
	cs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cs.setup(card, 1)  # Mode.REWARD
	if not owned:
		# 발견(관측)만 — 흑백 (자식 트리는 _ready 후 생성되므로 ready 시점에 적용)
		cs.ready.connect(_apply_grayscale.bind(cs), CONNECT_ONE_SHOT)
	holder.add_child(cs)

# 렐릭 아이콘(SVG)을 뷰포트 진입 시 패널에 생성 (가상 스크롤). 이름/설명은 즉시 생성됨.
func _realize_relic_cell(cell: Control) -> void:
	var holder: Control = cell.get_meta("holder")
	var icon := TextureRect.new()
	icon.texture = IconUtils.get_relic_icon(cell.get_meta("relic_name"))
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(icon)
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 8.0; icon.offset_top = 8.0
	icon.offset_right = -8.0; icon.offset_bottom = -8.0
	if not cell.get_meta("owned"):
		icon.material = _gray_mat  # 발견(미보유) 흑백

# ── 몬스터 셀 ──
# "enemy.{myth}.{slug}" → "{myth}_{slug}" (art 파일 베이스)
func _monster_art_base(mon) -> String:
	var parts: PackedStringArray = mon.enemy_name.split(".")
	return "%s_%s" % [parts[1], parts[2]] if parts.size() >= 3 else mon.enemy_name

# 페이즈 ph(1=기본, 2=_p1, ...) 의 일러스트 경로
func _monster_phase_path(base: String, ph: int) -> String:
	if ph <= 1:
		return ENEMY_ART_DIR + base + ".png"
	return ENEMY_ART_DIR + "%s_p%d.png" % [base, ph - 1]

# 사용 가능한 일러스트 수 (기본 + _p1, _p2, ...)
func _monster_phase_count(base: String) -> int:
	var n := 1 if ResourceLoader.exists(ENEMY_ART_DIR + base + ".png") else 0
	var k := 1
	while ResourceLoader.exists(ENEMY_ART_DIR + "%s_p%d.png" % [base, k]):
		n += 1
		k += 1
	return maxi(n, 1)

# 몬스터 셀 — 일러스트 + 이름 + (페이즈 있으면) 페이즈 선택. 일러스트는 가상 스크롤로 지연 생성.
func _make_monster_cell(mon) -> Control:
	var P := SacredPalette
	var discovered := _is_discovered(mon)
	var base := _monster_art_base(mon)

	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(MONSTER_CELL_W, MON_FRAME_H + 60.0)
	cell.add_theme_constant_override("separation", 6)

	# 일러스트 영역 — 배틀씬과 동일한 museum mat 프레임 + 내부 art 영역(0.6 비율, cover-crop).
	var art_row := HBoxContainer.new()
	art_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var frame_wrap := Control.new()
	frame_wrap.custom_minimum_size = Vector2(MON_FRAME_W, MON_FRAME_H)
	art_row.add_child(frame_wrap)
	cell.add_child(art_row)

	# 내부 art 클립 홀더 (MAT_INSET 만큼 안쪽) — 일러스트가 여기서 cover-crop
	var mat: int = MuseumMatFrame.MAT_INSET
	var holder := Control.new()
	holder.clip_contents = true
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_wrap.add_child(holder)
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.offset_left = mat; holder.offset_top = mat
	holder.offset_right = -mat; holder.offset_bottom = -mat
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.05, 0.10, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# museum mat 프레임 (홀더 위에 — 매트·테두리 오버레이, 배틀과 동일 두께)
	var frame := MuseumMatFrame.new()
	frame_wrap.add_child(frame)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	if not discovered:
		var q := Label.new()
		q.text = "?"
		q.add_theme_font_size_override("font_size", _fs(48))
		q.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 0.14))
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		holder.add_child(q)

	# 이름
	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", _fs(12))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_color_override("font_color", P.BONE_100 if discovered else P.BONE_400)
	name_lbl.text = tr(mon.enemy_name) if discovered else "— — —"
	cell.add_child(name_lbl)

	cell.set_meta("kind", "monster")
	cell.set_meta("art_base", base)
	cell.set_meta("holder", holder)
	cell.set_meta("owned", discovered)
	cell.set_meta("phase", 1)
	cell.set_meta("lazy", discovered)
	cell.set_meta("realized", not discovered)

	# 페이즈 선택 (조우 + 일러스트 2개 이상)
	if discovered:
		var phases := _monster_phase_count(base)
		if phases > 1:
			var prow := HBoxContainer.new()
			prow.alignment = BoxContainer.ALIGNMENT_CENTER
			prow.add_theme_constant_override("separation", 4)
			var btns: Array = []
			for ph in range(1, phases + 1):
				var pb := _make_phase_btn(cell, ph)
				prow.add_child(pb)
				btns.append(pb)
			cell.add_child(prow)
			cell.set_meta("phase_btns", btns)
			_refresh_phase_btns(cell, 1)
	return cell

# 몬스터 일러스트(PNG)를 뷰포트 진입 시 생성 (가상 스크롤). 이름/페이즈 버튼은 즉시.
# 배틀씬과 동일: cover-crop(영역 채움) + 좌우 반전(flip_h — 배틀의 음수 x scale 재현).
func _realize_monster_cell(cell: Control) -> void:
	var holder: Control = cell.get_meta("holder")
	var illust := TextureRect.new()
	illust.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illust.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	illust.flip_h = true  # 배틀씬 적 방향과 동일 (좌우 반전)
	illust.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(illust)
	illust.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)  # 내부 art 영역 꽉 채움
	cell.set_meta("illust", illust)
	_apply_monster_phase(cell, cell.get_meta("phase", 1))

# 페이즈 일러스트 적용 — 썸네일 비동기 요청 (캐시되어 있으면 즉시)
func _apply_monster_phase(cell: Control, ph: int) -> void:
	var illust = cell.get_meta("illust", null)
	cell.set_meta("phase", ph)
	if not is_instance_valid(illust):
		return
	_request_thumb(_monster_phase_path(cell.get_meta("art_base"), ph), illust)

# 썸네일 요청 — 캐시 hit 시 즉시 적용, 아니면 워커 스레드에 생성 의뢰 (스크롤 끊김 방지)
func _request_thumb(path: String, target: TextureRect) -> void:
	if _mon_thumb.has(path):
		if is_instance_valid(target):
			target.texture = _mon_thumb[path]
		return
	if not _thumb_waiters.has(path):
		_thumb_waiters[path] = []
	_thumb_waiters[path].append(target)
	if _thumb_inflight.has(path):
		return  # 이미 로딩 중
	_thumb_inflight[path] = WorkerThreadPool.add_task(_thumb_worker.bind(path))
	set_process(true)

# [워커 스레드] 거대 PNG → 다운스케일 Image. 텍스처화(GPU 업로드)는 메인에서.
func _thumb_worker(path: String) -> void:
	var img := _make_thumb_image(path)
	_thumb_mutex.lock()
	_thumb_ready[path] = img
	_thumb_mutex.unlock()

func _make_thumb_image(path: String) -> Image:
	if not ResourceLoader.exists(path):
		return null
	var tex: Texture2D = ResourceLoader.load(path, "Texture2D", ResourceLoader.CACHE_MODE_IGNORE)
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	var s := img.get_size()
	var longest: int = maxi(int(s.x), int(s.y))
	if longest > MON_THUMB_MAX:
		var sc: float = float(MON_THUMB_MAX) / float(longest)
		img.resize(maxi(1, int(s.x * sc)), maxi(1, int(s.y * sc)), Image.INTERPOLATE_BILINEAR)
	return img

# 완료된 워커 폴링 — Image → ImageTexture(메인) 후 대기 중 대상에 적용
func _process(_dt: float) -> void:
	if _thumb_inflight.is_empty():
		set_process(false)
		return
	var done: Array = []
	for path in _thumb_inflight:
		if WorkerThreadPool.is_task_completed(_thumb_inflight[path]):
			WorkerThreadPool.wait_for_task_completion(_thumb_inflight[path])
			done.append(path)
	for path in done:
		_thumb_inflight.erase(path)
		_thumb_mutex.lock()
		var img: Image = _thumb_ready.get(path, null)
		_thumb_ready.erase(path)
		_thumb_mutex.unlock()
		var tex: Texture2D = null
		if img != null:
			tex = ImageTexture.create_from_image(img)
			_mon_thumb[path] = tex
		var waiters: Array = _thumb_waiters.get(path, [])
		_thumb_waiters.erase(path)
		if tex != null:
			for w in waiters:
				if is_instance_valid(w):
					w.texture = tex

# 페이즈 선택 버튼 클릭 — 미생성 시 먼저 realize 후 일러스트 교체
func _select_monster_phase(cell: Control, ph: int) -> void:
	if not cell.get_meta("realized", false):
		_realize_cell(cell)
	_apply_monster_phase(cell, ph)
	_refresh_phase_btns(cell, ph)

func _make_phase_btn(cell: Control, ph: int) -> Button:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.text = str(ph)
	b.custom_minimum_size = Vector2(28, 24)
	b.add_theme_font_size_override("font_size", _fs(10))
	b.pressed.connect(func() -> void: _select_monster_phase(cell, ph))
	return b

# 페이즈 버튼 활성 표시 갱신
func _refresh_phase_btns(cell: Control, active_ph: int) -> void:
	var P := SacredPalette
	var btns: Array = cell.get_meta("phase_btns", [])
	for i in btns.size():
		var b: Button = btns[i]
		var on := (i + 1) == active_ph
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(P.BRASS_500.r, P.BRASS_500.g, P.BRASS_500.b, 0.22) if on else Color(0.03, 0.03, 0.04, 0.4)
		sb.border_color = P.BRASS_400 if on else P.BRASS_700
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		b.add_theme_color_override("font_color", P.BONE_100 if on else P.BONE_400)

# 뷰포트(+상하 1화면 버퍼) 안의 미생성 셀만 realize.
# 셀의 "콘텐츠 내 상대 y"(스크롤 무관) vs scroll_vertical 로 판정 — get_global_rect 의
# 스크롤 트랜스폼 적용 타이밍에 의존하지 않아 value_changed 콜백에서도 정확.
func _update_visible_cells() -> void:
	if not is_instance_valid(_scroll):
		return
	var vh := _scroll.size.y
	if vh <= 0.0:
		return
	var top := _scroll.scroll_vertical - vh          # 위쪽 버퍼 1화면
	var bot := _scroll.scroll_vertical + vh * 2.0     # 뷰 + 아래쪽 버퍼 1화면
	var content_top := _grid_host.global_position.y
	# 프레임당 realize 수 제한 — 몬스터는 썸네일을 비동기 로딩하므로 realize 자체는 가벼움(높게).
	# 카드는 CardScene 동기 인스턴스화라 낮게 유지.
	var budget := 12 if _tab == "monster" else 6
	for cell in _cell_cache.values():
		if budget <= 0:
			break
		if not is_instance_valid(cell):
			continue
		if cell.get_meta("realized", true):
			continue
		if cell.get_parent() == null or not cell.is_visible_in_tree():
			continue
		var cy: float = cell.global_position.y - content_top  # 콘텐츠 내 상대 y
		var ch: float = cell.size.y
		if (cy + ch) >= top and cy <= bot:
			_realize_cell(cell)
			budget -= 1
	if budget <= 0:
		_schedule_more_realize()  # 남은 가시 셀은 다음 프레임에 이어서

# 점진 realize — 다음 프레임에 _update_visible_cells 재실행 (중복 예약 방지)
func _schedule_more_realize() -> void:
	if _realize_pending:
		return
	_realize_pending = true
	var tree := get_tree()
	if tree == null:
		_realize_pending = false
		return
	await tree.process_frame
	_realize_pending = false
	if is_inside_tree():
		_update_visible_cells()

# 레이아웃 정착 후 가시 셀 갱신 — _render 끝에서 fire-and-forget.
# 콘텐츠 높이가 뷰포트 이상이 될 때까지 대기(중첩 컨테이너 min_size 전파 완료 신호).
# 그 전엔 전 셀이 (0,0) 근처로 잡혀 전부 realize 되므로 정착을 기다려야 함.
# 콘텐츠가 뷰포트보다 짧으면 어차피 전부 보이므로 전부 realize 해도 무방.
func _update_visible_deferred() -> void:
	# tree 를 미리 잡아둠 — 언어 변경/씬 reload 로 도감이 트리에서 빠진 뒤
	# get_tree() 가 null 이 되어 터지는 것 방지 (await 재개 시 노드가 freed/detached 가능).
	var tree := get_tree()
	if tree == null:
		return
	for i in 12:
		await tree.process_frame
		if not is_inside_tree() or not is_instance_valid(_scroll) or not is_instance_valid(_grid_host):
			return
		if _grid_host.size.y >= _scroll.size.y:
			break
	if is_inside_tree():
		_update_visible_cells()

func _card_back(disp: Vector2) -> Control:
	var P := SacredPalette
	var panel := Panel.new()
	panel.custom_minimum_size = disp
	panel.size = disp
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.92)
	sb.border_color = P.BRASS_700
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", sb)

	var q := Label.new()
	q.text = "?"
	q.add_theme_font_size_override("font_size", _fs(48))
	q.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 0.14))
	q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(q)

	var stamp := Label.new()
	stamp.theme_type_variation = "EyebrowLabel"
	stamp.add_theme_font_size_override("font_size", _fs(7))
	stamp.add_theme_color_override("font_color", P.BONE_400)
	stamp.text = tr("ui.codex.collection.locked")
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	stamp.offset_top = -22.0
	stamp.offset_bottom = -8.0
	panel.add_child(stamp)
	return panel

# 렐릭 셀 — 아이콘 + 이름 + 설명. 경량이라 즉시 생성(가상 스크롤 비대상).
# 보유=컬러 / 발견(미보유)=흑백 아이콘 / 미발견=? 카드백.
func _make_relic_cell(relic) -> Control:
	var P := SacredPalette
	var owned := _is_discovered(relic)
	var seen := _is_seen(relic)
	var shown := owned or seen

	var cell := VBoxContainer.new()
	cell.custom_minimum_size = Vector2(RELIC_CELL_W, 176.0)
	cell.add_theme_constant_override("separation", 7)

	# 아이콘 영역 (가운데)
	var icon_row := HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var box := RELIC_ICON + 16.0
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(box, box)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.06, 0.08, 0.92)
	sb.border_color = Color("d94a50") if (shown and relic.is_cursed) else P.BRASS_700
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	icon_row.add_child(panel)
	cell.add_child(icon_row)

	# 미발견은 "?" 즉시. 보유/발견 아이콘(SVG)은 뷰포트 진입 시 _realize_relic_cell 에서 생성.
	if not shown:
		var q := Label.new()
		q.text = "?"
		q.add_theme_font_size_override("font_size", _fs(40))
		q.add_theme_color_override("font_color", Color(0.96, 0.94, 0.90, 0.14))
		q.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(q)

	# 이름 (즉시 — 경량 텍스트)
	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", _fs(12))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.add_theme_color_override("font_color", P.BONE_100 if owned else (P.BONE_300 if seen else P.BONE_400))
	name_lbl.text = tr(relic.relic_name) if shown else "— — —"
	cell.add_child(name_lbl)

	# 설명 (보유/발견만, 즉시)
	if shown:
		var desc := Label.new()
		desc.add_theme_font_size_override("font_size", _fs(9))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_color_override("font_color", P.BONE_400)
		desc.text = tr(relic.description)
		desc.clip_text = true
		desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cell.add_child(desc)

	# 지연 생성 메타 — 보유/발견 아이콘만 뷰포트 진입 시 생성 (가상 스크롤)
	cell.set_meta("kind", "relic")
	cell.set_meta("relic_name", relic.relic_name)
	cell.set_meta("holder", panel)
	cell.set_meta("owned", owned)
	cell.set_meta("lazy", shown)
	cell.set_meta("realized", not shown)
	return cell

func _update_tally() -> void:
	var have := 0
	for c in _all:
		if _is_discovered(c):
			have += 1
	var total: int = _all.size()
	_tally_num.text = "%d / %d" % [have, total]
	var frac: float = (float(have) / float(total)) if total > 0 else 0.0
	_tally_bar.anchor_right = clampf(frac, 0.0, 1.0)
	_tally_bar.offset_right = 0.0

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE:
		_on_back()
		get_viewport().set_input_as_handled()

# 검색창 밖을 클릭/터치하면 포커스 해제 (모바일 가상 키보드 닫힘).
# 배경 ColorRect 가 mouse 이벤트를 먹어 _unhandled_input 엔 안 오므로 _input 으로 선처리.
# 이벤트는 소비하지 않음 → 밑의 칩/버튼 클릭도 정상 동작.
func _input(ev: InputEvent) -> void:
	if not is_instance_valid(_search_edit) or not _search_edit.has_focus():
		return
	var pos
	if ev is InputEventMouseButton and ev.pressed:
		pos = ev.position
	elif ev is InputEventScreenTouch and ev.pressed:
		pos = ev.position
	else:
		return
	if not _search_edit.get_global_rect().has_point(pos):
		_search_edit.release_focus()
