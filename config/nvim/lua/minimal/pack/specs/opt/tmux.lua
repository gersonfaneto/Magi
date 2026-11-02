local load = require('minimal.utils.load')

---@type minimal.pack.spec
return {
  src = 'module://minimal.plugin.tmux',
  data = {
    enabled = not vim.g.vscode and vim.g.has_ui,
    load = load.schedule_wrap(function()
      require('minimal.plugin.tmux').setup()
    end),
  },
}
