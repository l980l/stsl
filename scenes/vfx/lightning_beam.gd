# scenes/vfx/lightning_beam.gd
# 시전자→타겟 번개 볼트 VFX — ui_sample/Lightning Attack VFX.html 재현.
# battle_scene이 lightning damage_type 공격 시 .new() → add_child → play(caster, target).
# 노드는 position (0,0)으로 add_child해야 한다 (좌표를 global로 받아 그대로 그림).
extends Node2D

# 파티클 갯수 — GameSettings.particle_count_scale 적용 (하/중/상 = 0.25/0.5/1.0배)
var _particle_scale_override: float = -1.0  # vfx_preview 3-way 비교용 (음수=GameSettings)

func _pcount(n: int) -> int:
	if _particle_scale_override > 0.0:
		return maxi(1, int(round(n * _particle_scale_override)))
	var gs := get_node_or_null("/root/GameSettings")
	return n if gs == null else maxi(1, int(round(n * gs.particle_count_scale())))

const COL_GLOW   := Color(0.486, 0.769, 1.0)  # #7cc4ff — 외곽 글로우
const COL_MID    := Color(0.812, 0.902, 1.0)  # #cfe6ff — 중간
const COL_CORE   := Color(1, 1, 1)            # 흰 코어
const COL_BRANCH := Color(0.706, 0.863, 1.0)  # #b4dcff — 가지

# 구체 텍스처는 256×256 라디얼 그라데이션 — scale 0.16 ≈ 41px. 크기 조정은 이 상수만.
const ORB_CHARGE_START := 0.16  # 차지 구체 시작
const ORB_CHARGE_FULL  := 0.40  # 차지 완료
const ORB_FIRE         := 0.72  # 발사 폭발
const IMPACT_START     := 0.20  # 임팩트 팝 시작
const IMPACT_MID       := 0.80  # 임팩트 중간
const IMPACT_END       := 1.60  # 임팩트 잔광 끝
const IMPACT_DELAY     := 0.55  # 차지 종료 = 첫 볼트 명중 시점 (battle_manager 동기화용)

## 발사 순간 화면 플래시·흔들림 요청 (battle_scene이 수신)
signal screen_effect

var _caster: Vector2 = Vector2.ZERO
var _target: Vector2 = Vector2.ZERO
var _active_bolts: Array = []  # [{bolt: Dictionary, life: float, dur: float}]
var _charge_orb: Sprite2D
var _impact: Sprite2D
var _sparks: CPUParticles2D

# ── 지그재그 볼트 생성 (HTML makeBolt 1:1 포팅) ───────────────
# autoload 비의존 static — 단위 테스트 가능. 반환 점 개수 = segs+1, 양 끝점 == a/b.
static func make_bolt(a: Vector2, b: Vector2, segs: int, offset: float, branches: int) -> Dictionary:
	var pts := PackedVector2Array([a])
	var d: Vector2 = b - a
	var length: float = maxf(d.length(), 1.0)
	var perp := Vector2(-d.y / length, d.x / length)  # 수직 단위벡터
	for i in range(1, segs):
		var t: float = float(i) / float(segs)
		var base: Vector2 = a + d * t
		# 끝으로 갈수록 오프셋 감쇠 (HTML: offset * (1 - abs(t-0.5)*1.4))
		var k: float = randf_range(-1.0, 1.0) * offset * (1.0 - absf(t - 0.5) * 1.4)
		pts.append(base + perp * k)
	pts.append(b)
	var branch_list: Array = []
	# branches 는 make_bolt 호출자가 결정 (static 함수라 _pcount 호출 불가) — 호출처에서 _pcount 적용
	for _i in range(branches):
		var idx: int = 3 + randi() % maxi(1, pts.size() - 6)
		var start: Vector2 = pts[idx]
		var ang: float = (b - a).angle() + randf_range(-0.8, 0.8)
		var blen: float = randf_range(60.0, 180.0)
		var ex: Vector2 = start + Vector2(cos(ang), sin(ang)) * blen
		branch_list.append(make_bolt(start, ex, 8, 18.0, 0)["main"])
	return {"main": pts, "branches": branch_list}

# 라디얼 그라데이션 구체 텍스처 — orb.png는 배경이 불투명해 검은 박스로 보이므로 코드 생성.
static func _make_orb_tex(c_core: Color, c_mid: Color, c_edge: Color) -> GradientTexture2D:
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.42, 0.72, 1.0])
	grad.colors = PackedColorArray([c_core, c_mid, c_edge, Color(c_edge.r, c_edge.g, c_edge.b, 0.0)])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 256
	tex.height = 256
	return tex

