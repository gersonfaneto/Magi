# modules/dev/go.nix --- https://go.dev/
#
# Go is the language I reach for when I want a single static binary, a build
# system that doesn't fight me, and a toolchain that just works. The standard
# library is boring in the best way.
{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  devCfg = config.modules.dev;
  cfg = devCfg.go;
in {
  options.modules.dev.go = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        go
        gopls
        gotools
        delve
        golangci-lint
        gofumpt
      ];

      # `g` is intentionally absent: config/git/aliases.zsh defines it as a
      # function, and a system alias of the same name makes zsh refuse to
      # define that function.
      environment.shellAliases = {
        gob = "go build";
        gor = "go run";
        got = "go test";
      };
    })

    (mkIf cfg.xdg.enable {
      # Go already puts its build cache and env file under XDG on Linux, but
      # GOPATH still defaults to ~/go, so pin the rest too.
      environment.variables = rec {
        GOPATH = "$XDG_DATA_HOME/go";
        GOBIN = "${GOPATH}/bin";
        GOMODCACHE = "${GOPATH}/pkg/mod";
        GOCACHE = "$XDG_CACHE_HOME/go-build";
        GOENV = "$XDG_CONFIG_HOME/go/env";
        PATH = ["${GOBIN}"];
      };
    })
  ];
}
