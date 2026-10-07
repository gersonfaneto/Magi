---@type minimal.pack.spec
return {
  src = 'https://github.com/xiyaowong/transparent.nvim',
  data = {
    postload = function()
      require('transparent').setup({
        extra_groups = {
          'NormalSpecial',
        },
      })

      require('transparent').clear_prefix('Winbar')
    end,
  },
}
