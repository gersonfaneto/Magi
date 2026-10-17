---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.tabline',
  data = {
    enabled = not vim.g.vscode,
  },
}
