---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.term',
  data = {
    enabled = not vim.g.vscode,
    events = 'TermOpen',
    postload = function()
      require('minimal.plugin.term').setup()
    end,
  },
}
