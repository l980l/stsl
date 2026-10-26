extends SceneTree

# Guards SacredTheme.FS_SMALL as the minimum UI text size (1920×1080 design).
# Literal sizes below it are rejected unless the line is tagged as a decorative
# glyph. Card faces are excluded: they are scaled as whole nodes and read at
# hover zoom, so their internal sizes are not screen pixels.
const ROOTS := ["res://scenes", "res://autoload"]
const EXCLUDED := ["res://scenes/debug", "res://scenes/card", "res://autoload/debug_manager.gd"]
const ORNAMENT_TAG := "장식 글리프"
const PATTERNS := [
	"\"font_size\", *(\\d+)\\)",            # add_theme_font_size_override / set_font_size
	"fit_text\\([^,]+, *[^,]+, *(\\d+)",    # LabelUtils.fit_text min_px
	"_make_label\\(.*\\), *(\\d+)\\)$",     # battle HUD label helper
]

var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var sacred: Node = root.get_node("SacredTheme")
	var floor_px: int = sacred.FS_SMALL
	var regexes: Array = []
	for p in PATTERNS:
		var re := RegEx.new()
		re.compile(p)
		regexes.append(re)
	for root_dir in ROOTS:
		for path in _scripts(root_dir):
			var lines := FileAccess.get_file_as_string(path).split("\n")
			for i in lines.size():
				var line: String = lines[i]
				if line.contains(ORNAMENT_TAG):
					continue
				for re in regexes:
					var m: RegExMatch = re.search(line)
					if m == null:
						continue
					if int(m.get_string(1)) < floor_px:
						failed += 1
						printerr("FAIL: %s:%d font size %s < %d" % [path, i + 1, m.get_string(1), floor_px])
					else:
						passed += 1
	var theme: Theme = sacred.theme
	for variant in ["EyebrowLabel", "SubLabel", "ToastLabel", "Button", "RoomButton"]:
		if theme.get_font_size("font_size", variant) < floor_px:
			failed += 1
			printerr("FAIL: theme %s font size below floor" % variant)
		else:
			passed += 1
	print("Font size floor: %d passed, %d failed" % [passed, failed])
	quit(1 if failed else 0)

func _scripts(dir_path: String) -> Array:
	var out: Array = []
	if dir_path in EXCLUDED:
		return out
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		var path := dir_path.path_join(f)
		if f.ends_with(".gd") and path not in EXCLUDED:
			out.append(path)
	for d in dir.get_directories():
		out.append_array(_scripts(dir_path.path_join(d)))
	return out
