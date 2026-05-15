# scenes/vfx/blood_spray.gd
# 피 분출 VFX — ui_sample/vfx/Slash Attack VFX.html 의 blood spray 부분만 재현.
# 기존 slash_particle.tscn 은 그대로 두고, slash 명중 시 battle_scene이 추가로 발동한다.
# .new() → add_child → play(target, target). 노드는 position (0,0)으로 add_child.
# 피는 어두운 빨강 — 가산이면 안 보이므로 일반 블렌드(노드 기본)로 그린다.
extends Node2D

const COL_BLOOD      := Color(0.757, 0.102, 0.102) # #c11a1a — 갓 튄 피
const COL_BLOOD_DARK := Color(0.522, 0.043, 0.043) # 마르며 어두워진 피

# 개수/타이밍 — 이 상수만 만지면 된다.
const BLOOD_COUNT     := 55    # 작은 핏방울
const BLOOD_BIG_COUNT := 14    # 큰 핏방울
const PSPEED          := 60.0  # HTML(dt*0.06) → Godot(delta*60) 환산 계수

## 빔 VFX와 인터페이스 통일용 — 피 분출 VFX는 emit하지 않는다.
signal screen_effect

var _particles: Array = []  # [{pos, vel, life, max_life, r, grav}]

# ── 타원 윤곽 점 (autoload 비의존 static — 단위 테스트 가능) ──
# 빠른 핏방울을 속도 방향으로 늘린 streak 로 그릴 때 사용.
static func ellipse_poly(center: Vector2, rx: float, ry: float, rot: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(n):
		var a := TAU * float(i) / float(n)
		out.append(center + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out

func _ready() -> void:
	set_process(false)

# 첫 인자(caster)는 무시 — 피는 피격 지점에서 분출.
# dir_angle 이 유효하면 그 방향(슬래시 베기 방향) 중심으로, 아니면 기본 위쪽으로 분출.
func play(_caster_pos: Vector2, target_pos: Vector2, dir_angle: float = INF) -> void:
	var base_ang: float = dir_angle if is_finite(dir_angle) else -PI / 2.0
	# 작은 핏방울
	for _i in range(BLOOD_COUNT):
		var a := base_ang + randf_range(-1.0, 1.0)
		var sp := 3.0 + randf() * 8.0
		_particles.append({
			"pos": target_pos, "vel": Vector2(cos(a) * sp, sin(a) * sp),
			"life": 0.0, "max_life": 0.6 + randf() * 0.9,
			"r": 1.6 + randf() * 2.2, "grav": 0.18,
		})
	# 큰 핏방울
	for _i in range(BLOOD_BIG_COUNT):
		var a := base_ang + randf_range(-0.9, 0.9)
		var sp := 4.0 + randf() * 5.0
		_particles.append({
			"pos": target_pos, "vel": Vector2(cos(a) * sp, sin(a) * sp),
			"life": 0.0, "max_life": 0.9 + randf() * 0.9,
			"r": 3.0 + randf() * 3.0, "grav": 0.22,
		})
	set_process(true)
	_run()

func _run() -> void:
	await get_tree().create_timer(2.5).timeout
	if is_inside_tree():
		queue_free()

func _process(delta: float) -> void:
	# 파티클 물리 (HTML frame() 포팅) — 수명 만료 시 제거
	var damp: float = pow(0.992, delta * 60.0)
	var alive: Array = []
	for p in _particles:
		p["life"] += delta
		if p["life"] >= p["max_life"]:
			continue
		p["pos"] += p["vel"] * delta * PSPEED
		p["vel"].y += p["grav"] * delta * PSPEED
		p["vel"] *= damp
		alive.append(p)
	_particles = alive
	queue_redraw()

func _draw() -> void:
	for p in _particles:
		var k: float = p["life"] / p["max_life"]
		var a: float = 0.95 * (1.0 - k)
		var col := Color(
			lerpf(COL_BLOOD.r, COL_BLOOD_DARK.r, k),
			lerpf(COL_BLOOD.g, COL_BLOOD_DARK.g, k),
			lerpf(COL_BLOOD.b, COL_BLOOD_DARK.b, k), a)
		var pr: float = p["r"]
		var vel: Vector2 = p["vel"]
		# 빠른 핏방울은 속도 방향으로 늘어난 streak, 느린 건 둥근 방울
		if vel.length() > 2.0:
			draw_colored_polygon(ellipse_poly(p["pos"], pr * 1.6, pr * 0.7, vel.angle(), 10), col)
		else:
			draw_circle(p["pos"], pr, col)
