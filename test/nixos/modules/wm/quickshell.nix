# test/nixos/modules/wm/quickshell.nix --- tests for modules/wm/quickshell.nix
#
# The module wires a vendored shell to the system: links its config, starts its
# surfaces, and switches wifi to NetworkManager. None of that fails a build when
# it drifts -- the shell just never starts, or starts twice.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [
    {
      modules.wm.desktop = "hyprland";
      modules.wm.quickshell.enable = true;
    }
  ];
  off = evalConfig [{modules.wm.desktop = "hyprland";}];

  surfaces = filterAttrs (n: _: n == "quickshell-pill" || n == "quickshell-lock") on.systemd.user.services;
in {
  ## Gating.

  # Off unless asked, so nothing double-starts.
  testOffByDefaultStartsNothing = {
    expr = {
      noService = off.systemd.user.services ? quickshell-pill;
      noLinks = off.home.link ? "${off.home.dir}/.config/quickshell";
    };
    expected = {
      noService = false;
      noLinks = false;
    };
  };

  ## The vendored trees.

  # Linked from the live checkout, not snapshotted, so a QML edit needs no
  # rebuild.
  testLinksTheShellFromTheCheckout = {
    expr = {
      shell = on.home.link."${on.home.dir}/.config/quickshell";
      scripts = on.home.link."${on.home.dir}/.config/hypr/scripts";
      eq = on.home.link."${on.home.dir}/.config/hypr/sound/eq.conf";
      mic = hasPrefix "/nix/store/" on.home.link."${on.home.dir}/.config/hypr/sound/mic.conf";
    };
    expected = {
      shell = "/etc/magi/config/quickshell";
      scripts = "/etc/magi/config/hypr/scripts";
      eq = "/etc/magi/config/hypr/sound/eq.conf";
      mic = true;
    };
  };

  ## The surfaces.

  testStartsBothSurfaces = {
    expr = mapAttrs (n: s: hasInfix "-c ${removePrefix "quickshell-" n}" s.serviceConfig.ExecStart) surfaces;
    expected = {
      "quickshell-pill" = true;
      "quickshell-lock" = true;
    };
  };

  # The Settings surfaces write ~/.config/hypr/local/modules, never the
  # checkout; the seed unit makes that tree exist on login.
  testSettingsTreeIsLocalAndSeeded = {
    expr = {
      link = on.home.link ? "${on.home.dir}/.config/hypr/modules";
      seed = hasInfix "seed-local-config.sh" on.systemd.user.services.hypr-settings-seed.serviceConfig.ExecStart;
    };
    expected = {
      link = false;
      seed = true;
    };
  };

  # The Idle/Lock and Night Light surfaces own these conf files; the daemons
  # only run them (the surfaces regenerate the files themselves).
  testRunsIdleAndNightLight = {
    expr = {
      idle = hasInfix "hypridle" on.systemd.user.services.hypridle.serviceConfig.ExecStart;
      sunset = hasInfix "hyprsunset" on.systemd.user.services.hyprsunset.serviceConfig.ExecStart;
    };
    expected = {
      idle = true;
      sunset = true;
    };
  };

  # The shell drives hyprctl, awww and the user's apps from the session PATH,
  # not NixOS's minimal service PATH.
  testSurfacesInheritTheSessionPath = {
    expr = mapAttrs (_: s: s.enableDefaultPath) surfaces;
    expected = {
      "quickshell-pill" = false;
      "quickshell-lock" = false;
    };
  };

  testRestoresTheWallpaper = {
    expr = {
      service = hasInfix "wallpaper.sh init" on.systemd.user.services.quickshell-wallpaper.serviceConfig.ExecStart;
      path = on.systemd.user.services.quickshell-wallpaper.enableDefaultPath;
    };
    expected = {
      service = true;
      path = false;
    };
  };

  testGivesTheShellTheRNNoisePlugin = {
    expr = {
      service = hasSuffix "/librnnoise_ladspa.so" on.systemd.user.services.quickshell-pill.environment.RNNOISE_LADSPA_PATH;
      session = hasSuffix "/librnnoise_ladspa.so" on.environment.sessionVariables.RNNOISE_LADSPA_PATH;
    };
    expected = {
      service = true;
      session = true;
    };
  };

  testBothSurfacesRestart = {
    expr = mapAttrs (_: s: s.serviceConfig.Restart) surfaces;
    expected = {
      "quickshell-pill" = "always";
      "quickshell-lock" = "always";
    };
  };

  # The Mixer faders drive external monitors over DDC, which needs i2c exposed;
  # the udev rule grants the local seat access without a group.
  testExposesI2cForTheMixer = {
    expr = {
      on = on.hardware.i2c.enable;
      off = off.hardware.i2c.enable;
    };
    expected = {
      on = true;
      off = false;
    };
  };

  ## rishot.

  # The launcher resolves its src/ from an envvar, since the linked copy is a
  # store path with no sibling src/.
  testRishotPointsAtTheCheckout = {
    expr = {
      env = on.environment.sessionVariables.RISHOT_CONFIG_DIR;
      onPath = on.home.link."${on.home.dir}/.local/bin/rishot" != null;
    };
    expected = {
      env = "/etc/magi/config/rishot/src";
      onPath = true;
    };
  };

  ## The palette and template renderer.

  # Nix owns the washi and per-scheme palettes; the pill and the renderer read
  # them by key. One file per key, linked under $XDG_STATE_HOME.
  testLinksThePalettes = {
    expr = {
      washi = hasSuffix "/washi.json" on.home.stateLink."quickshell/palettes/washi.json";
      nano = hasSuffix "/nano-dark.json" on.home.stateLink."quickshell/palettes/nano-dark.json";
      sonokai = hasSuffix "/sonokai-light.json" on.home.stateLink."quickshell/palettes/sonokai-light.json";
    };
    expected = {
      washi = true;
      nano = true;
      sonokai = true;
    };
  };

  testGeneratesTheTemplateManifest = {
    expr = on.home.stateLink ? "quickshell/templates.json";
    expected = true;
  };

  # The renderer owns the palette; the path unit reruns it when the shell
  # changes flags or the manifest changes.
  testRunsTheThemeRenderer = {
    expr = {
      service = hasInfix "theme.py apply" on.systemd.user.services.quickshell-theme.serviceConfig.ExecStart;
      unit = on.systemd.user.paths.quickshell-theme.pathConfig.Unit;
      flags = elem "%h/.local/state/quickshell/flags.json" on.systemd.user.paths.quickshell-theme.pathConfig.PathChanged;
      manifest = elem "%h/.local/state/quickshell/templates.json" on.systemd.user.paths.quickshell-theme.pathConfig.PathChanged;
    };
    expected = {
      service = true;
      unit = "quickshell-theme.service";
      flags = true;
      manifest = true;
    };
  };
}
