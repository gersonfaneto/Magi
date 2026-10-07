# test/nixos/modules/wm/greeter.nix --- tests for modules/wm/greeter.nix
#
# tuigreet has to agree with greetd about who owns the login path and which
# session to hand over. The old Quickshell wrapper is gone; if it came back,
# greetd would run a compositor before login.
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
  testTuigreetOwnsTheSession = {
    expr = {
      greetd = greeter.services.greetd.enable;
      user = greeter.services.greetd.settings.default_session.user;
      tuigreet =
        hasInfix "tuigreet"
        greeter.services.greetd.settings.default_session.command;
      session = greeter.services.displayManager.defaultSession;
      sessionCmd =
        hasInfix "uwsm start"
        greeter.services.greetd.settings.default_session.command;
    };
    expected = {
      greetd = true;
      user = "greeter";
      tuigreet = true;
      session = "hyprland-uwsm";
      sessionCmd = true;
    };
  };

  testGreeterCanBeDisabled = {
    expr = disabled.services.greetd.enable;
    expected = false;
  };
}
