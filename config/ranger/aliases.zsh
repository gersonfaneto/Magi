#!/usr/bin/env zsh

alias ra='ranger'

# cd on exit: `rac` quits ranger into the directory it died in.
rac() {
  local cwd="$(mktemp -t ranger-cwd.XXXXXX)"
  ranger --choosedir="$cwd" "$@"
  [[ -s $cwd ]] && [[ "$(<$cwd)" != "$PWD" ]] && builtin cd -- "$(<$cwd)"
  command rm -f -- "$cwd"
}
