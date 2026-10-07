# test/nixos/modules/editors-vim.nix --- tests for modules/editors/vim.nix
#
# config/nvim is Nyx's vim.pack tree (lua/minimal/*, after/lsp/*). It discovers
# plugin specs via stdpath('config')/lua/..., so the module must link the whole
# tree onto stdpath -- a single-file init.lua shim would break spec collection.
# The suite pins the link shape, the runtime closure, and the theme handoff.
{
  evalConfig,
  lib,
  pkgs,
  flake,
  system,
  ...
}:
with lib; let
  on = evalConfig [{modules.editors.vim.enable = true;}];
  off = evalConfig [{modules.editors.vim.enable = false;}];
  nf = evalConfig [
    {
      modules.editors.vim.enable = true;
      modules.editors.vim.nerdFonts = true;
    }
  ];

  names = map (p: toLower (p.pname or p.name or "")) on.user.packages;
  has = name: any (n: n == name || hasPrefix "${name}-" n) names;
  neovims =
    filter
    (
      p: (toLower (p.pname or "")) == "neovim" || hasPrefix "neovim-" (toLower (p.name or ""))
    )
    on.user.packages;
in {
  # The full tree lives on the live checkout, editable without a rebuild.
  testNvimIsLinkedWholeFromDotfiles = let
    link = on.home.configLink.nvim or null;
  in {
    expr = {
      link = link;
      live = link != null && hasSuffix "/config/nvim" link;
      noShim = !(on.home.configFile ? "nvim/init.lua");
    };
    expected = {
      link = on.magi.configDir + "/nvim";
      live = true;
      noShim = true;
    };
  };

  # Nothing linked when disabled.
  testDisabledLinksNothing = let
    links = filterAttrs (n: _: hasPrefix "nvim" n) off.home.configLink;
  in {
    expr = links;
    expected = {};
  };

  # vim.pack + fzf-lua + treesitter + builds + curated LSP set.
  testRuntimeClosureCoversNyxDeps = {
    expr = map has [
      "neovim"
      "fzf"
      "fd"
      "ripgrep"
      "gcc"
      "gnumake"
      "cargo"
      "rustc"
      "nodejs"
      "luacheck"
      "stylua"
      "bash-language-server"
      "lua-language-server"
      "efm-langserver"
      "nixd"
      "nixfmt"
      "statix"
      "deadnix"
      "jq"
      "marksman"
      "yaml-language-server"
      "ruff"
      "pyright"
      "gopls"
      "rust-analyzer"
      "clang-tools"
      "shellcheck"
      "shfmt"
      "wl-clipboard"
    ];
    expected = map (_: true) (lib.range 1 29);
  };

  # The pipeline registers the only colorscheme, generated.lua, in nvim's site
  # dir; there are no curated colors/ files left to drift from the mono tone.
  testNvimRegistersGeneratedTemplate = {
    expr = let
      t = on.modules.wm.theme.files.nvim;
    in {
      registered = on.modules.wm.theme.files ? nvim;
      generated = hasSuffix "/nvim/site/colors/generated.lua" t.output_path;
      notInCheckout = !(hasPrefix "${on.magi.dir}/" t.output_path);
    };
    expected = {
      registered = true;
      generated = true;
      notInCheckout = true;
    };
  };

  # vim/v aliases survive the port.
  testShellAliasesSurvive = {
    expr = {
      vim = on.environment.shellAliases.vim or null;
      v = on.environment.shellAliases.v or null;
    };
    expected = {
      vim = "nvim";
      v = "nvim";
    };
  };

  # $NVIM_NF only when opted in; config/nvim checks for its presence.
  testNerdFontsOptIn = {
    expr = {
      enabled = nf.environment.sessionVariables.NVIM_NF or null;
      default = on.environment.sessionVariables.NVIM_NF or null;
    };
    expected = {
      enabled = "1";
      default = null;
    };
  };

  # Exactly one neovim, and it's the nightly wrap -- not nixpkgs stable.
  # (Relational, so `nix flake update` on either input can't break it.)
  testNeovimIsNightlyNotStable = {
    expr = {
      count = length neovims;
      differs = map (p: (p.version or "unknown") != pkgs.neovim.version) neovims;
    };
    expected = {
      count = 1;
      differs = [true];
    };
  };

  # The neovim must be the input's package itself, not a wrapNeovimUnstable
  # product: the wrapper exports VIMINIT at its generated init, and any set
  # VIMINIT makes nvim skip ~/.config/nvim/init.lua ($MYVIMRC stays empty).
  testNeovimIsUnwrappedInput = {
    expr = elem flake.inputs."neovim-nightly".packages.${system}.neovim on.user.packages;
    expected = true;
  };
}
