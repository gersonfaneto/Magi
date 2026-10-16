-- Nix language server via nixd
-- https://github.com/nix-community/nixd

-- Magi flake hosts (hosts/<name>/). `vim.fn.hostname()` does not always
-- equal the `nixosConfigurations.<host>` attr, so only wire per-host
-- options for known hosts; otherwise fall back to plain nixpkgs support
-- instead of sending nixd a broken `builtins.getFlake` expr.
local nixos_hosts = {
  harusame = true,
  htpc = true,
  melchior = true,
  ramen = true,
  soba = true,
  udon = true,
}

---Find the Magi flake root for the current buffer.
---Prefers the enclosing flake; a `shell.nix` project without a flake keeps
---channel nixpkgs; otherwise falls back to the live checkout env vars
---exported by `nix develop` (DOTFILES_HOME) and Magi login (see
---modules/hey.nix, modules/home.nix). Returns nil outside any of those.
---@return string?
local function flake_root()
  local project_flake = vim.fs.root(0, { 'flake.nix' })
  if project_flake ~= nil then
    return project_flake
  end
  if vim.fs.root(0, { 'shell.nix' }) ~= nil then
    return nil
  end
  local env = vim.env.DOTFILES_HOME or vim.env.DOTFILES
  return (env ~= nil and env ~= '') and env or nil
end

local flake = flake_root()
local host = vim.fn.hostname()

local nixpkgs_expr = flake == nil and 'import <nixpkgs> { }'
  or string.format('import (builtins.getFlake "%s").inputs.nixpkgs { }', flake)

-- Per-host options only when the flake root and host attr both resolve.
local options = {}
if flake ~= nil and nixos_hosts[host] then
  options.nixos = {
    expr = string.format(
      '(builtins.getFlake "%s").nixosConfigurations.%s.options',
      flake,
      host
    ),
  }
  options.home_manager = {
    expr = string.format(
      '(builtins.getFlake "%s").homeConfigurations.%s.options',
      flake,
      host
    ),
  }
end

---@type minimal.lsp.config
return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', 'flake.lock', '.git' },
  settings = {
    nixd = {
      nixpkgs = {
        expr = nixpkgs_expr,
      },
      options = options,
      formatting = {
        command = { 'nixfmt' },
      },
    },
  },
}
