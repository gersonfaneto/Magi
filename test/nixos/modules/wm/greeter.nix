# test/nixos/modules/wm/greeter.nix --- tests for modules/wm/greeter.nix
#
# The Quickshell greeter has to agree with greetd about who owns the login
# path. If the wrapper is missing, greetd would fall back to a bare tuigreet.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  greeter = evalConfig [{modules.wm.desktop = "hyprland";}];
  disabled = evalConfig [
    {
      modules.wm.desktop = "hyprland";
      modules.wm.greeter.enable = false;
    }
  ];
in {
  testQuickshellGreeterOwnsTheSession = {
    expr = {
      greetd = greeter.services.greetd.enable;
      user = greeter.services.greetd.settings.default_session.user;
      wrapper =
        hasInfix "quickshell-greeter-session"
        greeter.services.greetd.settings.default_session.command;
      session = greeter.services.displayManager.defaultSession;
    };
    expected = {
      greetd = true;
      user = "greeter";
      wrapper = true;
      session = "hyprland-uwsm";
    };
  };

  testGreeterCanBeDisabled = {
    expr = disabled.services.greetd.enable;
    expected = false;
  };
}
