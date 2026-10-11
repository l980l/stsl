class_name CharacterArtCache
extends RefCounted

const MAX_ENTRIES := 24

static var _textures: Dictionary = {}
static var _fifo_paths: Array[String] = []

# The exact actors already chosen for the next battle, not an entire chapter.
# Scene root names match character_placeholder's art ID conversion.
static func battle_paths(heroes: Array, enemies: Array) -> Array[String]:
	var paths: Array[String] = []
	for hero in heroes.slice(0, 3):
		var scene: PackedScene = hero.character_scene
		if scene != null:
			var id := String(scene.get_state().get_node_name(0)).to_snake_case()
			_append_existing(paths, "res://assets/art/heroes/%s.png" % id)
	for enemy in enemies:
		if enemy.character_scene == null:
			continue  # Runtime fallback node does not use an illustration.
		var parts: PackedStringArray = String(enemy.enemy_name).split(".")
		var id: String = "%s_%s" % [parts[1], parts[2]] if parts.size() >= 3 else String(enemy.enemy_name)
		_append_existing(paths, "res://assets/art/enemies/%s.png" % id)
		# Only phase art belonging to this selected encounter; no chapter scan.
		for phase in range(1, enemy.phase_thresholds.size() + 1):
			_append_existing(paths, "res://assets/art/enemies/%s_p%d.png" % [id, phase])
	return paths

static func _append_existing(paths: Array[String], path: String) -> void:
	if path not in paths and ResourceLoader.exists(path):
		paths.append(path)

static func get_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var cached: Texture2D = _textures.get(path)
	if cached != null:
		return cached
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	while _fifo_paths.size() >= MAX_ENTRIES:
		_textures.erase(_fifo_paths.pop_front())
	_textures[path] = texture
	_fifo_paths.append(path)
	return texture

static func clear() -> void:
	_textures.clear()
	_fifo_paths.clear()

static func size() -> int:
	return _fifo_paths.size()

static func max_entries() -> int:
	return MAX_ENTRIES

static func has_texture(path: String) -> bool:
	return _textures.has(path)
