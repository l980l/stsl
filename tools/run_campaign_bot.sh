#!/usr/bin/env bash
# Creates a fresh project/user directory; never launches the bot against player saves.
set -euo pipefail
# Parse the workflow before launching the long-lived engine. Shells otherwise
# resume reading a changed script at a stale byte offset after the engine exits.
main() {
repo_path="$(cd "$(dirname "$0")/.." && pwd)"
godot_bin="${GODOT_BIN:-/Applications/Godot_mono.app/Contents/MacOS/Godot}"
if [[ ! -x "$godot_bin" ]]; then
  godot_bin="$(command -v godot || true)"
fi
if [[ -z "$godot_bin" || ! -x "$godot_bin" ]]; then
  echo 'Godot not found. Set GODOT_BIN to its executable.' >&2
  exit 2
fi
test_project="$(mktemp -d /tmp/STSL-campaign-bot-XXXXXX)"
test_name="$(basename "$test_project")"
artifact_dir="$repo_path/log/campaign-bot/$test_name"
mkdir -p "$artifact_dir"
# Mechanical config rewrite of a COPY, before any autoload can touch user://.
awk -v name="$test_name" '
  /^config\/use_custom_user_dir=/ || /^config\/custom_user_dir_name=/ { next }
  { print }
  /^\[application\]$/ {
    print "config/use_custom_user_dir=true"
    print "config/custom_user_dir_name=\"" name "\""
  }
' "$repo_path/project.godot" > "$test_project/project.godot"
for directory in "$repo_path"/* "$repo_path"/.godot; do
  if [[ -d "$directory" ]]; then
    ln -s "$directory" "$test_project/$(basename "$directory")"
  fi
done
for asset_file in icon.svg icon.svg.import; do
  if [[ -f "$repo_path/$asset_file" ]]; then
    ln -s "$repo_path/$asset_file" "$test_project/$asset_file"
  fi
done
headless_mode=0
# Silence from engine startup, including autoloads before the bot runs. Keep
# scenes and audio logic active, but never send test audio to the speakers.
engine_args=(--audio-driver Dummy --path "$test_project" -s res://tools/campaign_bot.gd -- --report="$artifact_dir/report.json")
actual_report="$artifact_dir/report.json"
for argument in "$@"; do
  if [[ "$argument" == "--headless" ]]; then
    headless_mode=1
  else
    if [[ "$argument" == --report=* ]]; then
      actual_report="${argument#--report=}"
      if [[ "$actual_report" != /* ]]; then
        echo '--report must be an absolute filesystem path.' >&2
        exit 2
      fi
    fi
    engine_args+=("$argument")
  fi
done
if [[ "$headless_mode" == 1 ]]; then
  engine_args=(--headless "${engine_args[@]}")
fi
export STSL_BOT_SOURCE_COMMIT="$(git -C "$repo_path" rev-parse HEAD)"
export STSL_BOT_SOURCE_DIRTY="$(git -C "$repo_path" status --porcelain | wc -l | tr -d ' ')"
export STSL_BOT_SOURCE_HASH="$(find "$repo_path/autoload" "$repo_path/resources" "$repo_path/scenes" "$repo_path/tools" -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.csv' \) -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
export STSL_BOT_GAMEPLAY_HASH="$(find "$repo_path/autoload" "$repo_path/resources" "$repo_path/scenes" -type f \( -name '*.gd' -o -name '*.tscn' -o -name '*.csv' \) -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}')"
echo "Isolated test project: $test_project"
echo "Default report: $artifact_dir/report.json"
set +e
"$godot_bin" "${engine_args[@]}" 2>&1 | tee "$artifact_dir/engine.log"
engine_status=${PIPESTATUS[0]}
set -e
# Godot can exit 0 when the entry script failed to parse. Never call that success.
if rg -q 'SCRIPT ERROR:|^ERROR:' "$artifact_dir/engine.log"; then
  echo "Engine errors recorded in $artifact_dir/engine.log" >&2
  exit 2
fi
if [[ ! -s "$actual_report" ]]; then
  echo "Bot produced no report: $actual_report" >&2
  exit 2
fi
exit "$engine_status"
}
main "$@"
