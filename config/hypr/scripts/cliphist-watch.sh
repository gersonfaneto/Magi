#!/bin/sh
# Keep one store watcher per clipboard type alive. `restart` drops the current
# pair first: wl-paste can sit on a dead selection after a suspend and never
# deliver another event, so waking up restarts them instead of trusting them.
store="$HOME/.config/hypr/scripts/cliphist-store.sh"
pattern="wl-paste --type .* --watch $store"

if [ "$1" = "restart" ]; then
  pkill -f "$pattern" || true
  # Wait for the old pair to actually leave. pgrep below would still see a
  # dying watcher and skip starting its replacement, leaving no watcher at all.
  i=0
  while pgrep -f "$pattern" >/dev/null; do
    i=$((i + 1))
    [ "$i" -ge 50 ] && break
    sleep 0.1
  done
  pkill -9 -f "$pattern" || true
fi

# The path and type are separate arguments; passing them as one word makes
# wl-paste look for a file literally named "cliphist-store.sh text".
pgrep -f "cliphist-store.sh text" >/dev/null || wl-paste --type text --watch "$store" text &
pgrep -f "cliphist-store.sh image" >/dev/null || wl-paste --type image --watch "$store" image &
