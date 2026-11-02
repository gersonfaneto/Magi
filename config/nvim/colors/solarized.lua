-- Name:         solarized
-- Description:  Ethan Schoonover's Solarized colorscheme, dark and light
-- Author:       Ethan Schoonover
-- License:      MIT
-- Last Updated: Thu 12 Nov 2026

-- Clear hlgroups and set colors_name {{{1
vim.cmd.hi('clear')
vim.g.colors_name = 'solarized'
-- }}}1

-- Palette {{{1
-- stylua: ignore start
local c_base03, c_base02, c_base01, c_base00
local c_base0, c_base1, c_base2, c_base3
local c_yellow, c_orange, c_red, c_magenta
local c_violet, c_blue, c_cyan, c_green
local c_background, c_foreground, c_highlight, c_faint

c_base03  = { '#002b36', 234 }
c_base02  = { '#073642', 235 }
c_base01  = { '#586e75', 240 }
c_base00  = { '#657b83', 241 }
c_base0   = { '#839496', 244 }
c_base1   = { '#93a1a1', 245 }
c_base2   = { '#eee8d5', 254 }
c_base3   = { '#fdf6e3', 230 }
c_yellow  = { '#b58900', 136 }
c_orange  = { '#cb4b16', 166 }
c_red     = { '#dc322f', 160 }
c_magenta = { '#d33682', 125 }
c_violet  = { '#6c71c4', 61  }
c_blue    = { '#268bd2', 33  }
c_cyan    = { '#2aa198', 37  }
c_green   = { '#859900', 64  }

if vim.go.bg == 'dark' then
  c_background = c_base03
  c_foreground = c_base0
  c_highlight  = c_base02
  c_faint      = c_base01
else
  c_background = c_base3
  c_foreground = c_base00
  c_highlight  = c_base2
  c_faint      = c_base1
end
-- stylua: ignore end
-- }}}1

-- Terminal colors {{{1
-- stylua: ignore start
vim.g.terminal_color_0  = c_base02[1]
vim.g.terminal_color_1  = c_red[1]
vim.g.terminal_color_2  = c_green[1]
vim.g.terminal_color_3  = c_yellow[1]
vim.g.terminal_color_4  = c_blue[1]
vim.g.terminal_color_5  = c_magenta[1]
vim.g.terminal_color_6  = c_cyan[1]
vim.g.terminal_color_7  = c_base2[1]
vim.g.terminal_color_8  = c_base03[1]
vim.g.terminal_color_9  = c_orange[1]
vim.g.terminal_color_10 = c_base01[1]
vim.g.terminal_color_11 = c_base00[1]
vim.g.terminal_color_12 = c_base0[1]
vim.g.terminal_color_13 = c_violet[1]
vim.g.terminal_color_14 = c_base1[1]
vim.g.terminal_color_15 = c_base3[1]
-- stylua: ignore end
-- }}}1

