# DualSense + Moko modifier bridge

Use a **PS5 DualSense** (via [ControllerKeys](https://kevintang.xyz/apps/controller-keys)) as held modifiers, and a **P5 Plus / Moko Bluetooth keyboard** for keys like `V`, so chords such as ⌘V work across both devices.

Hammerspoon stamps ControllerKeys-held modifiers onto physical keyboard events.

## Layout

```text
hammerspoon/init.lua              # modifier bridge
controllerkeys/preferences/       # ControllerKeys UI prefs (not button maps)
controllerkeys/profiles/*.json    # exported ControllerKeys profiles (required)
install.sh                        # set up on a Mac
export.sh                         # refresh repo from this Mac
```

## First-time capture (this Mac)

```bash
cd ~/MyApps/dualsense-modifier-bridge
./export.sh
```

Export your DualSense profile from ControllerKeys into `controllerkeys/profiles/`, then commit.

## Install on another Mac

1. Copy or clone this repo onto the other Mac.
2. Install **ControllerKeys** (App Store / vendor site; not bundled).
3. Install **Hammerspoon** if needed (`brew install --cask hammerspoon`).
4. Run:

```bash
./install.sh
```

5. Grant **Accessibility** and **Input Monitoring** to both apps.
6. In ControllerKeys: **Import Profile...** → pick the JSON under `controllerkeys/profiles/`.
7. Connect DualSense + P5 Plus keyboard and test: hold **RT** (⌘) + press **V**.

## Suggested DualSense holds

| Button | Action        |
|--------|---------------|
| RT     | ⌘ hold        |
| LB     | ⌥ hold        |
| RB     | ⌃ hold        |
| Share  | ⌘⌥ hold (opt) |

Map these as **Hold Modifier** only (no key) in ControllerKeys.
