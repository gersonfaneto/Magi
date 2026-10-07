#!/usr/bin/env zsh
# Render a wallpaper for fsel's preview panel.
#
# Both images and videos become a cached still, scaled down for the preview
# panel, so fsel never decodes a 4K source while the picker is open.
#
# SYNOPSIS:
#   wallpaper-preview ROW

emulate -L zsh
local row=$1
local file=${row#*$'\t'}
[[ -n $file && -f $file ]] || exit 1

local cache=${XDG_CACHE_HOME:-$HOME/.cache}/magi/wp-thumbs
local thumb="$cache/${file:t}.jpg"
if [[ ! -s $thumb || $file -nt $thumb ]]; then
  mkdir -p "$cache"
  ffmpeg -y -loglevel quiet -i "$file" -frames:v 1 \
    -vf 'scale=1024:-2' -q:v 3 "$thumb" 2>/dev/null
fi
[[ -s $thumb ]] || exit 1

cat "$thumb"
