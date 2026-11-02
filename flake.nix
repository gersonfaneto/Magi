# flake.nix --- the heart of my dotfiles
#
# Welcome to ground zero. Where the whole flake gets set up and all its modules
# are loaded.
{
  description = "A grossly incandescent nixos config.";

  inputs = {
    # Core dependecies
    # nixpkgs tracks nixos-unstable on its own schedule. Hyprland builds its
    # packages against its own pin (and pushes those to hyprland.cachix), so
    # it has nothing to gain by dictating ours; following it only made nixpkgs
    # lag whenever its lock sat still.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    # Desktop dependencies
    hyprland.url = "github:hyprwm/Hyprland";

    # Extras (imported directly by modules/hosts that need them)
    emacs-overlay.url = "github:nix-community/emacs-overlay";
    emacs-overlay.inputs.nixpkgs.follows = "nixpkgs";
    # Nightly neovim for config/nvim (vim.pack + 0.13+ APIs). Used as a
    # package, not an overlay: as an overlay it can mismatch the bundled
    # tree-sitter vendor hash when our treesitter differs from its expected.
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";
    neovim-nightly.inputs.nixpkgs.follows = "nixpkgs";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    llm-agents.url = "github:numtide/llm-agents.nix";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [
      "https://hyprland.cachix.org" # hyprland
      "https://nix-community.cachix.org" # emacs-overlay
      "https://emacs-ci.cachix.org" # emacs-overlay
      "https://cache.numtide.com" # llm-agents
    ];
    extra-trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "emacs-ci.cachix.org-1:B5FVOrxhXXrOL0S+tQ7USrhjMT5iOPH+QN9q0NItom4="
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  outputs = inputs:
    with import ./lib {inherit (inputs.nixpkgs) lib;};
      mkFlake inputs {
        systems = ["x86_64-linux"];

        hosts = mapHosts ./hosts;
        modules.default = import ./.;

        apps.install = mkApp "${inputs.self.packages.x86_64-linux.installer}/bin/install";
        devShells.default = import ./shell.nix;
        checks = mapModules ./test import;
        overlays = mapModules ./overlays import;
        packages = mapModules ./packages import;
        templates = import ./templates;
        treefmt = ./treefmt.nix;
      };
}
