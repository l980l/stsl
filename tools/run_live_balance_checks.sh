#!/usr/bin/env bash
# Silent, isolated production-unit checks; never loads the player's user://.
set -euo pipefail
repo_path="$(cd "$(dirname "$0")/.." && pwd)"
export STSL_BOT_SOURCE_COMMIT="${STSL_BOT_SOURCE_COMMIT:-$(git -C "$repo_path" rev-parse HEAD)}"
if [[ -z "${STSL_BOT_SOURCE_DIRTY:-}" ]]; then
  STSL_BOT_SOURCE_DIRTY=0
  if [[ -n "$(git -C "$repo_path" status --porcelain)" ]]; then STSL_BOT_SOURCE_DIRTY=1; fi
  export STSL_BOT_SOURCE_DIRTY
fi
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
task_project="$(mktemp -d /tmp/STSL-tutorial-validation-live-XXXXXX)"
artifact_dir="$repo_path/log/live-balance/$(basename "$task_project")"
mkdir -p "$artifact_dir"
awk -v name="$(basename "$task_project")" '
  /^config\/use_custom_user_dir=/ || /^config\/custom_user_dir_name=/ { next }
  { print }
  /^\[application\]$/ {
    print "config/use_custom_user_dir=true"
    print "config/custom_user_dir_name=\"" name "\""
  }
  /^\[autoload\]$/ {
    print "OffscreenWindow=\"*res://tools/offscreen_window.gd\""
  }
  /^\[display\]$/ {
    # Rendered checks must not steal focus or mouse input from the developer.
    print "window/size/no_focus=true"
    print "window/size/borderless=true"
  }
' "$repo_path/project.godot" > "$task_project/project.godot"
for directory in "$repo_path"/* "$repo_path"/.godot; do
  if [[ -d "$directory" ]]; then
    ln -s "$directory" "$task_project/$(basename "$directory")"
  fi
done
display_args=(--headless)
if [[ "${1:-}" == "--rendered" ]]; then
  # Real rendering, but tools/offscreen_window.gd moves the window off-screen.
  display_args=()
  export STSL_RENDER_OFFSCREEN="${STSL_RENDER_OFFSCREEN:-1}"
  shift
  # Godot activates itself on macOS launch; remember the developer's app to hand focus back.
  if [[ "$(uname)" == "Darwin" ]]; then
    return_app_id="$(osascript -e 'id of application (path to frontmost application as text)' 2>/dev/null || true)"
  fi
fi
# While Godot starts, give focus back whenever it takes it (window creation, resolution apply).
return_focus() {
  local pid="$1" i
  for ((i = 0; i < 100; i++)); do
    kill -0 "$pid" 2>/dev/null || return 0
    if [[ "$(osascript -e 'tell application "System Events" to get unix id of first process whose frontmost is true' 2>/dev/null)" == "$pid" ]]; then
      osascript -e "tell application id \"$return_app_id\" to activate" >/dev/null 2>&1 || true
    fi
    sleep 0.1
  done
}
if [[ "$#" == 0 ]]; then set -- run_small_number_live; fi
for suite in "$@"; do
  if [[ ! "$suite" =~ ^[a-zA-Z0-9_]+$ ]]; then exit 2; fi
  "$godot_bin" ${display_args[@]+"${display_args[@]}"} --audio-driver Dummy --path "$task_project" \
    -s "res://tests/$suite.gd" > "$artifact_dir/$suite.log" 2>&1 &
  godot_pid=$!
  if [[ -n "${return_app_id:-}" ]]; then return_focus "$godot_pid" & fi
  wait "$godot_pid"
  tail -5 "$artifact_dir/$suite.log"
  if rg -q 'SCRIPT ERROR:|^ERROR:' "$artifact_dir/$suite.log"; then exit 2; fi
done
printf 'Reports: %s\n' "$artifact_dir"
