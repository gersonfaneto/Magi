#!/usr/bin/env zsh
# Push a foot palette file's colors into every running foot window.
#
# SYNOPSIS:
#   magi @foot reload-colors [FILE]
#
# DESCRIPTION:
#   Writes OSC sequences to the pty each foot window holds, which is the only
#   channel foot parses them from. That pty belongs to the shell in a bare foot
#   window, and to the tmux client in the foot+tmux windows open-term.zsh spawns
#   (a pane's pty belongs to tmux, which drops the OSCs its panes emit). Until I
#   find an alternative terminal with foot's light footprint but live reload,
#   this is what I'm stuck with; upstream has decided not to implement it (see
#   https://codeberg.org/dnkl/foot/issues/708).

local file=${1:-${XDG_CONFIG_HOME:-$HOME/.config}/foot/theme.ini}
[[ -r $file ]] || { print -u2 "reload-colors: no $file"; exit 1 }

# foot-ctlseqs(7) documents ST (`ESC \`) as the OSC terminator; xterm's BEL
# shorthand isn't mentioned there, so terminate every sequence with ST.
local st=$'\e\\'

# The Bekaboo theme files (config/foot/themes) carry no alpha, so default to the
# value the static config sets (alpha in config/foot/foot.ini), or the pushed
# background would come out opaque.
local seq= bg= alpha=0.92 line key val
for line in ${(f)"$(<$file)"}; do
  [[ $line == [\#\[]* || $line != *=* ]] && continue
  key=${line%%=*}; val=${line#*=}
  case $key in
    foreground)           seq+=$'\e]10;#'$val$st ;;
    background)           bg=$val ;;
    alpha)                alpha=$val ;;
    regular<0-7>)         seq+=$'\e]4;'${key#regular}';#'$val$st ;;
    bright<0-7>)          seq+=$'\e]4;'$(( ${key#bright} + 8 ))';#'$val$st ;;
    selection-foreground) seq+=$'\e]19;#'$val$st ;;
    selection-background) seq+=$'\e]17;#'$val$st ;;
    # foot's cursor= is "TEXT CURSOR"; only the cursor has an OSC.
    cursor)               seq+=$'\e]12;#'${val##* }$st ;;
  esac
done
# A plain #RRGGBB over OSC 11 makes foot opaque again, so the background goes
# out as rgba with alpha= (foot's URxvt-style extension, see foot-ctlseqs(7)).
if [[ -n $bg ]]; then
  local a=$(printf '%02x' $(printf '%.0f' $(( alpha * 255 ))))
  seq+=$'\e]11;rgba:'${bg[1,2]}/${bg[3,4]}/${bg[5,6]}/$a$st
fi
[[ -n $seq ]] || { print -u2 "reload-colors: no colors in $file"; exit 1 }

# Writing to a pty lands on the terminal emulator's side of it, so the sequence
# has to go to the pty foot itself holds. For a bare foot window that's the
# shell's pty; for the foot+tmux windows open-term.zsh spawns it's the tmux
# client's, because a pane's pty belongs to tmux, which parses (and drops) the
# OSCs its panes emit. Many shells share one pty (subshells, suspended jobs), so
# collect the devices and write to each once. Anything that isn't a pty is some
# script's stdin.
local -U ptys=()
local pid pty
# tmux renames its processes, so the client holding foot's pty is "tmux: client".
for pid in $(pgrep -u $UID -x 'zsh|tmux.*'); do
  pty=$(readlink /proc/$pid/fd/0 2>/dev/null) || continue
  [[ $pty == /dev/pts/* ]] && ptys+=$pty
done
for pty in $ptys; do
  print -rn -- $seq > $pty 2>/dev/null || true
done
