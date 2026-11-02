---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.winbar',
  data = {
    enabled = not vim.g.vscode,
    events = 'FileType',
    keys = {
      { lhs = '<Leader>;', opts = { desc = 'Pick symbols in winbar' } },
      {
        lhs = '[;',
        opts = { desc = 'Go to start of current context' },
      },
      { lhs = '];', opts = { desc = 'Select next context' } },
    },
    postload = function()
      require('minimal.plugin.winbar').setup({
        bar = { hover = false },
      })

      local winbar_api = require('minimal.plugin.winbar.api')

      vim.keymap.set('n', '<Leader>;', winbar_api.pick, {
        desc = 'Pick symbols in winbar',
      })
      vim.keymap.set('n', '[;', winbar_api.goto_context_start, {
        desc = 'Go to start of current context',
      })
      vim.keymap.set('n', '];', winbar_api.select_next_context, {
        desc = 'Select next context',
      })
    end,
  },
}
