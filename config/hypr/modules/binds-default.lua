-- config/hypr/modules/binds-default.lua
--
-- Built-in keybinds. The Quickshell Keybinds surface owns modules/binds.lua,
-- not this file, so the defaults here survive a Settings rewrite.
--
-- The layout is dwindle, but the Magi extras (per-monitor pad, media/stash/
-- private scratchpads, screenshots, recorder, OCR) stay on top of Ricelin's
-- base bindings.

local mod = "SUPER"
local home = os.getenv("HOME")
local function cmd(s) return hl.dsp.exec_cmd(s) end

-- * Scratchpad helpers

-- Toggle NAME, but go to it if it is already up on another monitor instead of
-- dragging it over to the focused one.
local function scratchpad(name)
  local special = "special:" .. name
  return function()
    local host, ws
    for _, m in ipairs(hl.get_monitors() or {}) do
      local w = m.active_special_workspace
      if w and w.name == special then
        host, ws = m, w
        break
      end
    end

    local win = host and hl.get_active_window()
    if not win or (win.workspace and win.workspace.name == special) then
      hl.dispatch(hl.dsp.workspace.toggle_special(name))
    else
      local go = host.focused and ws.last_window
      hl.dispatch(hl.dsp.focus(go and { window = go } or { monitor = host }))
    end
  end
end

local function local_pad(mon)
  return "pad:" .. mon.name
end

local function toggle_local_pad()
  local m = hl.get_active_monitor()
  if m then
    hl.dispatch(hl.dsp.workspace.toggle_special(local_pad(m)))
  end
end

-- Move into the pad of the monitor the window is on, not the focused one.
local function move_to_local_pad()
  local w = hl.get_active_window()
  local m = w and w.monitor
  if m then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. local_pad(m) }))
  end
end

