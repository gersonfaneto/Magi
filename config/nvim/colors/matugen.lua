local palette, err = require('config.colors').load()
if not palette then
  -- lazyvim catches this and falls back
  error('matugen colorscheme: ' .. err)
end

-- the palette doesn't say if it's light or dark, so measure it
local function is_dark(hex)
  local r, g, b = hex:match('^#(%x%x)(%x%x)(%x%x)$')
  if not r then
    return true
  end
  local lum = (
    0.2126 * tonumber(r, 16)
    + 0.7152 * tonumber(g, 16)
    + 0.0722 * tonumber(b, 16)
  ) / 255
  return lum < 0.5
end

local background = is_dark(palette.bg) and 'dark' or 'light'
if vim.o.background ~= background then
  -- this re-sources the file; second pass falls through
  vim.o.background = background
end

vim.cmd.highlight('clear')
if vim.fn.exists('syntax_on') == 1 then
  vim.cmd.syntax('reset')
end
vim.g.colors_name = 'matugen'

local c = palette

for group, opts in pairs({
  -- editor
  Normal = { fg = c.fg, bg = c.bg },
  NormalNC = { link = 'Normal' },
  NormalFloat = { fg = c.fg, bg = c.bg_alt },
  FloatBorder = { fg = c.border, bg = c.bg_alt },
  FloatTitle = { fg = c.accent, bg = c.bg_alt, bold = true },
  MsgArea = { fg = c.fg },
  ColorColumn = { bg = c.bg_alt },
  Conceal = { fg = c.grey },
  Cursor = { fg = c.bg, bg = c.fg },
  lCursor = { link = 'Cursor' },
  CursorIM = { link = 'Cursor' },
  TermCursor = { link = 'Cursor' },
  CursorLine = { bg = c.bg_alt },
  CursorColumn = { link = 'CursorLine' },
  CursorLineNr = { fg = c.accent, bold = true },
  LineNr = { fg = c.grey },
  SignColumn = { fg = c.grey, bg = c.bg },
  FoldColumn = { link = 'SignColumn' },
  Folded = { fg = c.fg_dim, bg = c.bg_light },
  Directory = { fg = c.blue },
  EndOfBuffer = { fg = c.bg },
  NonText = { fg = c.grey },
  SpecialKey = { fg = c.grey },
  Whitespace = { fg = c.border },
  MatchParen = { fg = c.accent, bold = true },
  ErrorMsg = { fg = c.red, bold = true },
  WarningMsg = { fg = c.yellow },
  MoreMsg = { fg = c.green },
  ModeMsg = { fg = c.fg, bold = true },
  Question = { fg = c.green },
  Title = { fg = c.accent, bold = true },

  -- selections and menus
  Visual = { bg = c.bg_highlight },
  VisualNOS = { link = 'Visual' },
  Search = { fg = c.on_selection, bg = c.selection },
  IncSearch = { fg = c.on_accent, bg = c.accent },
  CurSearch = { link = 'IncSearch' },
  Substitute = { link = 'IncSearch' },
  Pmenu = { fg = c.fg, bg = c.bg_light },
  PmenuSel = { fg = c.on_selection, bg = c.selection },
  PmenuSbar = { bg = c.bg_lighter },
  PmenuThumb = { bg = c.grey },
  PmenuMatch = { fg = c.accent, bold = true },
  PmenuMatchSel = { fg = c.accent, bg = c.selection, bold = true },
  QuickFixLine = { bg = c.bg_light, bold = true },
  WildMenu = { link = 'PmenuSel' },

  -- chrome
  StatusLine = { fg = c.fg_dim, bg = c.bg_alt },
  StatusLineNC = { fg = c.grey, bg = c.bg_alt },
  WinBar = { fg = c.fg_dim, bg = c.bg },
  WinBarNC = { fg = c.grey, bg = c.bg },
  WinSeparator = { fg = c.border },
  VertSplit = { link = 'WinSeparator' },
  TabLine = { fg = c.fg_dim, bg = c.bg_alt },
  TabLineFill = { bg = c.bg_dim },
  TabLineSel = { fg = c.on_accent, bg = c.accent },

  -- spelling
  SpellBad = { sp = c.red, undercurl = true },
  SpellCap = { sp = c.yellow, undercurl = true },
  SpellLocal = { sp = c.blue, undercurl = true },
  SpellRare = { sp = c.magenta, undercurl = true },

  -- syntax (treesitter links to these)
  Comment = { fg = c.grey, italic = true },
  Constant = { fg = c.cyan },
  String = { fg = c.green },
  Character = { fg = c.green },
  Number = { fg = c.magenta },
  Boolean = { fg = c.magenta },
  Float = { link = 'Number' },
  Identifier = { fg = c.fg },
  Function = { fg = c.blue },
  Statement = { fg = c.magenta },
  Conditional = { link = 'Statement' },
  Repeat = { link = 'Statement' },
  Label = { fg = c.yellow },
  Operator = { fg = c.fg_dim },
  Keyword = { fg = c.magenta },
  Exception = { link = 'Statement' },
  PreProc = { fg = c.cyan },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { link = 'PreProc' },
  PreCondit = { link = 'PreProc' },
  Type = { fg = c.yellow },
  StorageClass = { link = 'Type' },
  Structure = { link = 'Type' },
  Typedef = { link = 'Type' },
  Special = { fg = c.accent },
  SpecialChar = { fg = c.magenta },
  Delimiter = { fg = c.fg_dim },
  SpecialComment = { fg = c.fg_dim, italic = true },
  Debug = { fg = c.red },
  Underlined = { underline = true },
  Ignore = { fg = c.grey },
  Error = { fg = c.red },
  Todo = { fg = c.bg, bg = c.yellow, bold = true },

  -- captures nvim doesn't link anywhere useful
  ['@variable'] = { fg = c.fg },
  ['@variable.parameter'] = { fg = c.fg_dim },
  ['@variable.member'] = { fg = c.cyan },
  ['@property'] = { fg = c.cyan },
  ['@punctuation.bracket'] = { fg = c.fg_dim },
  ['@markup.heading'] = { fg = c.accent, bold = true },
  ['@markup.link'] = { fg = c.blue, underline = true },
  ['@markup.list'] = { fg = c.accent },
  ['@markup.raw'] = { fg = c.green },

  -- diffs
  DiffAdd = { fg = c.green, bg = c.bg_alt },
  DiffChange = { fg = c.yellow, bg = c.bg_alt },
  DiffDelete = { fg = c.red, bg = c.bg_alt },
  DiffText = { fg = c.bg, bg = c.yellow },
  Added = { fg = c.green },
  Changed = { fg = c.yellow },
  Removed = { fg = c.red },
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.yellow },
  GitSignsDelete = { fg = c.red },

  -- diagnostics
  DiagnosticError = { fg = c.red },
  DiagnosticWarn = { fg = c.yellow },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.cyan },
  DiagnosticOk = { fg = c.green },
  DiagnosticUnderlineError = { sp = c.red, undercurl = true },
  DiagnosticUnderlineWarn = { sp = c.yellow, undercurl = true },
  DiagnosticUnderlineInfo = { sp = c.blue, undercurl = true },
  DiagnosticUnderlineHint = { sp = c.cyan, undercurl = true },
  DiagnosticVirtualTextError = { fg = c.red, bg = c.bg_alt },
  DiagnosticVirtualTextWarn = { fg = c.yellow, bg = c.bg_alt },
  DiagnosticVirtualTextInfo = { fg = c.blue, bg = c.bg_alt },
  DiagnosticVirtualTextHint = { fg = c.cyan, bg = c.bg_alt },

  -- lsp
  LspReferenceText = { bg = c.bg_light },
  LspReferenceRead = { link = 'LspReferenceText' },
  LspReferenceWrite = { bg = c.bg_light, underline = true },
  LspInlayHint = { fg = c.grey, bg = c.bg_alt, italic = true },
  LspSignatureActiveParameter = { fg = c.accent, bold = true },
}) do
  vim.api.nvim_set_hl(0, group, opts)
