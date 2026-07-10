-- Neovim UI plugin setup, plus the two options coc.vim used to set.

-- Shorter updatetime and quieter completion messages.
vim.o.updatetime = 300
vim.opt.shortmess:append('c')

-- Insert-mode "jk" escape. Fires only when j and k are typed in quick
-- succession, so a slowly typed literal "jk" is left untouched.
require('better_escape').setup({
  timeout = 200,
  default_mappings = false,
  mappings = {
    i = { j = { k = '<Esc>' } },
    c = { j = { k = '<Esc>' } },
    t = { j = { k = '<Esc>' } },
    v = { j = { k = '<Esc>' } },
    s = { j = { k = '<Esc>' } },
  },
})

-- Statusline. Show the relative path instead of just the basename (lualine
-- auto-shortens it to fit when the window is narrow). Drop the default
-- 'encoding' and 'fileformat' components from section x (the line-ending icon
-- and encoding are not useful); keep branch on the left and "<line>/<total>
-- <col>" on the right.
-- A readonly or nomodifiable buffer shows a red Nerd Font lock glyph
-- ('\u{f023}') in place of lualine's default '[-]'. The highlight is embedded in
-- the symbol string (lualine escapes the filename but leaves symbols verbatim),
-- so its background is pinned to this theme's section-c bg (#282a2e, constant
-- across modes) so the glyph blends in; :colorscheme clears custom highlight
-- groups, so re-apply it on that event.
local function set_readonly_lock_hl()
  vim.api.nvim_set_hl(0, 'DotfilesReadonlyLock',
    { fg = '#d75f5f', bg = '#282a2e', ctermfg = 'red', ctermbg = 235 })
end
set_readonly_lock_hl()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('dotfiles_readonly_lock', { clear = true }),
  callback = set_readonly_lock_hl,
})

require('lualine').setup({
  options = {
    theme = 'tomorrow_night',
    globalstatus = true,
  },
  sections = {
    lualine_c = {
      { 'filename', path = 1, symbols = { readonly = '%#DotfilesReadonlyLock#\u{f023}' } },
    },
    lualine_x = { 'filetype' },
    lualine_y = {},
    lualine_z = {
      function()
        return string.format('%d/%d %d', vim.fn.line('.'), vim.fn.line('$'), vim.fn.col('.'))
      end,
    },
  },
})

-- Indentation guides. Normally a thin character guide ('\u{258f}', a one-eighth
-- block) in a subtle dark gray. When 'list' is on (hidden chars shown via
-- <leader>L) the character guides clash with the listchars, so switch to a
-- background stripe instead. Colours are defined in ibl's HIGHLIGHT_SETUP hook so
-- they survive colorscheme changes (per the ibl README).
local ibl = require('ibl')
local ibl_hooks = require('ibl.hooks')
ibl_hooks.register(ibl_hooks.type.HIGHLIGHT_SETUP, function()
  vim.api.nvim_set_hl(0, 'IblIndentGray', { ctermfg = 239 })  -- character guide
  vim.api.nvim_set_hl(0, 'IblIndentBg', { ctermbg = 238 })    -- background stripe (list mode)
end)

local function ibl_indent(list_on)
  if list_on then
    return { char = ' ', highlight = 'IblIndentBg' }
  end
  return { char = '\u{258f}', highlight = 'IblIndentGray' }
end

ibl.setup({ indent = ibl_indent(vim.o.list) })

-- Swap the guide style whenever 'list' is toggled (e.g. via <leader>L).
vim.api.nvim_create_autocmd('OptionSet', {
  pattern = 'list',
  group = vim.api.nvim_create_augroup('dotfiles_ibl_list', { clear = true }),
  callback = function()
    ibl.update({ indent = ibl_indent(vim.o.list) })
  end,
})
