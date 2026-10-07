______________________________________________________________________

## name: dotfile-management description: Load when user asks to commit, stage, diff, or do any git operation on Magi dotfiles in /etc/magi. Magi is a NixOS flake checkout (a regular git repo); use plain git with `-C /etc/magi` and the `hey` workflow below.

## Finding the repo

The live checkout is `/etc/magi` (the `hey.dir` module option, default `/etc/magi`). Confirm with:

```bash
git -C /etc/magi rev-parse --show-toplevel
```

## Git invocation

All standard git subcommands work. Run them with:

```bash
git -C /etc/magi <subcommand>
```

Prefer the `hey` wrappers when the task matches one:

- `hey sync build` / `hey sync switch` / `hey sync dry-activate` for rebuilds
- `hey sync check` for `nix flake check`
- `hey test` / `hey test hey` / `hey test nixos` for the test suites

Raw `nix` commands against the flake need `--accept-flake-config` for the cachix substituters (`hey` wrappers already pass it).

## Layout rules

- `lib/modules.nix` decides what gets picked up: only `*.nix` files, `_`-prefixed names skipped, a directory counts as a module only if it holds `default.nix`.
- `self.*` (flake inputs snapshot) is the store path nix evaluates; `config.hey.*` is the live checkout. Anything linked or sourced into the built system goes through `config.hey.*`.
- Never edit generated files: `config/claude/data/refs/*`, rendered themes (`config/zellij/themes/colors.kdl`, `config/yazi/theme.toml`, `config/rofi/themes/*.rasi`), and `*.meta.lua` LSP stubs.

## Migratability

Do not introduce machine-specific absolute paths such as `/home/user/...` into tracked dotfiles. These dotfiles are reused across hosts. In command strings interpreted by a shell, prefer `~` or `$HOME` so paths stay portable.

## Commit message style

Follow the repo convention, `<area>: <subject>`, imperative mood. Recent examples:

- `README: modern/minimal rewrite`
- `install.zsh: reject scaffold-only flags on existing hosts`
- `server role: track linux_6_12, hardened series is gone upstream`
