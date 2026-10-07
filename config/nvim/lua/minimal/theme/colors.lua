local Util = require('minimal.theme.utils')

local M = {}

local function is_dark(opts)
  local style = opts.style or vim.go.bg
  return style == 'dark'
end

---@param opts table
function M.setup(opts)
  local dark = is_dark(opts)
  local colorize = opts.colorize
  local transparent = opts.transparent

  local default_bg = dark and '#0d0d0d' or '#ffffff'

  Util.bg = default_bg
  Util.fg = dark and '#e0e0e0' or '#000000'

  local bg = default_bg
  local bg_dark = dark and '#0d0d0d' or '#f5f5f5'
  local bg_highlight = dark and '#1a1a1a' or '#e8e8e8'

  local fg = dark and '#e0e0e0' or '#000000'
  local fg_dark = dark and '#c8c8c8' or '#1a1a1a'
  local fg_gutter = dark and '#505050' or '#c0c0c0'

  local comment = dark and '#7a7a7a' or '#6e6e6e'
  local cyan = dark and '#8a8a8a' or '#3e3e3e'
  local dark3 = dark and '#606060' or '#a0a0a0'
  local dark5 = dark and '#909090' or '#808080'

  local blue = dark and '#b8b8b8' or '#1a1a1a'
  local blue0 = dark and '#2a2a2a' or '#b0b0b0'
  local blue1 = dark and '#a0a0a0' or '#2e2e2e'
  local blue2 = dark and '#a0a0a0' or '#3a3a3a'
  local blue5 = dark and '#888888' or '#4a4a4a'
  local blue6 = dark and '#9a9a9a' or '#3e3e3e'
  local blue7 = dark and '#1a1a1a' or '#e8e8e8'

  local green
  local green1
  if colorize then
    green = dark and '#6ca06c' or '#3d8040'
    green1 = dark and '#8ab88a' or '#4d9a50'
  else
    green = dark and '#9a9a9a' or '#3a3a3a'
    green1 = dark and '#a8a8a8' or '#2e2e2e'
  end

  local magenta = dark and '#b0b0b0' or '#2e2e2e'
  local magenta2 = dark and '#b0b0b0' or '#2e2e2e'
  local orange = dark and '#a0a0a0' or '#3a3a3a'
  local purple = dark and '#c8c8c8' or '#000000'

  local red
  local red1
  if colorize then
    red = dark and '#cc5c5c' or '#b34040'
    red1 = dark and '#d47a7a' or '#c55a5a'
  else
    red = dark and '#a0a0a0' or '#1a1a1a'
    red1 = dark and '#c0c0c0' or '#000000'
  end

  local teal = dark and '#909090' or '#5a5a5a'

  local yellow
  if colorize then
    yellow = dark and '#d4ac4a' or '#a89030'
  else
    yellow = dark and '#c8c8c8' or '#1a1a1a'
  end

  local error = red1
  local warning = yellow
  local info = blue2
  local hint = teal
  local none = transparent and 'NONE' or bg

  local subtle_bg = Util.blend_bg(fg, dark and 0.10 or 0.06, bg)
  local cursorline_bg = Util.blend_bg(fg, dark and 0.20 or 0.05, bg)
  local selection_bg = Util.blend_bg(fg, dark and 0.25 or 0.12, bg)
  local float_bg = Util.blend_bg(fg, dark and 0.12 or 0.04, bg)
  local visual_bg = Util.blend_bg(blue0, 0.4)

  local colors = {
    fg = fg,
    fg_dark = fg_dark,
    fg_gutter = fg_gutter,
    bg = bg,
    bg_dark = bg_dark,
    bg_highlight = bg_highlight,
    comment = comment,
    cyan = cyan,
    dark3 = dark3,
    dark5 = dark5,
    blue = blue,
    blue0 = blue0,
    blue1 = blue1,
    blue2 = blue2,
    blue5 = blue5,
    blue6 = blue6,
    blue7 = blue7,
    green = green,
    green1 = green1,
    green2 = green1,
    magenta = magenta,
    magenta2 = magenta2,
    orange = orange,
    purple = purple,
    red = red,
    red1 = red1,
    teal = teal,
    yellow = yellow,
    error = error,
    warning = warning,
    info = info,
    hint = hint,
    none = none,
    subtle_bg = subtle_bg,
    cursorline_bg = cursorline_bg,
    selection_bg = selection_bg,
    float_bg = float_bg,
    visual_bg = visual_bg,
    special_char = magenta2,
  }

  if opts.colors and next(opts.colors) then
    colors = vim.tbl_deep_extend('force', colors, opts.colors)
  end

  colors.git = {
    add = colors.green2 or colors.green,
    delete = colors.red1 or colors.red,
    change = colors.orange or colors.yellow,
    ignore = colors.dark3,
  }

  colors.diff = {
    add = Util.blend_bg(colors.green2 or colors.green, 0.25),
    delete = Util.blend_bg(colors.red1 or colors.red, 0.25),
    change = Util.blend_bg(colors.blue7 or colors.blue, 0.15),
    text = colors.blue7 or colors.blue,
  }

  colors.black = Util.blend_bg(colors.bg, 0.8, colors.bg)
  colors.border_highlight = Util.blend_bg(colors.blue1, 0.8)
  colors.border = dark and colors.black or Util.blend_bg(colors.fg, 0.15)

  colors.bg_popup = colors.bg_dark
  colors.bg_statusline = colors.bg_dark

  colors.bg_sidebar = opts.styles.sidebars == 'transparent' and colors.none
    or opts.styles.sidebars == 'dark' and colors.bg_dark
    or colors.bg

  colors.bg_float = opts.styles.floats == 'transparent' and colors.none
    or opts.styles.floats == 'dark' and colors.bg_dark
    or colors.bg

  colors.bg_visual = Util.blend_bg(colors.blue0, 0.4)
  colors.bg_search = colors.blue0
  colors.fg_sidebar = colors.fg
  colors.fg_float = colors.fg

  colors.todo = colors.blue

  colors.subtle_bg = subtle_bg
  colors.cursorline_bg = cursorline_bg
  colors.selection_bg = selection_bg
  colors.float_bg = float_bg

  colors.rainbow = {
    colors.blue,
    colors.yellow,
    colors.green,
    colors.teal,
    colors.magenta,
    colors.purple,
    colors.orange,
    colors.red,
  }

  colors.terminal = {
    black = colors.black,
    black_bright = dark and '#505050' or '#c0c0c0',
    red = colorize and (dark and '#cc5c5c' or '#b34040') or colors.red,
    red_bright = colorize and (dark and '#d47a7a' or '#c55a5a') or colors.red1,
    green = colorize and (dark and '#6ca06c' or '#3d8040') or colors.green,
    green_bright = colorize and (dark and '#8ab88a' or '#4d9a50')
      or colors.green1,
    yellow = colorize and (dark and '#d4ac4a' or '#a89030') or colors.yellow,
    yellow_bright = colorize and (dark and '#d4ac4a' or '#a89030')
      or colors.yellow,
    blue = colors.blue,
    blue_bright = colors.blue,
    magenta = colors.magenta,
    magenta_bright = colors.magenta,
    cyan = colors.cyan,
    cyan_bright = colors.cyan,
    white = colors.fg_dark,
    white_bright = colors.fg,
  }

  opts.on_colors(colors)

  return colors
end

return M
