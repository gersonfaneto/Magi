-- Statix lints and suggestions for the Nix programming language
-- https://github.com/oppiliappan/statix

---@type minimal.lsp.config
return {
  filetypes = { 'nix' },
  cmd = { 'efm-langserver' },
  requires = { 'statix' },
  name = 'statix',
  settings = {
    languages = {
      nix = {
        {
          lintSource = 'statix',
          -- Streaming mode: buffer on stdin, `errfmt` diagnostics on
          -- stdout (`<stdin>>line:col:Sev:code: message`). Exits 1 when
          -- findings exist, so ignore the exit code.
          lintCommand = 'statix check --stdin --format errfmt',
          lintFormats = { '<stdin>>%l:%c: %t:%n: %m' },
          lintAfterOpen = true,
          lintStdin = true,
          lintIgnoreExitCode = true,
        },
      },
    },
  },
}
