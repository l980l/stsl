extends SceneTree

const HELPERS := preload("res://scenes/vfx/gpu_particle_helpers.gd")

var _checks := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_failed += 1
		printerr("FAIL: ", label)

func _run() -> void:
	var points := HELPERS._heart_unit_pts()
	var matching_mask := true
	for y in 64:
		for x in 64:
			var point := Vector2(float(x) - 31.5, float(y) - 31.5)
			if Geometry2D.is_point_in_polygon(point, points) != HELPERS._point_in_polygon(point, points):
				matching_mask = false
	_check(matching_mask, "native heart mask matches legacy ray-cast at all 4,096 texels")

	HELPERS.release_cached_textures()
	var actual := HELPERS.heart_tex().get_image().get_data()
	var expected := _legacy_heart_texture(points).get_data()
	_check(actual == expected, "native heart texture pixels match legacy generator")
	HELPERS.release_cached_textures()
	print("GPU particle helper regression: ", _checks, " checks, ", _failed, " failures")
	quit(0 if _failed == 0 else 1)

func _legacy_heart_texture(points: PackedVector2Array) -> Image:
	var col_inner := Color(1.0, 0.604, 0.831)
	var col_outline := Color(1.0, 0.949, 0.976)
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var inside_mask := PackedByteArray()
	inside_mask.resize(64 * 64)
	for y in 64:
		for x in 64:
			var point := Vector2(float(x) - 31.5, float(y) - 31.5)
			if HELPERS._point_in_polygon(point, points):
				inside_mask[y * 64 + x] = 1
				image.set_pixel(x, y, col_inner)
	for y in 64:
		for x in 64:
			if inside_mask[y * 64 + x] == 0:
				continue
			var is_edge := false
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					if dx == 0 and dy == 0:
						continue
					var nx := x + dx
					var ny := y + dy
					if nx < 0 or nx >= 64 or ny < 0 or ny >= 64:
						continue
					if inside_mask[ny * 64 + nx] == 0:
						is_edge = true
						break
				if is_edge:
					break
			if is_edge:
				image.set_pixel(x, y, col_outline)
	return image
