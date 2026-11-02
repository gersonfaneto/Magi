-- config/hypr/modules/monitors.lua
--
-- Monitor layout. The Quickshell Display surface
-- (config/quickshell/pill/Display.qml) rewrites each block's mode, position and
-- scale through ~/.config/hypr/local/modules. The workspace loops are what it
-- rewrites when it swaps the main monitor, and they decide which output a
-- numbered workspace starts on.
--
-- Double-quoted strings on purpose: the surface's JS setters only strip double
-- quotes.

hl.monitor({
  output = "eDP-1",
  mode = "preferred",
  position = "auto",
  scale = 1,
  disabled = false,
  vrr = 0,
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "1920x1080@60",
  position = "1920x0",
  scale = 1,
})

for i = 1, 5 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "eDP-1" })
end

for i = 6, 10 do
  hl.workspace_rule({ workspace = tostring(i), monitor = "HDMI-A-1" })
end
