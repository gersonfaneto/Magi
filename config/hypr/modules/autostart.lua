-- config/hypr/modules/autostart.lua
--
-- Programs Hyprland launches at startup. The Quickshell Input surface
-- (config/quickshell/pill/Input.qml) rewrites the cursor line here through
-- ~/.config/hypr/local/modules so a cursor pick survives a restart.

hl.on("hyprland.start", function()
  hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 32")
  -- Seed the foot theme symlinks.
  hl.exec_cmd("magi hook on-started")
  -- The pill's clipboard surface only watches for changes; this is what
  -- stores the history cliphist reads back.
  hl.exec_cmd("$HOME/.config/hypr/scripts/cliphist-watch.sh")
end)
