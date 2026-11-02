#!/usr/bin/env janet
# Inspect and change the desktop palette.
#
# SYNOPSIS:
#   theme list
#   theme status
#   theme set [SCHEME] [TONE]
#   theme bg [light|dark]
#   theme apply
#   theme render
#   theme check
#   theme apps on|off
#
# DESCRIPTION:
#   One palette bundle drives the Quickshell pill and lock, Hyprland, Qt,
#   foot, highlight, nvim, tmux, fzf and the zsh shell (prompt, dircolors,
#   syntax highlighting and autosuggestions). The scheme list lives in
#   config/theme/schemes.json.
#
#   set is what setcolor calls, bg is what setbg calls, and the login service
#   runs apply. All of them go through the same renderer, so no consumer can be
#   left on a different palette. set also applies the scheme's first bundled
#   wallpaper, unless only its tone changed.
#
#   ARGS is the subcommand and its arguments: set takes a scheme name from
#   `theme list` and an optional light/dark tone, bg takes light or dark, and
#   apps takes on or off. Everything else takes no arguments.
#
# ARGUMENTS:
#   * ARGS @theme-arg

(use magi)

(defcmd theme [_ & args]
  (if (empty? args)
    (usage)
    (let [argv @["python3" (path :config "hypr" "scripts" "theme.py") ;args]]
      (def code (os/execute argv :p))
      (unless (zero? code) (exit code)))))
