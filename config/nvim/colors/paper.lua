-- Name:         paper
-- Description:  Colorscheme built from the paper scheme (Emacs untitled-plain)
-- Author:       Gerson Faneto

-- Clear hlgroups and set colors_name {{{
vim.cmd.hi('clear')
vim.g.colors_name = 'paper'
-- }}}

-- Palette {{{
-- stylua: ignore start
local dark = vim.go.bg == 'dark'

local c = dark and {
  foreground = '#f8f9e8',
  background = '#191919',
  highlight  = '#242424',
  region     = '#393939',
  subtle     = '#272727',
  shaded     = '#353535',
  comment    = '#696a6c',
  faint      = '#7d7e76',
  faded      = '#aaaba0',
  strong     = '#ffffff',
  cream      = '#eae3ce',
  string     = '#cdc8b1',
  coral      = '#cd5b45',
  green      = '#448c27',
  blue       = '#5191ed',
  violet     = '#a187d3',
  cyan       = '#00c2ff',
} or {
  foreground = '#212121',
  background = '#eae3ce',
  highlight  = '#e2d9bc',
  region     = '#d5c9b5',
  subtle     = '#ded8c4',
  shaded     = '#d3ccb9',
  comment    = '#7a6e58',
  faint      = '#908c80',
  faded      = '#67655e',
  strong     = '#000000',
  cream      = '#4a3c25',
  string     = '#8b5a2b',
  coral      = '#a44937',
  green      = '#36701f',
  blue       = '#0647a7',
  violet     = '#816ca9',
  cyan       = '#006b8c',
}
-- stylua: ignore end
-- }}}

-- Set terminal colors {{{
-- stylua: ignore start
local terminal = dark and {
  c.background, c.coral, c.green, c.string,
  c.blue, c.violet, c.cyan, c.foreground,
  c.region, '#d67b66', '#71a757', c.cream,
  '#98beeb', '#ab95d6', '#57d5f7', c.strong,
} or {
  c.background, c.coral, c.green, c.string,
  c.blue, c.violet, c.cyan, c.comment,
  c.region, '#cd5b45', '#448c27', '#996e44',
  '#085bd7', '#9980c8', '#0092bf', c.foreground,
}

for i, colour in ipairs(terminal) do
  vim.g['terminal_color_' .. (i - 1)] = colour
end
-- stylua: ignore end
-- }}}

