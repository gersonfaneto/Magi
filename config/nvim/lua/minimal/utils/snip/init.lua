---@diagnostic disable: assign-type-mismatch

return setmetatable({
  conds = nil, ---@module 'minimal.utils.snip.conds'
  funcs = nil, ---@module 'minimal.utils.snip.funcs'
  nodes = nil, ---@module 'minimal.utils.snip.nodes'
  snips = nil, ---@module 'minimal.utils.snip.snips'
}, {
  __index = function(_, key)
    return require('minimal.utils.snip.' .. key)
  end,
})
