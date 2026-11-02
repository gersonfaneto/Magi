---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.vscode',
  data = {
    enabled = not not vim.g.vscode,
    postload = function()
      require('minimal.plugin.vscode').setup()
    end,
  },
}
