-- config/hypr/modules/env.lua
--
-- Environment for the Hyprland session. The Quickshell Input surface
-- (config/quickshell/pill/Input.qml) rewrites the cursor lines here through
-- ~/.config/hypr/local/modules and applies them with `hyprctl setcursor`.

hl.env("XCURSOR_THEME", "catppuccin-mocha-dark-cursors")
hl.env("XCURSOR_SIZE", "32")
hl.env("HYPRCURSOR_SIZE", "32")
