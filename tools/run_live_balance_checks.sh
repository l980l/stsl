#!/usr/bin/env bash
# Silent, isolated production-unit checks; never loads the player's user://.
set -euo pipefail
repo_path="$(cd "$(dirname "$0")/.." && pwd)"
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
' "$repo_path/project.godot" > "$task_project/project.godot"
for directory in "$repo_path"/* "$repo_path"/.godot; do
  if [[ -d "$directory" ]]; then
    ln -s "$directory" "$task_project/$(basename "$directory")"
  fi
done
display_args=(--headless)
if [[ "${1:-}" == "--rendered" ]]; then display_args=(); shift; fi
if [[ "$#" == 0 ]]; then set -- run_small_number_live; fi
for suite in "$@"; do
  if [[ ! "$suite" =~ ^[a-zA-Z0-9_]+$ ]]; then exit 2; fi
  "$godot_bin" ${display_args[@]+"${display_args[@]}"} --audio-driver Dummy --path "$task_project" \
    -s "res://tests/$suite.gd" > "$artifact_dir/$suite.log" 2>&1
  tail -5 "$artifact_dir/$suite.log"
  if rg -q 'SCRIPT ERROR:|^ERROR:' "$artifact_dir/$suite.log"; then exit 2; fi
done
printf 'Reports: %s\n' "$artifact_dir"
