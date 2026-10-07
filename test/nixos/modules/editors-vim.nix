# test/nixos/modules/editors-vim.nix --- tests for modules/editors/vim.nix
#
# config/nvim is Nyx's vim.pack tree (lua/minimal/*, after/lsp/*). It discovers
# plugin specs via stdpath('config')/lua/..., so the module must link the whole
# tree onto stdpath -- a single-file init.lua shim would break spec collection.
# The suite pins the link shape, the runtime closure, and the theme bridge.

{ evalConfig, lib, pkgs, flake, system, ... }:

with lib;
let
  on = evalConfig [{ modules.editors.vim.enable = true; }];
  off = evalConfig [{ modules.editors.vim.enable = false; }];

  names = map (p: toLower (p.pname or p.name or "")) on.user.packages;
  has = name: any (n: n == name || hasPrefix "${name}-" n) names;
  neovims =
    filter (p: (toLower (p.pname or "")) == "neovim"
      || hasPrefix "neovim-" (toLower (p.name or ""))) on.user.packages;
in {
  # The full tree lives on the live checkout, editable without a rebuild.
  testNvimIsLinkedWholeFromDotfiles =
    let link = on.home.configLink.nvim or null; in {
      expr = {
        link = link;
        live = link != null && hasSuffix "/config/nvim" link;
        noShim = !(on.home.configFile ? "nvim/init.lua");
      };
      expected = {
        link = on.hey.configDir + "/nvim";
        live = true;
        noShim = true;
      };
    };

  # Nothing linked when disabled.
  testDisabledLinksNothing =
    let links = filterAttrs (n: _: hasPrefix "nvim" n) off.home.configLink; in {
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

  # Matugen template still renders to state; reload targets Nyx's minimal
  # scheme (matugen stays available as `:colorscheme matugen`).
  testThemeBridgeRendersAndReloadsMinimal =
    let
      t = on.modules.wm.theme.files.nvim;
      hook = t.post_hook or "";
    in {
      expr = {
        input = hasSuffix "/nvim/colors.template.lua" t.input_path;
        output = hasSuffix "/nvim/colors.lua" t.output_path;
        reloadsMinimal = hasInfix "colorscheme minimal" hook;
        notMatugen = !hasInfix "colorscheme matugen" hook;
      };
      expected = {
        input = true;
        output = true;
        reloadsMinimal = true;
        notMatugen = true;
      };
    };

  # vim/v aliases survive the port.
  testShellAliasesSurvive = {
    expr = {
      vim = on.environment.shellAliases.vim or null;
      v = on.environment.shellAliases.v or null;
    };
    expected = { vim = "nvim"; v = "nvim"; };
  };

  # Exactly one neovim, and it's the nightly wrap -- not nixpkgs stable.
  # (Relational, so `nix flake update` on either input can't break it.)
  testNeovimIsNightlyNotStable = {
    expr = {
      count = length neovims;
      differs = map (p: (p.version or "unknown") != pkgs.neovim.version)
        neovims;
    };
    expected = { count = 1; differs = [ true ]; };
  };

  # The neovim must be the input's package itself, not a wrapNeovimUnstable
  # product: the wrapper exports VIMINIT at its generated init, and any set
  # VIMINIT makes nvim skip ~/.config/nvim/init.lua ($MYVIMRC stays empty).
  testNeovimIsUnwrappedInput = {
    expr = elem flake.inputs."neovim-nightly".packages.${system}.neovim
      on.user.packages;
    expected = true;
  };
}