func _ready() -> void:
	# 모든 레이어를 가산 블렌드로 — Godot엔 shadowBlur가 없어 굵은 반투명 + 가산으로 글로우 근사
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	set_process(false)

	var orb_tex := _make_orb_tex(COL_CORE, COL_MID, COL_GLOW)

	_charge_orb = Sprite2D.new()
	_charge_orb.texture = orb_tex
	_charge_orb.modulate = Color(1, 1, 1, 0.0)  # 알파만 제어 — 색은 텍스처가 가짐
	_charge_orb.scale = Vector2(ORB_CHARGE_START, ORB_CHARGE_START)
	add_child(_charge_orb)

	_impact = Sprite2D.new()
	_impact.texture = orb_tex
	_impact.modulate = Color(1, 1, 1, 0.0)
	_impact.scale = Vector2(IMPACT_START, IMPACT_START)
	add_child(_impact)

	_sparks = CPUParticles2D.new()
	_sparks.emitting = false
	_sparks.one_shot = true
	_sparks.explosiveness = 1.0
	_sparks.amount = 14
	_sparks.lifetime = 0.8
	_sparks.spread = 180.0
	_sparks.initial_velocity_min = 80.0
	_sparks.initial_velocity_max = 240.0
	_sparks.gravity = Vector2.ZERO
	_sparks.scale_amount_min = 1.5
	_sparks.scale_amount_max = 3.0
	_sparks.color = COL_MID
	add_child(_sparks)

# caster_pos / target_pos 는 global 좌표 (노드가 (0,0)에 있다는 전제)
func play(caster_pos: Vector2, target_pos: Vector2) -> void:
	_caster = caster_pos
	_target = target_pos
	_charge_orb.position = caster_pos
	_impact.position = target_pos
	_sparks.position = target_pos
	_run()

func _run() -> void:
	# 1) 차지 — 시전자 손의 구체가 부풀어 오름 (0.55s)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_charge_orb, "modulate:a", 1.0, 0.15)
	tw.parallel().tween_property(_charge_orb, "scale", Vector2(ORB_CHARGE_FULL, ORB_CHARGE_FULL), 0.55)
	await get_tree().create_timer(0.55).timeout
	if not is_inside_tree():
		return
	# 2) 발사 — 구체 폭발 + 첫 볼트 + 화면 효과
	var tw2 := create_tween()
	tw2.tween_property(_charge_orb, "scale", Vector2(ORB_FIRE, ORB_FIRE), 0.15)
	tw2.parallel().tween_property(_charge_orb, "modulate:a", 0.0, 0.15)
	set_process(true)
	_spawn_bolts(5)
	screen_effect.emit()
	# 3) 임팩트 팝 + 스파크
	_impact.scale = Vector2(IMPACT_START, IMPACT_START)
	_impact.modulate.a = 1.0
	var twi := create_tween()
	twi.tween_property(_impact, "scale", Vector2(IMPACT_MID, IMPACT_MID), 0.1)
	twi.parallel().tween_property(_impact, "modulate:a", 0.0, 0.45)
	twi.tween_property(_impact, "scale", Vector2(IMPACT_END, IMPACT_END), 0.35)
	_sparks.restart()
	# 4) 지속 재타격 (HTML: 90ms 후 3개, 180ms 후 2개)
	await get_tree().create_timer(0.09).timeout
	if not is_inside_tree():
		return
	_spawn_bolts(3)
	await get_tree().create_timer(0.09).timeout
	if not is_inside_tree():
		return
	_spawn_bolts(2)
	# 5) 정리
	await get_tree().create_timer(1.0).timeout
	if is_inside_tree():
		queue_free()

func _spawn_bolts(n: int) -> void:
	for _i in range(_pcount(n)):
		_active_bolts.append({
			"bolt": make_bolt(_caster, _target, 20, 46.0, 3),
			"life": 1.0,
			"dur": randf_range(0.18, 0.26),
		})
	queue_redraw()

func _process(delta: float) -> void:
	var alive: Array = []
	for ab in _active_bolts:
		ab["life"] -= delta / ab["dur"]
		if ab["life"] > 0.0:
			alive.append(ab)
	_active_bolts = alive
	queue_redraw()
	if _active_bolts.is_empty():
		set_process(false)

func _draw() -> void:
	for ab in _active_bolts:
		# 깜빡임 (HTML: 0.6 + random*0.4)
		var a: float = clampf(ab["life"], 0.0, 1.0) * (0.6 + randf() * 0.4)
		var main: PackedVector2Array = ab["bolt"]["main"]
		# 3중 레이어: 외곽 글로우 → 중간 → 흰 코어
		draw_polyline(main, Color(COL_GLOW, 0.35 * a), 10.0, true)
		draw_polyline(main, Color(COL_MID, 0.85 * a), 4.5, true)
		draw_polyline(main, Color(COL_CORE, a), 1.6, true)
		for br in ab["bolt"]["branches"]:
			draw_polyline(br, Color(COL_BRANCH, 0.7 * a), 1.4, true)
