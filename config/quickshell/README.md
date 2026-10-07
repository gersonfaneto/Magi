# quickshell

Vendored from [Gakuseei/Ricelin](https://github.com/Gakuseei/Ricelin), the
`configs/quickshell` tree (the `pill` and `lock` surfaces). MIT licensed, see
`LICENSE`.

Upstream commit: `df7fd5f506b514330c825c55fd8cc2204d0b9ced`.

## Layout

- `pill/` -- the bar, panels and OSD, run as `qs -c pill`.
- `lock/` -- the session lock, run as `qs -c lock`.

Both are linked to `~/.config/quickshell/` by `modules/wm/quickshell.nix`, which
is where `qs -c NAME` looks for `NAME/shell.qml`.

## Local changes

Tracked here as we adapt it away from a standalone rice:

- `bin/`, `update` engine and the Rice-installer scripts were not vendored.
- Palette, font, wallpaper and Hyprland-config integration still to come.

## Upstream files the shell reads from outside this tree

- `~/.config/hypr/scripts/*` -- vendored at `config/hypr/scripts/`.
- `~/.config/hypr/sound/{eq,mic}.conf` -- vendored at `config/hypr/sound/`.
- `~/.config/hypr/{hypridle.conf,hyprsunset.conf,modules/*.lua}` -- Ricelin's own
  Hyprland config, deliberately not vendored; the Settings surface that edits
  them is inert until re-pointed at Magi's config.
