#!/usr/bin/env zsh
# Suspend event triggered
#
# SYNOPSIS:
#   magi hook on-suspend
#
# DESCRIPTION:
#   Triggered by `magi-sleep-hook` (modules/wm/hyprland/default.nix) when the
#   system goes to sleep.

magi.toast info "Going to sleep.."
playerctl -a pause
