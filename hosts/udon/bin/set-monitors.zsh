#!/usr/bin/env zsh
# Enable given monitors and disable the rest.
#
# SYNOPSIS:
#   set-monitors [--on|--off] [@all|@default|@primary|@tv|MONITOR...]
#
# DESCRIPTION:
#   Toggles monitors, like `hey wm set-monitors`, but understands a few special
#   shortcut targets specific to the Udon host.
#
# ARGUMENTS:
#   * MONITOR
#     @all        -- DP-3, HDMI-A-2, DP-2 and HDMI-A-1
#     @default    -- DP-3, HDMI-A-2 and DP-2 (used when nothing is given)
#     @primary    -- HDMI-A-2
#     @tv         -- HDMI-A-1

udon.all()     { echo DP-3 HDMI-A-2 DP-2 HDMI-A-1; }
udon.default() { echo DP-3 HDMI-A-2 DP-2; }
udon.primary() { echo HDMI-A-2; }
udon.tv()      { echo HDMI-A-1; }

local -a targets=()
for t in ${@:-@default}; do
  if [[ $t == @* ]]; then
    targets+=( $(udon.${t#@}) )
  else
    targets+=$t
  fi
done

hey wm set-monitors ${targets[@]}
