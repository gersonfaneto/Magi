# modules/wm/greeter.nix
#
# The graphical login screen: the vendored Quickshell greeter
# (config/quickshell/greeter), run inside cage. It speaks greetd's socket
# protocol through Quickshell.Services.Greetd and launches the configured
# Hyprland session.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.wm;
  qcfg = config.modules.wm.quickshell;

  sessionCmd = ["${pkgs.uwsm}/bin/uwsm" "start" "-e" "-D" "Hyprland" "hyprland.desktop"];

  # The greeter user cannot traverse the live checkout (~/.config is 0750), so
  # the greeter config is read from the store snapshot. cage is the kiosk
  # compositor; dbus-run-session gives Qt a session bus for portal registration.
  quickshellSession = pkgs.writeShellScript "quickshell-greeter-session" ''
    set -eu
    export XDG_RUNTIME_DIR="/tmp/quickshell-greeter-runtime-$(id -u)"
    mkdir -p "$XDG_RUNTIME_DIR"
    chmod 700 "$XDG_RUNTIME_DIR"
    export GREETER_USER="${config.user.name}"
    export GREETER_SESSION='${builtins.toJSON sessionCmd}'
    exec ${pkgs.dbus}/bin/dbus-run-session -- \
      ${pkgs.cage}/bin/cage -s -- \
      ${qcfg.package}/bin/qs -p ${self.configDir}/quickshell/greeter
  '';
in {
  options.modules.wm.greeter = {
    enable = mkOpt' types.bool (cfg.desktop != null) "Enable the graphical login screen.";
  };

  config = mkIf (cfg.desktop == "hyprland" && cfg.greeter.enable) {
    services.greetd.enable = true;
    services.displayManager.defaultSession = "hyprland-uwsm";
    services.greetd.settings.default_session = {
      command = "${quickshellSession}";
      user = "greeter";
    };
  };
}
