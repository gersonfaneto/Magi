#!/usr/bin/env janet
# Inspect and change the monochrome session theme.
#
# SYNOPSIS:
#   theme status
#   theme bg [light|dark]
#   theme apply
#   theme render
#   theme check
#   theme apps on|off
#
# DESCRIPTION:
#   One palette family, two tones. The active mono-<tone> bundle drives
#   Hyprland, Qt, GTK, fsel, qutebrowser, foot, highlight, nvim, tmux, fzf and
#   the zsh shell together.
#
#   bg switches the whole session between the light and dark variants and
#   applies the matching solid wallpaper. apply renders the active bundle again,
#   render only writes the templates, and check verifies the bundles and every
#   template. apps turns the GTK app override on or off.
#
#   ARGS is the subcommand and its arguments: bg takes light or dark, apps takes
#   on or off. Everything else takes no arguments.
#
# OPTIONS:
#   none
#
# ARGUMENTS:
#   * ARGS @theme-arg

(use magi)

(defn- usage []
  (print "Usage: magi theme {status,bg,apply,render,check,apps} [ARGS...]")
  1)

(defcmd theme [_ & args]
  (if (empty? args)
    (usage)
    (os/execute @["python3" (path :config "hypr" "scripts" "theme.py") ;args] :p)))
