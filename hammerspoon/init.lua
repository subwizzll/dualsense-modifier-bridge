-- DualSense (via ControllerKeys) held modifiers → physical keyboard chords
-- Example: hold RT (⌘) on DualSense, press V on P5 Plus / Moko → ⌘V

hs.ipc.cliInstall()

local MOD_KEYCODES = {
  [56] = "shift",  -- left shift
  [60] = "shift",  -- right shift
  [59] = "ctrl",   -- left control
  [62] = "ctrl",   -- right control
  [58] = "alt",    -- left option
  [61] = "alt",    -- right option
  [55] = "cmd",    -- left command
  [54] = "cmd",    -- right command
}

held = { cmd = false, ctrl = false, alt = false, shift = false }
controllerKeysPidSet = {}

local function refreshControllerKeysPids()
  local pids = {}
  for line in string.gmatch(hs.execute("/usr/bin/pgrep -x ControllerKeys") or "", "%d+") do
    pids[tonumber(line)] = true
  end
  controllerKeysPidSet = pids
end

local function isFromControllerKeys(event)
  local pid = event:getProperty(hs.eventtap.event.properties.eventSourceUnixProcessID)
  if not pid or pid == 0 then
    return false
  end
  return controllerKeysPidSet[pid] == true
end

local function anyHeld()
  return held.cmd or held.ctrl or held.alt or held.shift
end

local function syncFromSystem()
  local flags = hs.eventtap.checkKeyboardModifiers()
  held.cmd = flags.cmd == true
  held.ctrl = flags.ctrl == true
  held.alt = flags.alt == true
  held.shift = flags.shift == true
end

local function trackModifierEvent(event)
  local keycode = event:getKeyCode()
  local name = MOD_KEYCODES[keycode]
  if not name then
    return
  end

  local etype = event:getType()
  if etype == hs.eventtap.event.types.keyDown then
    held[name] = true
  elseif etype == hs.eventtap.event.types.keyUp then
    held[name] = false
  elseif etype == hs.eventtap.event.types.flagsChanged then
    syncFromSystem()
  end
end

local function applyHeldFlags(event)
  local flags = event:getFlags()
  flags.cmd = flags.cmd or held.cmd
  flags.ctrl = flags.ctrl or held.ctrl
  flags.alt = flags.alt or held.alt
  flags.shift = flags.shift or held.shift
  event:setFlags(flags)
end

modifierTracker = hs.eventtap.new({
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp,
  hs.eventtap.event.types.flagsChanged,
}, function(event)
  trackModifierEvent(event)
  if event:getType() == hs.eventtap.event.types.flagsChanged or MOD_KEYCODES[event:getKeyCode()] then
    syncFromSystem()
  end
  return false
end)

modifierBridge = hs.eventtap.new({
  hs.eventtap.event.types.keyDown,
  hs.eventtap.event.types.keyUp,
}, function(event)
  if hs.eventtap.isSecureInputEnabled() then
    return false
  end

  local keycode = event:getKeyCode()
  if MOD_KEYCODES[keycode] then
    return false
  end

  if isFromControllerKeys(event) then
    return false
  end

  syncFromSystem()
  if not anyHeld() then
    return false
  end

  applyHeldFlags(event)
  return false
end)

local function startBridge()
  refreshControllerKeysPids()
  if not modifierTracker:isEnabled() then
    modifierTracker:start()
  end
  if not modifierBridge:isEnabled() then
    modifierBridge:start()
  end
  syncFromSystem()
  if modifierBridge:isEnabled() then
    hs.alert.show("Modifier bridge ON", 2)
    print("modifier bridge enabled; ControllerKeys PIDs: " ..
      (hs.execute("/usr/bin/pgrep -x ControllerKeys") or "none"))
    return true
  end
  return false
end

refreshControllerKeysPids()
controllerKeysWatch = hs.timer.doEvery(5, refreshControllerKeysPids)

-- Prompt for Accessibility and keep retrying until the eventtap can start.
if hs.accessibilityState(true) then
  startBridge()
else
  hs.alert.show("Enable Hammerspoon in\nPrivacy → Accessibility\nthen reload", 5)
  print("waiting for Accessibility permission")
  accessibilityWatch = hs.timer.doEvery(2, function()
    if hs.accessibilityState() then
      if startBridge() and accessibilityWatch then
        accessibilityWatch:stop()
        accessibilityWatch = nil
      end
    end
  end)
end
