# test/nixos/modules/wm/shell.nix --- tests for the shell plumbing in
# modules/wm/hyprland.
#
# The desktop has no bar, pop-ups or overlays: fsel in foot replaces the old
# Quickshell surfaces, notifications are logged, and the lock is hyprlock. None
# of that fails a build when it drifts -- the session just loses the feature --
# so pin the wiring here.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  c = evalConfig [{modules.wm.desktop = "hyprland";}];
  services = c.systemd.user.services;
  paths = c.systemd.user.paths;

  pkgNames = map (p: p.pname or p.name or "") c.environment.systemPackages;
in {
  ## No shell.

  testQuickshellIsGone = {
    expr = {
      package = elem "quickshell" pkgNames;
      link = c.home.link ? "${c.home.dir}/.config/quickshell";
    };
    expected = {
      package = false;
      link = false;
    };
  };

  ## The launcher and clipboard.

  testFselReplacesTheLauncher = {
    expr = {
      fsel = elem "fsel" pkgNames;
      cliphist = elem "cliphist" pkgNames;
      clipService = services ? cliphist;
      clipScript = services.cliphist.serviceConfig.ExecStart;
    };
    expected = {
      fsel = true;
      cliphist = true;
      clipService = true;
      clipScript = "${c.magi.configDir}/hypr/scripts/cliphist-watch.sh";
    };
  };

  ## Notifications are a log sink.

  testNotificationsAreLogged = {
    expr = {
      service = services ? magi-notifyd;
      exec = hasInfix "bin/magi-notifyd" services.magi-notifyd.serviceConfig.ExecStart;
      python = hasInfix "python3" services.magi-notifyd.serviceConfig.ExecStart;
    };
    expected = {
      service = true;
      exec = true;
      python = true;
    };
  };

  ## Lock, idle and night light.

  testHypridleUsesHyprlock = {
    expr = {
      idle = services ? hypridle;
      sunset = services ? hyprsunset;
      seed = hasInfix "hypridle.conf" services.hypridle.serviceConfig.ExecStartPre;
    };
    expected = {
      idle = true;
      sunset = true;
      seed = true;
    };
  };

  testLockIsRendered = {
    expr = {
      lock = c.modules.wm.theme.files.hyprlock.output_path;
      template = c.modules.wm.theme.files.hyprlock.input_path;
      scripts = c.home.link."${c.home.dir}/.config/hypr/scripts";
    };
    expected = {
      lock = "${c.home.configDir}/hypr/hyprlock.conf";
      template = "${c.magi.configDir}/theme/hyprlock.template.conf";
      scripts = "${c.magi.configDir}/hypr/scripts";
    };
  };

  ## Theme and wallpaper follow the same startup.

  testThemePipeline = {
    expr = {
      service = services ? magi-theme;
      path = paths ? magi-theme;
      unit = paths.magi-theme.pathConfig.Unit;
      watched = paths.magi-theme.pathConfig.PathChanged;
      state = c.home.stateLink."magi/theme/templates.json";
      old = c.home.stateLink ? "quickshell/templates.json";
    };
    expected = {
      service = true;
      path = true;
      unit = "magi-theme.service";
      watched = [
        "%h/.local/state/magi/theme/flags.json"
        "%h/.local/state/magi/theme/templates.json"
      ];
      state = c.home.stateLink."magi/theme/templates.json";
      old = false;
    };
  };

  testWallpaperRestoresAtLogin = {
    expr = {
      service = services ? magi-wallpaper;
      exec = hasInfix "wallpaper.sh init" services.magi-wallpaper.serviceConfig.ExecStart;
    };
    expected = {
      service = true;
      exec = true;
    };
  };
}
