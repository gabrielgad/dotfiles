-- eberhardgross-534164 colorscheme for Neovim
-- Generated from: /home/gabe/Pictures/wallpapers/pexels-eberhardgross-534164.jpg

local M = {}

-- Color palette from theme
M.palette = {
  -- Surface colors (backgrounds)
  bg = "#0F1114",
  bg_dark = "#15191D",
  bg_highlight = "#1D232A",

  -- Text colors
  fg = "#EAEAEB",
  fg_dark = "#D0D0D2",
  fg_gutter = "#B6B7B8",

  -- Accent colors
  accent = "#80B8F8",
  accent2 = "#B8F8F8",
  accent3 = "#48FF00",

  -- Terminal colors (semantic)
  black = "#0F1114",
  red = "#5CA4F6",
  green = "#90F4F4",
  yellow = "#A3CBF9",
  blue = "#7DF2F2",
  magenta = "#40E500",
  cyan = "#40E500",
  white = "#B6B7B8",
  bright_black = "#1D232A",
  bright_red = "#C7DFFB",
  bright_green = "#F2FDFD",
  bright_yellow = "#D9E9FC",
  bright_blue = "#DFFBFB",
  bright_magenta = "#63FF26",
  bright_cyan = "#63FF26",
  bright_white = "#EAEAEB",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.o.termguicolors = true
  vim.g.colors_name = "eberhardgross-534164"

  local p = M.palette

  local function hi(group, opts)
    local cmd = "hi " .. group
    if opts.fg then cmd = cmd .. " guifg=" .. opts.fg end
    if opts.bg then cmd = cmd .. " guibg=" .. opts.bg end
    if opts.style then
      cmd = cmd .. " gui=" .. opts.style
    end
    vim.cmd(cmd)
  end

  -- Editor
  hi("Normal", { fg = p.fg, bg = p.bg })
  hi("NormalFloat", { fg = p.fg, bg = p.bg_dark })
  hi("NormalNC", { fg = p.fg, bg = p.bg })
  hi("Cursor", { fg = p.bg, bg = p.fg })
  hi("CursorLine", { bg = p.bg_dark })
  hi("CursorLineNr", { fg = p.accent, style = "bold" })
  hi("CursorColumn", { bg = p.bg_dark })
  hi("ColorColumn", { bg = p.bg_dark })
  hi("LineNr", { fg = p.fg_gutter })
  hi("VertSplit", { fg = p.accent2, bg = p.bg })
  hi("WinSeparator", { fg = p.accent2, bg = p.bg })
  hi("Folded", { fg = p.fg_dark, bg = p.bg_dark })
  hi("FoldColumn", { fg = p.fg_gutter, bg = p.bg })
  hi("SignColumn", { bg = p.bg })
  hi("MatchParen", { fg = p.bright_yellow, style = "bold" })
  hi("NonText", { fg = p.bright_black })
  hi("SpecialKey", { fg = p.bright_black })
  hi("Whitespace", { fg = p.bright_black })
  hi("EndOfBuffer", { fg = p.bright_black })

  -- Search
  hi("Search", { fg = p.bg, bg = p.bright_yellow })
  hi("IncSearch", { fg = p.bg, bg = p.yellow })
  hi("Substitute", { fg = p.bg, bg = p.red })
  hi("Visual", { bg = p.bg_highlight })
  hi("VisualNOS", { bg = p.bg_highlight })

  -- Messages
  hi("ErrorMsg", { fg = p.red, style = "bold" })
  hi("WarningMsg", { fg = p.yellow, style = "bold" })
  hi("ModeMsg", { fg = p.accent, style = "bold" })
  hi("MoreMsg", { fg = p.accent, style = "bold" })
  hi("Question", { fg = p.accent, style = "bold" })
  hi("Title", { fg = p.accent, style = "bold" })
  hi("Directory", { fg = p.blue })

  -- Popup menu
  hi("Pmenu", { fg = p.fg, bg = p.bg_dark })
  hi("PmenuSel", { fg = p.bg, bg = p.accent })
  hi("PmenuSbar", { bg = p.bg_dark })
  hi("PmenuThumb", { bg = p.accent })
  hi("WildMenu", { fg = p.bg, bg = p.accent })

  -- Status line
  hi("StatusLine", { fg = p.fg, bg = p.bg_dark })
  hi("StatusLineNC", { fg = p.fg_gutter, bg = p.bg_dark })
  hi("TabLine", { fg = p.fg, bg = p.bg_dark })
  hi("TabLineFill", { bg = p.bg_dark })
  hi("TabLineSel", { fg = p.bg, bg = p.accent })

  -- Diff
  hi("DiffAdd", { fg = p.bright_green, bg = p.bg_dark })
  hi("DiffChange", { fg = p.bright_yellow, bg = p.bg_dark })
  hi("DiffDelete", { fg = p.bright_red, bg = p.bg_dark })
  hi("DiffText", { fg = p.bg, bg = p.bright_yellow })
  hi("diffAdded", { fg = p.bright_green })
  hi("diffRemoved", { fg = p.bright_red })
  hi("diffChanged", { fg = p.bright_yellow })

  -- Spell
  hi("SpellBad", { style = "underline", fg = p.red })
  hi("SpellCap", { style = "underline", fg = p.yellow })
  hi("SpellLocal", { style = "underline", fg = p.cyan })
  hi("SpellRare", { style = "underline", fg = p.magenta })

  -- Syntax
  hi("Comment", { fg = p.fg_gutter, style = "italic" })
  hi("Constant", { fg = p.bright_magenta })
  hi("String", { fg = p.bright_green })
  hi("Character", { fg = p.bright_green })
  hi("Number", { fg = p.bright_yellow })
  hi("Boolean", { fg = p.bright_yellow })
  hi("Float", { fg = p.bright_yellow })

  hi("Identifier", { fg = p.fg })
  hi("Function", { fg = p.accent })

  hi("Statement", { fg = p.magenta })
  hi("Conditional", { fg = p.magenta })
  hi("Repeat", { fg = p.magenta })
  hi("Label", { fg = p.bright_yellow })
  hi("Operator", { fg = p.cyan })
  hi("Keyword", { fg = p.magenta, style = "italic" })
  hi("Exception", { fg = p.red })

  hi("PreProc", { fg = p.cyan })
  hi("Include", { fg = p.magenta })
  hi("Define", { fg = p.magenta })
  hi("Macro", { fg = p.magenta })
  hi("PreCondit", { fg = p.magenta })

  hi("Type", { fg = p.bright_yellow })
  hi("StorageClass", { fg = p.bright_yellow })
  hi("Structure", { fg = p.bright_yellow })
  hi("Typedef", { fg = p.bright_yellow })

  hi("Special", { fg = p.accent })
  hi("SpecialChar", { fg = p.yellow })
  hi("Tag", { fg = p.red })
  hi("Delimiter", { fg = p.fg })
  hi("SpecialComment", { fg = p.fg_gutter, style = "italic" })
  hi("Debug", { fg = p.red })

  hi("Underlined", { fg = p.accent, style = "underline" })
  hi("Ignore", { fg = p.bright_black })
  hi("Error", { fg = p.red, style = "bold" })
  hi("Todo", { fg = p.bg, bg = p.bright_yellow, style = "bold" })

  -- Treesitter
  hi("@variable", { fg = p.fg })
  hi("@variable.builtin", { fg = p.cyan })
  hi("@variable.parameter", { fg = p.yellow })
  hi("@variable.member", { fg = p.fg })
  hi("@constant", { fg = p.bright_magenta })
  hi("@constant.builtin", { fg = p.bright_magenta })
  hi("@string", { fg = p.bright_green })
  hi("@string.regex", { fg = p.bright_cyan })
  hi("@string.escape", { fg = p.yellow })
  hi("@character", { fg = p.bright_green })
  hi("@number", { fg = p.bright_yellow })
  hi("@boolean", { fg = p.bright_yellow })
  hi("@function", { fg = p.accent })
  hi("@function.builtin", { fg = p.cyan })
  hi("@function.macro", { fg = p.bright_magenta })
  hi("@parameter", { fg = p.yellow })
  hi("@method", { fg = p.accent })
  hi("@field", { fg = p.fg })
  hi("@property", { fg = p.fg })
  hi("@constructor", { fg = p.accent })
  hi("@conditional", { fg = p.magenta })
  hi("@repeat", { fg = p.magenta })
  hi("@label", { fg = p.bright_yellow })
  hi("@keyword", { fg = p.magenta, style = "italic" })
  hi("@keyword.function", { fg = p.magenta, style = "italic" })
  hi("@keyword.operator", { fg = p.cyan })
  hi("@keyword.return", { fg = p.magenta, style = "italic" })
  hi("@operator", { fg = p.cyan })
  hi("@exception", { fg = p.red })
  hi("@type", { fg = p.bright_yellow })
  hi("@type.builtin", { fg = p.bright_yellow })
  hi("@namespace", { fg = p.accent })
  hi("@include", { fg = p.magenta })
  hi("@punctuation.delimiter", { fg = p.fg })
  hi("@punctuation.bracket", { fg = p.fg })
  hi("@punctuation.special", { fg = p.cyan })
  hi("@comment", { fg = p.fg_gutter, style = "italic" })
  hi("@tag", { fg = p.red })
  hi("@tag.attribute", { fg = p.yellow })
  hi("@tag.delimiter", { fg = p.fg })

  -- LSP
  hi("DiagnosticError", { fg = p.red })
  hi("DiagnosticWarn", { fg = p.yellow })
  hi("DiagnosticInfo", { fg = p.blue })
  hi("DiagnosticHint", { fg = p.cyan })
  hi("DiagnosticUnderlineError", { style = "underline", fg = p.red })
  hi("DiagnosticUnderlineWarn", { style = "underline", fg = p.yellow })
  hi("DiagnosticUnderlineInfo", { style = "underline", fg = p.blue })
  hi("DiagnosticUnderlineHint", { style = "underline", fg = p.cyan })
  hi("LspReferenceText", { bg = p.bg_dark })
  hi("LspReferenceRead", { bg = p.bg_dark })
  hi("LspReferenceWrite", { bg = p.bg_dark })

  -- Git signs
  hi("GitSignsAdd", { fg = p.bright_green })
  hi("GitSignsChange", { fg = p.bright_yellow })
  hi("GitSignsDelete", { fg = p.bright_red })

  -- Telescope
  hi("TelescopeNormal", { fg = p.fg, bg = p.bg })
  hi("TelescopeBorder", { fg = p.accent, bg = p.bg })
  hi("TelescopePromptNormal", { fg = p.fg, bg = p.bg_dark })
  hi("TelescopePromptBorder", { fg = p.accent, bg = p.bg_dark })
  hi("TelescopePromptTitle", { fg = p.bg, bg = p.accent })
  hi("TelescopePreviewTitle", { fg = p.bg, bg = p.bright_green })
  hi("TelescopeResultsTitle", { fg = p.bg, bg = p.accent })
  hi("TelescopeSelection", { fg = p.fg, bg = p.bg_highlight })
  hi("TelescopeMatching", { fg = p.bright_yellow, style = "bold" })

  -- nvim-cmp
  hi("CmpItemAbbrMatch", { fg = p.bright_yellow, style = "bold" })
  hi("CmpItemAbbrMatchFuzzy", { fg = p.bright_yellow, style = "bold" })
  hi("CmpItemMenu", { fg = p.fg_gutter })
  hi("CmpItemKindDefault", { fg = p.magenta })
  hi("CmpItemKindFunction", { fg = p.accent })
  hi("CmpItemKindMethod", { fg = p.accent })
  hi("CmpItemKindVariable", { fg = p.fg })
  hi("CmpItemKindClass", { fg = p.bright_yellow })
  hi("CmpItemKindKeyword", { fg = p.magenta })
  hi("CmpItemKindSnippet", { fg = p.bright_green })

  -- Float windows
  hi("FloatBorder", { fg = p.accent, bg = p.bg_dark })
  hi("FloatTitle", { fg = p.bg, bg = p.accent })

  -- Terminal colors
  vim.g.terminal_color_0 = p.black
  vim.g.terminal_color_1 = p.red
  vim.g.terminal_color_2 = p.green
  vim.g.terminal_color_3 = p.yellow
  vim.g.terminal_color_4 = p.blue
  vim.g.terminal_color_5 = p.magenta
  vim.g.terminal_color_6 = p.cyan
  vim.g.terminal_color_7 = p.white
  vim.g.terminal_color_8 = p.bright_black
  vim.g.terminal_color_9 = p.bright_red
  vim.g.terminal_color_10 = p.bright_green
  vim.g.terminal_color_11 = p.bright_yellow
  vim.g.terminal_color_12 = p.bright_blue
  vim.g.terminal_color_13 = p.bright_magenta
  vim.g.terminal_color_14 = p.bright_cyan
  vim.g.terminal_color_15 = p.bright_white
end

return M
