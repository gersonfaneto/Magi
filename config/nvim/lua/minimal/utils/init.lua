---@diagnostic disable: assign-type-mismatch

return setmetatable({
  buf = nil, ---@module 'minimal.utils.buf'
  cmd = nil, ---@module 'minimal.utils.cmd'
  ctx = nil, ---@module 'minimal.utils.ctx'
  dap = nil, ---@module 'minimal.utils.dap'
  fs = nil, ---@module 'minimal.utils.fs'
  git = nil, ---@module 'minimal.utils.git'
  hl = nil, ---@module 'minimal.utils.hl'
  json = nil, ---@module 'minimal.utils.json'
  key = nil, ---@module 'minimal.utils.key'
  keys = nil, ---@module 'minimal.utils.keys'
  load = nil, ---@module 'minimal.utils.load'
  lsp = nil, ---@module 'minimal.utils.lsp'
  lua = nil, ---@module 'minimal.utils.lua'
  opt = nil, ---@module 'minimal.utils.opt'
  opts = nil, ---@module 'minimal.utils.opts'
  pack = nil, ---@module 'minimal.utils.pack'
  snippets = nil, ---@module 'minimal.utils.snip'
  static = nil, ---@module 'minimal.utils.static'
  stl = nil, ---@module 'minimal.utils.stl'
  str = nil, ---@module 'minimal.utils.str'
  syn = nil, ---@module 'minimal.utils.syn'
  tab = nil, ---@module 'minimal.utils.tab'
  term = nil, ---@module 'minimal.utils.term'
  term_t = nil, ---@module 'minimal.utils.term_t'
  test = nil, ---@module 'minimal.utils.test'
  ts = nil, ---@module 'minimal.utils.ts'
  web = nil, ---@module 'minimal.utils.web'
  win = nil, ---@module 'minimal.utils.win'
}, {
  __index = function(_, key)
    return require('minimal.utils.' .. key)
  end,
})
