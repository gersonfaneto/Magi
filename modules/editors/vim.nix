## modules/editor/vim.nix
#
# When I'm stuck in the terminal or don't have access to Emacs, (neo)vim is my
# go-to. I am a vimmer at heart, after all.

{ self, lib, config, options, pkgs, ... }:

with lib;
with self.lib;
let
  cfg = config.modules.editors.vim;
  # Nightly (0.13+) for config/nvim's vim.pack + latest APIs. Taken as a
  # package, not the input's overlay, which can mismatch the bundled
  # tree-sitter vendor hash. Taken unwrapped, not run through
  # wrapNeovimUnstable: the wrapper exports VIMINIT pointing at its generated
  # init, and a set VIMINIT makes nvim skip ~/.config/nvim/init.lua entirely
  # ($MYVIMRC stays empty, only plugin//after/ dirs still load).
  neovimNightly = self.inputs."neovim-nightly".packages.neovim;
in
{
  options.modules.editors.vim = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    user.packages = with pkgs; [
      editorconfig-core-c
      neovimNightly

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
      nixd
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
    ];

    # Symlink the whole config/nvim tree out of $XDG_CONFIG_HOME/nvim so edits
    # take effect without a rebuild. Nyx uses native vim.pack with
    # stdpath('config')/lua/... spec discovery, so a single-file init.lua shim
    # would break spec collection -- the full tree must be on stdpath.
    home.configLink."nvim" = "${config.hey.configDir}/nvim";

    # Seeds for rainbow-delimiters. blend harmonises each hue toward the
    # current scheme, so they stay distinguishable without clashing with it.
    modules.wm.theme.colors = {
      rainbow_red = { color = "#e53935"; blend = true; };
      rainbow_orange = { color = "#fb8c00"; blend = true; };
      rainbow_yellow = { color = "#fdd835"; blend = true; };
      rainbow_green = { color = "#43a047"; blend = true; };
      rainbow_cyan = { color = "#00acc1"; blend = true; };
      rainbow_blue = { color = "#1e88e5"; blend = true; };
      rainbow_violet = { color = "#8e24aa"; blend = true; };
    };

    modules.wm.theme.files.nvim = {
      input_path = "${config.hey.configDir}/nvim/colors.template.lua";
      output_path = "${config.home.stateDir}/nvim/colors.lua";

      # Reload nvim when the theme changes. The default scheme is Nyx's
      # `minimal`; `matugen` stays available via colors/matugen.lua +
      # lua/config/colors.lua for whoever wants the dynamic palette.
      post_hook = ''
        for sock in "''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/nvim.*; do
          [ -S "$sock" ] || continue
          ${neovimNightly}/bin/nvim --server "$sock" \
            --remote-expr "execute('colorscheme minimal')" >/dev/null 2>&1 || true
        done
      '';
    };

    environment.shellAliases = {
      vim = "nvim";
      v = "nvim";
    };
  };
}
