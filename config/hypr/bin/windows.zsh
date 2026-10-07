#!/usr/bin/env zsh
# Focus a window picked from a list.
#
# SYNOPSIS:
#   windows
#
# DESCRIPTION:
#   Lists every mapped window with its class and workspace, and focuses the one
#   fsel returns. Runs in a floating foot window (SUPER + SHIFT + W).

main() {
  local -a rows
  local title class ws addr
  while IFS=$'\t' read -r title class ws addr; do
    [[ -n $addr ]] || continue
    rows+=("${title//$'\t'/ }"$'\t'"${class} - ws ${ws}"$'\t'"$addr")
  done < <(hyprctl clients -j | jq -r '.[] | [
    (.title // ""), (.class // ""), ((.workspace.name // "") | tostring), .address
  ] | @tsv')

  (( $#rows )) || return 0

  addr=$(print -rl -- "${rows[@]}" |
    fsel --dmenu --delimiter $'\t' --with-nth 1,2 --match-nth 1,2 --accept-nth 3 --only-match) || return 0
  [[ -n $addr ]] || return 0

  hyprctl dispatch "hl.dsp.focus({ window = 'address:${addr}' })" >/dev/null
}

main "$@"
