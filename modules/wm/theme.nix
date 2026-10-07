## modules/wm/theme.nix
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.wm.theme;

  fontSize = 12;
  # The renderer owns the palette and writes the Qt colour scheme.
  qtScheme = "magi.conf";
  # Just enough of a qt{5,6}ct config for the session palette to land. The
  # rest of the file is qtct's own defaults and I'd rather not pin those.
  # QFont's string form grew nine fields between Qt5 and Qt6, so `tail` --
  # the weight and everything after it -- is all the two versions disagree on.
  mkQtCt = dir: tail: let
    font = name: ''"${name},${toString fontSize},-1,5,${tail}"'';
  in ''
     [Appearance]
    color_scheme_path=${config.home.configDir}/${dir}/colors/${qtScheme}
    custom_palette=true
    icon_theme=${cfg.icons.name}
    style=Fusion

    [Fonts]
    fixed=${font cfg.fonts.mono}
    general=${font cfg.fonts.sans}
  '';
in {
  options.modules.wm.theme = with types; {
    fonts = {
      mono = mkOpt' str "JetBrainsMono Nerd Font" "Font for terminals and editors";
      sans = mkOpt' str "Fira Sans" "Font for everything else";
      terminal = {
        name = mkOpt' (nullOr str) null "Font for terminals. Defaults to `mono`.";
        size = mkOpt' int 13 "Terminal font size, in points";
      };
      packages =
        mkOpt' (listOf package)
        (with pkgs; [
          # For GUIs
          fira
          ubuntu-classic

          # For editors/terminals
          dejavu_fonts
          fira-code
          fira-code-symbols
          symbola
          nerd-fonts.jetbrains-mono

          # For design software
          montserrat
          open-sans
        ]) "Complete font set. Setting it REPLACES the defaults. Must include `mono` and `sans`.";
      extraPackages =
        mkOpt' (listOf package) []
        "Fonts installed on top of `packages`. Use this to add to the defaults.";
    };

    cursor = {
      name = mkOpt' str "phinger-cursors-dark" "Cursor theme for the dark variant";
      lightName = mkOpt' str "phinger-cursors-light" "Cursor theme for the light variant";
      package =
        mkOpt' package pkgs.phinger-cursors
        "The package shipping both cursor themes. The greeter installs this itself.";
      size = mkOpt' int 32 "Cursor size, in pixels";
    };

    icons = {
      name = mkOpt' str "Mono-Dark" "Icon theme for the dark variant";
      lightName = mkOpt' str "Mono" "Icon theme for the light variant";
      packages =
        mkOpt' (listOf package)
        [self.packages.mono-icons]
        "Packages searched for `name` and `lightName`";
    };

    files =
      mkOpt'
      (attrsOf (submodule {
        options = {
          input_path = mkOpt' str "" "The template to render";
          output_path = mkOpt' str "" "Where to write the rendered template";
          scope =
            mkOpt' (enum ["desktop" "terminal"]) "desktop"
            "Which palette bundle renders this file";
          pre_hook = mkOpt' lines "" "Shell run before the template is written";
          post_hook = mkOpt' lines "" "Shell run after the template is written";
        };
      }))
      {} "Files the theme renderer writes when the palette changes";
  };

  config = mkIf (config.modules.wm.desktop == "hyprland") (mkMerge [
    {
      magi.info.theme = {
        fonts = {
          inherit (cfg.fonts) mono sans;
          terminal = {
            name =
              if cfg.fonts.terminal.name == null
              then cfg.fonts.mono
              else cfg.fonts.terminal.name;
            size = cfg.fonts.terminal.size;
          };
        };
        cursor = {inherit (cfg.cursor) name lightName size;};
        icons = {inherit (cfg.icons) name lightName;};
      };

      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = cfg.fonts.packages ++ cfg.fonts.extraPackages;
      };

      # glib is what supplies gsettings/gdbus, which wallcolors.py uses to retheme
      # GTK apps and post its backup notice. dconf alone doesn't put them on PATH.
      environment.systemPackages = [pkgs.glib cfg.cursor.package] ++ cfg.icons.packages;
    }

    ## So GTK apps respect the session theme
    {
      # GTK apps read icon-theme out of gsettings, so the default has to live
      # in dconf to be found. The cursor rides along for anything that asks.
      programs.dconf = {
        enable = true;
        profiles.user.databases = [
          {
            settings."org/gnome/desktop/interface" = {
              icon-theme = cfg.icons.name;
              cursor-theme = cfg.cursor.name;
              cursor-size = gvariant.mkInt32 cfg.cursor.size;
            };
          }
        ];
      };

      environment.sessionVariables = {
        # nixpkgs ships schemas outside XDG_DATA_DIRS, so gsettings needs pointing.
        GSETTINGS_SCHEMA_DIR = pkgs.glib.getSchemaPath pkgs.gsettings-desktop-schemas;
        XCURSOR_THEME = cfg.cursor.name;
        XCURSOR_SIZE = toString cfg.cursor.size;
        HYPRCURSOR_THEME = cfg.cursor.name;
        HYPRCURSOR_SIZE = toString cfg.cursor.size;
      };
    }

    ## So Qt apps respect the session palette
    {
      qt = {
        enable = true;
        platformTheme = "qt5ct";
      };
      environment.sessionVariables = {
        QT_QPA_PLATFORMTHEME = "qt5ct";
        QT_QPA_PLATFORMTHEME_QT6 = "qt6ct";
      };

      # Picking the scheme in qt6ct used to be a once-per-machine chore, and
      # the machine I did it on is still wearing the palette its predecessor
      # rendered. Nix owns both configs now, so the chore is gone -- at the
      # price of qtct's GUI no longer being able to save over them.
      home.configFile = {
        "qt5ct/qt5ct.conf".text = mkQtCt "qt5ct" "50,0,0,0,0,0";
        "qt6ct/qt6ct.conf".text = mkQtCt "qt6ct" "400,0,0,0,0,0,0,0,0,0,0,1,,0,0";
      };
    }

    ## The Qt colour scheme is one of the renderer's desktop outputs, so it
    ## follows the same palette as Hyprland, fsel and qutebrowser.
    {
      modules.wm.theme.files = {
        qt5ct = {
          input_path = "${config.magi.configDir}/theme/qtct.template.conf";
          output_path = "${config.home.configDir}/qt5ct/colors/magi.conf";
        };
        qt6ct = {
          input_path = "${config.magi.configDir}/theme/qtct.template.conf";
          output_path = "${config.home.configDir}/qt6ct/colors/magi.conf";
        };
        fsel = {
          input_path = "${config.magi.configDir}/fsel/config.template.toml";
          output_path = "${config.home.configDir}/fsel/config.toml";
        };
      };
    }
    ## The manifest theme.py reads. It is a state link so the renderer can
    ## watch for a rebuild without writing into the checkout.
    (mkIf (cfg.files != {}) {
      home.stateLink."magi/theme/templates.json" = "${pkgs.writeText "magi-templates.json" (
        builtins.toJSON (mapAttrsToList (name: f: {
            inherit name;
            inherit (f) input_path output_path scope pre_hook post_hook;
          })
          cfg.files)
      )}";
    })
  ]);
}
