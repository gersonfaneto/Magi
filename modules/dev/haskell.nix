# modules/dev/haskell.nix --- https://www.haskell.org/
#
# GHCi with my .ghci: prelude imports, the language extensions I reach for,
# and hoogle-backed :def searches. Cabal and Stack share the pinned package
# set, alongside the tools HLS and my editor expect on PATH.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  devCfg = config.modules.dev;
  cfg = devCfg.haskell;
  hs = pkgs.haskellPackages;
in {
  options.modules.dev.haskell = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = [
        (hs.ghcWithHoogle (
          p:
            with p; [
              lens
              random
            ]
        ))

        # Pinned to the same package set as GHC. HLS and these formatters are
        # what config/nvim/after/lsp/hls.lua expects to find on PATH.
        hs.cabal-install
        hs.stack
        hs.hpack
        hs.haskell-language-server
        hs.ormolu
        hs.cabal-fmt

        # Useful from both GHCi and the shell.
        hs.hlint
        hs.ghcid
      ];

      home.link.".ghci" = "${config.magi.configDir}/ghci";
    })

    (mkIf cfg.xdg.enable {
      environment.variables = {
        CABAL_DIR = "$XDG_DATA_HOME/cabal";
        CABAL_CONFIG = "$XDG_CONFIG_HOME/cabal/config";
        STACK_ROOT = "$XDG_DATA_HOME/stack";
      };
    })
  ];
}
