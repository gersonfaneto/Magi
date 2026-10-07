---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.expandtab',
  data = {
    enabled = not vim.g.vscode,
    events = 'InsertEnter',
    postload = function()
      require('minimal.plugin.expandtab').setup()
    end,
  },
}
