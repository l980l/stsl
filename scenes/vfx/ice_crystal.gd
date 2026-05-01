extends Node2D

@onready var _poly: Polygon2D = $CrystalPoly
@onready var _outline: Line2D = $CrystalOutline
@onready var _flash: Sprite2D = $ShatterFlash
@onready var _shards: GPUParticles2D = $IceShards

func _ready() -> void:
	_poly.polygon = _crystal_points()
	_outline.points = _crystal_outline()
	_poly.modulate.a = 0.0
	_outline.modulate.a = 0.0
	_flash.modulate.a = 0.0

func burst() -> void:
	# 초기 상태
	_poly.scale = Vector2(0.3, 0.3)
	_outline.scale = Vector2(0.3, 0.3)
	_poly.modulate.a = 0.0
	_outline.modulate.a = 0.0
	_flash.scale = Vector2(0.5, 0.5)
	_flash.modulate.a = 0.0

	var tw := get_tree().create_tween()
	# Phase 1: 결정 등장 (0 ~ 0.18s)
	tw.set_parallel(true)
	tw.tween_property(_poly, "modulate:a", 0.85, 0.15)
	tw.tween_property(_outline, "modulate:a", 1.0, 0.15)
	tw.tween_property(_poly, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_outline, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(false)
	# Hold (0.18 ~ 0.6s) — 안개 퍼지는 동안 결정은 가만히
	tw.tween_interval(0.42)
	# Phase 2: 깨짐 — 플래시 + 결정 페이드 + 파편 분출
	tw.tween_callback(_shatter)
	tw.set_parallel(true)
	tw.tween_property(_poly, "modulate:a", 0.0, 0.10)
	tw.tween_property(_outline, "modulate:a", 0.0, 0.10)
	tw.tween_property(_flash, "modulate:a", 1.0, 0.05)
	tw.tween_property(_flash, "scale", Vector2(2.0, 2.0), 0.2)
	tw.set_parallel(false)
	tw.tween_interval(0.05)
	tw.tween_property(_flash, "modulate:a", 0.0, 0.15)

func _shatter() -> void:
	if _shards:
		_shards.restart()

func _crystal_points() -> PackedVector2Array:
	# 수직 결정 (위로 뾰족한 6각형)
	return PackedVector2Array([
		Vector2(0, -34),
		Vector2(18, -10),
		Vector2(18, 18),
		Vector2(0, 32),
		Vector2(-18, 18),
		Vector2(-18, -10),
	])

func _crystal_outline() -> PackedVector2Array:
	var pts := _crystal_points()
	var result := PackedVector2Array(pts)
	result.append(pts[0])
	return result
