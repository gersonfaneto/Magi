# quickshell

Vendored from [Gakuseei/Ricelin](https://github.com/Gakuseei/Ricelin), the
`configs/quickshell` tree (the `pill` and `lock` surfaces). MIT licensed, see
`LICENSE`.

Upstream commit: `df7fd5f506b514330c825c55fd8cc2204d0b9ced`.

The emoji table (`pill/lib/emoji.js`), the bottom dock and its pins, and the
Emoji, Timer, Scratchpad, Profile, right-click slot and dock-settings surfaces
are adapted from [amanhex/Ukishima](https://github.com/amanhex/Ukishima),
MIT licensed, see `LICENSE-Ukishima`.

## Layout

- `pill/` -- the bar, panels and OSD, run as `qs -c pill`.
- `lock/` -- the session lock, run as `qs -c lock`.

Both are linked to `~/.config/quickshell/` by `modules/wm/quickshell.nix`, which
is where `qs -c NAME` looks for `NAME/shell.qml`.

## Local changes

Tracked here as we adapt it away from a standalone rice:

- `bin/`, `update` engine and the Rice-installer scripts were not vendored.
- Palette, font, wallpaper and Hyprland-config integration still to come.
- Keyboard navigation is shared through `pill/lib/nav.js` and the
  `PillSurface` nav contract (`kbStep`, `kbAdjust`, `kbPage`, `kbEdge`,
  `kbCycle`, `kbActivate`, `kbBack`, `kbLetter`). `Pill.qml` translates keys
  once, `shell.qml` forwards them, and `SearchField` handles keys while a text
  field owns focus.
- Surfaces and `magi @menu` scripts are reachable through launcher bangs
  (`pill/lib/bangs.js`), so Hyprland keeps only the launcher, clipboard and
  power chords.

## Bangs

Type `!` in the launcher (`SUPER + Space`) to enter bang mode. A bare `!`
lists every target; `!mi` filters, and the rest of the line is arguments for
menu and exec commands.

| Bang | Opens |
| --- | --- |
| `!mix`, `!audio` | Mixer |
| `!wifi`, `!net` | Wifi |
| `!bt` | Bluetooth |
| `!set`, `!prefs` | Settings index |
| `!theme`, `!look`, `!display`, `!input`, `!anim` | Appearance sub-surfaces |
| `!clip`, `!wall`, `!emoji`, `!timer`, `!notes` | Clipboard, wallpaper, emoji, timer, notes |
| `!file`, `!dirs`, `!bookmark`, `!icon`, `!mount` | `magi @menu` scripts |
| `!pass`, `!newpass` | Bitwarden entry list / new entry |
| `!color`, `!rgb`, `!hsl` | Hyprpicker color picker (hex / RGB / HSL) |
| `!game` | Toggle game mode |

The emoji surface has a tone strip: pick a skin tone once and it persists in
`Flags`, recolouring only the glyphs that have a Unicode modifier base.

Menu bangs accept arguments: `!file --dir /tmp`, `!file --dirs`. The same table
is available to scripts through the IPC door:

```sh
qs -c pill ipc call pill bang '!mix'
qs -c pill ipc call pill bang '!file --dir /tmp'
```

## Pill keyboard navigation

The pill is not a Hyprland keybind table; it routes keys itself whenever a
surface is open.

| Key | Action |
| --- | --- |
| `Up` / `Down`, `j` / `k` | Move the selection by one row |
| `Left` / `Right`, `h` / `l` | Move sideways, adjust a value, or seek |
| `PageUp` / `PageDown` | Move by one viewport |
| `Ctrl+Home` / `Ctrl+End` | Jump to the first or last row |
| `Tab` / `Shift+Tab` | Cycle rows or open a source picker |
| `Enter` / `Space` | Activate the focused row or toggle playback |
| `Shift+Enter` | Extend a calendar range |
| `Escape` | Pop one layer: form, query, editor, parent surface, close |
| `Ctrl+P` / `Ctrl+N` | Previous / next row inside a search field |
| `Alt+1` .. `Alt+9` | Launch the Nth visible result from a search |
| `Delete` | Remove the focused stashed or routed app |
| `r` | Rescan on Wifi and Bluetooth |
| `a` | Add an app or workspace on the routing surfaces |
| `t` | Jump the calendar cursor to today |

Menus wrap at the ends; settings lists clamp. A search field keeps typing keys,
but forwards navigation, paging and `Tab` to the list underneath. Surfaces
without rows (system monitor, battery, link, OSD, toast) intentionally ignore
navigation.

## Upstream files the shell reads from outside this tree

- `~/.config/hypr/scripts/*` -- vendored at `config/hypr/scripts/`.
- `~/.config/hypr/sound/{eq,mic}.conf` -- vendored at `config/hypr/sound/`.
- `~/.config/hypr/{hypridle.conf,hyprsunset.conf,modules/*.lua}` -- Ricelin's own
  Hyprland config, deliberately not vendored; the Settings surface that edits
  them is inert until re-pointed at Magi's config.
