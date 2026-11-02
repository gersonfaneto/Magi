# AGENTS.md

Personal NixOS flake dotfiles ("Magi", evolved from hlissner/dotfiles): NixOS
hosts, config/ dotfile trees, and `magi`, a custom Janet CLI for rebuilds,
tests, and remote ops. Only x86_64-linux. CI runs `magi test magi` + nixos checks on `main`. Formatter: `nix fmt` (treefmt-nix, see `treefmt.nix`); `nix flake check` fails on unformatted code. No pre-commit hook. README is a stub.

## Commands

- `nix develop` — janet, jpm, judge, zsh (the suites' *.zsh fixtures), nix
  tooling; shellHook exports DOTFILES_HOME, JANET\_*, and XDG\_\* defaults (magi
  aborts with `Invalid XDG directory: …` if XDG_BIN_HOME & co. are unset, as
  in bare shells — modules/home.nix only exports them at Magi login), and
  puts ./bin on PATH, so `magi` runs this checkout's interpreted bin/magi.
  Aliases: `install` (jpm install), `rebuild` (jpm clean && jpm install)
  for iterating on the CLI.
- Tests, via `magi` (dev shell):
  - `magi test` — both suites: magi (janet/judge) first, then nixos; stops on failure.
  - `magi test magi [SUITE…]` — judge; suite names like `magi/magi`, `magi/sync`
    (`magi test -l` lists). Builds `.#judge` and pins JANET_PATH so `(import magi)`
    and the spawned bin/magi resolve to this checkout. Single suite:
    `magi test magi magi/magi`.
  - `magi test nixos [suite]` — same as
    `nix build .#checks.x86_64-linux.nixos` / `….nixos.passthru.<suite>`.
- `nix build .#magi` — packaged CLI. Rebuilds: `magi sync build|switch|dry-activate|…`;
  `magi sync check` = `nix flake check`. `magi help` lists subcommands.
- Raw nix commands against this flake need `--accept-flake-config` to honor
  the cachix substituters in flake.nix's nixConfig (magi's wrappers already pass it).

## Layout

Wired by hand in flake.nix through lib/ (mkFlake; deliberately not
flake-parts). The lib/modules.nix walkers decide what gets picked up: only
`*.nix`; `_`-prefixed files/dirs are skipped (`test/_lib`,
`packages/_janet.nix`, `test/nixos/_lib.nix`); a directory counts as a module
only if it has default.nix; default.nix/flake.nix are never modules.

- `hosts/<name>/default.nix` returns `{ system, imports?, modules, config, hardware }`. `modules` is config in *this flake's* option namespace
  (profiles, wm, apps, shell, …); raw NixOS config goes in `config`/`hardware`.
- `modules/` — NixOS modules, imported recursively by default.nix. Features
  gate themselves with `mkIf` on `modules.profiles.{role,user,networks,hardware}`
  (modules/profiles/\*); hosts just set those values.
- `test/` → flake checks. Only test/nixos/ has a default.nix, so it alone is
  `checks.<sys>.nixos`, with suites on its passthru (names join dirs with `-`,
  e.g. `lib-modules`; `*.d` fixture dirs and `_` names are never collected).
- `packages/`, `overlays/` — one package/overlay per .nix (callPackage'd;
  checks additionally get `flake`).
- magi CLI: dispatch table in `bin/magi`, one script per subcommand in
  `bin/magi.d/*.janet` (explicit imports there — adding a file isn't enough),
  library in `lib/magi/` (`(use magi)`). A script's header comment is its help
  text *and* the zsh completion source (lib/magi/docs.janet), so new
  subcommands need SYNOPSIS:/OPTIONS:/ARGUMENTS: sections or the magi suite fails.
- `config/` — dotfile trees modules link onto systems. Hyprland's config is
  Lua: `config/hypr/hyprland.lua` + `lib/*.lua`, not a hyprland.conf.

## The two path trees

`self.*` (specialArg) is the store snapshot nix evaluates — read files through
it. `config.magi.*` (modules/magi.nix) is the live checkout, default
/etc/magi — anything linked or sourced into the built system goes through
it, so edits there take effect without a rebuild. magi.dir is asserted to be
absolute and outside the store.

## Testing quirks

- Janet suites: `test/<name>/*.janet` with judge assertions; `*.d` dirs
  beside them are fixtures and spawned scripts, never suites. Add a suite file
  and it's picked up automatically.
- NixOS suites: plain `lib.runTests` attrsets (test/nixos/\*.nix); test attrs
  MUST be named `test*` or mkSuite reports strays and fails. Evaluation only,
  no VM boot: use evalConfig/evalHost/presets from test/nixos/\_lib.nix, which
  fabricate `specialArgs.self` off the store — suites need no /etc/magi.
- project.janet's `jpm test` also runs judge on test/magi; its :dependencies
  mirror packages/\_janet.nix's janetDeps — keep both in sync when pinning a dep.
- Suites must not lean on ambient machine state: `magi sync` refuses a host
  still named `nixos` and `magi ops` gates on `$XDG_DATA_HOME/magi/info.json`'s
  role. Stub with `magi/with-envvars` (HOST, XDG_DATA_HOME → fixtures in
  test/magi/ops.d/) the way sibling suites do, or they only pass on a real
  Magi workstation.

## Gotchas

- `nixpkgs.follows = "hyprland/nixpkgs"` — Hyprland pins nixpkgs so its
  cachix hashes match ours; don't repin nixpkgs independently.
- Never edit generated files: `config/claude/data/refs/*` (built by
  config/claude/scripts/ensure-reference-\*.zsh), and `*.meta.lua` LSP stubs
  (symlinked by modules/wm/hyprland).
- `magi ops` refuses to run except on workstation hosts.
- install.zsh clones github:gersonfaneto/Magi (this checkout).
- Offline doc mirrors (nix/nixos options, hyprland, janet): see
  config/claude/CLAUDE.md and config/claude/data/refs/README.md — grep first.
