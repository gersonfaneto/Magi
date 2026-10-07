# test/nixos/modules/wm/theme.nix --- tests for modules/wm/theme.nix
#
# The module owns the Qt scheme, the font sets and the manifest the theme
# renderer reads. It rides modules.wm.desktop, so every read goes through that;
# the manifest points at live templates, which pure eval can't open, so the
# on-disk checks read them off the snapshot DIR stands in for.
{
  evalConfig,
  presets,
  lib,
  pkgs,
  dir,
  ...
}:
with lib; let
  desktop = modules: evalConfig ([{modules.wm.desktop = "hyprland";}] ++ modules);
  shell = presets.hyprland;

  # Every real host with a desktop, plus the template-bearing apps no host
  # happens to run right now.
  configs =
    filter (c: c.modules.wm.desktop != null) (attrValues presets.hosts)
    ++ [
      (desktop [
        {
          modules.shell.tmux.enable = true;
          modules.apps.term.foot.enable = true;
          modules.apps.browsers.librewolf.enable = true;
        }
      ])
    ];
  inputs = unique (
    concatMap
    (
      c:
        map (p: dir + removePrefix c.magi.dir p) (
          catAttrs "input_path" (attrValues c.modules.wm.theme.files)
        )
    )
    configs
  );
in {
  ## The Qt scheme and the manifest.

  testNothingIsWrittenWithoutTheDesktop = let
    c = presets.bare;
  in {
    expr = {
      qt = c.home.configFile ? "qt6ct/qt6ct.conf";
      manifest = c.home.stateLink ? "magi/theme/templates.json";
    };
    expected = {
      qt = false;
      manifest = false;
    };
  };

  # The renderer writes colors/magi.conf, so these files are what actually puts
  # the palette on a Qt app.
  testQtCtSelectsThePaletteScheme = let
    c = shell;
  in {
    expr =
      map
      (
        v:
          hasInfix "color_scheme_path=${c.home.configDir}/${v}ct/colors/magi.conf"
          c.home.configFile."${v}ct/${v}ct.conf".text
      )
      [
        "qt5"
        "qt6"
      ];
    expected = [
      true
      true
    ];
  };

  testQtCtIsInstalledWithTheDesktop = {
    expr = shell.home.configFile ? "qt6ct/qt6ct.conf";
    expected = true;
  };

  # wallcolors.py rethemes GTK through gsettings and posts its notice through
  # gdbus; dconf alone doesn't install either binary.
  testGlibProvidesGSettings = {
    expr = any (p: (p.pname or "") == "glib") presets.hyprland.environment.systemPackages;
    expected = true;
  };

  # bat's base16 theme emits terminal ANSI colours, so it follows the palette
  # without a generated theme or a cache rebuild.
  testBatUsesTerminalPalette = let
    c = desktop [{modules.shell.zsh.enable = true;}];
  in {
    expr = c.home.configFile."bat/config".text;
    expected = "--theme=base16\n";
  };

  testFzfTarget = let
    c = desktop [{modules.shell.zsh.enable = true;}];
  in {
    expr = c.modules.wm.theme.files.fzf.output_path;
    expected = "${c.home.configDir}/fzf/theme.opts";
  };

  # The shell reads the same bundle as the rest of the desktop: prompt,
  # dircolors, fast-syntax-highlighting and autosuggestions.
  testZshTargets = let
    c = desktop [{modules.shell.zsh.enable = true;}];
  in {
    expr = {
      p10k = c.modules.wm.theme.files."zsh-p10k".output_path;
      dircolors = c.modules.wm.theme.files."zsh-dircolors".output_path;
      syntax = c.modules.wm.theme.files."zsh-syntax-highlighting".output_path;
      autosuggest = c.modules.wm.theme.files."zsh-autosuggestions".output_path;
    };
    expected = {
      p10k = "${c.home.configDir}/zsh/theme.p10k.zsh";
      dircolors = "${c.home.configDir}/zsh/dircolors.theme";
      syntax = "${c.home.configDir}/zsh/theme.fsh.zsh";
      autosuggest = "${c.home.configDir}/zsh/theme.autosuggest.zsh";
    };
  };

  testTmuxTarget = let
    c = desktop [{modules.shell.tmux.enable = true;}];
  in {
    expr = {
      output = c.modules.wm.theme.files.tmux.output_path;
      sourced = hasInfix "tmux/theme.conf" c.environment.etc."tmux.conf".text;
    };
    expected = {
      output = "${c.home.configDir}/tmux/theme.conf";
      sourced = true;
    };
  };

  # Generated config belongs in XDG directories, never in the live checkout.
  testTargetsStayOutOfCheckout = let
    c = desktop [
      {
        modules.shell.zsh.enable = true;
        modules.shell.tmux.enable = true;
      }
    ];
  in {
    expr = filter (f: hasPrefix c.magi.dir f.output_path) (attrValues c.modules.wm.theme.files);
    expected = [];
  };

  # Both desktop and terminal outputs render the active mono bundle now.
  testDesktopFileScopes = let
    c = shell;
  in {
    expr = map (name: c.modules.wm.theme.files.${name}.scope) ["hyprland" "hyprlock" "qt5ct" "qt6ct" "fsel"];
    expected = ["desktop" "desktop" "desktop" "desktop" "desktop"];
  };

  testTerminalFileScopes = let
    c = desktop [
      {
        modules.apps.term.foot.enable = true;
        modules.shell.scripts.enable = true;
        modules.shell.tmux.enable = true;
        modules.shell.zsh.enable = true;
        modules.editors.vim.enable = true;
      }
    ];
    names = [
      "foot"
      "highlight"
      "tmux"
      "fzf"
      "zsh-p10k"
      "zsh-dircolors"
      "zsh-syntax-highlighting"
      "zsh-autosuggestions"
      "nvim"
    ];
  in {
    expr = map (name: c.modules.wm.theme.files.${name}.scope) names;
    expected = map (_: "terminal") names;
  };

  testManifestMatchesFiles = let
    c = desktop [
      {
        modules.wm.theme.files.example = {
          input_path = "${dir}/theme/qtct.template.conf";
          output_path = "/out";
          pre_hook = "true";
        };
      }
    ];
    manifest = filter (f: f.name == "example") (fromJSON (readFile c.home.stateLink."magi/theme/templates.json"));
  in {
    expr = manifest;
    expected = [
      {
        name = "example";
        input_path = "${dir}/theme/qtct.template.conf";
        output_path = "/out";
        scope = "desktop";
        pre_hook = "true";
        post_hook = "";
      }
    ];
  };

  testExplicitScope = let
    c = desktop [
      {
        modules.wm.theme.files.example = {
          input_path = "${dir}/theme/foot.template.ini";
          output_path = "/out";
          scope = "terminal";
        };
      }
    ];
    manifest = filter (f: f.name == "example") (fromJSON (readFile c.home.stateLink."magi/theme/templates.json"));
  in {
    expr = manifest;
    expected = [
      {
        name = "example";
        input_path = "${dir}/theme/foot.template.ini";
        output_path = "/out";
        scope = "terminal";
        pre_hook = "";
        post_hook = "";
      }
    ];
  };

  ## Font sets: `packages` replaces the defaults, `extraPackages` adds to them.

  testExtraPackagesAppend = {
    expr = let
      base = presets.hyprland.fonts.packages;
      c = desktop [{modules.wm.theme.fonts.extraPackages = [pkgs.hello];}];
    in {
      keepsDefaults = all (p: elem p c.fonts.packages) base;
      addsExtra = elem pkgs.hello c.fonts.packages;
      emptyByDefault = presets.hyprland.modules.wm.theme.fonts.extraPackages;
    };
    expected = {
      keepsDefaults = true;
      addsExtra = true;
      emptyByDefault = [];
    };
  };

  testPackagesReplaceDefaults = {
    expr = let
      c = desktop [
        {
          modules.wm.theme.fonts.packages = [pkgs.hello];
        }
      ];
    in {
      # The theme option itself is replaced ...
      theme = c.modules.wm.theme.fonts.packages;
      # ... and the system set follows it (plus nixpkgs' own
      # enableGhostscriptFonts additions).
      systemHasHello = elem pkgs.hello c.fonts.packages;
      systemDropsDefaultFira = elem pkgs.fira c.fonts.packages;
    };
    expected = {
      theme = [pkgs.hello];
      systemHasHello = true;
      systemDropsDefaultFira = false;
    };
  };

  ## Terminal font: `terminal` rides `mono` unless overridden.

  testTerminalFontDefaultsToMono = {
    expr = (desktop []).magi.info.theme.fonts.terminal;
    expected = {
      name = "JetBrainsMono Nerd Font";
      size = 13;
    };
  };

  testTerminalFontOverrides = {
    expr = map (m: (desktop m).magi.info.theme.fonts.terminal) [
      [{modules.wm.theme.fonts.mono = "Foo";}]
      [{modules.wm.theme.fonts.terminal.name = "Bar";}]
      [{modules.wm.theme.fonts.terminal.size = 14;}]
    ];
    expected = [
      {
        name = "Foo";
        size = 13;
      }
      {
        name = "Bar";
        size = 13;
      }
      {
        name = "JetBrainsMono Nerd Font";
        size = 14;
      }
    ];
  };

  testFootFontFollowsTerminalFont = {
    expr = let
      c = desktop [
        {
          modules.apps.term.foot.enable = true;
          modules.wm.theme.fonts.terminal.name = "Bar";
          modules.wm.theme.fonts.terminal.size = 14;
        }
      ];
    in
      hasInfix "font=Bar:size=14" c.home.configFile."foot/foot.ini".text;
    expected = true;
  };

  ## Template inputs and the mono palette.

  # The renderer fails on a missing input instead of skipping it, and it can't
  # be handed a font, so no template may ask for one -- fonts come from Nix.
  testEveryTemplateInputExistsAndAsksForNoFont = {
    expr = rec {
      missing = filter (p: !(builtins.pathExists p)) inputs;
      fonts = filter (p: hasInfix "theme.fonts" (readFile p)) (subtractLists missing inputs);
    };
    expected = {
      missing = [];
      fonts = [];
    };
  };

  # There is one palette family with two tones. Both foot themes must exist
  # and palette.nix has to link both bundles.
  testMonoPalettesAreComplete = let
    c = presets.hyprland;
    tones = ["dark" "light"];
  in {
    expr = {
      foot = map (tone: builtins.pathExists "${dir}/config/foot/themes/mono-${tone}.ini") tones;
      links = map (tone: c.home.stateLink ? "magi/theme/palettes/mono-${tone}.json") tones;
    };
    expected = {
      foot = [true true];
      links = [true true];
    };
  };

  testMonoWallpapersLinked = let
    c = presets.hyprland;
  in {
    expr = c.home.dataLink."magi/wallpapers";
    expected = "${c.magi.configDir}/assets/wallpapers";
  };

  testMonoCursorAndIcons = let
    c = presets.hyprland;
  in {
    expr = {
      icons = {
        name = c.modules.wm.theme.icons.name;
        light = c.modules.wm.theme.icons.lightName;
        packages = map (p: p.pname or "") c.modules.wm.theme.icons.packages;
      };
      cursor = {
        name = c.modules.wm.theme.cursor.name;
        light = c.modules.wm.theme.cursor.lightName;
        package = c.modules.wm.theme.cursor.package.pname or "";
      };
      info = {
        inherit (c.magi.info.theme) icons cursor;
      };
    };
    expected = {
      icons = {
        name = "Mono-Dark";
        light = "Mono";
        packages = ["magi-mono-icons"];
      };
      cursor = {
        name = "phinger-cursors-dark";
        light = "phinger-cursors-light";
        package = "phinger-cursors";
      };
      info = {
        icons = {
          name = "Mono-Dark";
          lightName = "Mono";
        };
        cursor = {
          name = "phinger-cursors-dark";
          lightName = "phinger-cursors-light";
          size = 32;
        };
      };
    };
  };
}
