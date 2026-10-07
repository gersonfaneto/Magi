#!/usr/bin/env zsh
# Swap the current pane with an adjacent one.
#
# SYNOPSIS:
#   swap-pane [up|down|left|right|master]
#
# ARGUMENTS:
#   1 DIRECTION
#     up        -- Swap with the pane above.
#     down      -- Swap with the pane below.
#     left      -- Swap with the pane to the left.
#     right     -- Swap with the pane to the right.
#     master    -- Swap with the master pane.

local target
case $1 in
  up) target="U" ;;
  down) target="D" ;;
  left) target="L" ;;
  right) target="R" ;;
  master) target="M" ;;
  *) exit 1 ;;
esac

local src_pane=$(tmux display-message -p "#P")
hey.do tmux select-pane -${target}

local dst_pane=$(tmux display-message -p "#P")
hey.do tmux select-pane -t${src_pane}

[[ "$target" == M ]] && dst_pane=0
hey.do tmux swap-pane -s"$src_pane" -t"$dst_pane"
hey.do tmux select-pane -t"$dst_pane"
