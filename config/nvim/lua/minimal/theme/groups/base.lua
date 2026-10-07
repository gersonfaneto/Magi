local Util = require('minimal.theme.utils')

local M = {}

---@param c table
---@param opts table
function M.get(c, opts)
  -- stylua: ignore
  return {
    -- Editor
    Normal                      = { fg = c.fg, bg = opts.transparent and c.none or c.bg },
    NormalNC                    = { fg = c.fg, bg = opts.transparent and c.none or opts.dim_inactive and c.bg_dark or c.bg },
    NormalSB                    = { fg = c.fg_sidebar, bg = c.bg_sidebar },
    NormalFloat                 = { fg = c.fg_float, bg = c.bg_float },
    Cursor                      = { fg = c.bg, bg = c.fg },
    lCursor                     = { fg = c.bg, bg = c.fg },
    CursorIM                    = { fg = c.bg, bg = c.fg },
    CursorColumn                = { bg = c.bg_highlight },
    CursorLine                  = { bg = c.cursorline_bg },
    Visual                      = { bg = c.visual_bg },
    VisualNOS                   = { bg = c.visual_bg },
    Search                      = { bg = c.bg_search, fg = c.fg, bold = true },
    IncSearch                   = { bg = c.orange, fg = c.black, bold = true },
    CurSearch                   = 'IncSearch',
    Substitute                  = { bg = c.red, fg = c.black },
    MatchParen                  = { fg = c.orange, bold = true },
    Highlight                   = { bg = c.subtle_bg },

    -- Line numbers
    LineNr                      = { fg = c.fg_gutter },
    CursorLineNr                = { fg = c.orange, bold = true },
    LineNrAbove                 = { fg = c.fg_gutter },
    LineNrBelow                 = { fg = c.fg_gutter },

    -- Folding
    Folded                      = { fg = c.blue, bg = c.fg_gutter, style = opts.styles.comments },
    FoldColumn                  = { bg = opts.transparent and c.none or c.bg, fg = c.comment },

    -- Signs / Gutter
    SignColumn                  = { bg = opts.transparent and c.none or c.bg, fg = c.fg_gutter },
    SignColumnSB                = { bg = c.bg_sidebar, fg = c.fg_gutter },

    -- Popup / Completion
    Pmenu                       = { bg = c.bg_popup, fg = c.fg },
    PmenuMatch                  = { bg = c.bg_popup, fg = c.blue1 },
    PmenuSel                    = { bg = Util.blend_bg(c.fg_gutter, 0.8) },
    PmenuMatchSel               = { bg = Util.blend_bg(c.fg_gutter, 0.8), fg = c.blue1 },
    PmenuSbar                   = { bg = Util.blend_fg(c.bg_popup, 0.95) },
    PmenuThumb                  = { bg = c.fg_gutter },
    WildMenu                    = { bg = c.bg_visual },

    -- Statusline
    StatusLine                  = { fg = c.fg_sidebar, bg = c.bg_statusline },
    StatusLineNC                = { fg = c.fg_gutter, bg = c.bg_statusline },
    WinBar                      = { link = 'StatusLine' },
    WinBarNC                    = { link = 'StatusLineNC' },

    -- Tabline
    TabLine                     = { bg = c.bg_statusline, fg = c.fg_gutter },
    TabLineFill                 = { bg = c.bg },
    TabLineSel                  = { fg = c.fg, bg = c.bg_highlight },
    Title                       = { fg = c.blue, bold = true },

    -- Messages / Command line
    MsgArea                     = { fg = c.fg_dark },
    ModeMsg                     = { fg = c.fg_dark },
    MoreMsg                     = { fg = c.blue },
    Question                    = { fg = c.blue },
    WarningMsg                  = { fg = c.warning, bold = true },
    ErrorMsg                    = { fg = c.error, bold = true },
    ShowCmd                     = { fg = c.fg_dark },

    -- Diff
    DiffAdd                     = { bg = c.diff.add },
    DiffChange                  = { bg = c.diff.change },
    DiffDelete                  = { bg = c.diff.delete },
    DiffText                    = { bg = c.diff.text },

    diffAdded                   = { bg = c.diff.add, fg = c.git.add },
    diffRemoved                 = { bg = c.diff.delete, fg = c.git.delete },
    diffChanged                 = { bg = c.diff.change, fg = c.git.change },
    diffOldFile                 = { fg = c.blue1, bg = c.diff.delete },
    diffNewFile                 = { fg = c.blue1, bg = c.diff.add },
    diffFile                    = { fg = c.blue },
    diffLine                    = { fg = c.comment },
    diffIndexLine               = { fg = c.magenta },

    -- Spelling
    SpellBad                    = { sp = c.error, undercurl = true },
    SpellCap                    = { sp = c.warning, undercurl = true },
    SpellLocal                  = { sp = c.info, undercurl = true },
    SpellRare                   = { sp = c.hint, undercurl = true },

    -- Various UI
    ColorColumn                 = { bg = c.bg },
    Conceal                     = { fg = c.dark5 },
    Directory                   = { fg = c.blue },
    EndOfBuffer                 = { fg = c.bg },
    FloatBorder                 = { fg = c.border_highlight, bg = c.bg_float },
    FloatTitle                  = { fg = c.border_highlight, bg = c.bg_float, bold = true },
    NonText                     = { fg = c.dark3 },
    QuickFixLine                = { bg = c.bg_visual, bold = true },
    SpecialKey                  = { fg = c.dark3 },
    VertSplit                   = { fg = c.border },
    WinSeparator                = { fg = c.border },
    Whitespace                  = { fg = c.fg_gutter },

    -- Vim syntax groups
    Comment                     = { fg = c.comment, style = opts.styles.comments },
    Constant                    = { fg = c.purple },
    String                      = { fg = c.green },
    Character                   = { fg = c.green },
    Number                      = { fg = c.orange },
    Boolean                     = { fg = c.orange },
    Float                       = { fg = c.orange },
    Identifier                  = { fg = c.magenta2, style = opts.styles.variables },
    Function                    = { fg = c.fg, bold = true, style = opts.styles.functions },
    Statement                   = { fg = c.purple, bold = true },
    Conditional                 = { fg = c.purple },
    Repeat                      = { fg = c.purple },
    Label                       = { fg = c.yellow },
    Operator                    = { fg = c.blue5 },
    Keyword                     = { fg = c.purple, bold = true, style = opts.styles.keywords },
    Exception                   = { fg = c.magenta2 },
    PreProc                     = { fg = c.cyan },
    Include                     = { fg = c.blue },
    Define                      = { fg = c.purple },
    Macro                       = { fg = c.cyan },
    PreCondit                   = { fg = c.cyan },
    Type                        = { fg = c.yellow, bold = true },
    StorageClass                = { fg = c.yellow },
    Structure                   = { fg = c.yellow },
    Typedef                     = { fg = c.yellow },
    Special                     = { fg = c.cyan },
    SpecialChar                 = { fg = c.special_char },
    Tag                         = { fg = c.red },
    Delimiter                   = { fg = c.blue5 },
    SpecialComment              = { fg = c.comment, style = opts.styles.comments },
    Debug                       = { fg = c.red },
    Underlined                  = { underline = true },
    Ignore                      = { fg = c.dark3 },
    Error                       = { fg = c.error, bold = true },
    Todo                        = { bg = c.yellow, fg = c.bg, bold = true },

    -- LSP / Reference
    LspReferenceText            = { bg = c.fg_gutter },
    LspReferenceRead            = { bg = c.fg_gutter },
    LspReferenceWrite           = { bg = c.fg_gutter },
    LspSignatureActiveParameter = { bg = Util.blend_bg(c.bg_visual, 0.4), bold = true },
    LspCodeLens                 = { fg = c.comment },
    LspInlayHint                = { bg = Util.blend_bg(c.blue7, 0.1), fg = c.dark3 },
    LspInfoBorder               = { fg = c.border_highlight, bg = c.bg_float },

    -- Diagnostics
    DiagnosticUnnecessary       = { fg = c.cyan },
    DiagnosticError             = { fg = c.error },
    DiagnosticWarn              = { fg = c.warning },
    DiagnosticInfo              = { fg = c.info },
    DiagnosticHint              = { fg = c.hint },
    DiagnosticVirtualTextError  = { fg = c.error, bg = Util.blend_bg(c.error, 0.1) },
    DiagnosticVirtualTextWarn   = { fg = c.warning, bg = Util.blend_bg(c.warning, 0.1) },
    DiagnosticVirtualTextInfo   = { fg = c.info, bg = Util.blend_bg(c.info, 0.1) },
    DiagnosticVirtualTextHint   = { fg = c.hint, bg = Util.blend_bg(c.hint, 0.1) },
    DiagnosticUnderlineError    = { undercurl = true, sp = c.error },
    DiagnosticUnderlineWarn     = { undercurl = true, sp = c.warning },
    DiagnosticUnderlineInfo     = { undercurl = true, sp = c.info },
    DiagnosticUnderlineHint     = { undercurl = true, sp = c.hint },

    -- Git signs
    GitSignsAdd                 = { fg = c.git.add, bold = true },
    GitSignsChange              = { fg = c.git.change, bold = true },
    GitSignsDelete              = { fg = c.git.delete, bold = true },

    -- Health
    healthError                 = { fg = c.error },
    healthSuccess               = { fg = c.green1 },
    healthWarning               = { fg = c.warning },

    -- Misc
    debugBreakpoint             = { bg = Util.blend_bg(c.info, 0.1), fg = c.info },
    debugPC                     = { bg = c.bg_sidebar },
    helpCommand                 = { bg = c.subtle_bg, fg = c.blue },
    htmlH1                      = { fg = c.magenta, bold = true },
    htmlH2                      = { fg = c.blue, bold = true },
    qfFileName                  = { fg = c.blue },
    qfLineNr                    = { fg = c.dark5 },
    dosIniLabel                 = '@property',
  }
end

return M
