# test/theme/default.nix --- palette and template checks
#
# The nixos suites are evaluation-only, so they can assert that a registry
# entry has a matching theme file but cannot render the generated configs. This
# check runs the real Python pipeline over every bundle and template instead.
{pkgs, ...}: let
  src = ../..;
in
  pkgs.runCommand "theme-tests" {
    nativeBuildInputs = [pkgs.python3];
  } ''
    python3 ${src}/test/theme/test_theme.py ${src}
    touch $out
  ''
