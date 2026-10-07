# modules/wm/greeter.nix
#
# The login screen: tuigreet on greetd's VT, launching the configured Hyprland
# session. No compositor and no shell run before login.
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

  # greetd runs the session command through sh, and tuigreet hands --cmd to it.
  session = "${getExe pkgs.uwsm} start -e -D Hyprland hyprland.desktop";

  tuigreet = "${getExe pkgs.tuigreet} --time --remember --asterisks --cmd '${session}'";
in {
  options.modules.wm.greeter = {
    enable = mkOpt' types.bool (cfg.desktop != null) "Enable the login screen.";
  };

  config = mkIf (cfg.desktop == "hyprland" && cfg.greeter.enable) {
    services.greetd.enable = true;
    services.displayManager.defaultSession = "hyprland-uwsm";
    services.greetd.settings.default_session = {
      command = tuigreet;
      user = "greeter";
    };
  };
}
