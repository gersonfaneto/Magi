---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.colorcolumn',
  data = {
    enabled = not vim.g.vscode,
    postload = function()
      require('minimal.plugin.colorcolumn').setup()
    end,
  },
}
