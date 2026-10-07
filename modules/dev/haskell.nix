## modules/dev/haskell.nix
#
# GHCi with my .ghci: prelude imports, the language extensions I reach for,
# and hoogle-backed :def searches.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let cfg = config.modules.dev.haskell;
in {
  options.modules.dev.haskell = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = [
      (pkgs.haskellPackages.ghcWithHoogle (p: with p; [
        lens
        random
      ]))
    ];

    home.link.".ghci" = "${config.hey.configDir}/ghci";
  };
}
