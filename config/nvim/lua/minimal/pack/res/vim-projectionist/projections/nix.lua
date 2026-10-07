-- Projections for Nix files (Magi flake layout).
-- `*.nix`: lint the current file with statix via :Dispatch.
-- `flake.nix`: workspace check via `hey sync check` (= `nix flake check`).
return {
  ['*.nix'] = {
    ['*.nix'] = {
      type = 'source',
      dispatch = 'statix check %',
    },
  },
  ['flake.nix'] = {
    ['flake.nix'] = {
      type = 'config',
      dispatch = 'hey sync check',
    },
  },
}
