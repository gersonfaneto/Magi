---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.session',
  data = {
    enabled = not vim.g.vscode,
    events = 'BufRead',
    cmds = {
      'SessionLoad',
      'SessionSave',
      'SessionRemove',
      'SessionSelect',
      'Mkssession',
      'Restart',
    },
    keys = {
      {
        lhs = '<Leader>w',
        opts = { desc = 'Load session (workspace) interactively' },
      },
      {
        lhs = '<Leader>W',
        opts = { desc = 'Load session (workspace) for cwd' },
      },
    },
    postload = function()
      local session = require('minimal.plugin.session')
      session.setup({
        autoload = { enabled = false },
        autoremove = { enabled = false },
      })

      vim.keymap.set('n', '<Leader>w', function()
        session.select(true)
      end, { desc = 'Load session (workspace) interactively' })

      vim.keymap.set('n', '<Leader>W', function()
        session.load(nil, true)
      end, { desc = 'Load session (workspace) for cwd' })
    end,
  },
}
