---@type minimal.pack.spec
return {
  src = 'https://github.com/gipo355/nvim-intellij-lsp',
  data = {
    postload = function()
      require('intellij-lsp').setup({
        server_dir = vim.fn.expand('~/') .. '.local/share/intellij-server',
      })

      vim.lsp.config('intellij-lsp', {
        initOptions = {
          defaultSdk = vim.fn.expand('~/')
            .. '.local/share/mise/installs/java/27',
        },
        root_markers = {
          {
            ---@diagnostic disable-next-line undefined-field
            vim.uv.cwd(), -- equivalent of `single_file_mode` in lspconfig
          },
        },
      })

      vim.lsp.enable('intellij-lsp')
    end,
  },
}
