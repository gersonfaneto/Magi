-- config/hypr/modules/monitors.lua
--
-- Monitor layout. Edit this file directly; the
-- checkout's ~/.config/hypr/local/modules shadows it if present. The workspace
-- loops decide which output a numbered workspace starts on.

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
