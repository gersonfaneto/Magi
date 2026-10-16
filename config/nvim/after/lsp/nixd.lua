-- Nix language server via nixd
-- https://github.com/nix-community/nixd
--
-- Completion + NixOS option eval. Runs alongside nil.lua: completion
-- comes from both (nixd's evaluated nixpkgs index plus nil's
-- scope-based names; the client dedupes), nil owns everything else
-- (formatting, rename, code actions, hover, goto, static diagnostics).

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

---Find the Magi flake root for a buffer root.
---Prefers the enclosing flake; a `shell.nix` project without a flake keeps
---channel nixpkgs; otherwise falls back to the live checkout env vars
---exported by `nix develop` (DOTFILES_HOME) and Magi login (see
---modules/hey.nix, modules/home.nix). Returns nil outside any of those.
---@param root_dir string? buffer root, falls back to current buffer
---@return string?
local function flake_root(root_dir)
  local source = root_dir or 0
  local project_flake = vim.fs.root(source, { 'flake.nix' })
  if project_flake ~= nil then
    return project_flake
  end
  if vim.fs.root(source, { 'shell.nix' }) ~= nil then
    return nil
  end
  local env = vim.env.DOTFILES_HOME or vim.env.DOTFILES
  return (env ~= nil and env ~= '') and env or nil
end

---@param flake string?
---@return string
local function nixpkgs_expr(flake)
  if flake == nil then
    return 'import <nixpkgs> { }'
  end
  return string.format(
    'import (builtins.getFlake "%s").inputs.nixpkgs { }',
    flake
  )
end

-- Per-host NixOS options only when the flake root and host attr both
-- resolve. Magi has no `homeConfigurations` output and no home-manager
-- integration (see modules/home.nix), so only `nixos` is wired. The key
-- name is arbitrary per nixd docs; `nixos` matches upstream examples.
---@param flake string?
---@param host string?
---@return table
local function nixd_options(flake, host)
  if flake == nil or host == nil or not nixos_hosts[host] then
    return {}
  end
  return {
    nixos = {
      expr = string.format(
        '(builtins.getFlake "%s").nixosConfigurations.%s.options',
        flake,
        host
      ),
    },
  }
end

---@param params lsp.InitializeParams
---@param config vim.lsp.Config
local function before_init(params, config)
  local root_dir = config.root_dir
  if (root_dir == nil or root_dir == '') and params.rootUri ~= nil then
    root_dir = vim.uri_to_fname(params.rootUri)
  end
  local flake = flake_root(root_dir)
  config.settings = config.settings or {}
  config.settings.nixd = config.settings.nixd or {}
  config.settings.nixd.nixpkgs = { expr = nixpkgs_expr(flake) }
  config.settings.nixd.options = nixd_options(flake, vim.fn.hostname())
  -- Formatting lives in nil.lua; leaving `formatting` unset here keeps a
  -- single `alejandra` owner so `vim.lsp.buf.format()` never races.
  config.settings.nixd.formatting = nil
end

-- Completion plus eval diagnostics: nil.lua owns formatting, rename,
-- code actions, hover, goto and static diagnostics. Completion is kept
-- here too (deduped by the client). Push diagnostics
-- (`publishDiagnostics`) still flow from nixd; only pull/static
-- capabilities are stripped here.
---@param client vim.lsp.Client
local function on_attach(client, _bufnr) -- luacheck: no unused args
  local caps = client.server_capabilities
  caps.callHierarchyProvider = nil
  caps.codeActionProvider = nil
  caps.codeLensProvider = nil
  caps.colorProvider = nil
  caps.declarationProvider = nil
  caps.definitionProvider = nil
  caps.documentFormattingProvider = nil
  caps.documentHighlightProvider = nil
  caps.documentLinkProvider = nil
  caps.documentOnTypeFormattingProvider = nil
  caps.documentRangeFormattingProvider = nil
  caps.documentSymbolProvider = nil
  caps.executeCommandProvider = nil
  caps.foldingRangeProvider = nil
  caps.hoverProvider = nil
  caps.implementationProvider = nil
  caps.inlayHintProvider = nil
  caps.inlineValueProvider = nil
  caps.linkedEditingRangeProvider = nil
  caps.monikerProvider = nil
  caps.referencesProvider = nil
  caps.renameProvider = nil
  caps.selectionRangeProvider = nil
  caps.semanticTokensProvider = nil
  caps.signatureHelpProvider = nil
  caps.typeDefinitionProvider = nil
  caps.typeHierarchyProvider = nil
  caps.workspaceSymbolProvider = nil
end

---@type minimal.lsp.config
return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', 'flake.lock', '.git' },
  before_init = before_init,
  on_attach = on_attach,
  settings = {
    nixd = {
      nixpkgs = {
        expr = 'import <nixpkgs> { }',
      },
      options = {},
    },
  },
}
