# packages/theme-palettes.nix -- build the palette bundles and foot fallbacks
#
# config/theme/themes/*.toml is the canonical source. The builder derives the
# shell roles from each theme and writes both the Quickshell JSON bundles and
# the static foot files used for the pre-login fallback.
{
  runCommand,
  python3,
  ...
}: let
  themes = ../config/theme;
  builder = ../config/hypr/scripts/quickshell-palette.py;
in
  runCommand "theme-palettes" {
    nativeBuildInputs = [python3];
    PYTHONPATH = "${../config/hypr/scripts}";
  } ''
    python3 ${builder} \
      --themes ${themes}/themes \
      --schemes ${themes}/schemes.json \
      --out $out
  ''
