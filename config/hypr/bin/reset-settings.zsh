#!/usr/bin/env zsh
# Reset the local Hyprland files to the checkout defaults.
#
# SYNOPSIS:
#   reset-settings
#
# DESCRIPTION:
#   The Settings surfaces write to ~/.config/hypr/local/modules so they never
#   touch the git checkout. This copies the tracked defaults back over that
#   local tree and reloads Hyprland, throwing away every Settings edit.

set -eu

src="${0:A:h:h}/modules"
dst="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/local/modules"

mkdir -p "$dst"

for name in \
  binds.lua \
  decoration.lua \
  monitors.lua \
  input.lua \
  env.lua \
  autostart.lua \
  animations.lua \
  spaces.lua \
  stash-apps.lua; do
  cp -f "$src/$name" "$dst/$name"
done

hyprctl reload >/dev/null
print -r -- "Hyprland settings reset to the checkout defaults."
