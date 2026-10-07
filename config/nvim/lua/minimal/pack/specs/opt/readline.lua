---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.readline',
  data = {
    enabled = not vim.g.vscode,
    events = { 'CmdlineEnter', 'InsertEnter' },
    postload = function()
      require('minimal.plugin.readline').setup()
    end,
  },
}
