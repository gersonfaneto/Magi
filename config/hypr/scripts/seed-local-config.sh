#!/usr/bin/env sh
# Seed ~/.config/hypr/local/modules from the checkout defaults.
#
# The Quickshell Settings surfaces write only the local tree, so this runs on
# login to make sure every file they expect exists. Existing files are left
# alone: the local tree is the user's, the checkout is only the template.

set -eu

src="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)/modules"
dst="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/local/modules"

mkdir -p "$dst"

for name in \
  binds.lua \
  decoration.lua \
  monitors.lua \
  input.lua \
  env.lua \
  autostart.lua \
  animations.lua \
  spaces.lua \
  stash-apps.lua; do
  if [ ! -e "$dst/$name" ]; then
    cp "$src/$name" "$dst/$name"
  fi
done
