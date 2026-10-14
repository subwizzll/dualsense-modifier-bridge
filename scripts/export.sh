#!/usr/bin/env bash
# Pull live config from this Mac into the repo (run before copying to another machine).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HS_SRC="${HOME}/.hammerspoon/init.lua"
HS_DST="$ROOT/hammerspoon/init.lua"
# Bundle ID is still KevinTang.XboxControllerMapper (legacy name for ControllerKeys).
CK_PREFS_SRC="${HOME}/Library/Preferences/KevinTang.XboxControllerMapper.plist"
CK_PREFS_DST="$ROOT/controllerkeys/preferences/KevinTang.XboxControllerMapper.plist"
CK_PROFILES="$ROOT/controllerkeys/profiles"

echo "==> Exporting into $ROOT"

if [[ -f "$HS_SRC" ]]; then
  mkdir -p "$(dirname "$HS_DST")"
  cp "$HS_SRC" "$HS_DST"
  echo "    Hammerspoon init.lua"
else
  echo "WARN: $HS_SRC missing"
fi

if [[ -f "$CK_PREFS_SRC" ]]; then
  mkdir -p "$(dirname "$CK_PREFS_DST")"
  cp "$CK_PREFS_SRC" "$CK_PREFS_DST"
  echo "    ControllerKeys preferences plist"
else
  echo "WARN: ControllerKeys prefs missing (is the app installed?)"
fi

mkdir -p "$CK_PROFILES"
open "$CK_PROFILES"
[[ -d /Applications/ControllerKeys.app ]] && open -a ControllerKeys || true

cat <<EOF

ControllerKeys stores button mappings inside the app, not as a plain prefs file.
Export them manually:

  1. In ControllerKeys, select your DualSense profile
  2. Export Profile (profile menu / sidebar)
  3. Save the .json into:
       $CK_PROFILES

Then commit:

  cd "$ROOT"
  git add -A
  git commit -m "Update DualSense / Hammerspoon bridge config"

EOF

shopt -s nullglob
existing=("$CK_PROFILES"/*.json)
shopt -u nullglob
if ((${#existing[@]} > 0)); then
  echo "Profiles already in repo:"
  for p in "${existing[@]}"; do echo "  - $(basename "$p")"; done
else
  echo "No .json profiles in repo yet."
fi
