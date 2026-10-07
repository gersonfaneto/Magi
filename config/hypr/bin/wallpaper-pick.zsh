#!/usr/bin/env zsh
# Pick a wallpaper with fsel and apply it.
#
# fsel previews images inline and video stills through a generated frame.
#
# SYNOPSIS:
#   wallpaper-pick [TARGET]
#
# ARGUMENTS:
#   1 TARGET
#     A monitor name, or "all" (the default), as accepted by wallpaper.sh.

local script_dir=${0:A:h}

main() {
  setopt localoptions extendedglob
  local target=${1:-all}
  local state=${XDG_STATE_HOME:-$HOME/.local/state}
  local wpdir=$(cat "$state/magi/wallpaper-dir" 2>/dev/null)
  [[ -n $wpdir ]] || wpdir=$HOME/Pictures/Wallpapers

  local -a files
  files=("$wpdir"/*.(#i)(jpg|jpeg|png|gif|webp|mp4|webm|mkv|mov)(N.))
  (( $#files )) || { print -u2 "No wallpapers in $wpdir"; return 1 }

  local -a rows
  local f
  for f in "${files[@]}"; do
    rows+=("${f:t}"$'\t'"$f")
  done

  local pic
  pic=$(print -rl -- "${rows[@]}" |
    fsel --dmenu --delimiter=$'\t' --with-nth=1 --match-nth=1 --accept-nth=2 \
         --only-match --preview="${script_dir}/wallpaper-preview.zsh {}" \
         --info-position=right --info-size=50) || return 0
  [[ -n $pic ]] || return 0

  "$HOME/.config/hypr/scripts/wallpaper.sh" set "$pic" "$target"
}

main "$@"
