#!/bin/sh
MAGICK_CONFIGURE_PATH="$(dirname "$0")/magick-policy"
export MAGICK_CONFIGURE_PATH

flags="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/flags.json"
wpdir=$(jq -r '.wallpaperDir // ""' "$flags" 2>/dev/null || echo "")
[ -n "$wpdir" ] || wpdir=$(cat "${XDG_STATE_HOME:-$HOME/.local/state}/quickshell-wallpaper-dir" 2>/dev/null || true)
[ -n "$wpdir" ] || wpdir="$HOME/Pictures/Wallpapers"
themedir="${XDG_DATA_HOME:-$HOME/.local/share}/magi/wallpapers"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-wp-thumbs"
mkdir -p "$cache"

make_thumb() {
    src=$1
    thumb=$2
    [ -s "$thumb" ] && [ ! "$src" -nt "$thumb" ] && return
    mkdir -p "$(dirname "$thumb")"
    case "$src" in
        *.[Mm][Pp]4|*.[Ww][Ee][Bb][Mm]|*.[Mm][Kk][Vv]|*.[Mm][Oo][Vv])
            ffmpeg -y -loglevel quiet -i "$src" -frames:v 1 -vf 'scale=512:-2' -f image2 -c:v png "$thumb.tmp" 2>/dev/null
            ;;
        *)
            magick "${src}[0]" -strip -resize 512x "png:$thumb.tmp" 2>/dev/null
            ;;
    esac
    if [ -s "$thumb.tmp" ]; then
        mv "$thumb.tmp" "$thumb"
    else
        rm -f "$thumb.tmp"
    fi
}

# The theme tree is ~80 high-resolution stills; decoding them one at a time
# makes the first wallpaper open crawl. xargs re-enters this script per source
# so the cache warms across cores instead.
if [ "${1:-}" = "--thumb" ]; then
    make_thumb "$2" "$3"
    exit
fi

for f in "$cache"/*.png; do
    [ -e "$f" ] || continue
    base="$(basename "$f" .png)"
    [ -n "$(find "$wpdir" -type f -name "$base" -print -quit)" ] || rm -f "$f"
done

if [ -d "$cache/theme" ]; then
    find "$cache/theme" -type f -name '*.png' | while IFS= read -r f; do
        rel="${f#"$cache/theme/"}"
        theme="${rel%%/*}"
        base="${rel#*/}"
        base="${base%.png}"
        [ -e "$themedir/$theme/$base" ] || rm -f "$f"
    done
    find "$cache/theme" -mindepth 1 -type d -empty -delete 2>/dev/null || true
fi

find "$wpdir" -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) | while IFS= read -r src; do
    make_thumb "$src" "$cache/$(basename "$src").png"
done

if [ -d "$themedir" ]; then
    find -L "$themedir" -mindepth 2 -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) -print0 |
        xargs -0 -r -P "${THUMB_JOBS:-4}" -I{} sh -c '
            src=$1
            rel=${src#"$2"/}
            theme=${rel%%/*}
            "$0" --thumb "$src" "$3/theme/$theme/$(basename "$src").png"
        ' "$0" {} "$themedir" "$cache"
fi
