-- config/hypr/modules/autostart.lua
--
-- Programs Hyprland launches at startup. Edit this file directly; the
-- checkout's ~/.config/hypr/local/modules shadows it if present.

hl.on("hyprland.start", function()
  -- Re-apply the mono theme once hyprctl can set the tone-correct cursor;
  -- the systemd unit runs before the compositor is listening.
  hl.exec_cmd("magi hook on-started")
  -- The pill's clipboard surface only watches for changes; this is what
  -- stores the history cliphist reads back.
  hl.exec_cmd("$HOME/.config/hypr/scripts/cliphist-watch.sh")
end)
