-- User-editable keybinds. The Quickshell Keybinds surface
-- (config/quickshell/pill/Keybinds.qml) rewrites this file through
-- ~/.config/hypr/local/modules. Magi's built-in, programmatic binds stay in
-- config/hypr/modules/binds-default.lua; this is the extra layer the surface
-- manages.

local mod = "SUPER"

-- Examples:
-- hl.bind(mod .. " + Return", hl.dsp.exec_cmd("foot"))
-- hl.bind(mod .. " + SHIFT + Return", hl.dsp.exec_cmd("foot -a float"))