-- Highlight groups {{{1
local hlgroups = {
  -- Common {{{2
  ColorColumn = { bg = c_highlight },
  Conceal = { fg = c_foreground },
  CurSearch = { link = 'IncSearch' },
  Cursor = { fg = c_background, bg = c_foreground },
  CursorColumn = { bg = c_highlight },
  CursorIM = { link = 'Cursor' },
  CursorLine = { bg = c_highlight },
  CursorLineNr = { fg = c_base1, bold = true },
  DiffAdd = { fg = c_green, bg = c_highlight },
  DiffAdded = { fg = c_green },
  DiffChange = { fg = c_yellow, bg = c_highlight },
  DiffDelete = { fg = c_red },
  DiffRemoved = { fg = c_red },
  DiffText = { fg = c_base1, bg = c_faint },
  Directory = { fg = c_blue },
  EndOfBuffer = { fg = c_background },
  ErrorMsg = { fg = c_red },
  FloatBorder = { fg = c_faint, bg = c_highlight },
  FloatFooter = { link = 'FloatTitle' },
  FloatShadow = { bg = c_base03, blend = 70 },
  FloatShadowThrough = { link = 'None' },
  FloatTitle = { fg = c_foreground, bg = c_highlight, bold = true },
  FoldColumn = { fg = c_faint },
  Folded = { fg = c_faint, bg = c_highlight },
  HealthSuccess = { fg = c_green },
  IncSearch = { fg = c_background, bg = c_orange, bold = true },
  LineNr = { fg = c_faint },
  MatchParen = { fg = c_orange, bold = true },
  ModeMsg = { fg = c_foreground },
  MoreMsg = { fg = c_foreground },
  MsgArea = { link = 'Normal' },
  MsgSeparator = { link = 'StatusLine' },
  NonText = { fg = c_faint },
  Normal = { fg = c_foreground, bg = c_background },
  NormalFloat = { fg = c_foreground, bg = c_highlight },
  NormalNC = { link = 'Normal' },
  Pmenu = { fg = c_foreground, bg = c_highlight },
  PmenuExtra = { fg = c_faint },
  PmenuSbar = { bg = c_highlight },
  PmenuSel = { bg = c_faint, bold = true },
  PmenuThumb = { bg = c_blue },
  Question = { fg = c_foreground },
  QuickFixLine = { bg = c_highlight },
  Search = { bg = c_faint },
  SignColumn = { fg = c_faint },
  SpecialKey = { fg = c_faint },
  SpellBad = { underdashed = true },
  SpellCap = { link = 'SpellBad' },
  SpellLocal = { link = 'SpellBad' },
  SpellRare = { link = 'SpellBad' },
  StatusLine = { fg = c_base1, bg = c_highlight },
  StatusLineNC = { fg = c_faint, bg = c_highlight },
  Substitute = { link = 'Search' },
  TabLine = { link = 'StatusLine' },
  TabLineFill = { fg = c_foreground, bg = c_highlight },
  TabLineSel = { fg = c_foreground, bg = c_faint, bold = true },
  TermCursor = { fg = c_background, bg = c_foreground },
  Title = { fg = c_blue, bold = true },
  VertSplit = { fg = c_highlight },
  Visual = { bg = c_highlight },
  VisualNOS = { link = 'Visual' },
  WarningMsg = { fg = c_orange },
  Whitespace = { link = 'NonText' },
  WildMenu = { link = 'PmenuSel' },
  WinBar = { fg = c_foreground, bg = c_highlight },
  WinBarNC = { fg = c_faint, bg = c_highlight },
  WinSeparator = { link = 'VertSplit' },
  lCursor = { link = 'Cursor' },
  -- }}}2

  -- Syntax {{{2
  Comment = { fg = c_faint, italic = true },
  Constant = { fg = c_cyan },
  String = { fg = c_cyan },
  DocumentKeyword = { link = 'Keyword' },
  Character = { fg = c_cyan },
  Number = { fg = c_cyan },
  Boolean = { link = 'Constant' },
  Array = { fg = c_cyan },
  Float = { link = 'Number' },
  Identifier = { fg = c_blue },
  Builtin = { fg = c_blue },
  Field = { link = 'None' },
  Enum = { fg = c_yellow },
  Namespace = { fg = c_blue },
  Function = { fg = c_blue, bold = true },
  Statement = { fg = c_green },
  Specifier = { fg = c_green },
  Object = { fg = c_green },
  Conditional = { fg = c_green },
  Repeat = { fg = c_green },
  Label = { fg = c_green },
  Operator = { fg = c_green },
  Keyword = { fg = c_green },
  Exception = { fg = c_green },
  PreProc = { fg = c_orange },
  PreCondit = { link = 'PreProc' },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { fg = c_orange },
  Type = { fg = c_yellow },
  StorageClass = { link = 'Keyword' },
  Structure = { link = 'Type' },
  Typedef = { fg = c_yellow },
  Special = { fg = c_orange },
  SpecialChar = { link = 'Special' },
  Tag = { fg = c_blue, underline = true },
  Delimiter = { fg = c_foreground },
  Bracket = { fg = c_foreground },
  SpecialComment = { link = 'SpecialChar' },
  Debug = { link = 'Special' },
  Underlined = { underline = true },
  Ignore = { fg = c_faint },
  Error = { fg = c_red },
  Todo = { fg = c_yellow, bg = c_highlight, bold = true },
  -- }}}2

  -- Treesitter syntax {{{2
  ['@variable.member'] = { link = 'Field' },
  ['@property'] = { link = 'Field' },
  ['@property.yaml'] = { link = 'Special' },
  ['@annotation'] = { link = 'Operator' },
  ['@comment'] = { link = 'Comment' },
  ['@none'] = { link = 'None' },
  ['@keyword.directive'] = { link = 'PreProc' },
  ['@keyword.directive.define'] = { link = 'Define' },
  ['@operator'] = { link = 'Operator' },
  ['@punctuation.delimiter'] = { link = 'Delimiter' },
  ['@punctuation.bracket'] = { link = 'Bracket' },
  ['@markup.list'] = { link = 'Delimiter' },
  ['@markup.list.checked'] = { link = 'DiagnosticOk' },
  ['@markup.list.unchecked'] = { link = '@markup.link.markdown_inline' },
  ['@string'] = { link = 'String' },
  ['@string.escape'] = { fg = c_orange },
  ['@string.regexp'] = { fg = c_orange },
  ['@string.yaml'] = { link = 'Normal' },
  ['@character'] = { link = 'Character' },
  ['@character.special'] = { link = 'SpecialChar' },
  ['@boolean'] = { link = 'Boolean' },
  ['@number'] = { link = 'Number' },
  ['@number.float'] = { link = 'Float' },
  ['@function'] = { link = 'Function' },
  ['@function.call'] = { link = 'Function' },
  ['@function.builtin'] = { link = 'Function' },
  ['@function.macro'] = { link = 'Macro' },
  ['@function.method'] = { link = 'Function' },
  ['@function.method.call'] = { link = 'Function' },
  ['@constructor'] = { link = 'Function' },
  ['@constructor.lua'] = { link = 'None' },
  ['@variable.parameter'] = { link = 'Parameter' },
  ['@keyword'] = { link = 'Keyword' },
  ['@keyword.function'] = { link = 'Keyword' },
  ['@keyword.return'] = { link = 'Keyword' },
  ['@keyword.conditional'] = { link = 'Conditional' },
  ['@keyword.repeat'] = { link = 'Repeat' },
  ['@keyword.debug'] = { link = 'Debug' },
  ['@label'] = { link = 'Keyword' },
  ['@keyword.import'] = { link = 'Include' },
  ['@keyword.exception'] = { link = 'Exception' },
  ['@type'] = { link = 'Type' },
  ['@type.builtin'] = { link = 'Type' },
  ['@type.qualifier'] = { link = 'Type' },
  ['@type.definition'] = { link = 'Typedef' },
  ['@keyword.storage'] = { link = 'StorageClass' },
  ['@attribute'] = { link = 'Label' },
  ['@variable'] = { link = 'Identifier' },
  ['@variable.builtin'] = { link = 'Builtin' },
  ['@constant'] = { link = 'Constant' },
  ['@constant.builtin'] = { link = 'Constant' },
  ['@constant.macro'] = { link = 'Macro' },
  ['@module'] = { link = 'Namespace' },
  ['@markup.heading'] = { link = 'Title' },
  ['@markup.raw'] = { link = 'String' },
  ['@markup.link.url'] = { link = 'htmlLink' },
  ['@markup.environment'] = { link = 'Macro' },
  ['@markup.environment.name'] = { link = 'Type' },
  ['@markup.link'] = { link = 'Constant' },
  ['@markup.heading.1.markdown'] = { link = 'markdownH1' },
  ['@markup.heading.2.markdown'] = { link = 'markdownH2' },
  ['@markup.heading.3.markdown'] = { link = 'markdownH3' },
  ['@markup.heading.4.markdown'] = { link = 'markdownH4' },
  ['@markup.heading.5.markdown'] = { link = 'markdownH5' },
  ['@markup.heading.6.markdown'] = { link = 'markdownH6' },
  ['@markup.heading.1.marker.markdown'] = { link = 'markdownH1Delimiter' },
  ['@markup.heading.2.marker.markdown'] = { link = 'markdownH2Delimiter' },
  ['@markup.heading.3.marker.markdown'] = { link = 'markdownH3Delimiter' },
  ['@markup.heading.4.marker.markdown'] = { link = 'markdownH4Delimiter' },
  ['@markup.heading.5.marker.markdown'] = { link = 'markdownH5Delimiter' },
  ['@markup.heading.6.marker.markdown'] = { link = 'markdownH6Delimiter' },
  ['@markup.heading.1.delimiter.vimdoc'] = { link = 'helpSectionDelim' },
  ['@markup.heading.2.delimiter.vimdoc'] = { link = 'helpSectionDelim' },
  ['@comment.todo'] = { fg = c_background, bg = c_yellow, bold = true },
  ['@comment.note'] = { fg = c_background, bg = c_blue, bold = true },
  ['@comment.warning'] = { fg = c_background, bg = c_orange, bold = true },
  ['@comment.error'] = { fg = c_background, bg = c_red, bold = true },
  ['@diff.delta'] = { link = 'DiffChange' },
  ['@diff.minus'] = { link = 'DiffRemoved' },
  ['@diff.plus'] = { link = 'DiffAdded' },
  ['@tag'] = { link = 'Tag' },
  ['@tag.attribute'] = { link = 'Identifier' },
  ['@tag.delimiter'] = { link = 'Delimiter' },
  ['@text.todo.unchecked'] = { link = 'DiagnosticWarn' },
  ['@text.todo.checked'] = { link = 'DiagnosticOk' },
  ['@markup.strong'] = { bold = true },
  ['@markup.strike'] = { strikethrough = true },
  ['@markup.emphasis'] = { italic = true },
  ['@markup.underline'] = { underline = true },
  ['@keyword.operator'] = { link = 'Operator' },
  -- }}}2

  -- LSP semantic {{{2
  ['@lsp.type.enum'] = { link = 'Type' },
  ['@lsp.type.type'] = { link = 'Type' },
  ['@lsp.type.class'] = { link = 'Structure' },
  ['@lsp.type.struct'] = { link = 'Structure' },
  ['@lsp.type.macro'] = { link = 'Macro' },
  ['@lsp.type.method'] = { link = 'Function' },
  ['@lsp.type.comment'] = {}, -- avoid interfere with `@comment.note/todo/warning/error`
  ['@lsp.type.function'] = { link = 'Function' },
  ['@lsp.type.property'] = { link = 'Field' },
  ['@lsp.type.variable'] = { link = 'Identifier' },
  ['@lsp.type.decorator'] = { link = 'Label' },
  ['@lsp.type.interface'] = { link = 'Structure' },
  ['@lsp.type.namespace'] = { link = 'Namespace' },
  ['@lsp.type.parameter'] = { link = 'Parameter' },
  ['@lsp.type.enumMember'] = { link = 'Enum' },
  ['@lsp.type.typeParameter'] = { link = 'Parameter' },
  ['@lsp.typemod.keyword.documentation'] = { link = 'DocumentKeyword' },
  ['@lsp.typemod.function.defaultLibrary'] = { link = 'Function' },
  ['@lsp.typemod.variable.defaultLibrary'] = { link = 'Builtin' },
  ['@lsp.typemod.variable.global'] = { link = 'Identifier' },
  -- }}}2

  -- LSP {{{2
  LspReferenceText = { link = 'Visual' },
  LspReferenceRead = { link = 'LspReferenceText' },
  LspReferenceWrite = { link = 'LspReferenceText' },
  LspSignatureActiveParameter = { link = 'IncSearch' },
  LspInfoBorder = { link = 'FloatBorder' },
  -- }}}2

  -- Diagnostic {{{2
  DiagnosticOk = { fg = c_green },
  DiagnosticError = { fg = c_red },
  DiagnosticWarn = { fg = c_orange },
  DiagnosticInfo = { fg = c_blue },
  DiagnosticHint = { fg = c_cyan },
  DiagnosticVirtualTextOk = { fg = c_green, bg = c_highlight },
  DiagnosticVirtualTextError = { fg = c_red, bg = c_highlight },
  DiagnosticVirtualTextWarn = { fg = c_orange, bg = c_highlight },
  DiagnosticVirtualTextInfo = { fg = c_blue, bg = c_highlight },
  DiagnosticVirtualTextHint = { fg = c_cyan, bg = c_highlight },
  DiagnosticUnderlineOk = { underline = true, sp = c_green },
  DiagnosticUnderlineError = { undercurl = true, sp = c_red },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c_orange },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c_blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = c_cyan },
  DiagnosticFloatingOk = { link = 'DiagnosticOk' },
  DiagnosticFloatingError = { link = 'DiagnosticError' },
  DiagnosticFloatingWarn = { link = 'DiagnosticWarn' },
  DiagnosticFloatingInfo = { link = 'DiagnosticInfo' },
  DiagnosticFloatingHint = { link = 'DiagnosticHint' },
  DiagnosticSignOk = { link = 'DiagnosticOk' },
  DiagnosticSignError = { link = 'DiagnosticError' },
  DiagnosticSignWarn = { link = 'DiagnosticWarn' },
  DiagnosticSignInfo = { link = 'DiagnosticInfo' },
  DiagnosticSignHint = { link = 'DiagnosticHint' },
  DiagnosticUnnecessary = {
    fg = c_faint,
    sp = c_foreground,
    undercurl = true,
  },
  -- }}}2

  -- Git {{{2
  GitSignsAdd = { fg = c_green },
  GitSignsChange = { fg = c_yellow },
  GitSignsDelete = { fg = c_red },
  -- }}}2

  -- FileType {{{2
  -- HTML
  htmlArg = { fg = c_foreground },
  htmlBold = { bold = true },
  htmlBoldItalic = { bold = true, italic = true },
  htmlTag = { fg = c_foreground },
  htmlTagName = { link = 'Tag' },
  htmlSpecialTagName = { fg = c_base1 },
  htmlEndTag = { fg = c_base1 },
  htmlH1 = { fg = c_blue, bold = true },
  htmlH2 = { fg = c_blue, bold = true },
  htmlH3 = { fg = c_blue, bold = true },
  htmlH4 = { fg = c_blue, bold = true },
  htmlH5 = { fg = c_blue, bold = true },
  htmlH6 = { fg = c_blue, bold = true },
  htmlItalic = { italic = true },
  htmlLink = { fg = c_blue, underline = true },
  htmlSpecialChar = { link = 'SpecialChar' },
  htmlTitle = { fg = c_foreground },

  -- Json
  jsonKeyword = { link = 'Keyword' },
  jsonBraces = { fg = c_foreground },

  -- Markdown
  markdownBold = { bold = true },
  markdownBoldItalic = { bold = true, italic = true },
  markdownCode = { fg = c_cyan },
  markdownError = { link = 'None' },
  markdownEscape = { link = 'None' },
  markdownListMarker = { fg = c_orange },
  markdownH1 = { link = 'htmlH1' },
  markdownH2 = { link = 'htmlH2' },
  markdownH3 = { link = 'htmlH3' },
  markdownH4 = { link = 'htmlH4' },
  markdownH5 = { link = 'htmlH5' },
  markdownH6 = { link = 'htmlH6' },
  markdownH1Delimiter = { link = 'markdownH1' },
  markdownH2Delimiter = { link = 'markdownH2' },
  markdownH3Delimiter = { link = 'markdownH3' },
  markdownH4Delimiter = { link = 'markdownH4' },
  markdownH5Delimiter = { link = 'markdownH5' },
  markdownH6Delimiter = { link = 'markdownH6' },
  -- }}}2

  -- Plugins {{{2
  -- blink.cmp
  CmpItemAbbrMatch = { fg = c_blue },
  CmpItemAbbrMatchFuzzy = { link = 'CmpItemAbbrMatch' },
  CmpItemKind = { fg = c_yellow },
  CmpItemKindFunction = { fg = c_blue },
  CmpItemKindMethod = { fg = c_blue },
  CmpItemKindKeyword = { fg = c_green },
  CmpItemKindVariable = { fg = c_foreground },
  CmpItemMenu = { fg = c_faint },

  -- fzf-lua
  FzfLuaBorder = { link = 'FloatBorder' },
  FzfLuaTitle = { link = 'FloatTitle' },
  FzfLuaCursorLine = { link = 'CursorLine' },
  FzfLuaSearch = { link = 'IncSearch' },

  -- gitsigns
  GitSignsAddNr = { link = 'GitSignsAdd' },
  GitSignsChangeNr = { link = 'GitSignsChange' },
  GitSignsDeleteNr = { link = 'GitSignsDelete' },

  -- lazy.nvim
  LazyNormal = { link = 'NormalFloat' },
  LazyButton = { bg = c_highlight },
  LazyButtonActive = { bg = c_faint, bold = true },
  LazyH1 = { fg = c_background, bg = c_blue, bold = true },
  LazySpecial = { link = 'Special' },
  LazyCommit = { fg = c_yellow },
  LazyReasonFt = { fg = c_green },
  LazyReasonCmd = { fg = c_green },
  LazyReasonPlugin = { fg = c_green },
  LazyReasonSource = { fg = c_green },
  LazyReasonRuntime = { fg = c_green },
  LazyReasonEvent = { fg = c_green },
  LazyReasonKeys = { fg = c_faint },

  -- statusline
  StatusLineDiagnosticError = { fg = c_red, bg = c_highlight },
  StatusLineDiagnosticHint = { fg = c_cyan, bg = c_highlight },
  StatusLineDiagnosticInfo = { fg = c_blue, bg = c_highlight },
  StatusLineDiagnosticWarn = { fg = c_orange, bg = c_highlight },
  StatusLineGitAdded = { fg = c_green, bg = c_highlight },
  StatusLineGitChanged = { fg = c_yellow, bg = c_highlight },
  StatusLineGitRemoved = { fg = c_red, bg = c_highlight },
  StatusLineHeader = { fg = c_background, bg = c_blue },
  StatusLineHeaderModified = { fg = c_background, bg = c_orange },

  -- winbar
  WinBarIconUIIndicator = { fg = c_blue },
  WinBarMenuNormalFloat = { fg = c_foreground, bg = c_highlight },
  WinBarMenuHoverIcon = { fg = c_blue, bg = c_faint },
  WinBarMenuHoverEntry = { fg = c_foreground, bg = c_faint },
  WinBarMenuCurrentContext = { fg = c_foreground, bg = c_highlight },
  -- }}}2
}
-- }}}1

-- Highlight group overrides {{{1
if vim.go.bg == 'dark' then
  hlgroups.CmpItemAbbrMatch = { fg = c_blue, bold = true }
  hlgroups.DiffText = { fg = c_base1, bg = c_faint }
end
-- }}}1

-- Set highlight groups {{{1
for name, attr in pairs(hlgroups) do
  attr.ctermbg = attr.bg and attr.bg[2]
  attr.ctermfg = attr.fg and attr.fg[2]
  attr.bg = attr.bg and attr.bg[1]
  attr.fg = attr.fg and attr.fg[1]
  attr.sp = attr.sp and attr.sp[1]
  vim.api.nvim_set_hl(0, name, attr)
end
-- }}}1

-- vim:ts=2:sw=2:sts=2:fdm=marker
