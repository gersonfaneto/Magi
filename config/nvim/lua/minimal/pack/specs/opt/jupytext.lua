---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.jupytext',
  data = {
    enabled = not vim.g.vscode,
    events = { event = 'BufReadCmd', pattern = '*.ipynb' },
    postload = function()
      require('minimal.plugin.jupytext').setup()
    end,
  },
}
