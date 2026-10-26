extends Node
## Injected only by tools/run_live_balance_checks.sh --rendered. macOS clamps the
## initial window position on-screen and GameSettings re-centers the window when
## it applies the resolution, so keep moving it to the bottom-right corner. Only
## a 2 px sliver stays visible: Godot stops drawing fully occluded macOS windows,
## so the window cannot go entirely off-screen. Captures keep their size, but the
## window no longer covers the desktop or takes the developer's clicks.
const VISIBLE_SLIVER := 2

func _ready() -> void:
	if OS.get_environment("STSL_RENDER_OFFSCREEN") != "1" or DisplayServer.get_name() == "headless":
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	var screen := DisplayServer.window_get_current_screen()
	var corner := DisplayServer.screen_get_position(screen) + DisplayServer.screen_get_size(screen) - Vector2i(VISIBLE_SLIVER, VISIBLE_SLIVER)
	if DisplayServer.window_get_position() != corner:
		DisplayServer.window_set_position(corner)
