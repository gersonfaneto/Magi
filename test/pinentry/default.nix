# test/pinentry/default.nix --- the pinentry shim
#
# The nixos suites are evaluation-only, so they can assert that the module
# wires the card but cannot run gpg through it. This check drives the shim's
# protocol against a stand-in for the Quickshell surface, then against a real
# gpg-agent, which is what decides whether the escaping, the cancel code and
# the retry loop are right.
{pkgs, ...}: let
  src = ../..;
in
  pkgs.runCommand "pinentry-tests" {
    nativeBuildInputs = [pkgs.python3 pkgs.gnupg];
  } ''
    python3 ${src}/test/pinentry/test_pinentry.py ${src}
    touch $out
  ''
