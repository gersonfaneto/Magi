---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.intro',
  data = {
    enabled = not vim.g.vscode,
  },
}
