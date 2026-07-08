-- Neovim entry point (~/.config/nvim/init.lua). Neovim does not read ~/.vimrc,
-- and its runtimepath excludes ~/.vim, so add the ~/.vim layout back -- that is
-- where vim-plug lives (~/.vim/autoload/plug.vim) -- then source the shared
-- vimrc. Lua form of the ':help nvim-from-vim' recipe.
vim.opt.runtimepath:prepend(vim.fn.expand('~/.vim'))
vim.opt.runtimepath:append(vim.fn.expand('~/.vim/after'))
vim.o.packpath = vim.o.runtimepath

-- Put the dotfiles vim/ dir on the runtimepath so its lua/ modules are
-- requirable as 'dotfiles.*' (e.g. require('dotfiles.lsp')). The Neovim-only
-- config lives there and is loaded from plugins.vim once vim-plug is set up.
vim.opt.runtimepath:prepend(vim.fn.expand('~/.dotfiles/vim'))

vim.cmd('source ~/.vimrc')
