#!/bin/sh
store="$HOME/.config/hypr/scripts/cliphist-store.sh"
pgrep -f "cliphist-store.sh text" >/dev/null || wl-paste --type text --watch "$store text" &
pgrep -f "cliphist-store.sh image" >/dev/null || wl-paste --type image --watch "$store image" &
