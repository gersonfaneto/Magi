-- config/hypr/modules/decoration.lua
--
-- Window-decoration knobs. The Quickshell Look surface
-- (config/quickshell/pill/Look.qml) rewrites this file through
-- ~/.config/hypr/local/modules and reloads Hyprland. Border colours stay with
-- the palette pipeline (hyprland-colors), never here.
--
-- Double-quoted strings on purpose: the surface's JS setters only strip double
-- quotes, so single-quoting `layout` would break its read back.

hl.config({
  general = {
    gaps_in = 6,
    gaps_out = 12,
    border_size = 2,
    layout = "dwindle",
    resize_on_border = true,
  },
  decoration = {
    rounding = 12,
    rounding_power = 4,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    dim_strength = 0.35,
    dim_inactive = true,
    dim_special = 0.4,
    dim_around = 0.4,
    shadow = {
      enabled = true,
      range = 12,
      render_power = 3,
      color = "0xaa14110f",
    },
    blur = {
      enabled = true,
      size = 8,
      passes = 3,
      vibrancy = 0.17,
      noise = 0.01,
      new_optimizations = true,
    },
  },
})

-- Keep the pill's layer blurred without fading it in and out with the session
-- lock. The Look surface owns this named rule.
hl.layer_rule({
  name = "pill-blur",
  match = { namespace = "pill" },
  blur = true,
  ignore_alpha = 0.5,
})
