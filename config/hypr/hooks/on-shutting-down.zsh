#!/usr/bin/env zsh
# Executed at shutdown
#
# SYNOPSIS:
#   magi hook on-shutting-down
#
# DESCRIPTION:
#   Run by magi-shutdown-hook.service as the session goes down, however it was
#   asked to. on-rebooting is a symlink to this file; the session dies the same
#   either way.

local stamp=$(magi path runtime session-ending)
[[ -e $stamp ]] && exit 0
mkdir -p ${stamp:h} && : >|$stamp

magi.toast warn "Shutting down..."

# Fade out. Plus the ~130ms quickshell takes to cold-start.
magi .fade -d 1250 out &
wait
