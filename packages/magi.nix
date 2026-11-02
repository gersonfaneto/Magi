# packages/magi.nix -- the MagiOS CLI
{callPackage, ...}: let
  janet = callPackage ./_janet.nix {};
in
  janet.mkJanetBin {
    name = "magi";
    description = "A control center for my dotfiles";
    # modules/magi.nix puts this on JANET_PATH, for the janet scripts magi
    # dispatches to but doesn't compile in.
    passthru = {inherit (janet) janetLibs;};
  }
