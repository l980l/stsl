extends Node2D

@onready var _poly: Polygon2D = $ShieldPoly
@onready var _outline: Line2D = $ShieldOutline

func _ready() -> void:
	_poly.polygon = _shield_points()
	_outline.points = _shield_outline()
	_poly.modulate.a = 0.0
	_outline.modulate.a = 0.0

func play_shield() -> void:
	_poly.scale = Vector2(0.2, 0.2)
	_outline.scale = Vector2(0.2, 0.2)
	_poly.modulate.a = 0.0
	_outline.modulate.a = 0.0

	var tw := get_tree().create_tween()
	tw.set_parallel(true)
	tw.tween_property(_poly, "modulate:a", 0.75, 0.1)
	tw.tween_property(_outline, "modulate:a", 1.0, 0.1)
	tw.tween_property(_poly, "scale", Vector2.ONE, 0.12)
	tw.tween_property(_outline, "scale", Vector2.ONE, 0.12)
	tw.set_parallel(false)
	tw.tween_interval(0.22)
	tw.set_parallel(true)
	tw.tween_property(_poly, "modulate:a", 0.0, 0.18)
	tw.tween_property(_outline, "modulate:a", 0.0, 0.18)

func _shield_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	var w := 28.0
	var top := -32.0
	var mid := 6.0
	var bot := 34.0
	var r := 7.0
	for i in 10:
		var a := deg_to_rad(180 + i * 9.0)
		pts.append(Vector2(-w + r + cos(a) * r, top + r + sin(a) * r))
	for i in 10:
		var a := deg_to_rad(270 + i * 9.0)
		pts.append(Vector2(w - r + cos(a) * r, top + r + sin(a) * r))
	pts.append(Vector2(w, mid))
	pts.append(Vector2(0, bot))
	pts.append(Vector2(-w, mid))
	return pts

func _shield_outline() -> PackedVector2Array:
	var pts := _shield_points()
	var result := PackedVector2Array(pts)
	result.append(pts[0])
	return result
