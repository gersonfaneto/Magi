# rishot

Vendored from [Gakuseei/rishot](https://github.com/Gakuseei/rishot), a Wayland
screenshot and annotation overlay built on Quickshell. MIT licensed, see
`LICENSE`.

Upstream commit: `93d44757271d2e18104772da6fd7366f41188cb0`.

## Wiring

`bin/rishot` is linked to `~/.local/bin/rishot` by `modules/wm/quickshell.nix`,
and `RISHOT_CONFIG_DIR` points at `src/` here. Its settings file is mutable
(`~/.config/rishot/config.json`), not managed by Nix.
