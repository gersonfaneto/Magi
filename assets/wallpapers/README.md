# Theme wallpapers

Most of these wallpapers come from Omarchy's per-theme `backgrounds/`
directories at commit `2d33fd5973eb349c3f7e3ae56e6c293516cc4e18`, the same
snapshot the canonical palettes in `config/theme/themes/` were imported from.
Only still images are vendored; the `omarchy.webp` placeholder and the
`backgrounds/intros/` videos are omitted. The Omarchy license is included
alongside this file.

The remaining schemes have no upstream background directories. Their two
wallpapers (`1-orb` and `2-ribbon`) are generated from that scheme's own
palette, so every selectable theme ends up with at least one bundled
background.

Directory names match scheme names in `config/theme/schemes.json`.
`theme.py set` applies the first file in the chosen scheme's directory, and the
wallpaper strip falls back to the full library only if a scheme has no files.

`modules/magi.nix` links this directory to
`$XDG_DATA_HOME/magi/wallpapers`, and `Walls.qml` exposes those files to the
wallpaper strip.
