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
playerctl -a pause 2>/dev/null || true

# hypridle asks quickshell to lock, but logind can freeze the session before the
# reveal has painted; the grow then only plays on wake. This hook runs before
# sleep.target, so wait for the lock surface to report a committed reveal and let
# suspend freeze on the finished lock screen instead. Skipped when the lock shell
# is not running, and capped so a wedged lock can never hold the lid.
ready="${XDG_RUNTIME_DIR:-/run/user/$UID}/quickshell-lock-ready"
if [[ -e $ready ]]; then
  for _ in {1..60}; do
    [[ "$(<$ready)" == 1 ]] && break
    sleep 0.05
  done
fi
