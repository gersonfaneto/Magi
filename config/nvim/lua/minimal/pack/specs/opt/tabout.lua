---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.tabout',
  data = {
    enabled = not vim.g.vscode,
    events = 'InsertEnter',
    postload = function()
      require('minimal.plugin.tabout').setup()
    end,
  },
}
