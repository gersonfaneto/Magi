---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.lsp-commands',
  data = {
    enabled = not vim.g.vscode,
    events = { 'Syntax', 'FileType', 'LspAttach', 'DiagnosticChanged' },
    postload = function()
      require('minimal.plugin.lsp-commands').setup()
    end,
  },
}
