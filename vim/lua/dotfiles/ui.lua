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

-- Git change signs in the gutter.
require('gitsigns').setup()

-- Statusline: branch on the left, no y section, "<line>/<total> <col>" on the right.
require('lualine').setup({
  options = {
    theme = 'auto',
    globalstatus = true,
  },
  sections = {
    lualine_y = {},
    lualine_z = {
      function()
        return string.format('%d/%d %d', vim.fn.line('.'), vim.fn.line('$'), vim.fn.col('.'))
      end,
    },
  },
})

-- Indentation guides.
require('ibl').setup()
