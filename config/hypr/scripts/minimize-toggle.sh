#!/bin/sh
#
# SUPER+M minimize toggle. A window on the desktop drops into the special
# "minimized" stash; the same key on a window already in the stash brings it
# back to the focused monitor's real workspace.

aw=$(hyprctl activewindow -j 2>/dev/null)
addr=$(printf '%s' "$aw" | jq -r '.address // ""')
ws=$(printf '%s' "$aw" | jq -r '.workspace.name // ""')

[ -n "$addr" ] || exit 0

if [ "$ws" = "special:minimized" ]; then
	real=$(hyprctl monitors -j | jq -r 'map(select(.focused)) | .[0].activeWorkspace.id // 1')
	hyprctl dispatch movetoworkspacesilent "$real,address:$addr"
else
	hyprctl dispatch movetoworkspacesilent "special:minimized,address:$addr"
fi
