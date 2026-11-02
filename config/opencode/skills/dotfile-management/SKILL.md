---
name: dotfile-management
description: >-
  Load when user asks to commit, stage, diff, or do any git operation on Magi
  dotfiles in /etc/magi. Magi is a NixOS flake checkout (a regular git repo);
  use plain git with `-C /etc/magi` and the `magi` workflow below.
---

## Finding the repo

The live checkout is `/etc/magi` (the `magi.dir` module option, default `/etc/magi`). Confirm with:

```bash
git -C /etc/magi rev-parse --show-toplevel
```

## Git invocation

All standard git subcommands work. Run them with:

```bash
git -C /etc/magi <subcommand>
```

Prefer the `magi` wrappers when the task matches one:

- `magi sync build` / `magi sync switch` / `magi sync dry-activate` for rebuilds
- `magi sync check` for `nix flake check`
- `magi test` / `magi test magi` / `magi test nixos` for the test suites

Raw `nix` commands against the flake need `--accept-flake-config` for the cachix substituters (`magi` wrappers already pass it).

## Layout rules

- `lib/modules.nix` decides what gets picked up: only `*.nix` files, `_`-prefixed names skipped, a directory counts as a module only if it holds `default.nix`.
- `self.*` (flake inputs snapshot) is the store path nix evaluates; `config.magi.*` is the live checkout. Anything linked or sourced into the built system goes through `config.magi.*`.
- Never edit generated files: `config/claude/data/refs/*`, rendered themes (`config/zellij/themes/colors.kdl`, `config/yazi/theme.toml`), and `*.meta.lua` LSP stubs.

## Migratability

Do not introduce machine-specific absolute paths such as `/home/user/...` into tracked dotfiles. These dotfiles are reused across hosts. In command strings interpreted by a shell, prefer `~` or `$HOME` so paths stay portable.

## Commit message style

Follow the repo convention, `<area>: <subject>`, imperative mood. Recent examples:

- `README: modern/minimal rewrite`
- `install.zsh: reject scaffold-only flags on existing hosts`
- `server role: track linux_6_12, hardened series is gone upstream`
