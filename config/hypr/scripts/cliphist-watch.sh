#!/bin/sh
# Keep one store watcher per clipboard type alive. `restart` drops the current
# pair first: wl-paste can sit on a dead selection after a suspend and never
# deliver another event, so waking up restarts them instead of trusting them.
store="$HOME/.config/hypr/scripts/cliphist-store.sh"

if [ "$1" = "restart" ]; then
  pkill -f "wl-paste --type .* --watch $store" || true
fi

# The path and type are separate arguments; passing them as one word makes
# wl-paste look for a file literally named "cliphist-store.sh text".
pgrep -f "cliphist-store.sh text" >/dev/null || wl-paste --type text --watch "$store" text &
pgrep -f "cliphist-store.sh image" >/dev/null || wl-paste --type image --watch "$store" image &
