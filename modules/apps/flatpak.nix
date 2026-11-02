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

  # Shared by the ensure unit and the on-gc hook. `system` is the generation
  # last ensured; `ensure` is every ID ever declared, so an ID removed from
  # the config is distinguishable from a fresh machine.
  state = "/var/lib/magi/flatpak";
  ensure = pkgs.writeText "magi-flatpak-ensure" (concatLines cfg.ensure);
in {
  options.modules.apps.flatpak = with types; {
    enable = mkBoolOpt false;
    ensure =
      mkOpt' (listOf str) []
      "Flatpak app IDs this host wants installed. Removing one here uninstalls it on the next `magi gc -s`.";
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

    systemd.services.magi-flatpak-ensure-packages = {
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      after = ["network-online.target"];
      path = [config.services.flatpak.package];
      # A one-shot: without these it drops to inactive the moment it returns,
      # and a boot without network leaves a failed unit behind.
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # N installs plus an update can outlast the 90s default.
        timeoutStartSec = "30min";
      };
      script =
        ''
          system="$(readlink /run/current-system)"
          [ "$(cat ${state}/system 2>/dev/null)" = "$system" ] && exit 0
          flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        ''
        + optionalString (cfg.ensure != []) ''
          flatpak install -y --noninteractive --or-update flathub ${escapeShellArgs cfg.ensure}
        ''
        + ''
          flatpak update -y --noninteractive
          mkdir -p ${state}
          # Keep track of what flatpaks are managed from nix. Atomic, since the
          # on-gc hook may be reading this.
          cat ${ensure} ${state}/ensure 2>/dev/null | sort -u >${state}/ensure.new
          mv ${state}/ensure.new ${state}/ensure
          printf '%s\n' "$system" >${state}/system
        '';
    };

    # Uninstall unused/unneeded packages. Only on a system GC: removals are
    # slow, and `magi gc -s` is already the explicit maintenance action.
    magi.hooks."on-gc".flatpak = let
      prune = pkgs.writeShellScript "magi-flatpak-prune" ''
        set -eu
        flatpak=${config.services.flatpak.package}/bin/flatpak

        # Run as root, so `flatpak list` sees the system installation: the
        # same one the ensure unit installs into.
        [ -n "$($flatpak list --app --columns=application)" ] || exit 0

        dropped="$(comm -23 <(LC_ALL=C sort ${state}/ensure 2>/dev/null) \
                           <(LC_ALL=C sort ${ensure}) \
                   | grep -Fxf <($flatpak list --app --columns=application) || true)"
        [ -z "$dropped" ] || $flatpak uninstall -y --noninteractive $dropped
        $flatpak uninstall -y --noninteractive --unused

        # Settled; forget them, or they'd be "dropped" at every gc after a
        # reinstall. Atomic, the ensure unit reads this too.
        mkdir -p ${state}
        cat ${ensure} >${state}/ensure.new
        mv ${state}/ensure.new ${state}/ensure
      '';
    in ''
      [[ " $* " == *" system "* ]] || exit 0
      sudo ${prune}
    '';
  };
}
