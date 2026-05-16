# scenes/debug/hd2d_demo.gd
# HD-2D 프로토타입 데모 — battle_scene 의 3D 버전 시각 시연.
# Camera3D (perspective) + Plane3D ground + Sprite3D billboard 캐릭터/배경.
# 실행: 에디터에서 이 .tscn 열고 F6 (Run Current Scene).
#
# 조작:
#   [좌클릭]  마우스 위치(ground)로 카메라 dolly in/out
#   [V]       defense_buff VFX 발동 — 가운데 적
#   [T]       VFX A안(2D canvas) ↔ B안(3D ground plane) 토글
#   [ESC]     종료
extends Node3D

const _GROUND_SIZE := 60.0
# 옥토패스 톤 — fov 좁고 카메라 멀리 → "거의 직교 느낌의 perspective".
const _CAM_FOV := 28.0
const _CAM_HOME := Vector3(0.0, 8.0, 18.0)
const _CAM_LOOK := Vector3(0.0, 1.5, 0.0)

# battle_scene 2D 슬롯 좌표 → 3D 매핑.
# slot pos = panel 좌상단, 발 = slot + (SLOT_W/2=120, SLOT_H=280).
# x 와 z 비율 분리 — 2D 좌표는 isometric 평면이라 z 차이가 작아서 깊이 강조 위해 z 만 2배 확장.
const PX_PER_M_X := 200.0
const PX_PER_M_Z := 100.0
const SCREEN_CENTER := Vector2(960.0, 540.0)
const HERO_FOOTS := [
	Vector2(345.0 + 120.0, 228.0 + 280.0),  # H1
	Vector2(77.0 + 120.0,  274.0 + 280.0),  # H2
	Vector2(610.0 + 120.0, 283.0 + 280.0),  # H3
]
const ENEMY_FOOTS := [
	Vector2(1332.0 + 120.0, 216.0 + 280.0),  # E1
	Vector2(1593.0 + 120.0, 251.0 + 280.0),  # E2
	Vector2(1073.0 + 120.0, 281.0 + 280.0),  # E3
	Vector2(1084.0 + 120.0, 498.0 + 280.0),  # E4
	Vector2(1609.0 + 120.0, 484.0 + 280.0),  # E5
	Vector2(1354.0 + 120.0, 472.0 + 280.0),  # E6
]
const HERO_COLORS := [
	Color(0.40, 0.70, 1.0),   # H1 파랑
	Color(0.95, 0.85, 0.30),  # H2 노랑
	Color(0.75, 0.45, 0.95),  # H3 보라
]

var _camera: Camera3D
var _hero_billboards: Array = []  # Sprite3D × 3
var _enemy_billboards: Array = []  # Sprite3D × 6
var _vfx_canvas: CanvasLayer       # A안 — 기존 2D vfx 띄움
var _status_label: Label
var _use_b_an: bool = false
var _busy: bool = false
# A안 추적용 — {wrapper: Node2D, target_3d: Sprite3D, foot_offset_local: Vector2, base_zoom: Vector2}
var _active_2d_vfx: Array = []

