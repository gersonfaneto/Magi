-- config/hypr/modules/window_rules.lua
--
-- Window and layer rules. Mostly Ricelin's vanilla set, plus the Magi extras
-- that survived the move off the scrolling layout (image previewers, dialog
-- sizing, Steam/Faugus, the media scratchpad).

-- * General

hl.window_rule({
  name = "suppress-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  name = "fix-xwayland-drags",
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

hl.window_rule({
  name = "no-fullscreen-floats",
  match = { float = true },
  suppress_event = "fullscreen maximize",
})

hl.window_rule({
  name = "idle-inhibit-fullscreen",
  match = { class = ".*" },
  idle_inhibit = "fullscreen",
})

-- * Floating apps

hl.window_rule({
  name = "float-system-dialogs",
  match = { class = "(pavucontrol|nm-connection-editor|blueman-manager|org.kde.polkit-kde-authentication-agent-1|xdg-desktop-portal-gtk)" },
  float = true,
})

hl.window_rule({
  name = "float-file-pickers",
  match = { title = "(Open File|Save File|Save As|Choose Files|Open Folder)" },
  float = true,
})

hl.window_rule({
  name = "float-spotify",
  match = { class = "[Ss]potify" },
  float = true,
})

hl.window_rule({
  name = "float-qalculate",
  match = { class = "io.github.Qalculate.qalculate-qt" },
  float = true,
})

hl.window_rule({
  name = "float-emacs-everywhere",
  match = { initial_title = "emacs-everywhere" },
  float = true,
})

hl.window_rule({
  name = "image-previewers",
  match = { class = "^(imv|swayimg)$" },
  float = true,
  center = true,
  dim_around = true,
  border_size = 1,
  max_size = { "monitor_w*0.96", "monitor_h*0.96" },
})

-- File dialogs can remember a size from a larger monitor.
hl.window_rule({
  name = "dialog-windows",
  match = { float = true, class = "^(xdg-desktop-portal-gtk|librewolf|thunar)$" },
  center = true,
  max_size = { "monitor_w*0.9", "monitor_h*0.9" },
})

-- * Steam and media

hl.window_rule({
  name = "steam-all-windows",
  match = { class = "steam" },
  workspace = "special:media silent",
  immediate = true,
  no_dim = true,
  no_blur = true,
  no_anim = true,
  no_shadow = true,
  no_max_size = true,
  min_size = { 1, 1 },
})

hl.window_rule({
  name = "steam-main-window",
  match = { class = "steam", initial_title = "Steam" },
  suppress_event = "fullscreen maximize",
  float = false,
  fullscreen = false,
})

hl.window_rule({
  name = "steam-popups",
  match = { class = "steam", initial_title = "negative:Steam" },
  float = true,
})

hl.window_rule({
  name = "steam-games",
  match = { initial_class = "(gamescope|steam_app_(default|\\d+))" },
  workspace = "special:media silent",
  no_dim = true,
  immediate = true,
  no_blur = true,
  no_anim = true,
  no_initial_focus = true,
  suppress_event = "maximize",
  content = "game",
  fullscreen = true,
  float = false,
  tile = false,
})

hl.window_rule({
  name = "faugus",
  match = { initial_class = "io.github.Faugus.faugus-launcher" },
  workspace = "special:media silent",
  float = true,
})

hl.window_rule({
  name = "feishin",
  match = { class = "^feishin$" },
  workspace = "special:media",
})

-- * Stash

local ok, stashApps = pcall(require, "modules.stash-apps")
if ok and type(stashApps) == "table" then
  for _, cls in ipairs(stashApps) do
    hl.window_rule({
      name = "stash-" .. cls,
      match = { class = cls },
      workspace = "special:stash",
    })
  end
end

-- * Layers

-- Keep the pill from fading when the session lock hides and restores its
-- layer, so it never pops back in out of sync with the lock morph.
hl.layer_rule({
  name = "pill-no-fade",
  match = { namespace = "pill" },
  no_anim = true,
})
