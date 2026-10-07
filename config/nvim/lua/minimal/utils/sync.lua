local json = require('minimal.utils.json')

local M = {}

function M.apply_state()
  local state_home = vim.fn.getenv('XDG_STATE_HOME')
    or vim.fn.expand('~/.local/state')
  local path = vim.fs.joinpath(state_home, 'minimal', 'minimal.json')
  local colors_config = json.read(path)
  if not next(colors_config) then
    return
  end

  local theme = require('minimal.theme.config')
  local opts = theme.options
  local changed = false

  local variant = colors_config.variant or colors_config.bg
  if variant and vim.go.bg ~= variant then
    vim.g.script_background = 1
    vim.go.bg = variant
    changed = true
  end

  if
    colors_config.colorize ~= nil and opts.colorize ~= colors_config.colorize
  then
    opts.colorize = colors_config.colorize
    changed = true
  end

  if changed then
    require('minimal.theme.theme').setup(opts)
    vim.g.script_background = nil
  end
end

return M
