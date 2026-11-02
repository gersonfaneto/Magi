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

runtime="${XDG_RUNTIME_DIR:-/run/user/$UID}"
locked="$runtime/quickshell-locked"
ready="$runtime/quickshell-lock-ready"
lock="$HOME/.config/hypr/scripts/lock.sh"

# hypridle locks from its before_sleep_cmd, but only while it runs -- `magi idle
# off` stops it, and a lid close would then suspend to a live desktop. Every
# suspend goes through this hook, so ask quickshell to lock unless something
# already did.
if [[ -x $lock && (! -r $locked || "$(<$locked)" != 1) ]]; then
  "$lock"
fi

# logind can freeze the session before the reveal has painted; the grow then
# only plays on wake. This hook runs before sleep.target, so wait for the lock
# surface to report a committed reveal and let suspend freeze on the finished
# lock screen instead. Skipped when the lock shell is not running, and capped so
# a wedged lock can never hold the lid.
if [[ -e $ready ]]; then
  for _ in {1..60}; do
    [[ "$(<$ready)" == 1 ]] && break
    sleep 0.05
  done
fi
