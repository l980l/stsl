# scenes/vfx/defense_buff_3d.gd
# defense_buff 의 B안 (HD-2D prototype) — 모든 요소를 3D 로 포팅.
#   - 룬링 (ground 평면, 별도 MeshInstance3D + z 살짝 뒤로 → 캐릭터 sprite 가 가림)
#   - 차지오브 (Sprite3D billboard, 캐릭터 머리 위)
#   - 돔 (6 hex, 캐릭터 정면 vertical 평면)
#   - 배리어 (XY 평면 vertical 타원, 점선 + 펄스)
# 두꺼운 라인: ImmediateMesh PRIMITIVE_LINES(1px 고정) 대신 TRIANGLES quad strip 으로 직접.
# segment 간 틈 방지: closed loop / open strip 헬퍼가 인접 segment 평균 perp 로 vertex 공유.
class_name DefenseBuff3D
extends Node3D

# 캐릭터 키 1.76m 기준. 원본 크기 × 0.61 비례 축소.
const RING_RADIUS_M := 1.1
const PANEL_DIST_M := 0.64
const PANEL_SIZE_M := 0.26
const BARRIER_RX := 1.0
const BARRIER_RY := 1.4
const CHARGE_TIME := 0.3
const BUFF_TIME := 1.2
const DURATION := CHARGE_TIME + BUFF_TIME + 0.3
const SPIN_SPEED := TAU / 14.0
const ORB_OFFSET_Y := 1.95   # 캐릭터 머리(1.76) 위쪽 0.2m
const DOME_OFFSET_Y := 0.9   # 캐릭터 가슴 높이
const LINE_THICK := 0.025
const COL_MID := Color(0.659, 0.816, 1.0)
const COL_HOT := Color(1.0, 1.0, 1.0)
const COL_DEEP := Color(0.165, 0.420, 0.690)

signal screen_effect

var _ring_age: float = -1.0
var _dome_age: float = -1.0
var _barrier_age: float = -1.0
var _spin: float = 0.0

# ring 만 별도 mesh — 카메라 반대쪽으로 살짝 옮겨 sprite z-buffer 에 가려짐
var _ring_mesh: ImmediateMesh
var _ring_instance: MeshInstance3D
# dome + barrier 통합 mesh — vertical 평면이라 sprite 가림 무관
var _overlay_mesh: ImmediateMesh
var _overlay_instance: MeshInstance3D
var _orb: Sprite3D

func _ready() -> void:
	var mat := _make_add_mat()
	_ring_mesh = ImmediateMesh.new()
	_ring_instance = MeshInstance3D.new()
	_ring_instance.mesh = _ring_mesh
	_ring_instance.material_override = mat
	# y 살짝 위(z-fight 방지) + z 살짝 뒤(카메라 반대쪽 → sprite 보다 멀어 ring 가려짐).
	# 카메라가 +z 방향에 있어서 z 감소 = 카메라 멀어짐.
	_ring_instance.position = Vector3(0.0, 0.02, -0.08)
	add_child(_ring_instance)

	_overlay_mesh = ImmediateMesh.new()
	_overlay_instance = MeshInstance3D.new()
	_overlay_instance.mesh = _overlay_mesh
	_overlay_instance.material_override = mat
	add_child(_overlay_instance)

	_orb = Sprite3D.new()
	_orb.texture = _make_orb_tex()
	_orb.pixel_size = 0.0073  # 256px × 0.0073 ≈ 1.87m 최대
	_orb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_orb.shaded = false
	_orb.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	_orb.no_depth_test = true  # 캐릭터 sprite 와 alpha 정렬 깨짐 방지
	_orb.modulate = Color(1, 1, 1, 0.0)
	_orb.scale = Vector3.ONE * 0.1
	_orb.position = Vector3(0.0, ORB_OFFSET_Y, 0.0)
	add_child(_orb)

	set_process(false)

