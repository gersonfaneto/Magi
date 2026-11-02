#!/usr/bin/env zsh
# Wakeup from sleep.
#
# SYNOPSIS:
#   magi hook on-wakeup
#
# DESCRIPTION:
#   Triggered by `magi-sleep-hook` (modules/wm/hyprland/default.nix) when the
#   system wakes up from sleep.

magi.toast info "Waking up..."

# Sessions outlive suspends, so this is the closest thing to a new day. Walks
# the sockets for the same reason on-reload.zsh does.
for sock in ${XDG_RUNTIME_DIR:-/run/user/$UID}/hypr/*(/N); do
  hyprctl -i ${sock:t} eval 'magi.ws.compact()' >/dev/null || true
done
