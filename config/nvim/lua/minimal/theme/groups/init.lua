local Util = require('minimal.theme.utils')

local M = {}

---@param colors table
---@param opts table
function M.setup(colors, opts)
  local base = require('minimal.theme.groups.base').get(colors, opts)
  local treesitter =
    require('minimal.theme.groups.treesitter').get(colors, opts)
  local lsp = require('minimal.theme.groups.lsp').get(colors, opts)

  local ret = vim.tbl_deep_extend('force', base, treesitter, lsp)

  opts.on_highlights(ret, colors)

  return Util.resolve(ret)
end

return M
