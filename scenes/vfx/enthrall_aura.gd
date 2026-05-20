# scenes/vfx/enthrall_aura.gd
# 반함(enthrall) 상태 표시 VFX — 머리 위로 커다란 하트가 0.5초마다 솟아오름.
# 하트 윤곽·색은 infatuation VFX 재사용 (별도 디자인 아님).
# 두 가지 모드 (stun_stars 와 동일 인터페이스):
#   - 기본: play() 후 ONESHOT_TIME 만 표시되고 자동 free (vfx_preview 일회성).
#   - persistent: set_persistent(true) + set_target_node(node) — 노드 따라다니며 stop() 까지 무한 지속.
extends Node2D

const Infatuation = preload("res://scenes/vfx/infatuation.gd")  # heart_shape() 재사용

## 빔 VFX 와 인터페이스 통일용 — 하트 오라는 emit 하지 않는다.
signal screen_effect

const HEAD_OFFSET_Y := -100.0  # 타겟 머리 위 위치(px)
const SPAWN_INTERVAL := 0.5    # 하트 생성 간격(s)
const HEART_LIFE := 1.3        # 하트 1개 수명(s)
const HEART_SIZE := 34.0       # 커다란 하트 (반지름 스케일)
const RISE := 46.0             # 하트가 떠오르는 높이(px)
const FADE_TIME := 0.3
const ONESHOT_TIME := 2.0      # 일회성 모드 표시 시간(s)
const COL_HEART := Color(1.0, 0.296, 0.376)  # #ff4b60 — infatuation 하트색

var _target := Vector2.ZERO
var _follow_node: Node2D = null
var _custom_head_y: float = HEAD_OFFSET_Y
var _persistent: bool = false
var _stopping: bool = false
var _stop_age: float = 0.0
var _age: float = -1.0
var _spawn_acc: float = 0.0
var _hearts: Array = []   # {ox: float, life: float, sway: float}
var _heart_pts: PackedVector2Array

func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	_heart_pts = Infatuation.heart_shape()
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

# 첫 인자(caster) 무시 — 하트 오라는 타겟 머리 위에서만 표시
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	_spawn_acc = SPAWN_INTERVAL  # 첫 하트 즉시 생성
	set_process(true)
	if not _persistent:
		await get_tree().create_timer(ONESHOT_TIME).timeout
		if is_inside_tree():
			stop()

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
	# stop 전까지만 새 하트 생성
	else:
		_spawn_acc += delta
		if _spawn_acc >= SPAWN_INTERVAL:
			_spawn_acc -= SPAWN_INTERVAL
			_hearts.append({"ox": randf_range(-14.0, 14.0), "life": 0.0, "sway": randf() * TAU})
	# 하트 수명 갱신
	var live: Array = []
	for h in _hearts:
		h["life"] += delta
		if h["life"] < HEART_LIFE:
			live.append(h)
	_hearts = live
	queue_redraw()

func _draw() -> void:
	if _age < 0.0:
		return
	var head := _target + Vector2(0.0, _custom_head_y)
	var gfade := 1.0
	if _persistent:
		gfade = clampf(_age / 0.2, 0.0, 1.0)  # persistent — fade in 0.2s
	if _stopping:
		gfade *= clampf(1.0 - _stop_age / FADE_TIME, 0.0, 1.0)
	if gfade <= 0.0:
		return
	for h in _hearts:
		var k: float = h["life"] / HEART_LIFE
		var rise: float = -k * RISE
		var sway: float = sin((k * 2.0 + h["sway"]) * PI) * 7.0
		var pos: Vector2 = head + Vector2(h["ox"] + sway, rise)
		# alpha — 빠른 페이드인, 후반 페이드아웃
		var a: float = 1.0
		if k < 0.15:
			a = k / 0.15
		elif k > 0.55:
			a = clampf(1.0 - (k - 0.55) / 0.45, 0.0, 1.0)
		a *= gfade
		if a <= 0.0:
			continue
		var sz: float = HEART_SIZE * clampf(k / 0.12, 0.45, 1.0)  # 팝인 스케일
		# 헤일로
		draw_circle(pos, sz * 1.35, Color(COL_HEART.r, COL_HEART.g, COL_HEART.b, 0.22 * a))
		draw_circle(pos, sz * 0.7, Color(COL_HEART.r, COL_HEART.g, COL_HEART.b, 0.38 * a))
		# 하트 본체
		var poly := PackedVector2Array()
		for v in _heart_pts:
			poly.append(pos + v * sz)
		draw_colored_polygon(poly, Color(COL_HEART, a))
