---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.multicursor',
  data = {
    enabled = not vim.g.vscode,
    postload = function()
      require('minimal.plugin.multicursor').setup()
    end,
  },
}
