-- Neovim color setup, sourced from vimrc right after 'syntax on' and before its
-- highlight overrides (so those are not cleared by the colorscheme's hi clear).

-- Render highlights with their 24-bit (gui) colors.
vim.o.termguicolors = true

-- Use classic Vim's default colorscheme rather than Neovim's built-in default.
vim.cmd.colorscheme('vim')

-- The colorscheme's gui colors differ from the terminal colors its cterm colors
-- map to, so set each group to the terminal colors: ANSI 0-15 from the Ghostty
-- JNTerm theme (terminals/ghostty/themes/JNTerm), the rest from the standard
-- xterm 256-color palette.

-- Syntax
vim.api.nvim_set_hl(0, 'Comment', { fg = '#5bfff5' })
vim.api.nvim_set_hl(0, 'Constant', { fg = '#ff92df' })
vim.api.nvim_set_hl(0, 'Identifier', { fg = '#5bfff5', bold = true })
vim.api.nvim_set_hl(0, 'Statement', { fg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'PreProc', { fg = '#5fd7ff' })
vim.api.nvim_set_hl(0, 'Type', { fg = '#87ffaf' })
vim.api.nvim_set_hl(0, 'Special', { fg = '#ffd7d7' })
vim.api.nvim_set_hl(0, 'Underlined', { fg = '#5fd7ff', underline = true })
vim.api.nvim_set_hl(0, 'Ignore', { fg = '#1d1f21' })
vim.api.nvim_set_hl(0, 'Error', { fg = '#eaeaea', bg = '#ff6e6e' })
vim.api.nvim_set_hl(0, 'Todo', { fg = '#1d1f21', bg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'Added', { fg = '#15ff60' })
vim.api.nvim_set_hl(0, 'Changed', { fg = '#70cfff' })
vim.api.nvim_set_hl(0, 'Removed', { fg = '#ff6e6e' })

-- Editor UI
vim.api.nvim_set_hl(0, 'LineNr', { fg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = '#ffcb6b', underline = true })
vim.api.nvim_set_hl(0, 'SignColumn', { fg = '#5bfff5', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'FoldColumn', { fg = '#5bfff5', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'Folded', { fg = '#5bfff5', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'CursorColumn', { bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'Conceal', { fg = '#c5c8c6', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'NonText', { fg = '#70cfff' })
vim.api.nvim_set_hl(0, 'SpecialKey', { fg = '#5fd7ff' })
vim.api.nvim_set_hl(0, 'Directory', { fg = '#afffff' })
vim.api.nvim_set_hl(0, 'Title', { fg = '#ffd7ff' })
vim.api.nvim_set_hl(0, 'Visual', { fg = '#1d1f21', bg = '#a8a8a8' })
vim.api.nvim_set_hl(0, 'Search', { fg = '#1d1f21', bg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'MatchParen', { bg = '#7fd8cf' })
vim.api.nvim_set_hl(0, 'WildMenu', { fg = '#1d1f21', bg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'PmenuSbar', { bg = '#a8a8a8' })
vim.api.nvim_set_hl(0, 'PmenuThumb', { bg = '#eaeaea' })
vim.api.nvim_set_hl(0, 'TabLine', { fg = '#eaeaea', bg = '#6c6c6c', underline = true })
vim.api.nvim_set_hl(0, 'StatusLineTerm', { fg = '#1d1f21', bg = '#87ffaf', bold = true })
vim.api.nvim_set_hl(0, 'StatusLineTermNC', { fg = '#1d1f21', bg = '#87ffaf' })

-- Messages
vim.api.nvim_set_hl(0, 'ErrorMsg', { fg = '#eaeaea', bg = '#ff5555' })
vim.api.nvim_set_hl(0, 'WarningMsg', { fg = '#ffd7d7' })
vim.api.nvim_set_hl(0, 'MoreMsg', { fg = '#87ffaf' })
vim.api.nvim_set_hl(0, 'Question', { fg = '#87ffaf' })
vim.api.nvim_set_hl(0, 'OkMsg', { fg = '#15ff60' })

-- Diagnostics
vim.api.nvim_set_hl(0, 'DiagnosticError', { fg = '#ff5555' })
vim.api.nvim_set_hl(0, 'DiagnosticWarn', { fg = '#fac357' })
vim.api.nvim_set_hl(0, 'DiagnosticInfo', { fg = '#77abff' })
vim.api.nvim_set_hl(0, 'DiagnosticHint', { fg = '#c5c8c6' })
vim.api.nvim_set_hl(0, 'DiagnosticOk', { fg = '#15ff60' })

-- Spelling: a colored background rather than an undercurl.
vim.api.nvim_set_hl(0, 'SpellBad', { bg = '#ff6e6e' })
vim.api.nvim_set_hl(0, 'SpellCap', { bg = '#70cfff' })
vim.api.nvim_set_hl(0, 'SpellLocal', { bg = '#5bfff5' })
vim.api.nvim_set_hl(0, 'SpellRare', { bg = '#ff92df' })

-- indent-blankline scope guide
vim.api.nvim_set_hl(0, 'IblScope', { fg = '#ffcb6b' })
vim.api.nvim_set_hl(0, '@ibl.scope.char.1', { fg = '#ffcb6b', nocombine = true })

-- Neovim internals
vim.api.nvim_set_hl(0, 'NvimInternalError', { fg = '#ff6e6e', bg = '#ff6e6e' })
vim.api.nvim_set_hl(0, 'RedrawDebugClear', { bg = '#ffcb6b' })
vim.api.nvim_set_hl(0, 'RedrawDebugComposed', { bg = '#15ff60' })
vim.api.nvim_set_hl(0, 'RedrawDebugRecompose', { bg = '#ff6e6e' })

-- vim-gitgutter signs (and its diff preview colors, derived from them). The
-- plugin keeps an already-set sign foreground instead of applying its own.
vim.api.nvim_set_hl(0, 'GitGutterAdd', { fg = '#58e37b', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'GitGutterChange', { fg = '#fac357', bg = '#6c6c6c' })
vim.api.nvim_set_hl(0, 'GitGutterDelete', { fg = '#ff5555', bg = '#6c6c6c' })

-- Current line: a very slight background highlight instead of the colorscheme's
-- underline (which the indent guides break up). Set after the colorscheme.
vim.api.nvim_set_hl(0, 'CursorLine', { bg = '#303030', ctermbg = 236 })

-- Completion / popup menu. The 'vim' colorscheme defaults these to a garish
-- magenta background (ctermbg=13); use a dark gray with light text, and a
-- lighter gray for the selected row. The kind/extra columns share the base look.
vim.api.nvim_set_hl(0, 'Pmenu', { fg = '#bcbcbc', bg = '#444444', ctermfg = 250, ctermbg = 238 })
vim.api.nvim_set_hl(0, 'PmenuSel', { fg = '#d0d0d0', bg = '#808080', ctermfg = 252, ctermbg = 244 })
vim.api.nvim_set_hl(0, 'PmenuKind', { link = 'Pmenu' })
vim.api.nvim_set_hl(0, 'PmenuExtra', { link = 'Pmenu' })
