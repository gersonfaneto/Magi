return setmetatable({
  borders = nil, ---@module 'minimal.utils.static.borders'
  boxes = nil, ---@module 'minimal.utils.static.boxes'
  icons = nil, ---@module 'minimal.utils.static.icons'
}, {
  __index = function(_, key)
    return require('minimal.utils.static.' .. key)
  end,
})
