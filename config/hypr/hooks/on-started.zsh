#!/usr/bin/env zsh
# Executed at startup
#
# SYNOPSIS:
#   magi hook on-started
#
# DESCRIPTION:
#   Run at session start (modules/wm/hyprland modules/autostart.lua). Also seeds
#   the mutable foot theme symlinks foot.ini includes, so a fresh install gets
#   the setcolor/setbg palette (and no missing-include error) from the first
#   window -- setcolor makes themes/{dark,light}.ini, setbg makes theme.ini on
#   top.

if command -v setcolor >/dev/null 2>&1; then
  config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  # Only when missing, so a login never resets the picked scheme or the mode.
  [[ -e $config_home/foot/themes/dark.ini ]] || setcolor
  [[ -e $config_home/foot/theme.ini ]] || setbg "$(getbg)"
fi
