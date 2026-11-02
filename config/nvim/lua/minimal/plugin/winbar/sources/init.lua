---@class minimal.winbar.source
---@field get_symbols fun(buf: integer, win: integer, cursor: integer[]): minimal.winbar.symbol[]

---@type table<string, minimal.winbar.source>
return setmetatable({}, {
  __index = function(_, key)
    return require('minimal.plugin.winbar.sources.' .. key)
  end,
})
