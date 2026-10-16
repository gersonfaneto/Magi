# test/nixos/modules/apps-rofi.nix --- tests for modules/apps/rofi.nix
#
# The universal clipboard's history (SUPER+CTRL+v, `hey @rofi clipmenu`) is
# only as good as its database: cliphist has to be installed and its store
# has to watch the Wayland clipboard for the whole graphical session.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  # The bookmark launcher interpolates the default browser, as on any host.
  on = evalConfig [
    {
      modules.apps.rofi.enable = true;
      modules.apps.browsers.default = "chromium";
    }
  ];
  off = evalConfig [{modules.apps.rofi.enable = false;}];

  names = map (p: toLower (p.pname or p.name or "")) on.user.packages;
  has = name: any (n: n == name || hasPrefix "${name}-" n) names;
in {
  # The picker shell-outs to both, so both have to be around.
  testClipboardHistoryToolsAreInstalled = {
    expr = map has ["cliphist"];
    expected = [true];
  };

  # wl-paste --watch is what keeps the database fed; partOf is what starts
  # and stops it with the session, and restart keeps one crash from ending
  # history until next login.
  testCliphistStoreWatchesTheClipboard = let
    unit = on.systemd.user.services.cliphist or {};
    start = unit.serviceConfig.ExecStart or "";
  in {
    expr = {
      watches = hasInfix "wl-paste --watch" start && hasInfix "cliphist store" start;
      onSession = elem "graphical-session.target" (unit.wantedBy or []);
      partOf = elem "graphical-session.target" (unit.partOf or []);
      restarts = (unit.serviceConfig.Restart or null) == "on-failure";
    };
    expected = {
      watches = true;
      onSession = true;
      partOf = true;
      restarts = true;
    };
  };

  # Nothing installed, nothing running when disabled.
  testDisabledInstallsNothing = let
    offNames = map (p: toLower (p.pname or p.name or "")) off.user.packages;
  in {
    expr = {
      pkgs = filter (n: n == "cliphist" || hasPrefix "cliphist-" n) offNames;
      unit = (off.systemd.user.services or {}).cliphist or null;
    };
    expected = {
      pkgs = [];
      unit = null;
    };
  };
}
