-- Neovim color setup, sourced from vimrc right after 'syntax on' and before its
-- highlight overrides (so those are not cleared by the colorscheme's hi clear).

-- Match classic Vim's use of the terminal's own palette. On a truecolor terminal
-- Neovim auto-enables 'termguicolors', which makes colorschemes render their gui
-- (hex) colors instead of mapping cterm colors to the terminal theme. Setting it
-- explicitly both forces it off and opts out of the auto-enable.
vim.o.termguicolors = false

-- Neovim's built-in default colorscheme overrides the terminal palette, unlike
-- classic Vim which defers to it. The 'vim' colorscheme restores that behavior.
vim.cmd.colorscheme('vim')

-- Current line: a very slight background highlight instead of the colorscheme's
-- underline (which the indent guides break up). Set after the colorscheme.
vim.api.nvim_set_hl(0, 'CursorLine', { ctermbg = 236 })
