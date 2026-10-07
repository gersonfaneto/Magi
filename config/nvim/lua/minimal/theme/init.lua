local M = {}

function M.load(opts)
  opts = require('minimal.theme.config').extend(opts)
  return require('minimal.theme.theme').setup(opts)
end

M.setup = require('minimal.theme.config').setup

return M