func _ready() -> void:
	# ── 환경 (ambient + sky) ──
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.50, 0.62, 0.78)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.60, 0.70)
	environment.ambient_light_energy = 0.7
	env.environment = environment
	add_child(env)

	# ── 메인 라이트 ──
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50.0, 35.0, 0.0)
	light.light_energy = 1.1
	light.light_color = Color(1.0, 0.96, 0.86)  # warm key
	add_child(light)

	# ── ground (greek scenery 톤) ──
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(_GROUND_SIZE, _GROUND_SIZE)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.45, 0.32)  # 마른 풀/흙
	mat.roughness = 0.9
	ground.material_override = mat
	add_child(ground)

	# ── 카메라 ──
	_camera = Camera3D.new()
	_camera.fov = _CAM_FOV
	add_child(_camera)
	_camera.position = _CAM_HOME
	_camera.look_at(_CAM_LOOK, Vector3.UP)

	# ── 영웅 3명 (battle_scene 슬롯 위치 매핑) ──
	for i in HERO_FOOTS.size():
		var pos3d: Vector3 = _2d_foot_to_3d(HERO_FOOTS[i])
		var b := _make_char_billboard(HERO_COLORS[i], pos3d)
		add_child(b)
		_hero_billboards.append(b)

	# ── 적 6명 (battle_scene 슬롯 위치 매핑) ──
	for i in ENEMY_FOOTS.size():
		var pos3d: Vector3 = _2d_foot_to_3d(ENEMY_FOOTS[i])
		var b := _make_char_billboard(Color(1.0, 0.4, 0.4), pos3d)
		add_child(b)
		_enemy_billboards.append(b)

	# ── 배경 빌보드 (greek SVG) ──
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/cypress_a_leaves.svg",
		Vector3(-9.0, 0.0, -8.5), 4.8)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/cypress_a_trunk.svg",
		Vector3(-9.0, 0.0, -8.5), 4.8)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/cypress_b_leaves.svg",
		Vector3(9.0, 0.0, -7.0), 4.8)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/cypress_b_trunk.svg",
		Vector3(9.0, 0.0, -7.0), 4.8)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/temple_small_a.svg",
		Vector3(0.0, 0.0, -11.0), 4.5)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/statue_warrior_a.svg",
		Vector3(-5.5, 0.0, -2.5), 2.6)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/altar_a_base.svg",
		Vector3(5.0, 0.0, -1.0), 2.0)
	_spawn_bg_object("res://assets/art/backgrounds/objects/greek/altar_a_flame.svg",
		Vector3(5.0, 0.0, -1.0), 2.0)

	# ── VFX 2D 캔버스 (A안) ──
	_vfx_canvas = CanvasLayer.new()
	_vfx_canvas.layer = 50
	add_child(_vfx_canvas)

	# ── 도움말 + 상태 ──
	var help := Label.new()
	help.text = "[좌클릭] 카메라 dolly\n[V] VFX 발동 (H1 영웅 self-buff)\n[T] A안/B안 토글\n[ESC] 종료"
	help.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	help.add_theme_font_size_override("font_size", 18)
	help.position = Vector2(20, 20)
	_vfx_canvas.add_child(help)

	_status_label = Label.new()
	_status_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))
	_status_label.add_theme_font_size_override("font_size", 22)
	_status_label.position = Vector2(20, 130)
	_vfx_canvas.add_child(_status_label)
	_update_status()

# ── 2D 슬롯 발 좌표 → 3D ground 위치 매핑 ──
# 화면 중앙 (960, 540) 이 3D 원점. 화면 위(y 작음) = -z 방향 (멀리).
func _2d_foot_to_3d(p_2d: Vector2) -> Vector3:
	var x: float = (p_2d.x - SCREEN_CENTER.x) / PX_PER_M_X
	var z: float = (p_2d.y - SCREEN_CENTER.y) / PX_PER_M_Z
	return Vector3(x, 0.0, z)

# ── 빌보드 헬퍼 ──
func _make_char_billboard(color: Color, foot_pos: Vector3) -> Sprite3D:
	var spr := Sprite3D.new()
	# 색상 placeholder — 원본 sprite 비율(1:2) 유지, 크기만 사람 키로 축소
	var img := Image.create(80, 160, false, Image.FORMAT_RGBA8)
	img.fill(color)
	spr.texture = ImageTexture.create_from_image(img)
	# pixel_size 0.011 → 0.88m × 1.76m (사람 키. 비율 1:2 = sprite 사각형 박스)
	spr.pixel_size = 0.011
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
	spr.position = foot_pos + Vector3(0, 160.0 * 0.011 * 0.5, 0)
	return spr

func _spawn_bg_object(path: String, foot_pos: Vector3, height_m: float) -> void:
	if not ResourceLoader.exists(path):
		return
	var spr := Sprite3D.new()
	spr.texture = load(path)
	spr.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS  # z-buffer 정렬
	var tex_h: float = (spr.texture as Texture2D).get_height()
	spr.pixel_size = height_m / tex_h
	# 발이 ground 에 닿도록
	spr.position = foot_pos + Vector3(0, height_m * 0.5, 0)
	add_child(spr)

# ── 입력 ──
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_V:
				# defense_buff 는 영웅 self-buff — H1 (인덱스 0) 에 발동
				_spawn_defense_buff_on(_hero_billboards[0])
			KEY_T:
				_use_b_an = not _use_b_an
				_update_status()
			KEY_ESCAPE:
				get_tree().quit()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 마우스 → 3D ray → ground 교차점으로 dolly
		var ray_origin: Vector3 = _camera.project_ray_origin(event.position)
		var ray_dir: Vector3 = _camera.project_ray_normal(event.position)
		if abs(ray_dir.y) > 0.001:
			var t: float = -ray_origin.y / ray_dir.y
			if t > 0.0:
				var hit: Vector3 = ray_origin + ray_dir * t
				_dolly_to(hit)

