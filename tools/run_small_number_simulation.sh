#!/usr/bin/env bash
# Paired balance experiment. No player saves/audio or performance instrumentation.
set -euo pipefail
export STSL_LEGACY_COMBAT=1

main() {
  local repo_path godot_bin task_project task_name artifact_dir revision dirty
  repo_path="$(cd "$(dirname "$0")/.." && pwd)"
  godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
  if [[ ! -x "$godot_bin" ]]; then
    echo 'Set GODOT_BIN to an executable Godot binary.' >&2
    return 2
  fi
  task_project="$(mktemp -d /tmp/STSL-tutorial-validation-simulation-XXXXXX)"
  task_name="$(basename "$task_project")"
  mkdir -p "$repo_path/log/small-number-simulation"
  artifact_dir="$(mktemp -d "$repo_path/log/small-number-simulation/run-XXXXXX")"
  awk -v name="$task_name" '
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
  revision="$(git -C "$repo_path" rev-parse HEAD)"
  dirty="$(git -C "$repo_path" status --porcelain | wc -l | tr -d ' ')"
  export STSL_BOT_SOURCE_COMMIT="$revision"
  export STSL_BOT_SOURCE_DIRTY="$dirty"
  echo "Isolated project: $task_project"
  echo "Reports: $artifact_dir"
  local argument
  # macOS Bash 3 treats an empty array as unset under nounset.
  local instant_args=(--power-turns=0)
  for argument in "$@"; do
    case "$argument" in
      --weak|--vulnerable|--power-turns=*|--poison-ticks=*) instant_args+=("$argument") ;;
    esac
  done
  "$godot_bin" --headless --audio-driver Dummy --path "$task_project" \
    --script res://tools/evaluate_small_numbers.gd --log-file "$artifact_dir/instant.log" \
    -- --output="$artifact_dir/instant.json" --revision="$revision" --dirty="$dirty" "${instant_args[@]}"
  "$godot_bin" --headless --audio-driver Dummy --path "$task_project" \
    --script res://tools/simulate_small_number_battles.gd --log-file "$artifact_dir/battles.log" \
    -- --output="$artifact_dir/battles.json" "$@"
  for report in instant battles; do
    if [[ ! -s "$artifact_dir/$report.json" ]] || rg -q 'SCRIPT ERROR:|^ERROR:' "$artifact_dir/$report.log"; then
      echo "Invalid $report run; inspect $artifact_dir/$report.log" >&2
      return 2
    fi
  done
}

main "$@"
