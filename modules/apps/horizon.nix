# modules/apps/horizon.nix --- https://github.com/ludovic111/horizon
#
# Horizon releases the launcher and its helpers (horizon-prepare,
# horizon-client, horizon-server, horizon-ctl) as generic Linux binaries that
# link against /lib64/ld-linux-x86-64.so.2. The launcher downloads the helpers
# at runtime and starts them as children, so patchelf-ing the launcher alone is
# not enough: everything runs inside an FHS env built from the system nixpkgs,
# which also keeps the FHS glibc in sync with the host Mesa/RADV drivers.
#
# To bump the release, update `version` and the fetchurl hash:
#   nix store prefetch-file --json \
#     "https://github.com/ludovic111/horizon/releases/download/launcher@<version>/horizon-launcher-linux-x86_64.tar.gz"
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
  cfg = config.modules.apps.horizon;

  version = "0.2.8";
  hash = "sha256-OLWqpwZxobnSz3oxy1WHn83szOJ1PYZ1IqABJHgmV+s=";

  horizon-launcher-unwrapped = pkgs.stdenvNoCC.mkDerivation {
    pname = "horizon-launcher-unwrapped";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/ludovic111/horizon/releases/download/launcher@${version}/horizon-launcher-linux-x86_64.tar.gz";
      inherit hash;
    };
    sourceRoot = ".";

    dontConfigure = true;
    dontBuild = true;
    dontFixup = true;

    installPhase = ''
      install -Dm755 horizon-launcher $out/bin/horizon-launcher
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "horizon-launcher";
    desktopName = "Horizon";
    genericName = "Game launcher";
    comment = "Install, prepare and play Horizon, Minecraft: Java Edition rewritten in Rust";
    exec = "horizon-launcher";
    icon = "horizon";
    categories = ["Game"];
    startupWMClass = "horizon-launcher";
  };

  horizon-launcher = pkgs.buildFHSEnv {
    pname = "horizon-launcher";
    inherit version;

    targetPkgs = pkgs:
      with pkgs; [
        horizon-launcher-unwrapped

        # Graphics and display
        wayland
        libxkbcommon
        libx11
        libxcb
        libxcursor
        libxi
        libxrandr
        vulkan-loader
        alsa-lib
        udev

        # Runtime
        zulu25
        python3
        xdg-utils
      ];

    profile = ''
      export JAVA_HOME=${pkgs.zulu25}
      export HORIZON_LAUNCHER_NO_SELF_UPDATE=1
      export HORIZON_LAUNCHER_DESKTOP_EXEC=/run/current-system/sw/bin/horizon-launcher

      # Make Wayland's client library discoverable by dynamically loaded clients.
      export LD_LIBRARY_PATH="${pkgs.wayland}/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    '';

    runScript = "horizon-launcher";

    extraInstallCommands = ''
      install -Dm644 -t $out/share/applications ${desktopItem}/share/applications/*.desktop
    '';

    meta = {
      description = "Launcher for Horizon, Minecraft: Java Edition rewritten in Rust";
      homepage = "https://github.com/ludovic111/horizon";
      license = lib.licenses.mit;
      mainProgram = "horizon-launcher";
      platforms = ["x86_64-linux"];
    };
  };
in {
  options.modules.apps.horizon = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [horizon-launcher];
  };
}
