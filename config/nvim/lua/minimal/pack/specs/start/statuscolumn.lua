---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.statuscolumn',
  data = {
    enabled = not vim.g.vscode,
  },
}
