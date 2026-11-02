---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.addasync',
  data = {
    enabled = not vim.g.vscode,
    events = 'InsertEnter',
    postload = function()
      require('minimal.plugin.addasync').setup()
    end,
  },
}