func _make_add_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.vertex_color_use_as_albedo = true
	return mat

static func _make_orb_tex() -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([
		Color(1, 1, 1, 1.0),
		Color(0.659, 0.816, 1.0, 0.95),
		Color(0.165, 0.420, 0.690, 0.85),
		Color(0.165, 0.420, 0.690, 0.0),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func play() -> void:
	_ring_age = -1.0
	_dome_age = -1.0
	_barrier_age = -1.0
	_spin = 0.0
	set_process(true)
	var tw := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_orb, "modulate:a", 1.0, 0.12)
	tw.tween_property(_orb, "scale", Vector3.ONE * 0.32, CHARGE_TIME)
	await get_tree().create_timer(CHARGE_TIME).timeout
	var tw2 := create_tween()
	tw2.tween_property(_orb, "modulate:a", 0.0, 0.12)
	_ring_age = 0.0
	_dome_age = 0.0
	_barrier_age = 0.0
	screen_effect.emit()
	await get_tree().create_timer(BUFF_TIME + 0.5).timeout
	queue_free()

func _process(delta: float) -> void:
	if _ring_age >= 0.0:
		_ring_age += delta
		_spin += delta * SPIN_SPEED
	if _dome_age >= 0.0:
		_dome_age += delta
	if _barrier_age >= 0.0:
		_barrier_age += delta
	_rebuild()

func _rebuild() -> void:
	_ring_mesh.clear_surfaces()
	_overlay_mesh.clear_surfaces()
	if _ring_age >= 0.0:
		_draw_ring()
	if _barrier_age >= 0.0:
		_draw_barrier()
	if _dome_age >= 0.0:
		_draw_dome()

# ── 두꺼운 라인 헬퍼 — vertex 공유 (segment 간 틈 없음) ──
# closed loop: 첫/끝 vertex 가 같이 연결됨.
func _add_thick_loop(mesh: ImmediateMesh, verts: PackedVector3Array, plane_normal: Vector3, thick: float, color: Color) -> void:
	var n: int = verts.size()
	if n < 3:
		return
	var perps: Array = []
	for i in range(n):
		var prev_v: Vector3 = verts[(i - 1 + n) % n]
		var next_v: Vector3 = verts[(i + 1) % n]
		var in_dir: Vector3 = (verts[i] - prev_v).normalized()
		var out_dir: Vector3 = (next_v - verts[i]).normalized()
		var avg: Vector3 = (in_dir + out_dir).normalized()
		perps.append(avg.cross(plane_normal).normalized() * (thick * 0.5))
	_add_quad_strip_from_perps(mesh, verts, perps, color, true)

# open strip: 첫/끝 vertex 연결 안 함 (segment 끝 perp 는 segment 방향 그대로).
func _add_thick_strip(mesh: ImmediateMesh, verts: PackedVector3Array, plane_normal: Vector3, thick: float, color: Color) -> void:
	var n: int = verts.size()
	if n < 2:
		return
	var perps: Array = []
	for i in range(n):
		var in_dir: Vector3
		var out_dir: Vector3
		if i == 0:
			out_dir = (verts[1] - verts[0]).normalized()
			in_dir = out_dir
		elif i == n - 1:
			in_dir = (verts[i] - verts[i - 1]).normalized()
			out_dir = in_dir
		else:
			in_dir = (verts[i] - verts[i - 1]).normalized()
			out_dir = (verts[i + 1] - verts[i]).normalized()
		var avg: Vector3 = (in_dir + out_dir).normalized()
		perps.append(avg.cross(plane_normal).normalized() * (thick * 0.5))
	_add_quad_strip_from_perps(mesh, verts, perps, color, false)

func _add_quad_strip_from_perps(mesh: ImmediateMesh, verts: PackedVector3Array, perps: Array, color: Color, closed: bool) -> void:
	var n: int = verts.size()
	var seg_count: int = n if closed else n - 1
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(seg_count):
		var j: int = (i + 1) % n
		var a: Vector3 = verts[i] + perps[i]
		var b: Vector3 = verts[i] - perps[i]
		var c: Vector3 = verts[j] + perps[j]
		var d: Vector3 = verts[j] - perps[j]
		mesh.surface_set_color(color); mesh.surface_add_vertex(a)
		mesh.surface_set_color(color); mesh.surface_add_vertex(b)
		mesh.surface_set_color(color); mesh.surface_add_vertex(c)
		mesh.surface_set_color(color); mesh.surface_add_vertex(c)
		mesh.surface_set_color(color); mesh.surface_add_vertex(b)
		mesh.surface_set_color(color); mesh.surface_add_vertex(d)
	mesh.surface_end()

# ── 바닥 룬링 (ground 평면, _ring_instance) ──
func _draw_ring() -> void:
	var grow: float = clampf(_ring_age / 0.35, 0.0, 1.0)
	var fade: float = 1.0
	if _ring_age > BUFF_TIME:
		fade = clampf(1.0 - (_ring_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var sc: float = lerpf(0.3, 1.0, grow)
	var a: float = grow * fade * 0.9
	# 두 동심원 — 48 segment closed loop
	for radius in [RING_RADIUS_M, RING_RADIUS_M * 0.87]:
		var rad: float = float(radius) * sc
		var ring_verts := PackedVector3Array()
		for i in range(48):
			var ang: float = TAU * float(i) / 48.0
			ring_verts.append(Vector3(cos(ang) * rad, 0.0, sin(ang) * rad))
		_add_thick_loop(_ring_mesh, ring_verts, Vector3.UP, LINE_THICK, Color(COL_MID, a))
	# 8 hex tab — fan triangle 채움 + 윤곽 loop
	var tab_r: float = RING_RADIUS_M * sc
	_ring_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(8):
		var ang: float = TAU * float(i) / 8.0 + _spin
		var center: Vector3 = Vector3(cos(ang) * tab_r, 0.0, sin(ang) * tab_r)
		var hex_size: float = 0.11 * sc
		var verts: Array = []
		for k in range(6):
			var pa: float = TAU * float(k) / 6.0 - PI * 0.5
			verts.append(center + Vector3(cos(pa) * hex_size, 0.0, sin(pa) * hex_size))
		for k in range(1, 5):
			_ring_mesh.surface_set_color(Color(COL_HOT, a * 0.7))
			_ring_mesh.surface_add_vertex(verts[0])
			_ring_mesh.surface_set_color(Color(COL_HOT, a * 0.7))
			_ring_mesh.surface_add_vertex(verts[k])
			_ring_mesh.surface_set_color(Color(COL_HOT, a * 0.7))
			_ring_mesh.surface_add_vertex(verts[k + 1])
	_ring_mesh.surface_end()

# ── 외곽 배리어 점선 ellipse (XY 평면, 캐릭터 정면) ──
func _draw_barrier() -> void:
	var grow: float = clampf(_barrier_age / 0.4, 0.0, 1.0)
	var fade: float = 1.0
	if _barrier_age > BUFF_TIME:
		fade = clampf(1.0 - (_barrier_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var pulse: float = 0.55 + sin(_barrier_age * (TAU / 1.8)) * 0.20
	var a: float = grow * fade * pulse
	var rx: float = BARRIER_RX * grow
	var ry: float = BARRIER_RY * grow
	var center := Vector3(0.0, DOME_OFFSET_Y, 0.0)
	# 16 점선 dash — 각 dash 는 짧은 strip (4 sub-vertex)
	for i in range(16):
		var a0: float = TAU * float(i) / 16.0
		var a1: float = a0 + TAU / 32.0
		var dash_verts := PackedVector3Array()
		for k in range(5):
			var t: float = float(k) / 4.0
			var ang: float = lerpf(a0, a1, t)
			dash_verts.append(center + Vector3(cos(ang) * rx, sin(ang) * ry, 0.0))
		_add_thick_strip(_overlay_mesh, dash_verts, Vector3.FORWARD, LINE_THICK, Color(COL_MID, 0.85 * a))

# ── 6 hex 패널 dome (XY 평면) ──
func _draw_dome() -> void:
	var fade: float = 1.0
	if _dome_age > BUFF_TIME:
		fade = clampf(1.0 - (_dome_age - BUFF_TIME) / 0.4, 0.0, 1.0)
	if fade <= 0.0:
		return
	var positions := [
		Vector2(-1.0, 0.7), Vector2(0.0, 1.05), Vector2(1.0, 0.7),
		Vector2(-0.85, -0.5), Vector2(0.0, -0.85), Vector2(0.85, -0.5),
	]
	var delays := [0.0, 0.04, 0.08, 0.12, 0.16, 0.2]
	const SNAP_DUR := 0.30
	var center_y: float = DOME_OFFSET_Y
	# 패널 채움 + 외곽선 (vertex 공유)
	_overlay_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(6):
		var local_age: float = _dome_age - delays[i]
		if local_age < 0.0:
			continue
		var t: float = clampf(local_age / SNAP_DUR, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var p2: Vector2 = positions[i]
		var start_pos: Vector3 = Vector3(p2.x * (PANEL_DIST_M * 1.8), center_y + p2.y * (PANEL_DIST_M * 1.8), 0.0)
		var end_pos: Vector3 = Vector3(p2.x * PANEL_DIST_M, center_y + p2.y * PANEL_DIST_M, 0.0)
		var center: Vector3 = start_pos.lerp(end_pos, eased)
		var sc: float = lerpf(0.4, 1.0, eased) * PANEL_SIZE_M
		var alpha: float = clampf(t * 2.0, 0.0, 1.0) * fade * 0.55
		var verts: Array = []
		for k in range(6):
			var pa: float = TAU * float(k) / 6.0 - PI * 0.5
			verts.append(center + Vector3(cos(pa) * sc, sin(pa) * sc, 0.0))
		for k in range(1, 5):
			_overlay_mesh.surface_set_color(Color(COL_MID, alpha))
			_overlay_mesh.surface_add_vertex(verts[0])
			_overlay_mesh.surface_set_color(Color(COL_MID, alpha))
			_overlay_mesh.surface_add_vertex(verts[k])
			_overlay_mesh.surface_set_color(Color(COL_MID, alpha))
			_overlay_mesh.surface_add_vertex(verts[k + 1])
	_overlay_mesh.surface_end()
	# hex 외곽선 (vertex 공유 loop)
	for i in range(6):
		var local_age: float = _dome_age - delays[i]
		if local_age < 0.0:
			continue
		var t: float = clampf(local_age / SNAP_DUR, 0.0, 1.0)
		var eased: float = 1.0 - pow(1.0 - t, 3.0)
		var p2: Vector2 = positions[i]
		var start_pos: Vector3 = Vector3(p2.x * (PANEL_DIST_M * 1.8), center_y + p2.y * (PANEL_DIST_M * 1.8), 0.0)
		var end_pos: Vector3 = Vector3(p2.x * PANEL_DIST_M, center_y + p2.y * PANEL_DIST_M, 0.0)
		var center: Vector3 = start_pos.lerp(end_pos, eased)
		var sc: float = lerpf(0.4, 1.0, eased) * PANEL_SIZE_M
		var alpha: float = clampf(t * 2.0, 0.0, 1.0) * fade * 0.9
		var outline_verts := PackedVector3Array()
		for k in range(6):
			var pa: float = TAU * float(k) / 6.0 - PI * 0.5
			outline_verts.append(center + Vector3(cos(pa) * sc, sin(pa) * sc, 0.0))
		_add_thick_loop(_overlay_mesh, outline_verts, Vector3.FORWARD, LINE_THICK, Color(COL_HOT, alpha))
