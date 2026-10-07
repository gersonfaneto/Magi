#!/usr/bin/env zsh
# Pick a clipboard history entry and put it back on the clipboard.
#
# fsel previews every row from cliphist's raw bytes: images render inline and
# text shows up as text.
#
# SYNOPSIS:
#   clipboard-pick

emulate -L zsh
local here=${0:A:h}
local selected

selected=$(cliphist list |
  fsel --dmenu --delimiter=$'\t' --with-nth=2 --match-nth=2 --accept-nth=1 \
       --only-match --preview="${here}/cliphist-preview.zsh {}" \
       --info-position=right --info-size=50) || return 0
[[ -n $selected ]] || return 0

cliphist decode "$selected" | wl-copy
