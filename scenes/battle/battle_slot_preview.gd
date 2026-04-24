@tool
extends Node2D

const SLOT_W := 240
const SLOT_H := 280
const TOKEN_COLS := 6
const TOKEN_ROWS := 2
const TOKEN_TILE_W := 111
const TOKEN_TILE_H := 138
const TOKEN_TILE_GAP := 4

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var hero_fill  := Color(0.3, 0.6, 1.0, 0.15)
	var hero_line  := Color(0.3, 0.6, 1.0, 0.9)
	var enemy_fill := Color(1.0, 0.3, 0.3, 0.15)
	var enemy_line := Color(1.0, 0.3, 0.3, 0.9)

	for i in range(3):
		var marker: Marker2D = get_node_or_null("../HeroSlot%d" % (i + 1))
		if marker == null:
			continue
		var rect := Rect2(marker.position, Vector2(SLOT_W, SLOT_H))
		draw_rect(rect, hero_fill)
		draw_rect(rect, hero_line, false, 2.0)
		draw_string(ThemeDB.fallback_font, marker.position + Vector2(4, 18),
				"H%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, hero_line)

	for i in range(6):
		var marker: Marker2D = get_node_or_null("../EnemySlot%d" % (i + 1))
		if marker == null:
			continue
		var rect := Rect2(marker.position, Vector2(SLOT_W, SLOT_H))
		draw_rect(rect, enemy_fill)
		draw_rect(rect, enemy_line, false, 2.0)
		draw_string(ThemeDB.fallback_font, marker.position + Vector2(4, 18),
				"E%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, enemy_line)

	var summon_fill := Color(0.9, 0.8, 0.2, 0.12)
	var summon_line := Color(0.9, 0.8, 0.2, 0.8)
	var grid_w: int = TOKEN_COLS * TOKEN_TILE_W + (TOKEN_COLS - 1) * TOKEN_TILE_GAP
	var grid_h: int = TOKEN_ROWS * TOKEN_TILE_H + (TOKEN_ROWS - 1) * TOKEN_TILE_GAP
	for i in range(3):
		var marker: Marker2D = get_node_or_null("../SummonArea%d" % (i + 1))
		if marker == null:
			continue
		var origin := marker.position
		draw_rect(Rect2(origin, Vector2(grid_w, grid_h)), summon_fill)
		draw_rect(Rect2(origin, Vector2(grid_w, grid_h)), summon_line, false, 2.0)
		draw_string(ThemeDB.fallback_font, origin + Vector2(4, 18),
				"Summon%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, summon_line)
