---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.statusline',
  data = {
    enabled = not vim.g.vscode,
  },
}