-- Highlight groups {{{1
local hlgroups = {
  -- Common {{{2
  ColorColumn = { bg = c.highlight },
  Conceal = { fg = c.foreground },
  CurSearch = { link = 'IncSearch' },
  Cursor = { fg = c.background, bg = c.cyan },
  CursorColumn = { bg = c.highlight },
  CursorIM = { link = 'Cursor' },
  CursorLine = { bg = c.highlight },
  CursorLineNr = { fg = c.faded, bold = true },
  DiffAdd = { bg = c.subtle },
  DiffChange = { bg = c.subtle },
  DiffDelete = { fg = c.faint, bg = c.subtle },
  DiffText = { fg = c.strong, bg = c.region },
  Directory = { fg = c.faded },
  EndOfBuffer = { fg = c.subtle },
  ErrorMsg = { fg = c.coral },
  FloatBorder = { fg = c.foreground, bg = c.subtle },
  FloatFooter = { link = 'FloatTitle' },
  FloatShadow = { bg = c.background, blend = 70 },
  FloatShadowThrough = { link = 'None' },
  FloatTitle = { fg = c.foreground, bg = c.subtle, bold = true },
  FoldColumn = { fg = c.faded },
  Folded = { fg = c.faded, bg = c.highlight },
  HealthSuccess = { fg = c.green },
  IncSearch = { fg = c.background, bg = c.cyan, bold = true },
  LineNr = { fg = c.faint },
  MatchParen = { bg = c.region, bold = true },
  ModeMsg = { fg = c.foreground },
  MoreMsg = { fg = c.foreground },
  MsgArea = { link = 'Normal' },
  MsgSeparator = { link = 'StatusLine' },
  NonText = { fg = c.faded },
  Normal = { fg = c.foreground, bg = c.background },
  NormalFloat = { fg = c.foreground, bg = c.subtle },
  NormalNC = { link = 'Normal' },
  Pmenu = { fg = c.foreground, bg = c.highlight },
  PmenuExtra = { fg = c.faded },
  PmenuSbar = { bg = c.subtle },
  PmenuSel = { bg = c.region, bold = true },
  PmenuThumb = { bg = c.cyan },
  Question = { fg = c.foreground },
  QuickFixLine = { bg = c.region },
  Search = { bg = c.region },
  SignColumn = { fg = c.faded },
  SpecialKey = { fg = c.blue },
  SpellBad = { underdashed = true },
  SpellCap = { link = 'SpellBad' },
  SpellLocal = { link = 'SpellBad' },
  SpellRare = { link = 'SpellBad' },
  StatusLine = { fg = c.foreground, bg = c.subtle },
  StatusLineNC = { fg = c.faded, bg = c.subtle },
  Substitute = { link = 'Search' },
  TabLine = { link = 'StatusLine' },
  TabLineFill = { fg = c.foreground, bg = c.subtle },
  TabLineSel = { fg = c.strong, bg = c.shaded, bold = true },
  TermCursor = { link = 'Cursor' },
  Title = { fg = c.foreground, bold = true },
  VertSplit = { fg = c.subtle },
  Visual = { bg = c.region },
  VisualNOS = { link = 'Visual' },
  WarningMsg = { fg = c.violet },
  Whitespace = { link = 'NonText' },
  WildMenu = { link = 'PmenuSel' },
  WinBar = { fg = c.foreground, bg = c.highlight },
  WinBarNC = { fg = c.faded, bg = c.highlight },
  WinSeparator = { link = 'VertSplit' },
  lCursor = { link = 'Cursor' },
  -- }}}2

  -- Syntax {{{2
  Comment = { fg = c.faint },
  Constant = { fg = c.faded },
  String = { fg = c.string },
  Character = { fg = c.green },
  Number = { fg = c.faded },
  Boolean = { link = 'Constant' },
  Float = { link = 'Number' },
  Identifier = { fg = c.foreground },
  Builtin = { fg = c.foreground },
  Field = { link = 'None' },
  Enum = { fg = c.violet },
  Namespace = { fg = c.foreground },
  Function = { fg = c.foreground, bold = true },
  Statement = { fg = c.blue },
  Specifier = { fg = c.blue },
  Object = { fg = c.blue },
  Conditional = { fg = c.blue },
  Repeat = { fg = c.blue },
  Label = { fg = c.blue },
  Operator = { fg = c.coral },
  Keyword = { fg = c.blue, bold = true },
  Exception = { fg = c.coral },
  PreProc = { fg = c.blue },
  PreCondit = { link = 'PreProc' },
  Include = { link = 'PreProc' },
  Define = { link = 'PreProc' },
  Macro = { fg = c.faded },
  Type = { fg = c.violet },
  StorageClass = { link = 'Keyword' },
  Structure = { link = 'Type' },
  Typedef = { fg = c.violet },
  Special = { fg = c.coral },
  SpecialChar = { link = 'Special' },
  Tag = { fg = c.cyan, underline = true },
  Delimiter = { fg = c.foreground },
  Bracket = { fg = c.foreground },
  SpecialComment = { link = 'SpecialChar' },
  Debug = { link = 'Special' },
  Underlined = { underline = true },
  Ignore = { fg = c.subtle },
  Error = { fg = c.coral },
  Todo = { fg = c.foreground, bg = c.highlight, bold = true },
  -- }}}2

  -- Treesitter syntax {{{2
  ['@variable.member'] = { link = 'Field' },
  ['@property'] = { link = 'Field' },
  ['@annotation'] = { link = 'Operator' },
  ['@comment'] = { link = 'Comment' },
  ['@none'] = { link = 'None' },
  ['@keyword.directive'] = { link = 'PreProc' },
  ['@keyword.directive.define'] = { link = 'Define' },
  ['@operator'] = { link = 'Operator' },
  ['@punctuation.delimiter'] = { link = 'Delimiter' },
  ['@punctuation.bracket'] = { link = 'Bracket' },
  ['@markup.list'] = { link = 'Delimiter' },
  ['@string'] = { link = 'String' },
  ['@string.escape'] = { link = 'Special' },
  ['@string.regexp'] = { fg = c.coral },
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
  ['@markup.link'] = { link = 'Constant' },
  ['@markup.heading.1.markdown'] = { link = 'markdownH1' },
  ['@markup.heading.2.markdown'] = { link = 'markdownH2' },
  ['@markup.heading.3.markdown'] = { link = 'markdownH3' },
  ['@markup.heading.4.markdown'] = { link = 'markdownH4' },
  ['@markup.heading.5.markdown'] = { link = 'markdownH5' },
  ['@markup.heading.6.markdown'] = { link = 'markdownH6' },
  ['@comment.todo'] = { fg = c.foreground, bg = c.highlight, bold = true },
  ['@comment.note'] = { fg = c.blue, bg = c.highlight, bold = true },
  ['@comment.warning'] = { fg = c.violet, bg = c.highlight, bold = true },
  ['@comment.error'] = { fg = c.coral, bg = c.highlight, bold = true },
  ['@diff.delta'] = { link = 'DiffChange' },
  ['@diff.minus'] = { link = 'DiffRemoved' },
  ['@diff.plus'] = { link = 'DiffAdded' },
  ['@tag'] = { link = 'Tag' },
  ['@tag.attribute'] = { link = 'Identifier' },
  ['@tag.delimiter'] = { link = 'Delimiter' },
  ['@markup.strong'] = { bold = true },
  ['@markup.strike'] = { strikethrough = true },
  ['@markup.emphasis'] = { fg = c.coral, bold = true },
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
  ['@lsp.type.comment'] = {}, -- keep @comment.note/todo/warning/error visible
  ['@lsp.type.function'] = { link = 'Function' },
  ['@lsp.type.property'] = { link = 'Field' },
  ['@lsp.type.variable'] = { link = 'Variable' },
  ['@lsp.type.decorator'] = { link = 'Label' },
  ['@lsp.type.interface'] = { link = 'Structure' },
  ['@lsp.type.namespace'] = { link = 'Namespace' },
  ['@lsp.type.parameter'] = { link = 'Parameter' },
  ['@lsp.type.enumMember'] = { link = 'Enum' },
  ['@lsp.type.typeParameter'] = { link = 'Parameter' },
  ['@lsp.typemod.variable.defaultLibrary'] = { link = 'Builtin' },
  -- }}}2

  -- Diagnostics {{{2
  DiagnosticOk = { fg = c.green },
  DiagnosticError = { fg = c.coral },
  DiagnosticWarn = { fg = c.violet },
  DiagnosticInfo = { fg = c.blue },
  DiagnosticHint = { fg = c.cyan },
  DiagnosticVirtualTextOk = { fg = c.green, bg = c.highlight },
  DiagnosticVirtualTextError = { fg = c.coral, bg = c.highlight },
  DiagnosticVirtualTextWarn = { fg = c.violet, bg = c.highlight },
  DiagnosticVirtualTextInfo = { fg = c.blue, bg = c.highlight },
  DiagnosticVirtualTextHint = { fg = c.cyan, bg = c.highlight },
  DiagnosticUnderlineOk = { undercurl = true, sp = c.green },
  DiagnosticUnderlineError = { undercurl = true, sp = c.coral },
  DiagnosticUnderlineWarn = { undercurl = true, sp = c.violet },
  DiagnosticUnderlineInfo = { undercurl = true, sp = c.blue },
  DiagnosticUnderlineHint = { undercurl = true, sp = c.cyan },
  DiagnosticUnnecessary = { fg = c.faint, undercurl = true, sp = c.faint },
  -- }}}2

  -- FileType {{{2
  -- HTML
  htmlArg = { fg = c.foreground },
  htmlBold = { bold = true },
  htmlBoldItalic = { bold = true, italic = true },
  htmlTag = { fg = c.foreground },
  htmlTagName = { link = 'Tag' },
  htmlSpecialTagName = { fg = c.cyan },
  htmlEndTag = { fg = c.cyan },
  htmlH1 = { fg = c.cream, bold = true },
  htmlH2 = { link = 'htmlH1' },
  htmlH3 = { link = 'htmlH1' },
  htmlH4 = { link = 'htmlH1' },
  htmlH5 = { link = 'htmlH1' },
  htmlH6 = { link = 'htmlH1' },
  htmlItalic = { italic = true },
  htmlLink = { fg = c.faded, underline = true },
  htmlSpecialChar = { link = 'SpecialChar' },
  htmlTitle = { fg = c.foreground },

  -- Json
  jsonKeyword = { link = 'Keyword' },
  jsonBraces = { fg = c.foreground },

  -- Markdown
  markdownBold = { bold = true },
  markdownBoldItalic = { bold = true, italic = true },
  markdownCode = { fg = c.string },
  markdownError = { link = 'None' },
  markdownEscape = { link = 'None' },
  markdownListMarker = { fg = c.coral },
  markdownH1 = { link = 'htmlH1' },
  markdownH2 = { link = 'htmlH2' },
  markdownH3 = { link = 'htmlH3' },
  markdownH4 = { link = 'htmlH4' },
  markdownH5 = { link = 'htmlH5' },
  markdownH6 = { link = 'htmlH6' },

  -- Shell
  shDeref = { link = 'Macro' },
  shDerefVar = { link = 'Macro' },

  -- Git
  gitHash = { fg = c.faded },

  -- Checkhealth
  helpHeader = { fg = c.foreground, bold = true },
  helpSectionDelim = { fg = c.faded, bold = true },
  helpCommand = { fg = c.blue },
  helpBacktick = { fg = c.blue },

  -- Man
  manBold = { fg = c.blue, bold = true },
  manItalic = { fg = c.faded, italic = true },
  manOptionDesc = { fg = c.faded },
  manReference = { link = 'htmlLink' },
  manSectionHeading = { link = 'manBold' },
  manUnderline = { fg = c.coral },
  -- }}}2

  -- Plugins {{{2
  -- netrw
  netrwClassify = { link = 'Directory' },

  -- gitsigns
  GitSignsAdd = { fg = c.green },
  GitSignsChange = { fg = c.violet },
  GitSignsDelete = { fg = c.coral },
  GitSignsUntracked = { fg = c.subtle },
  GitSignsCurrentLineBlame = { fg = c.violet },

  -- telescope
  TelescopeNormal = { fg = c.faded, bg = c.subtle },
  TelescopePromptNormal = { bg = c.highlight },
  TelescopeTitle = { fg = c.subtle, bg = c.faded, bold = true },
  TelescopeBorder = { fg = c.foreground, bg = c.subtle },
  TelescopePromptBorder = { fg = c.foreground, bg = c.highlight },
  TelescopePreviewLine = { bg = c.shaded },
  TelescopePreviewMatch = { fg = c.cyan, bold = true },
  TelescopeMatching = { fg = c.cyan, bold = true },
  TelescopePromptCounter = { link = 'Comment' },
  TelescopePromptPrefix = { fg = c.coral },
  TelescopeSelection = { fg = c.foreground, bg = c.shaded },
  TelescopeMultiIcon = { fg = c.cyan, bold = true },
  TelescopeMultiSelection = { bg = c.shaded, bold = true },
  TelescopeSelectionCaret = { fg = c.coral, bg = c.shaded },

  -- blink.cmp
  BlinkCmpKindFunction = { link = 'Function' },
  BlinkCmpKindKeyword = { link = 'Keyword' },
  BlinkCmpKindVariable = { link = 'Identifier' },
  BlinkCmpKindText = { fg = c.foreground },
  BlinkCmpLabelDeprecated = { fg = c.faint, strikethrough = true },

  -- lazy.nvim
  LazyDir = { link = 'Directory' },
  LazyUrl = { link = 'htmlLink' },
  LazySpecial = { link = 'Special' },
  LazyCommit = { fg = c.faded },
  LazyReasonFt = { fg = c.blue },
  LazyReasonCmd = { fg = c.blue },
  LazyReasonPlugin = { fg = c.blue },
  LazyReasonSource = { fg = c.blue },
  LazyReasonRuntime = { fg = c.blue },
  LazyReasonEvent = { fg = c.blue },
  LazyReasonKeys = { fg = c.faded },
  LazyButton = { bg = c.subtle },
  LazyButtonActive = { bg = c.shaded, bold = true },
  LazyH1 = { fg = c.subtle, bg = c.faded, bold = true },

  -- copilot.lua
  CopilotSuggestion = { fg = c.faint, italic = true },
  CopilotAnnotation = { fg = c.faint, italic = true },
  -- }}}2
}
-- }}}1

-- Set highlight groups {{{1
for name, attr in pairs(hlgroups) do
  vim.api.nvim_set_hl(0, name, attr)
end
-- }}}1

-- vim:ts=2:sw=2:sts=2:fdm=marker
