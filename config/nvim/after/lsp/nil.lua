-- Nix language server via nil
-- https://github.com/oxalica/nil
--
-- Static analysis companion to nixd.lua: nil owns formatting, rename,
-- code actions, hover, goto and static diagnostics. Completion stays
-- enabled here alongside nixd: nil's scope-based package names (e.g.
-- inside `with pkgs; [ ... ]`) complement nixd's evaluated nixpkgs
-- index, and the client dedupes identical labels.

---@type minimal.lsp.config
return {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', 'flake.lock', '.git' },
  settings = {
    ['nil'] = {
      -- Single `alejandra` owner (matches treefmt.nix); nixd.lua
      -- deliberately sets no formatting command so `gq;` never races.
      formatting = {
        command = { 'alejandra' },
      },
      diagnostics = {
        ignored = {},
        excludedFiles = {},
      },
      nix = {
        binary = 'nix',
        maxMemoryMB = 2560,
        flake = {
          -- Never hit the network from the editor; only use fetched
          -- inputs. nixd already carries the evaluated nixpkgs index,
          -- so nil contributes scope-based completions without the
          -- extra `autoEvalInputs` memory cost.
          autoArchive = false,
          autoEvalInputs = false,
          nixpkgsInputName = 'nixpkgs',
        },
      },
    },
  },
}
