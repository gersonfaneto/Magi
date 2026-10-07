local M = {}

M.defaults = {
  style = nil, -- nil follows vim.go.bg ('dark'|'light')
  colorize = false,
  transparent = false,
  dim_inactive = false,
  terminal_colors = true,
  styles = {
    comments = { italic = true },
    keywords = { italic = true },
    functions = {},
    variables = {},
    sidebars = 'dark',
    floats = 'dark',
  },
  colors = {},
  on_colors = function(colors) end, -- luacheck: no unused args
  on_highlights = function(highlights, colors) end, -- luacheck: no unused args
}

M.options = nil

---@param options? table
function M.setup(options)
  M.options = vim.tbl_deep_extend('force', {}, M.defaults, options or {})
end

---@param opts? table
function M.extend(opts)
  return opts and vim.tbl_deep_extend('force', {}, M.options, opts)
    or M.options
end

setmetatable(M, {
  __index = function(_, k)
    if k == 'options' then
      return M.defaults
    end
  end,
})

return M
