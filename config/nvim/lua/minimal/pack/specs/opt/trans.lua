---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.trans',
  data = {
    enabled = not vim.g.vscode,
    cmds = 'Translate',
    keys = {
      mode = 'x',
      lhs = '<C-t>',
      opts = { desc = 'Translate selected text' },
    },
    postload = function()
      local trans = require('minimal.plugin.trans')

      trans.setup()

      vim.keymap.set('x', '<C-t>', function()
        trans.translate({
          text = table.concat(
            vim.fn.getregion(vim.fn.getpos('v'), vim.fn.getpos('.'), {
              type = vim.fn.mode(),
            }),
            '\n'
          ),
        })
      end, { desc = 'Translate selected text' })
    end,
  },
}
