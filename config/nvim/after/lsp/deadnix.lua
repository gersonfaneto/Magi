-- deadnix finds and removes unused code in .nix source files
-- https://github.com/astro/deadnix

---@type minimal.lsp.config
return {
  filetypes = { 'nix' },
  cmd = { 'efm-langserver' },
  requires = { 'deadnix', 'jq' },
  name = 'deadnix',
  settings = {
    languages = {
      nix = {
        {
          lintSource = 'deadnix',
          -- deadnix has no stdin mode: lint the saved file, convert its
          -- JSON report to `Severity file:line:col: message` via jq.
          -- Silent (exit 0, no output) when the file is clean.
          lintCommand = [[deadnix --output-format json ${INPUT} | jq -r '.results[] as $r | "W \(.file):\($r.line):\($r.column): \($r.message)"']],
          lintFormats = { '%tarning %f:%l:%c: %m' },
          lintAfterOpen = true,
          lintStdin = false,
          lintIgnoreExitCode = true,
        },
      },
    },
  },
}