# ── 카메라 dolly ──
func _dolly_to(ground_target: Vector3) -> void:
	if _busy:
		return
	_busy = true
	# 클릭 ground 점이 화면 정중앙에 오도록 — y=ground 그대로
	var look_target: Vector3 = ground_target
	# fov 28° 좁아서 dolly 거리 크게 — 카메라가 target 가까이 이동해야 의미있게 확대됨
	var cam_target: Vector3 = Vector3(
		ground_target.x * 0.75,
		_CAM_HOME.y * 0.55,
		ground_target.z + 5.5
	)
	var tw_in := create_tween().set_parallel(true)
	tw_in.tween_property(_camera, "position", cam_target, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_in.tween_method(func(t: float) -> void:
		var cur_look: Vector3 = _CAM_LOOK.lerp(look_target, t)
		_camera.look_at(cur_look, Vector3.UP),
		0.0, 1.0, 0.45)
	await tw_in.finished
	await get_tree().create_timer(0.5).timeout
	# 복귀
	var tw_out := create_tween().set_parallel(true)
	tw_out.tween_property(_camera, "position", _CAM_HOME, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw_out.tween_method(func(t: float) -> void:
		var cur_look: Vector3 = look_target.lerp(_CAM_LOOK, t)
		_camera.look_at(cur_look, Vector3.UP),
		0.0, 1.0, 0.5)
	await tw_out.finished
	_busy = false

# ── VFX dispatch ──
func _spawn_defense_buff_on(target: Sprite3D) -> void:
	if _use_b_an:
		_spawn_defense_buff_3d(target)
	else:
		_spawn_defense_buff_2d(target)

# A안 — 기존 2D defense_buff.gd 를 CanvasLayer 의 wrapper Node2D 안에 spawn.
# wrapper.position 을 매 프레임 unproject 로 업데이트 → 카메라 이동 시 vfx 가 캐릭터 따라감.
# 한계: 카메라 zoom 시 vfx 자체 크기는 변하지 않음 (화면 평면 고정). 추후 fov 거리 비율로 wrapper.scale 도 가능.
func _spawn_defense_buff_2d(target: Sprite3D) -> void:
	var DBClass = preload("res://scenes/vfx/defense_buff.gd")
	var wrapper := Node2D.new()
	_vfx_canvas.add_child(wrapper)
	var fx = DBClass.new()
	wrapper.add_child(fx)
	# fx 의 _target / ground anchor 는 wrapper 로컬 좌표 — 발이 wrapper origin.
	# 캐릭터 중심(가슴/머리) 은 발에서 위쪽 (화면 좌표 y 마이너스).
	# 발-중심 화면 거리 계산 (3D 캐릭터 sprite 의 height 픽셀로 추정).
	var foot_world: Vector3 = target.global_position
	foot_world.y = 0.0
	var foot_screen: Vector2 = _camera.unproject_position(foot_world)
	var center_screen: Vector2 = _camera.unproject_position(target.global_position)
	var center_offset_local: Vector2 = center_screen - foot_screen
	fx.set_ground_anchor(Vector2.ZERO)  # wrapper origin = 발
	fx.play(center_offset_local, center_offset_local)
	# 추적 등록 — 매 프레임 wrapper.position 갱신
	_active_2d_vfx.append({"wrapper": wrapper, "target": target, "fx": fx})
	# fx 가 자동 queue_free 시 wrapper 도 정리
	fx.tree_exited.connect(func() -> void:
		_active_2d_vfx = _active_2d_vfx.filter(func(e): return e["fx"] != fx)
		if is_instance_valid(wrapper):
			wrapper.queue_free())

func _process(_delta: float) -> void:
	# A안 vfx 캐릭터 추적 — wrapper.position 을 매 프레임 unproject
	for entry in _active_2d_vfx:
		var t: Sprite3D = entry["target"]
		var w: Node2D = entry["wrapper"]
		if not is_instance_valid(t) or not is_instance_valid(w):
			continue
		var foot_world: Vector3 = t.global_position
		foot_world.y = 0.0
		w.position = _camera.unproject_position(foot_world)

# B안 — ground plane 에 박힌 진짜 3D 룬링 (MeshInstance3D + spatial shader).
# 카메라 dolly/회전 시 perspective 자동 변형 — A안 화면 평면 한계 없음.
# 단순화: orb/dome/barrier 는 구현 안 함 (룬링 중심 비교).
func _spawn_defense_buff_3d(target: Sprite3D) -> void:
	var DB3D = preload("res://scenes/vfx/defense_buff_3d.gd")
	var fx = DB3D.new()
	var foot_world: Vector3 = target.global_position
	foot_world.y = 0.0
	fx.position = foot_world
	add_child(fx)
	fx.play()

func _update_status() -> void:
	if _status_label == null:
		return
	_status_label.text = "VFX 모드: %s" % ("B안 — 3D ground plane (룬링만)" if _use_b_an else "A안 — 2D canvas + unproject")
