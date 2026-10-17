---Base class for input method backends
---@class minimal.im.backend
---@field detect fun(self: minimal.im.backend): boolean
---@field try_turn_on fun(self: minimal.im.backend, buf: integer): nil Try turning input method on for buffer given by `buf` if it is previously active in the same buffer
---@field turn_off fun(self: minimal.im.backend): nil Turns input method off unconditionally
---@field save_status fun(self: minimal.im.backend, buf: integer): nil Save current input method status in `b:im_status`
local base = {}
base.__index = base

---@class minimal.im.backends
---@field base minimal.im.backend
local M = {
  base = base,
  fcitx = nil, ---@module 'minimal.plugin.im.backends.fcitx'
  macos = nil, ---@module 'minimal.plugin.im.backends.macos'
  windows = nil, ---@module 'minimal.plugin.im.backends.windows'
}

local backends_path =
  vim.fs.joinpath(vim.fn.stdpath('config'), 'lua/minimal/plugin/im/backends')

---Pick the first available backend and return an instance of it
---@return minimal.im.backend?
function M.detect()
  for name, type in vim.fs.dir(backends_path) do
    if
      type == 'file'
      and vim.endswith(name, '.lua')
      and name ~= 'init.lua'
    then
      local module =
        require('minimal.plugin.im.backends.' .. name:gsub('%.lua$', ''))
      local instance = module.backend:new()
      if instance:detect() then
        return instance
      end
    end
  end
end

return setmetatable(M, {
  __index = function(_, key)
    return require('minimal.plugin.im.backends.' .. key)
  end,
})
