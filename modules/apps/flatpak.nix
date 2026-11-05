# modules/apps/flatpak.nix
#
# For the software that won't be packaged for nix, and the software I'd rather
# keep at arm's length from the rest of the system.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.apps.flatpak;
in {
  options.modules.apps.flatpak = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.flatpak = {
      enable = true;
      package =
        mkIf config.modules.xdg.enable
        # Respect XDG, damn it!
        (
          mkWrapper pkgs.flatpak ''
            wrapProgram "$out/bin/flatpak" \
              --run 'export HOME="''${XDG_FAKE_HOME:-$HOME}"'
          ''
        );
    };

    systemd.services.magi-flatpak-repo = {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      path = [config.services.flatpak.package];
      # A one-shot: without these it drops to inactive the moment it returns,
      # and a boot without network leaves a failed unit behind.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
      '';
    };
  };
}
