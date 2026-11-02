-- config/hypr/modules/input.lua
--
-- Pointer, keyboard and tablet input. The Quickshell Input surface
-- (config/quickshell/pill/Input.qml) rewrites this file through
-- ~/.config/hypr/local/modules and reloads Hyprland.
--
-- Double-quoted strings on purpose: the surface's JS setters only strip double
-- quotes, so single-quoted values would break its read back.

hl.config({
  input = {
    kb_layout = "br",
    kb_variant = "thinkpad",
    kb_options = "compose:ralt",
    follow_mouse = 2,
    focus_on_close = 2,
    float_switch_override_focus = 0,
    sensitivity = 0.0,
    accel_profile = "adaptive",
    repeat_rate = 25,
    repeat_delay = 600,
    numlock_by_default = false,
    touchpad = {
      natural_scroll = true,
      tap_and_drag = true,
      drag_lock = 2,
      drag_3fg = 1,
    },
  },
  binds = {
    scroll_event_delay = 40,
  },
})
