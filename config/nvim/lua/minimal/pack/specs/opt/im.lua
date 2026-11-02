---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.im',
  data = {
    enabled = not vim.g.vscode,
    events = {
      event = 'ModeChanged',
      pattern = '*:[ictRss\x13]*',
    },
    postload = function()
      require('minimal.plugin.im').setup()
    end,
  },
}
