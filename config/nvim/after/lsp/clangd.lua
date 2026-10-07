---@type minimal.lsp.config
return {
  cmd = {
    'clangd',
    '-j=' .. (vim.env.CORES and vim.env.CORES or '4'),
    '--background-index',
    '--clang-tidy',
    '--inlay-hints',
    '--fallback-style=llvm',
    '--all-scopes-completion',
    '--completion-style=detailed',
    '--header-insertion=iwyu',
    '--header-insertion-decorators',
    '--pch-storage=memory',
  },
  filetypes = {
    'c',
    'cpp',
  },
  root_markers = {
    {
      '.clangd',
      '.clang-tidy',
      '.clang-format',
    },
    {
      'compile_commands.json',
      'compile_flags.txt',
      'configure.ac',
    },
    {
      '.git',
    },
    {
      ---@diagnostic disable-next-line undefined-field
      vim.uv.cwd(), -- equivalent of `single_file_mode` in lspconfig
    },
  },
}
