-- config/hypr/modules/input.lua
--
-- Pointer, keyboard and tablet input. Edit this file directly; the
-- checkout's ~/.config/hypr/local/modules shadows it if present.

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
