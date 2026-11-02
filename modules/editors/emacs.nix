# Emacs is my main driver. The configuration itself lives in config/emacs and
# is linked into place whole, so edits take effect without a rebuild.
{
  self,
  lib,
  config,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.editors.emacs;
  emacs = pkgs.emacs-git-pgtk;
in {
  options.modules.editors.emacs = with types; {
    enable = mkBoolOpt false;

    font =
      mkOpt' (nullOr str) null
      "Default Emacs font. Defaults to modules.wm.theme.fonts.mono.";

    variableFont =
      mkOpt' (nullOr str) null
      "Default Emacs variable-pitch font. Defaults to modules.wm.theme.fonts.sans.";

    fontSize =
      mkOpt' int 10
      "Default Emacs font size, in points.";
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      self.inputs.emacs-overlay.overlays.default
    ];

    user.packages = with pkgs; [
      (mkLauncherEntry "Emacs (Debug Mode)" {
        description = "Start Emacs in debug mode";
        icon = "emacs";
        exec = "${emacs}/bin/emacs --debug-init";
      })

      ## Emacs itself
      binutils # native-comp needs 'as', provided by this
      emacs # HEAD + native-comp

      ## Core runtime
      git
      ripgrep
      gnutls # for TLS connectivity
      xdg-utils # dired's open-with-external-program
      multimarkdown # markdown-mode's default export command
      (mkIf (config.programs.gnupg.agent.enable) pinentry-emacs) # in-emacs gnupg prompts

      ## Checkers and language servers
      (aspellWithDicts (ds: with ds; [en]))
      nixd # nix-mode's eglot server
      alejandra # nixd's formatter
      direnv # loaded by direnv.el when present
    ];

    # The whole tree is a live link into the checkout. straight.el and Emacs
    # write their mutable state under XDG data/cache/state (see early-init.el),
    # so the checkout stays source-only.
    home.configLink."emacs" = "${config.magi.configDir}/emacs";

    environment.sessionVariables = {
      MAGI_EMACS_FONT =
        if cfg.font != null
        then cfg.font
        else config.modules.wm.theme.fonts.mono;
      MAGI_EMACS_VARIABLE_FONT =
        if cfg.variableFont != null
        then cfg.variableFont
        else config.modules.wm.theme.fonts.sans;
      MAGI_EMACS_FONT_SIZE = toString cfg.fontSize;
    };

    # The active Magi palette is rendered into Emacs' state directory; the
    # post-hook asks a running server to reload it after every theme apply.
    modules.wm.theme.files.emacs = {
      input_path = "${config.magi.configDir}/theme/emacs.template.el";
      output_path = "${config.home.stateDir}/quickshell/emacs-palette.el";
      post_hook = ''
        ${emacs}/bin/emacsclient --eval '(minimal/reload-theme)' >/dev/null 2>&1 || true
      '';
    };

    modules.shell.zsh.rcFiles = ["${config.magi.configDir}/emacs/aliases.zsh"];

    fonts.packages = [pkgs.nerd-fonts.symbols-only];
  };
}
