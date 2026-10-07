# modules/dev/zig.nix --- https://ziglang.org/
#
# Zig is what I reach for when C's build system and dependency story get in the
# way. It is also the closest thing we have to a "better C" that ships its own
# toolchain, so I keep it around for small, self-contained projects.
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
  cfg = devCfg.zig;
in {
  options.modules.dev.zig = {
    enable = mkBoolOpt false;
    xdg.enable = mkBoolOpt devCfg.xdg.enable;
  };

  config = mkMerge [
    (mkIf cfg.enable {
      user.packages = with pkgs; [
        zig
        zls
      ];
    })

    (mkIf cfg.xdg.enable {
      # Zig already follows XDG on Linux, but set it explicitly for consistency
      # with the other dev modules. The local cache stays project-local.
      environment.variables.ZIG_GLOBAL_CACHE_DIR = "$XDG_CACHE_HOME/zig";
    })
  ];
}
