# AGENTS.md

Personal NixOS flake dotfiles ("Magi", evolved from hlissner/dotfiles): NixOS
hosts, config/ dotfile trees, and `hey`, a custom Janet CLI for rebuilds,
tests, and remote ops. Only x86_64-linux. No CI, no formatter, no pre-commit,
no git remote. README is a stub.

## Commands

- `nix develop` — janet, jpm, judge, zsh (the suites' *.zsh fixtures), nix
  tooling; shellHook exports DOTFILES_HOME, JANET_*, and XDG_* defaults (hey
  aborts with `Invalid XDG directory: …` if XDG_BIN_HOME & co. are unset, as
  in bare shells — modules/home.nix only exports them at Magi login), and
  puts ./bin on PATH, so `hey` runs this checkout's interpreted bin/hey.
  Aliases: `install` (jpm install), `rebuild` (jpm clean && jpm install)
  for iterating on the CLI.
- Tests, via `hey` (dev shell):
  - `hey test` — both suites: hey (janet/judge) first, then nixos; stops on failure.
  - `hey test hey [SUITE…]` — judge; suite names like `hey/hey`, `hey/sync`
    (`hey test -l` lists). Builds `.#judge` and pins JANET_PATH so `(import hey)`
    and the spawned bin/hey resolve to this checkout. Single suite:
    `hey test hey hey/hey`.
  - `hey test nixos [suite]` — same as
    `nix build .#checks.x86_64-linux.nixos` / `….nixos.passthru.<suite>`.
- `nix build .#hey` — packaged CLI. Rebuilds: `hey sync build|switch|dry-activate|…`;
  `hey sync check` = `nix flake check`. `hey help` lists subcommands.
- Raw nix commands against this flake need `--accept-flake-config` to honor
  the cachix substituters in flake.nix's nixConfig (hey's wrappers already pass it).

## Layout

Wired by hand in flake.nix through lib/ (mkFlake; deliberately not
flake-parts). The lib/modules.nix walkers decide what gets picked up: only
`*.nix`; `_`-prefixed files/dirs are skipped (`test/_lib`,
`packages/_janet.nix`, `test/nixos/_lib.nix`); a directory counts as a module
only if it has default.nix; default.nix/flake.nix are never modules.

- `hosts/<name>/default.nix` returns `{ system, imports?, modules, config,
  hardware }`. `modules` is config in *this flake's* option namespace
  (profiles, wm, apps, shell, …); raw NixOS config goes in `config`/`hardware`.
- `modules/` — NixOS modules, imported recursively by default.nix. Features
  gate themselves with `mkIf` on `modules.profiles.{role,user,networks,hardware}`
  (modules/profiles/*); hosts just set those values.
- `test/` → flake checks. Only test/nixos/ has a default.nix, so it alone is
  `checks.<sys>.nixos`, with suites on its passthru (names join dirs with `-`,
  e.g. `lib-modules`; `*.d` fixture dirs and `_` names are never collected).
- `packages/`, `overlays/` — one package/overlay per .nix (callPackage'd;
  checks additionally get `flake`).
- hey CLI: dispatch table in `bin/hey`, one script per subcommand in
  `bin/hey.d/*.janet` (explicit imports there — adding a file isn't enough),
  library in `lib/hey/` (`(use hey)`). A script's header comment is its help
  text *and* the zsh completion source (lib/hey/docs.janet), so new
  subcommands need SYNOPSIS:/OPTIONS:/ARGUMENTS: sections or the hey suite fails.
- `config/` — dotfile trees modules link onto systems. Hyprland's config is
  Lua: `config/hypr/hyprland.lua` + `lib/*.lua`, not a hyprland.conf.

## The two path trees

`self.*` (specialArg) is the store snapshot nix evaluates — read files through
it. `config.hey.*` (modules/hey.nix) is the live checkout, default
/etc/dotfiles — anything linked or sourced into the built system goes through
it, so edits there take effect without a rebuild. hey.dir is asserted to be
absolute and outside the store.

## Testing quirks

- Janet suites: `test/<name>/*.janet` with judge assertions; `*.d` dirs
  beside them are fixtures and spawned scripts, never suites. Add a suite file
  and it's picked up automatically.
- NixOS suites: plain `lib.runTests` attrsets (test/nixos/*.nix); test attrs
  MUST be named `test*` or mkSuite reports strays and fails. Evaluation only,
  no VM boot: use evalConfig/evalHost/presets from test/nixos/_lib.nix, which
  fabricate `specialArgs.self` off the store — suites need no /etc/dotfiles.
- project.janet's `jpm test` also runs judge on test/hey; its :dependencies
  mirror packages/_janet.nix's janetDeps — keep both in sync when pinning a dep.
- Suites must not lean on ambient machine state: `hey sync` refuses a host
  still named `nixos` and `hey ops` gates on `$XDG_DATA_HOME/hey/info.json`'s
  role. Stub with `hey/with-envvars` (HOST, XDG_DATA_HOME → fixtures in
  test/hey/ops.d/) the way sibling suites do, or they only pass on a real
  Magi workstation.

## Gotchas

- `nixpkgs.follows = "hyprland/nixpkgs"` — Hyprland pins nixpkgs so its
  cachix hashes match ours; don't repin nixpkgs independently.
- Never edit generated files: `config/claude/data/refs/*` (built by
  config/claude/scripts/ensure-reference-*.zsh), theme renders
  (`config/zellij/themes/colors.kdl`, `config/yazi/theme.toml`,
  `config/rofi/themes/*.rasi`), and `*.meta.lua` LSP stubs (symlinked by
  modules/wm/hyprland).
- `hey ops` refuses to run except on workstation hosts.
- install.zsh still clones github:hlissner/dotfiles (upstream), not this checkout.
- Offline doc mirrors (nix/nixos options, hyprland, janet): see
  config/claude/CLAUDE.md and config/claude/data/refs/README.md — grep first.
