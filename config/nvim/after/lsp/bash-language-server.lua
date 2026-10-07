---@type minimal.lsp.config
return {
  filetypes = { 'bash', 'zsh', 'sh' },
  cmd = {
    'bash-language-server',
    'start',
  },
  settings = {
    bashIde = {
      globPattern = vim.env.GLOB_PATTERN or '*@(.sh|.zsh|.inc|.bash|.command)',
      shfmt = {
        keepPadding = true,
      },
    },
  },
}
