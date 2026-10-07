#!/usr/bin/env zsh
# Executed at startup
#
# SYNOPSIS:
#   magi hook on-started
#
# DESCRIPTION:
#   Run at session start (config/hypr/modules/autostart.lua). The theme unit
#   may have started before Hyprland was listening, so re-apply here: this is
#   what pushes the tone-correct cursor and icon themes through gsettings and
#   hyprctl, and refreshes the generated foot palette.

if command -v magi >/dev/null 2>&1; then
  magi theme apply >/dev/null 2>&1 || true
fi
