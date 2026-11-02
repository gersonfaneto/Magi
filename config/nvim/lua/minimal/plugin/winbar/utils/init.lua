return setmetatable({
  bar = nil, ---@module 'minimal.plugin.winbar.utils.bar'
  menu = nil, ---@module 'minimal.plugin.winbar.utils.menu'
  source = nil, ---@module 'minimal.plugin.winbar.utils.source'
}, {
  __index = function(_, key)
    return vim.npcall(require, 'minimal.plugin.winbar.utils.' .. key)
      or require('minimal.utils.' .. key)
  end,
})
