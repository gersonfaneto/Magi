-- config/hypr/hyprland.lua
--
-- Dwindle-based Hyprland config, following Ricelin's module layout with the
-- Magi extras on top. The modules under modules/ are hand-edited; the stable
-- frame around them lives here.

require('modules.env')
require('modules.monitors')
require('modules.input')
require('modules.decoration')
require('modules.animations')
require('modules.binds-default')
require('modules.window_rules')
require('modules.spaces-apply')
require('modules.autostart')
-- User-added binds live in modules/binds.lua; the Keybinds surface edits it.
require('modules.binds')

pcall(require, 'modules.private')
pcall(require, 'local')

-- * Options

-- https://wiki.hypr.land/Configuring/Start/
hl.config({
  general = {
    no_focus_fallback = true,
  },
  render = {
    direct_scanout = 2,
  },
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  dwindle = {
    preserve_split = true,
  },
  misc = {
    background_color = '0xff000000',
    force_default_wallpaper = 0,
    disable_watchdog_warning = true,
    disable_hyprland_logo = true,
    disable_autoreload = true,
    disable_splash_rendering = true,
    key_press_enables_dpms = true,
    initial_workspace_token_timeout = 20,
  },
  cursor = {
    default_monitor = magi.hypr.primaryMonitor,
    zoom_rigid = true,
  },
})

-- * Layer rules

-- Invisible margins/padding will get blurred too without this
hl.layer_rule({
  match = { namespace = 'notifications' },
  blur = true,
  ignore_alpha = 0.3,
})

-- * Workspace rules

-- Steam and its games, out of the way until summoned.
hl.workspace_rule({
  workspace = 'special:media',
  no_border = true,
  no_shadow = true,
  no_rounding = true,
})
-- One scratchpad per monitor, as special:pad:OUTPUT (see binds-default.lua).
hl.workspace_rule({
  workspace = 'n[s:special:pad:]',
  gaps_in = 10,
  gaps_out = 85,
})
