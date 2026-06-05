# scenes/vfx/stun_stars.gd
# 스턴 표시 VFX — 머리 위에 5각 별 3개가 회전.
# 두 가지 모드:
#   - 기본: play() 후 STUN_TIME 만 표시되고 자동 free (일회성 burst — 기존 호환).
#   - persistent: set_persistent(true) + set_target_node(node) — 노드 따라다니며 stop() 호출까지 무한 지속.
extends Node2D

const COL_HIT_RING := Color(1.0, 0.816, 0.416)  # #ffd06a — 황금 별

const HEAD_OFFSET_Y := -120.0  # 타겟 위로 별 무리 위치(px)
const ORBIT_RADIUS_X := 28.0   # 타원 가로 반경
const ORBIT_RADIUS_Y := 11.0   # 타원 세로 반경 (squash ~0.4 — 머리 위 평평한 궤도)
const STAR_OUTER    := 9.0
const STAR_INNER    := 4.0
const ROT_SPEED     := 4.5     # rad/s — 약 1.4초 한 바퀴
const STUN_TIME     := 2.0     # 일회성 모드 표시 지속 시간(s)
const FADE_TIME     := 0.3

## 빔 VFX 와 인터페이스 통일용 — 스턴 표시는 emit 하지 않는다.
@warning_ignore("unused_signal")
signal screen_effect

var _target := Vector2.ZERO
var _age := -1.0
var _follow_node: Node2D = null
var _custom_head_y: float = HEAD_OFFSET_Y
var _persistent: bool = false
var _stopping: bool = false
var _stop_age: float = 0.0

# ── 별 윤곽 (autoload 비의존 static — 단위 테스트 가능) ──
static func star_poly(center: Vector2, outer_r: float, inner_r: float, points: int, rot: float) -> PackedVector2Array:
	var n := points * 2
	var out := PackedVector2Array()
	for i in range(n):
		var ang := TAU * float(i) / float(n) - PI * 0.5 + rot
		var r: float = outer_r if i % 2 == 0 else inner_r
		out.append(center + Vector2(cos(ang), sin(ang)) * r)
	return out

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	set_process(false)

# persistent 모드 — stop() 또는 follow 노드 죽음 시까지 표시 유지
func set_persistent(v: bool) -> void:
	_persistent = v

# 노드 따라다님 — 매 프레임 global_position 추적. 노드 free 되면 자동 cleanup.
func set_target_node(node: Node2D, head_offset_y: float = HEAD_OFFSET_Y) -> void:
	_follow_node = node
	_custom_head_y = head_offset_y

# persistent 모드 종료 — fade out 후 queue_free
func stop() -> void:
	if _stopping:
		return
	_stopping = true
	_stop_age = 0.0

# 첫 인자(caster) 무시 — 스턴 별은 타겟 머리 위에서만 표시
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	if not _persistent:
		_run_oneshot()

func _run_oneshot() -> void:
	await get_tree().create_timer(STUN_TIME + 0.5).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	if _follow_node != null:
		if is_instance_valid(_follow_node):
			_target = _follow_node.global_position
		else:
			queue_free()
			return
	_age += delta
	if _stopping:
		_stop_age += delta
		if _stop_age >= FADE_TIME:
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	if _age < 0.0:
		return
	var fade := 1.0
	if _persistent:
		# persistent — fade in 0.2s, stop() 시 fade out
		fade = clampf(_age / 0.2, 0.0, 1.0)
		if _stopping:
			fade *= clampf(1.0 - _stop_age / FADE_TIME, 0.0, 1.0)
	else:
		# 일회성 — 끝 0.3s fade
		if _age > STUN_TIME - 0.3:
			fade = clampf((STUN_TIME - _age) / 0.3, 0.0, 1.0)
	if fade <= 0.0:
		return
	var head := _target + Vector2(0.0, _custom_head_y)
	for i in range(3):
		var phase := TAU * float(i) / 3.0
		var ang := _age * ROT_SPEED + phase
		# 타원 궤도 — 가로 길게 세로 짧게 (머리 위 평평한 회전)
		var sp := head + Vector2(cos(ang) * ORBIT_RADIUS_X, sin(ang) * ORBIT_RADIUS_Y)
		draw_colored_polygon(star_poly(sp, STAR_OUTER, STAR_INNER, 5, 0.0),
			Color(COL_HIT_RING, 0.9 * fade))