end

-- :terminal, same order as ghostty
for i, color in ipairs({
  c.bg_lighter,
  c.red,
  c.green,
  c.yellow,
  c.blue,
  c.magenta,
  c.cyan,
  c.fg_dim,
  c.grey,
  c.red,
  c.green,
  c.yellow,
  c.blue,
  c.magenta,
  c.cyan,
  c.fg,
}) do
  vim.g['terminal_color_' .. (i - 1)] = color
end

-- indent-blankline, cycling up the surface ramp
for i, color in ipairs({ c.bg_lighter, c.bg_highlight, c.border, c.grey }) do
  vim.api.nvim_set_hl(0, 'IblIndent' .. i, { fg = color })
end
vim.api.nvim_set_hl(0, 'IblIndent', { fg = c.bg_highlight })
vim.api.nvim_set_hl(0, 'IblWhitespace', { fg = c.bg_light })
vim.api.nvim_set_hl(0, 'IblScope', { fg = c.accent })

-- rainbow-delimiters, if matugen has rendered the harmonised hues yet
if c.rainbow_red then
  for group, color in pairs({
    RainbowDelimiterRed = c.rainbow_red,
    RainbowDelimiterOrange = c.rainbow_orange,
    RainbowDelimiterYellow = c.rainbow_yellow,
    RainbowDelimiterGreen = c.rainbow_green,
    RainbowDelimiterCyan = c.rainbow_cyan,
    RainbowDelimiterBlue = c.rainbow_blue,
    RainbowDelimiterViolet = c.rainbow_violet,
  }) do
    vim.api.nvim_set_hl(0, group, { fg = color })
  end
end
