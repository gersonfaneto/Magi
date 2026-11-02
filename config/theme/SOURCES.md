# Theme sources

`config/theme/themes/<name>-<tone>.toml` is the canonical palette format. The
shell derives its Material-ish roles from each file, and every application
config is rendered from the resulting bundle. Foot is a generated target, not
the source.

## Imports

The imported palettes come from Omarchy's `themes/<name>/colors.toml` at commit
`2d33fd5973eb349c3f7e3ae56e6c293516cc4e18`. Their colours were normalized to
the same concise field set as the converted themes: the derived Omarchy fields
(`dark_background`, `orange`, `brown`, `hyprland_active_border`, ...) were
dropped, hex values were lowercased, and `selection_foreground` was filled from
`foreground`. The file name carries the tone, and `mode` inside the file must
match it.

Imported schemes:

- `catppuccin-dark`
- `catppuccin-latte-light`
- `ethereal-dark`
- `flexoki-light-light`
- `gruvbox-dark`
- `hackerman-dark`
- `jade-horse-dark`
- `kanagawa-dark`
- `last-horizon-dark`
- `lumon-dark`
- `lupine-light`
- `matte-black-dark`
- `miasma-dark`
- `nord-dark`
- `retro-82-dark`
- `ristretto-dark`
- `rose-pine-light`
- `solitude-dark`
- `starship-dark`
- `tokyo-night-dark`
- `vantablack-dark`
- `white-light`

Omarchy's `everforest` palette was not imported because the existing curated
`everforest-dark` and `everforest-light` predate this corpus, but its bundled
backgrounds are still available to that scheme.

## Wallpapers

Still backgrounds from the same Omarchy snapshot live under
`assets/wallpapers/<scheme>/`. Schemes without an Omarchy background directory
carry two generated palette wallpapers (`1-orb` and `2-ribbon`) instead, so
every selectable scheme has a default. `theme.py set` applies the scheme's
first wallpaper, `modules/magi.nix` links the tree to
`$XDG_DATA_HOME/magi/wallpapers`, and the Quickshell wallpaper strip reads it
alongside the local wallpaper folder. The strip's `theme` filter shows only the
active scheme's directory, and theme wallpapers are read-only in the picker
(the press-and-hold trash gesture stays reserved for local files). The
`omarchy.webp` placeholder and `backgrounds/intros/` videos are not vendored.

## Converted themes

The nine original schemes were converted from the foot palette files that used
to live in `config/foot/themes` (now generated). They keep Omarchy's field names
and add four optional keys so the terminal slots stay byte-for-byte identical:

- `ansi0` -- foot's `regular0`, when it differs from `background`
- `ansi7` -- foot's `regular7`, when it differs from `foreground`
- `cursor` -- the text colour under the cursor
- `urls` -- foot's `urls`

The rest maps directly:

| colors.toml | ANSI slot | foot key |
| --- | --- | --- |
| `ansi0` or `background` | 0 | `regular0` |
| `red` | 1 | `regular1` |
| `green` | 2 | `regular2` |
| `yellow` | 3 | `regular3` |
| `blue` | 4 | `regular4` |
| `magenta` or `purple` | 5 | `regular5` |
| `cyan` | 6 | `regular6` |
| `ansi7` or `foreground` | 7 | `regular7` |
| `muted` | 8 | `bright0` |
| `bright_red` | 9 | `bright1` |
| `bright_green` | 10 | `bright2` |
| `bright_yellow` | 11 | `bright3` |
| `bright_blue` | 12 | `bright4` |
| `bright_magenta` or `bright_purple` | 13 | `bright5` |
| `bright_cyan` | 14 | `bright6` |
| `bright_foreground` | 15 | `bright7` |

`selection` and `selection_foreground` map to foot's selection pair.
`selection_foreground` is optional and falls back to `foreground`; Omarchy's
files omit it. `cursor` is optional and falls back to `accent`; `urls` falls
back to `blue`.

## Generated outputs

`packages/theme-palettes.nix` runs `quickshell-palette.py` at build time and
writes:

- `<name>-<tone>.json` under the package root, linked into
  `$XDG_STATE_HOME/quickshell/palettes/`
- `foot/<name>-<tone>.ini`, linked into `$XDG_CONFIG_HOME/foot/themes/` for
  `foot.ini`'s fallback include

The active application configs are rendered at runtime by `theme.py` from the
same bundles. Do not add new app-specific palette files under `config/foot` or
`config/highlight` as sources; the generated foot files and the rendered
`highlight.theme` are outputs.
