---@type minimal.pack.spec
return {
  src = 'https://github.com/jtprogru/pack-ui.nvim',
  data = {
    postload = function()
      require('pack_ui').setup({
        title = ' vim.pack ',
        auto_check = false, -- on setup, check remotes and notify if updates exist
        auto_update = false, -- on setup, apply every available update automatically
        keymaps = {
          prefix = '<leader>p',
          status = 's', -- <leader>ps -> :PackStatus
          update_all = 'U', -- <leader>pU -> :PackUpdateAll
        },
      })
    end,
  },
}
