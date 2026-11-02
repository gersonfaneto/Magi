# test/nixos/modules/editors-emacs.nix --- tests for modules/editors/emacs.nix
#
# The configuration is a straight.el tree in config/emacs: init.el,
# early-init.el and the minimal-* libraries. It has to be linked whole (not
# copied) because Emacs loads sibling files from user-emacs-directory. Mutable
# state, including straight.el, deliberately lives outside the checkout.
{
  evalConfig,
  lib,
  ...
}:
with lib; let
  on = evalConfig [{modules.editors.emacs.enable = true;}];
  off = evalConfig [{modules.editors.emacs.enable = false;}];
  custom = evalConfig [
    {
      modules.editors.emacs.enable = true;
      modules.editors.emacs.font = "Test Mono";
      modules.editors.emacs.variableFont = "Test Sans";
      modules.editors.emacs.fontSize = 14;
    }
  ];

  names = map (p: toLower (p.pname or p.name or "")) on.user.packages;
  has = name: any (n: n == name || hasPrefix "${name}-" n) names;
in {
  # The live checkout, not a store snapshot: edits take effect without a rebuild.
  testEmacsIsLinkedWholeFromDotfiles = let
    link = on.home.configLink.emacs or null;
  in {
    expr = {
      link = link;
      live = link != null && hasSuffix "/config/emacs" link;
      noShim = !(on.home.configFile ? "emacs/init.el");
    };
    expected = {
      link = on.magi.configDir + "/emacs";
      live = true;
      noShim = true;
    };
  };

  testDisabledLinksNothing = let
    links = filterAttrs (n: _: hasPrefix "emacs" n) off.home.configLink;
  in {
    expr = links;
    expected = {};
  };

  # HEAD + native-comp, taken straight from the emacs-overlay package set.
  testEmacsIsPgtkHead = {
    expr = has "emacs-pgtk";
    expected = true;
  };

  # External programs the configuration invokes directly or through eglot.
  testRuntimeClosureCoversConfigDependencies = {
    expr = map has [
      "binutils"
      "git"
      "ripgrep"
      "gnutls"
      "xdg-utils"
      "multimarkdown"
      "nixd"
      "alejandra"
      "direnv"
      "aspell"
    ];
    expected = map (_: true) (lib.range 1 10);
  };

  # Emacs consumes the same palette bundle as the rest of the desktop. The
  # rendered file must stay out of the checkout and reload a running server.
  testEmacsUsesTheMagiPalette = let
    palette = on.modules.wm.theme.files.emacs;
  in {
    expr = {
      template = palette.input_path;
      target = palette.output_path;
      outsideCheckout = !(hasPrefix "${on.magi.dir}/" palette.output_path);
      reloads = hasInfix "minimal/reload-theme" palette.post_hook;
    };
    expected = {
      template = "${on.magi.configDir}/theme/emacs.template.el";
      target = "${on.home.stateDir}/quickshell/emacs-palette.el";
      outsideCheckout = true;
      reloads = true;
    };
  };

  testDisabledDoesNotRegisterPalette = {
    expr = off.modules.wm.theme.files ? emacs;
    expected = false;
  };

  # The default fonts come from the desktop theme; both parts are overridable.
  testFontDefaultsToTheme = {
    expr = {
      font = on.environment.sessionVariables.MAGI_EMACS_FONT;
      variableFont = on.environment.sessionVariables.MAGI_EMACS_VARIABLE_FONT;
      size = on.environment.sessionVariables.MAGI_EMACS_FONT_SIZE;
    };
    expected = {
      font = on.modules.wm.theme.fonts.mono;
      variableFont = on.modules.wm.theme.fonts.sans;
      size = "10";
    };
  };

  testFontOverrides = {
    expr = {
      font = custom.environment.sessionVariables.MAGI_EMACS_FONT;
      variableFont = custom.environment.sessionVariables.MAGI_EMACS_VARIABLE_FONT;
      size = custom.environment.sessionVariables.MAGI_EMACS_FONT_SIZE;
    };
    expected = {
      font = "Test Mono";
      variableFont = "Test Sans";
      size = "14";
    };
  };

  testShellAliasesAreSourced = {
    expr = any (p: hasSuffix "/config/emacs/aliases.zsh" p) on.modules.shell.zsh.rcFiles;
    expected = true;
  };
}
