#!/usr/bin/env bash
# Install DualSense (ControllerKeys) + Hammerspoon modifier bridge on this Mac.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HS_SRC="$ROOT/hammerspoon/init.lua"
HS_DST="${HOME}/.hammerspoon/init.lua"
# Bundle ID is still KevinTang.XboxControllerMapper (legacy name for ControllerKeys).
# This plist is UI/onboarding/telemetry only — button maps live in exported profile JSON.
CK_PREFS_SRC="$ROOT/controllerkeys/preferences/KevinTang.XboxControllerMapper.plist"
CK_PREFS_DST="${HOME}/Library/Preferences/KevinTang.XboxControllerMapper.plist"
CK_PROFILES="$ROOT/controllerkeys/profiles"

echo "==> DualSense modifier bridge install"
echo "    repo: $ROOT"

if [[ ! -f "$HS_SRC" ]]; then
  echo "ERROR: missing $HS_SRC" >&2
  exit 1
fi

# --- Apps (optional via Homebrew) ---
if ! [[ -d /Applications/Hammerspoon.app ]]; then
  if command -v brew >/dev/null 2>&1; then
    echo "==> Installing Hammerspoon via Homebrew"
    brew install --cask hammerspoon
  else
    echo "WARN: Hammerspoon.app not found. Install from https://www.hammerspoon.org/ or brew install --cask hammerspoon"
  fi
fi

if ! [[ -d /Applications/ControllerKeys.app ]]; then
  echo "WARN: ControllerKeys.app not found."
  echo "      Install from https://kevintang.xyz/apps/controller-keys (paid app; not bundled here)."
fi

# --- Hammerspoon config ---
echo "==> Installing Hammerspoon config"
mkdir -p "${HOME}/.hammerspoon"
if [[ -f "$HS_DST" ]]; then
  backup="${HS_DST}.bak.$(date +%Y%m%d%H%M%S)"
  cp "$HS_DST" "$backup"
  echo "    backed up existing init.lua -> $backup"
fi
cp "$HS_SRC" "$HS_DST"
echo "    wrote $HS_DST"

# --- ControllerKeys preferences (UI/onboarding only; mappings live in exported profiles) ---
if [[ -f "$CK_PREFS_SRC" ]]; then
  echo "==> Installing ControllerKeys preferences plist"
  if [[ -f "$CK_PREFS_DST" ]]; then
    backup="${CK_PREFS_DST}.bak.$(date +%Y%m%d%H%M%S)"
    cp "$CK_PREFS_DST" "$backup"
    echo "    backed up existing prefs -> $backup"
  fi
  cp "$CK_PREFS_SRC" "$CK_PREFS_DST"
  echo "    wrote $CK_PREFS_DST"
fi

# --- ControllerKeys profiles ---
shopt -s nullglob
profiles=("$CK_PROFILES"/*.json)
shopt -u nullglob
if ((${#profiles[@]} > 0)); then
  echo "==> Found ${#profiles[@]} ControllerKeys profile(s):"
  for p in "${profiles[@]}"; do
    echo "    - $(basename "$p")"
  done
  echo "    Open ControllerKeys → Import Profile... and choose one of those JSON files."
  open "$CK_PROFILES"
else
  echo "WARN: no controllerkeys/profiles/*.json found."
  echo "      On the source Mac run ./export.sh and export your profile into controllerkeys/profiles/."
fi

# --- Permissions ---
echo "==> Opening Privacy settings (enable Hammerspoon + ControllerKeys)"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility" || true
sleep 1
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent" || true

# --- Launch ---
echo "==> Launching apps"
[[ -d /Applications/ControllerKeys.app ]] && open -a ControllerKeys || true
[[ -d /Applications/Hammerspoon.app ]] && open -a Hammerspoon || true
sleep 1
open "hammerspoon://reload" 2>/dev/null || true

cat <<'EOF'

Done. Checklist on this Mac:
  [ ] Hammerspoon: Accessibility ON
  [ ] Hammerspoon: Input Monitoring ON
  [ ] ControllerKeys: Accessibility ON
  [ ] ControllerKeys: Input Monitoring / Bluetooth as prompted
  [ ] ControllerKeys: Import profile JSON from controllerkeys/profiles/
  [ ] DualSense connected; hold RT (⌘) + press V on P5 Plus / Moko → paste

EOF
