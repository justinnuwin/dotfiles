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

-- Statusline. Drop the default 'encoding' and 'fileformat' components from
-- section x (the line-ending icon and encoding are not useful); keep branch on
-- the left and "<line>/<total> <col>" on the right.
require('lualine').setup({
  options = {
    theme = 'tomorrow_night',
    globalstatus = true,
  },
  sections = {
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
