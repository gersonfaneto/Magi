#!/usr/bin/env zsh
# Browse clipboard history with Rofi, with image previews.
#
# SYNOPSIS:
#   clipmenu
#
# DESCRIPTION:
#   Lists everything cliphist has seen since the session started, newest
#   first -- text as-is, images as thumbnails (typing filters the list).
#   Picking an entry copies it back onto the clipboard, ready to paste with
#   SUPER+v.

hey.requires cliphist rofi wl-copy

local -a raws=() texts=() thumbs=() mimes=()
local line id preview thumb mime
local -a parts
local size unit fmt bytes
local max_images=25 max_bytes=$(( 20 * 1024 * 1024 )) n_images=0

# Thumbnails live in tmpfs and die with the menu, so a stale decode can never
# haunt a later entry reusing an id.
local thumbs_dir=$(hey path runtime clipmenu-thumbs.$$)
mkdir -p $thumbs_dir || exit 1
trap "rm -rf $thumbs_dir" EXIT

# Binary entries read e.g. `[[ binary data 300 B png 64x64 ]]`.
while IFS= read -r line; do
  [[ -n $line ]] || continue
  id=${line%%$'\t'*}
  preview=${line#*$'\t'}
  thumb= mime=
  if [[ $preview == "[[ binary data "* ]]; then
    parts=( ${=preview} )
    size=${parts[4]:-0} unit=${parts[5]:-B} fmt=${parts[6]:l}
    # A format cliphist changed under us parses as size 0 and skips previewing.
    [[ $size == [0-9]##(|.[0-9]##) ]] || size=0
    bytes=0
    case $unit in
      B)   bytes=$(( size )) ;;
      KiB) bytes=$(( size * 1024 )) ;;
      MiB) bytes=$(( size * 1024 * 1024 )) ;;
      GiB) bytes=$(( size * 1024 * 1024 * 1024 )) ;;
    esac
    # wl-copy with no -t offers stdin as text, so binary entries need their
    # type named or they paste as text anywhere that cares.
    case $fmt in
      png)       mime=image/png ;;
      jpg|jpeg)  mime=image/jpeg ;;
      gif)       mime=image/gif ;;
      bmp)       mime=image/bmp ;;
      webp)      mime=image/webp ;;
      svg)       mime=image/svg+xml ;;
    esac
    if [[ -n $mime ]] && (( n_images < max_images )) \
        && (( bytes > 0 && bytes <= max_bytes )); then
      # zsh can't hold rofi's NUL-separated `text\0icon\x1f...` rows in a
      # variable, so only the paths are kept here; the rows are printf'd
      # straight into rofi below.
      thumb=$thumbs_dir/$id
      if print -r -- "$line" | cliphist decode > $thumb 2>/dev/null; then
        (( n_images++ ))
      else
        thumb=; rm -f $thumb
      fi
    fi
  fi
  raws+=( "$line" )
  texts+=( "$preview" )
  thumbs+=( "$thumb" )
  mimes+=( "$mime" )
done < <(cliphist list)

(( $#raws )) || exit 0

local idx
idx=$(for (( i = 1; i <= $#raws; i++ )); do
  if [[ -n $thumbs[$i] ]]; then
    printf '%s\0icon\x1f%s\n' "$texts[$i]" "$thumbs[$i]"
  else
    printf '%s\n' "$texts[$i]"
  fi
done | rofi -dmenu -i -p Clipboard -theme appmenu.rasi -show-icons -format d) || exit 0
[[ $idx == <-> && $idx -gt 0 ]] || exit 0
if [[ -n $mimes[$idx] ]]; then
  print -r -- "$raws[$idx]" | cliphist decode | wl-copy -t "$mimes[$idx]"
else
  print -r -- "$raws[$idx]" | cliphist decode | wl-copy
fi
