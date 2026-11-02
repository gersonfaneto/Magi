## modules/editor/vim.nix
#
# When I'm stuck in the terminal or don't have access to Emacs, (neo)vim is my
# go-to. I am a vimmer at heart, after all.
{
  self,
  lib,
  config,
  options,
  pkgs,
  ...
}:
with lib;
with self.lib; let
  cfg = config.modules.editors.vim;
  # Nightly (0.13+) for config/nvim's vim.pack + latest APIs. Taken as a
  # package, not the input's overlay, which can mismatch the bundled
  # tree-sitter vendor hash. Taken unwrapped, not run through
  # wrapNeovimUnstable: the wrapper exports VIMINIT pointing at its generated
  # init, and a set VIMINIT makes nvim skip ~/.config/nvim/init.lua entirely
  # ($MYVIMRC stays empty, only plugin//after/ dirs still load).
  neovimNightly = self.inputs."neovim-nightly".packages.neovim;
in {
  options.modules.editors.vim = {
    enable = mkBoolOpt false;
    nerdFonts = mkOpt' types.bool false ''
      Enable nerd-font icons in nvim. Sets $NVIM_NF, which
      config/nvim/lua/minimal/core/opts.lua reads at startup (any value
      enables it; the terminal must also render a nerd font).
    '';
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      editorconfig-core-c
      neovimNightly
      vim # fallback when nvim is unusable; config/vim/vimrc is Bekaboo/dot's .vimrc

      ## Finder / core (fzf-lua hard-errors without fzf; fd/rg fall back to find/grep)
      git
      fd
      ripgrep
      fzf

      ## For nvim-treesitter (grammars compile on demand via :TSInstall)
      gcc
      tree-sitter

      ## Clipboard provider (stock pkgs.neovim's wrapper supplies this; the
      ## unwrapped nightly needs it on PATH for unnamedplus to work)
      wl-clipboard

      ## Plugin build toolchains (blink.cmp, LuaSnip, markdown-preview, molten)
      gnumake
      cargo
      rustc
      nodejs
      python3
      python3Packages.pynvim

      ## Config lint (config/nvim/Makefile)
      luaPackages.luacheck
      stylua

      ## Language servers, linters and formatters (curated subset of
      ## config/nvim/after/lsp; the rest resolve from PATH when installed)
      bash-language-server
      lua-language-server
      efm-langserver
      nil
      nixd
      alejandra
      # nixd formats Nix with this (config/nvim/after/lsp/nixd.lua); alejandra
      # is what `nix fmt` (treefmt) uses.
      nixfmt
      statix
      deadnix
      jq # deadnix JSON -> efm via jq (also used by terraform validate)
      marksman
      yaml-language-server
      ruff
      pyright
      gopls
      rust-analyzer
      clang-tools
      shellcheck
      shfmt
      # qmlls/qmllint/qmlformat for QML (config/nvim/after/lsp/qmlls.lua).
      qt6.qtdeclarative
    ];

    # Symlink the whole config/nvim tree out of $XDG_CONFIG_HOME/nvim so edits
    # take effect without a rebuild. Nyx uses native vim.pack with
    # stdpath('config')/lua/... spec discovery, so a single-file init.lua shim
    # would break spec collection -- the full tree must be on stdpath.
    home.configLink."nvim" = "${config.magi.configDir}/nvim";

    # ShellCheck reads $XDG_CONFIG_HOME/shellcheckrc (or ~/.shellcheckrc); the
    # shellcheck LSP above and plain CLI use share it.
    home.configLink."shellcheckrc" = "${config.magi.configDir}/shellcheckrc";

    # Plain vim's fallback config (Bekaboo/dot's .vimrc), snapshotted into the
    # store. Interactive shells still alias vim -> nvim below.
    home.file.".vimrc".source = "${self.configDir}/vim/vimrc";

    # nvim's curated themes are the setcolor/setbg scheme set
    # (config/nvim/colors/* plus the everforest/gruvbox-material plugins). The
    # pipeline additionally renders generated.lua into nvim's site dir for the
    # washi/dynamic sources; it is never written into the checkout.
    modules.wm.theme.files.nvim = {
      input_path = "${config.magi.configDir}/theme/nvim.template.lua";
      output_path = "${config.home.dataDir}/nvim/site/colors/generated.lua";
    };

    environment.shellAliases = {
      vim = "nvim";
      v = "nvim";
    };

    # config/nvim/lua/minimal/core/opts.lua gates its nerd-font icon set on
    # this being present; any value counts, so "1" is just conventional.
    #
    # qmlls (config/nvim/after/lsp/qmlls.lua) runs with `-E`, i.e. it reads
    # this variable for QML module dirs. The store binary does not infer its
    # own QML prefix, so qtdeclarative is explicit; the rest is what the
    # vendored Quickshell rice imports (mirrors modules/wm/quickshell.nix).
    environment.sessionVariables = mkMerge [
      (mkIf cfg.nerdFonts {
        NVIM_NF = "1";
      })
      {
        QML_IMPORT_PATH = concatMapStringsSep ":" (p: "${p}/lib/qt-6/qml") (
          [pkgs.qt6.qtdeclarative]
          ++ optionals config.modules.wm.quickshell.enable [
            pkgs.quickshell
            pkgs.qt6.qtmultimedia
            pkgs.qt6.qt5compat
          ]
        );
      }
    ];
  };
}
