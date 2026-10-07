---@type minimal.pack.spec
return {
  src = 'https://github.com/saecki/crates.nvim',
  version = 'stable',
  data = {
    events = {
      event = 'BufRead',
      pattern = 'Cargo.toml',
    },
    postload = function()
      require('crates').setup({
        completion = {
          crates = {
            enabled = true,
          },
          blink = {
            use_custom_kind = true,
          },
        },
        lsp = {
          enabled = true,
          actions = true,
          completion = true,
          hover = true,
        },
      })

      require('minimal.utils.hl').persist(function()
        -- stylua: ignore start
        vim.api.nvim_set_hl(0, 'BlinkCmpKindVersion', { link = '@number', default = true })
        vim.api.nvim_set_hl(0, 'BlinkCmpKindFeature', { link = '@function', default = true })
        -- stylua: ignore end
      end)
    end,
  },
}
