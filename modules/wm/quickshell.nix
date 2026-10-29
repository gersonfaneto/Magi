# modules/wm/quickshell.nix
#
# The desktop shell: a vendored Ricelin Quickshell (config/quickshell/), wired
# for Magi. Follows modules.wm.desktop = "hyprland".
#
# Off by default. melchior turns this on.
#
# Wifi and bluetooth are driven through NetworkManager and BlueZ; the pill
# glyph and the Wifi surface use Quickshell.Networking, which speaks
# NetworkManager's D-Bus API. The Nix palette, the template renderer, the
# Hyprland binds/hooks, and the Quickshell greeter (modules/wm/greeter.nix) are
# wired.
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
  qcfg = cfg.quickshell;
  qs = qcfg.package;

  # nixpkgs builds quickshell against qtbase/qtdeclarative/qtwayland/qtsvg only.
  # Ricelin imports QtMultimedia (the wallpaper surface) and
  # Qt5Compat.GraphicalEffects (rishot), so those QML modules and their plugins
  # have to be on the runtime search path. A wrapper rather than an
  # overrideAttrs, so adding two directories doesn't rebuild the whole shell.
  # `makeWrapper --prefix` appends to the env the inner wrapper already sets.
  qsShell =
    pkgs.runCommand "quickshell-${pkgs.quickshell.version}-shell" {
      nativeBuildInputs = [pkgs.makeWrapper];
    } ''
      mkdir -p $out/bin
      makeWrapper ${getExe' pkgs.quickshell "quickshell"} $out/bin/quickshell \
        --prefix NIXPKGS_QT6_QML_IMPORT_PATH : \
          '${pkgs.qt6.qtmultimedia}/lib/qt-6/qml:${pkgs.qt6.qt5compat}/lib/qt-6/qml' \
        --prefix QT_PLUGIN_PATH : \
          '${pkgs.qt6.qtmultimedia}/lib/qt-6/plugins:${pkgs.qt6.qt5compat}/lib/qt-6/plugins'
      ln -s $out/bin/quickshell $out/bin/qs
    '';

  # hypridle/hyprsunset read their config from ~/.config/hypr, but the Idle/Lock
  # and Night Light surfaces own those files. Seed the initial copy from the
  # checkout when missing so the daemons can start before the surfaces are opened.
  seedConf = name:
    pkgs.writeShellScript "magi-seed-${name}" ''
      cfg="$HOME/.config/hypr/${name}"
      if [ ! -e "$cfg" ]; then
        mkdir -p "$(dirname "$cfg")"
        cp "${config.magi.configDir}/hypr/${name}" "$cfg"
      fi
    '';
in {
  options.modules.wm.quickshell = with types; {
    enable = mkOpt' bool false "Enable the Quickshell desktop shell (vendored Ricelin).";
    package = mkOpt' package qsShell "The package providing the `qs` binary.";
  };

  config = mkIf (cfg.desktop == "hyprland" && qcfg.enable) (mkMerge [
    ## The shell and everything it drives.
    {
      environment.systemPackages = with pkgs; [
        qs
        python3 # wallcolors.py, the wallpaper-derived palette
        awww # wallpaper daemon
        matugen # wallpaper palette
        cava # audio visualizer
        cliphist # clipboard history
        brightnessctl # brightness OSD
        ddcutil # external-monitor brightness (Mixer faders)
        xorg.xrandr # XWayland primary flag when the Display surface swaps the main monitor
        gpu-screen-recorder # recorder surface
        ffmpeg-headless # wallpaper stills and thumbnails; no X11/GL needed
        mpvpaper # video wallpapers
        rnnoise-plugin # mic noise filter
        hypridle # idle / lock
        hyprsunset # night light
        gamemode # game mode surface
        imagemagick # wallpaper analysis and thumbnails
        adw-gtk3 # base theme for the GTK app palette
        # rishot OCR. The stock tesseract drags tessdata-all (1 GiB); the
        # languages actually used are enough. Add to this list when OCR needs
        # another language.
        (tesseract.override {enableLanguages = ["eng" "por" "osd"];})
        kdePackages.kdialog # rishot save dialog
      ];

      services.upower.enable = true;
      services.power-profiles-daemon.enable = true;

      # External-monitor brightness/contrast over DDC. The udev rule grants the
      # local seat access (TAG+="uaccess"), so no group membership is needed.
      hardware.i2c.enable = true;
    }

    ## The vendored trees, linked from the live checkout, so a QML edit is picked
    ## up by Quickshell's file watch rather than a rebuild.
    {
      home.configLink = {
        "quickshell" = "${config.magi.configDir}/quickshell";
        "hypr/scripts" = "${config.magi.configDir}/hypr/scripts";
        "hypr/sound/eq.conf" = "${config.magi.configDir}/hypr/sound/eq.conf";
      };

      # The mic filter points at the store copy of RNNoise, so it is generated
      # rather than linked from the checkout. The EQ graph is static.
      home.configFile = {
        "hypr/sound/mic.conf".source = pkgs.replaceVars "${self.configDir}/hypr/sound/mic.conf.in" {
          rnnoise = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
        };
      };

      # rishot locates its src/ through this; the launcher itself resolves to a
      # store copy, so the sibling-src fallback wouldn't find it.
      environment.sessionVariables = {
        RISHOT_CONFIG_DIR = "${config.magi.configDir}/rishot/src";
        RNNOISE_LADSPA_PATH = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
      };
      home.file.".local/bin/rishot" = {
        source = "${self.configDir}/rishot/bin/rishot";
        executable = true;
      };

      # The pill's surfaces replace the old launcher targets.
      user.packages = [
        (mkLauncherEntry "Quickshell: Settings" {
          icon = "preferences-system";
          exec = "qs -c pill ipc call pill settings \"\"";
        })
        (mkLauncherEntry "Quickshell: change wallpaper" {
          icon = "preferences-desktop-wallpaper";
          exec = "qs -c pill ipc call pill wallpaper \"\"";
        })
        (mkLauncherEntry "Quickshell: recorder" {
          icon = "media-record";
          exec = "qs -c pill ipc call pill recorder \"\"";
        })
      ];
    }

    ## The two surfaces. Ricelin ships a watchdog script to respawn these;
    ## systemd's Restart=always replaces it.
    {
      systemd.user.services = genAttrs ["quickshell-pill" "quickshell-lock"] (unit: let
        surface = removePrefix "quickshell-" unit;
      in {
        description = "Quickshell ${surface} (Ricelin shell)";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = [
          "graphical-session.target"
          "wayland-wm@hyprland.desktop.service"
        ];
        # The shell spawns hyprctl, awww, python3, rishot and the user's apps;
        # inherit the session's PATH instead of NixOS's minimal default.
        enableDefaultPath = false;
        serviceConfig = {
          ExecStart = "${getExe' qs "qs"} -c ${surface}";
          Restart = "always";
          RestartSec = 1;
        };
      });
    }

    ## Sound.qml probes this before offering the mic filter.
    {
      systemd.user.services.quickshell-pill.environment.RNNOISE_LADSPA_PATH = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
    }

    ## Idle and night-light daemons. The Idle/Lock and Night Light surfaces own
    ## hypridle.conf/hyprsunset.conf (seeded above), so these only run them.
    {
      systemd.user.services = {
        hypridle = {
          description = "Hypridle idle daemon";
          wantedBy = ["graphical-session.target"];
          partOf = ["graphical-session.target"];
          after = ["graphical-session.target"];
          # lock.sh needs hyprctl, jq and grim from the session PATH.
          enableDefaultPath = false;
          serviceConfig = {
            ExecStartPre = "${seedConf "hypridle.conf"}";
            ExecStart = "${getExe' pkgs.hypridle "hypridle"}";
            Restart = "on-failure";
          };
        };
        hyprsunset = {
          description = "Hyprsunset night light";
          wantedBy = ["graphical-session.target"];
          partOf = ["graphical-session.target"];
          after = ["graphical-session.target"];
          enableDefaultPath = false;
          serviceConfig = {
            ExecStartPre = "${seedConf "hyprsunset.conf"}";
            ExecStart = "${getExe' pkgs.hyprsunset "hyprsunset"}";
            Restart = "on-failure";
          };
        };
      };
    }

    ## Bring the last wallpaper back once Hyprland is up. wallpaper.sh starts
    ## awww itself, and mpvpaper for video wallpapers, so there is no separate
    ## wallpaper daemon unit to keep alive.
    {
      systemd.user.services.quickshell-wallpaper = {
        description = "Restore the last Quickshell wallpaper";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target" "wayland-wm@hyprland.desktop.service"];
        # wallpaper.sh drives awww, mpvpaper, jq, hyprctl and python3.
        enableDefaultPath = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${config.magi.configDir}/hypr/scripts/wallpaper.sh init";
          RemainAfterExit = true;
        };
      };
    }

    ## The palette-driven templates. Nix owns the palettes (modules/wm/palette.nix);
    ## theme.py copies the active bundle to current.json and renders the manifest
    ## that modules/wm/theme.nix generates. The path unit re-renders when the
    ## shell changes paletteMode/scheme/bg or the manifest changes.
    {
      systemd.user.services.quickshell-theme = {
        description = "Apply the active palette and render its templates";
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];
        # The post-hooks and wallcolors.py run hyprctl/gsettings/matugen.
        enableDefaultPath = false;
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.python3}/bin/python3 ${config.magi.configDir}/hypr/scripts/theme.py apply --refresh";
        };
      };

      systemd.user.paths.quickshell-theme = {
        wantedBy = ["graphical-session.target"];
        partOf = ["graphical-session.target"];
        pathConfig = {
          PathChanged = [
            "%h/.local/state/quickshell/flags.json"
            "%h/.local/state/quickshell/templates.json"
          ];
          Unit = "quickshell-theme.service";
        };
      };
    }
  ]);
}
