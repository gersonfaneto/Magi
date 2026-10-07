# profiles/hardware/bluetooth.nix --- bluetooth support
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib;
  mkIf (elem "bluetooth" config.modules.profiles.hardware) {
    hardware.bluetooth.enable = true;

    # Leave Policy.ReconnectAttempts at BlueZ's default (7). It used to be
    # pinned to 0 here, which disables host-side reconnection, so paired input
    # devices and headsets never came back after a link loss or suspend.

    # bluetoothd has no pairing agent of its own, and bluetoothctl only
    # registers one in interactive mode (client/main.c skips registration
    # whenever commands are passed as arguments). With no agent, every pairing
    # that needs a confirmation fails with "No agent available for request
    # type 2" -- both the pill's non-interactive `bluetoothctl pair` and a
    # device bonding on its own. Keep a just-works agent alive for the session;
    # NoInputNoOutput because there is no passkey dialog to answer.
    systemd.user.services.bluetooth-agent = {
      description = "Bluetooth pairing agent";
      wantedBy = ["default.target"];
      serviceConfig = {
        ExecStart = "${pkgs.bash}/bin/bash -c 'exec ${getExe' pkgs.bluez "bluetoothctl"} --agent=NoInputNoOutput < <(${getExe' pkgs.coreutils "sleep"} infinity)'";
        Restart = "always";
        RestartSec = 2;
      };
    };

    # Brute force a reset after waking up from sleep, as some bluetooth devices
    # will fail to connect to a system that's been suspended at some point.
    # systemd.services.bluetooth-resume = {
    #   description = "Restart bluetooth after resume";
    #   wantedBy = [ "sleep.target" ];
    #   before = [ "sleep.target" ];
    #   unitConfig.StopWhenUnneeded = true;
    #   preStop = "${pkgs.systemd}/bin/systemctl restart bluetooth.service";
    #   serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    # };
  }
