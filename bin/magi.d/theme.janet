#!/usr/bin/env janet
# Inspect and change the desktop palette.
#
# SYNOPSIS:
#   theme list
#   theme status
#   theme set [SCHEME]
#   theme bg [light|dark]
#   theme source scheme|dynamic
#   theme apply [--refresh]
#   theme render
#   theme check
#   theme apps on|off
#
# DESCRIPTION:
#   One palette bundle drives the Quickshell pill and lock, Hyprland, Qt,
#   foot, highlight, nvim, tmux, fzf and the zsh shell (prompt, dircolors,
#   syntax highlighting and autosuggestions). The scheme list lives in
#   config/theme/schemes.json; wallpaper-derived palettes are generated at
#   runtime by wallcolors.py.
#
#   set is what setcolor calls, bg is what setbg calls, and the login service
#   runs apply. All of them go through the same renderer, so no consumer can be
#   left on a different palette.
#
#   ARGS is the subcommand and its arguments: set takes a scheme name from
#   `theme list`, bg takes light or dark, source takes scheme or dynamic, and
#   apps takes on or off. Everything else takes no arguments.
#
# OPTIONS:
#   --refresh
#     Regenerate the dynamic palette before applying.
#
# ARGUMENTS:
#   * ARGS @theme-arg

(use magi)

(defn- usage []
  (print "Usage: magi theme {list,status,set,bg,source,apply,render,check,apps} [ARGS...]")
  1)

(defcmd theme [_ & args &opts refresh? --refresh]
  (if (empty? args)
    (usage)
    (do
      (def argv @["python3" (path :config "hypr" "scripts" "theme.py") ;args])
      # theme.py wants the option after the subcommand, not before it.
      (when refresh? (array/insert argv 3 "--refresh"))
      (os/execute argv :p))))
