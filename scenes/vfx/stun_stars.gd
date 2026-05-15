# scenes/vfx/stun_stars.gd
# 스턴 표시 VFX — 머리 위에 5각 별 3개가 회전. 추후 stun 상태이상 적용 시 발동 예정.
# .new() → add_child → play(target, target). caster 인자는 무시된다.
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
extends Node2D

const COL_HIT_RING := Color(1.0, 0.816, 0.416)  # #ffd06a — 황금 별

# 위치/크기/타이밍 — 이 상수만 만지면 된다.
const HEAD_OFFSET_Y := -120.0  # 타겟 위로 별 무리 위치(px)
const ORBIT_RADIUS  := 22.0    # 회전 궤도 반경(px)
const STAR_OUTER    := 9.0     # 별 바깥 반경
const STAR_INNER    := 4.0     # 별 안쪽 반경
const ROT_SPEED     := 4.5     # rad/s — 약 1.4초 한 바퀴
const STUN_TIME     := 2.0     # 표시 지속 시간(s)

## 빔 VFX와 인터페이스 통일용 — 스턴 표시는 emit하지 않는다.
signal screen_effect

var _target := Vector2.ZERO
var _age := -1.0

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
	# 가산 블렌드 — 황금 별이 어두운 배경에서 빛남
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = m
	set_process(false)

# 첫 인자(caster)는 무시 — 스턴 별은 타겟 머리 위에서만 표시
func play(_caster_pos: Vector2, target_pos: Vector2) -> void:
	_target = target_pos
	_age = 0.0
	set_process(true)
	_run()

func _run() -> void:
	await get_tree().create_timer(STUN_TIME + 0.5).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	_age += delta
	queue_redraw()

func _draw() -> void:
	if _age < 0.0:
		return
	var fade := 1.0
	if _age > STUN_TIME - 0.3:
		fade = clampf((STUN_TIME - _age) / 0.3, 0.0, 1.0)
	if fade <= 0.0:
		return
	var head := _target + Vector2(0.0, HEAD_OFFSET_Y)
	for i in range(3):
		var phase := TAU * float(i) / 3.0
		var ang := _age * ROT_SPEED + phase
		var sp := head + Vector2(cos(ang), sin(ang)) * ORBIT_RADIUS
		draw_colored_polygon(star_poly(sp, STAR_OUTER, STAR_INNER, 5, 0.0),
			Color(COL_HIT_RING, 0.9 * fade))