-- Into NAME (or the supplied dispatcher/function), or back to the workspace
-- under it when the window is already in a special:NAME*.
local function move_to_or_back(name, there)
  return function()
    local w = hl.get_active_window()
    local ws = w and w.workspace
    local prefix = "special:" .. name
    if ws and ws.name and ws.name:sub(1, #prefix) == prefix then
      local target = w.monitor and w.monitor.active_workspace
      if target then
        hl.dispatch(hl.dsp.window.move({ workspace = target }))
      end
    elseif type(there) == "function" then
      there()
    else
      hl.dispatch(there or hl.dsp.window.move({ workspace = prefix }))
    end
  end
end

-- * Zoom and DPMS

local function zoom(ratio)
  return function()
    local current = hl.get_config("cursor:zoom_factor") or 1
    local next = ratio == 0 and 1 or math.max(1, math.min(3, current + ratio))
    hl.config({ cursor = { zoom_factor = next } })
  end
end

-- Upstream warns against dispatching DPMS straight from a keybind.
local function dpms(state)
  return function()
    hl.timer(function()
      hl.dispatch(hl.dsp.dpms({ action = state and "enable" or "disable" }))
    end, { timeout = 500, type = "oneshot" })
  end
end

-- Resize the active window to SPEC: a fraction of the monitor's usable width,
-- or pixels if > 1.
local function resize_width(spec)
  return function()
    local w = hl.get_active_window()
    local m = w and w.monitor
    if not m then
      return
    end
    local usable = m.width / m.scale - m.reserved.left - m.reserved.right
    local px = spec > 1 and spec or usable * spec
    hl.dispatch(
      hl.dsp.window.resize({ x = math.floor(px), y = w.size.y })
    )
  end
end

-- * Shell surfaces

hl.bind(mod .. " + Space", cmd('qs -c pill ipc call pill launcher ""'))
hl.bind(mod .. " + E", cmd('qs -c pill ipc call pill emoji ""'))
hl.bind(mod .. " + SHIFT + T", cmd('qs -c pill ipc call pill timer ""'))
hl.bind(mod .. " + ALT + N", cmd('qs -c pill ipc call pill scratch ""'))
hl.bind(mod .. " + V", cmd('qs -c pill ipc call pill clipboard ""'))
hl.bind(mod .. " + W", cmd('qs -c pill ipc call pill wallpaper ""'))
hl.bind(mod .. " + A", cmd('qs -c pill ipc call pill mixer ""'))
hl.bind(mod .. " + C", cmd('qs -c pill ipc call pill calendar ""'))
hl.bind(mod .. " + COMMA", cmd('qs -c pill ipc call pill settings ""'))
hl.bind(mod .. " + SLASH", cmd('qs -c pill ipc call pill keybinds ""'))

-- * Menus

-- The `magi @menu` scripts (config/menu/bin) draw in the pill's generic Menu
-- surface. Shift keeps them clear of the focus and movement letters below.
-- hl.bind(mod .. " + SHIFT + B", cmd("magi @menu bookmark"))
hl.bind(mod .. " + SHIFT + D", cmd("magi @menu file"))
hl.bind(mod .. " + SHIFT + E", cmd("magi @menu emoji"))
hl.bind(mod .. " + SHIFT + I", cmd("magi @menu icon"))
hl.bind(mod .. " + SHIFT + N", cmd('qs -c pill ipc call pill page "" wifi'))
hl.bind(mod .. " + SHIFT + U", cmd("magi @menu mount"))
hl.bind(mod .. " + SHIFT + B", cmd("magi @menu rbw"))
hl.bind(mod .. " + ALT + SHIFT + B", cmd("magi @menu rbw --new"))

-- * OS and session

hl.bind(mod .. " + SHIFT + R", cmd("magi reload @hypr"))
hl.bind(mod .. " + CTRL + I", cmd("magi idle toggle"))
hl.bind(mod .. " + Return", cmd("magi .open-term"))
hl.bind(mod .. " + SHIFT + Return", cmd("foot || xterm"))
hl.bind(mod .. " + Escape", function()
  zoom(0)()
  hl.exec_cmd("qs -c pill ipc call pill notificationsClear")
end)
hl.bind(mod .. " + CTRL + L", cmd(home .. "/.config/hypr/scripts/lock.sh"))
hl.bind("CTRL + ALT + Delete", cmd('qs -c pill ipc call pill power ""'))
hl.bind(mod .. " + Q", hl.dsp.window.close(), { submap_universal = true })
hl.bind(mod .. " + SHIFT + Q", hl.dsp.window.kill())

-- * Tools

hl.bind(mod .. " + D", cmd("rishot"))
hl.bind(mod .. " + X", cmd("magi .ocr region"))
hl.bind(mod .. " + Print", cmd('qs -c pill ipc call pill quickRecord ""'))
hl.bind(mod .. " + SHIFT + Print", cmd('qs -c pill ipc call pill recorder ""'))
hl.bind(mod .. " + G", cmd('qs -c pill ipc call pill gameMode ""'))

-- * Zoom

hl.bind(mod .. " + Minus", zoom(-0.3), { repeating = true, submap_universal = true })
hl.bind(mod .. " + Equal", zoom(0.3), { repeating = true, submap_universal = true })

-- * Window layout

hl.bind(mod .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + SHIFT + F", hl.dsp.window.fullscreen())
hl.bind(mod .. " + T", function()
  hl.dispatch(hl.dsp.window.float({ action = "set" }))
  hl.dispatch(hl.dsp.window.pin())
end)
hl.bind(mod .. " + O", function()
  local w = hl.get_active_window()
  hl.dispatch(hl.dsp.window.cycle_next({ floating = w and not w.floating }))
end)
hl.bind(mod .. " + SHIFT + O", hl.dsp.layout("togglesplit"))
hl.bind(mod .. " + M", cmd(home .. "/.config/hypr/scripts/minimize-toggle.sh"))

-- * Workspaces

for i = 1, 10 do
  local key = i % 10
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Per-monitor pad
hl.bind(mod .. " + APOSTROPHE", toggle_local_pad)
hl.bind(mod .. " + SHIFT + APOSTROPHE", move_to_or_back("pad", move_to_local_pad))

-- Global media scratchpad, one modifier over the workspace-10 key.
hl.bind(mod .. " + ALT + 0", scratchpad("media"))
hl.bind(mod .. " + ALT + SHIFT + 0", move_to_or_back("media"))

-- Stash and private scratchpads
hl.bind(mod .. " + S", scratchpad("stash"))
hl.bind(mod .. " + SHIFT + S", move_to_or_back("stash"))
hl.bind(mod .. " + P", scratchpad("private"))
hl.bind(mod .. " + SHIFT + P", move_to_or_back("private"))

-- Minimized windows
hl.bind(mod .. " + SHIFT + M", hl.dsp.workspace.toggle_special("minimized"))

-- * Focus and movement

local directions = {
  h = "left",
  j = "down",
  k = "up",
  l = "right",
}

for key, dir in pairs(directions) do
  hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = dir }))
  hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

hl.bind(mod .. " + TAB", hl.dsp.window.cycle_next())

-- Quick width presets on 2-6.
for i, spec in ipairs({ 700, 0.5, 0.6, 0.8, 1.0 }) do
  hl.bind(mod .. " + " .. (i + 1), resize_width(spec), { submap_universal = true })
end

hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true, submap_universal = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true, submap_universal = true })

-- * Media keys

hl.bind("XF86AudioRaiseVolume", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86MonBrightnessUp", cmd("brightnessctl -e4 -n2 set 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", cmd("brightnessctl -e4 -n2 set 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioPlay", hl.dsp.global("quickshell:mediaToggle"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.global("quickshell:mediaNext"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.global("quickshell:mediaPrev"), { locked = true })
hl.bind("XF86PowerOff", dpms(false), { locked = true })
