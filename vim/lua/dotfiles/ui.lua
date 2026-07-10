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
-- The filename component shows a red Nerd Font lock glyph ('\u{f0341}',
-- md-lock-outline) for a readonly or nomodifiable buffer, in place of lualine's
-- default '[-]'. The highlight (DotfilesReadonlyLock) is embedded in the symbol
-- string and defined just after this setup call -- it copies lualine's section-c
-- background, which only exists once lualine has been configured.
require('lualine').setup({
  options = {
    theme = 'tomorrow_night',
    globalstatus = true,
  },
  sections = {
    lualine_c = {
      { 'filename', path = 1, symbols = { readonly = '%#DotfilesReadonlyLock#\u{f0341}' } },
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

-- Define DotfilesReadonlyLock now that lualine's section groups exist. nocombine
-- is essential: the 'vim' colorscheme's StatusLine group is 'reverse', and a
-- statusline %#group# combines with (and so inherits 'reverse' from) StatusLine
-- unless it opts out -- without nocombine the red fg is swapped into the
-- background, drawing a red block with the glyph knocked out. lualine adds
-- nocombine to all of its own groups for this reason. The background (gui and
-- cterm) is copied from lualine's own section-c group so the glyph blends into
-- the statusline exactly, in both truecolor and 256-color terminals.
-- :colorscheme clears custom groups (and lualine rebuilds its own), so re-apply.
local function set_readonly_lock_hl()
  local sec = vim.api.nvim_get_hl(0, { name = 'lualine_c_normal' })
  vim.api.nvim_set_hl(0, 'DotfilesReadonlyLock', {
    fg = '#d75f5f', bg = sec.bg, nocombine = true,
    ctermfg = 'red', ctermbg = sec.ctermbg,
  })
end
set_readonly_lock_hl()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('dotfiles_readonly_lock', { clear = true }),
  callback = function() vim.schedule(set_readonly_lock_hl) end,
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
