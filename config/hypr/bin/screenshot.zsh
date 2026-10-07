#!/usr/bin/env zsh
# Capture a screenshot to clipboard.
#
# SYNOPSIS:
#   screenshot [-o FILE] [all|full|last|region|window|output]
#
# DESCRIPTION:
#   Captures a screenshot with grim (selecting through `magi .slurp`), compresses
#   it with pngquant, then copies it to your clipboard. To draw on the screen,
#   use the vendored `rishot` editor (SUPER + D); this script is for the
#   headless `-o FILE` captures `magi wm ocr` and friends rely on.
#
# OPTIONS:
#   -o, --output FILE @files
#     Write the PNG to FILE (- for stdout) and say nothing, instead of copying
#     it to the clipboard. For scripts that want the image rather than my
#     clipboard, like `magi wm ocr`.
#
# ARGUMENTS:
#   1 TARGET
#     all       -- Capture all outputs combined
#     full      -- Capture the focused output
#     last      -- Capture the previous selection.
#     region    -- Select a region interactively (the default).
#     window    -- Select selected window.
#     output    -- Select a monitor.

main() {
  set -eo pipefail
  magi.requires grim pngquant
  local -a outfile
  zparseopts -D -F -- o:=outfile -output:=outfile || exit 1
  local -a args
  case ${1:-region} in
    all) ;;
    full) args=( -o "$(hyprctl activeworkspace -j | jq -r .monitor)" ) ;;
    last|region|window|output) args=( -g "$(magi .slurp $1)" ) ;;
    *) magi.abort "Unknown target: $1" ;;
  esac
  if [[ $outfile ]]; then
    local dest=${outfile[2]}
    [[ $dest == - ]] && dest=/dev/stdout
    grim "${args[@]}" - | pngquant --strip -s 10 - >| $dest
    return
  fi
  local preview_file=$(magi path runtime screenshot.png)
  if grim "${args[@]}" - | \
       pngquant --strip -s 10 - >$preview_file | \
       wl-copy -t image/png; then
    trap "rm -f $preview_file" EXIT
    magi.toast -i $preview_file info "Screenshot captured" "Copied to clipboard"
  else
    magi.toast warn "Aborted"
  fi
}

main $@
