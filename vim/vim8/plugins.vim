" Classic Vim (vim8) only plugins. Neovim loads faster lua equivalents from
" vim/lua/dotfiles/ instead, so plugins.vim sources this file only when
" !has('nvim'). It runs inside the plug#begin/end block opened by plugins.vim,
" so the Plug command and g:dotfilesDirectory are available here.

" Code Completion.
" coc.nvim drives completion + language features for classic Vim. Neovim uses
" its built-in LSP client with nvim-cmp instead (vim/lua/dotfiles/lsp.lua and
" completion.lua).
Plug 'neoclide/coc.nvim', {'branch': 'release'}
execute 'source' g:dotfilesDirectory . '/vim/vim8/coc.vim'

" Snippets core engine from 'SirVer/ultisnips' not needed since we can use coc
" Include popular snippets. Neovim uses friendly-snippets via LuaSnip instead.
Plug 'honza/vim-snippets'

" Powerline Status Bar.
" Neovim uses lualine.nvim (vim/lua/dotfiles/ui.lua), which is faster.
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
let g:airline_powerline_fonts = 1
let g:airline_extensions = ['branch']
let g:airline_skip_empty_sections = 1
let g:airline_section_y = []  " Disable default ffenc section
let g:airline_section_z = '%l/%L %c'  " Disable the file percentage
let g:airline#extensions#branch#displayed_head_limit = 20
let g:airline#extensions#branch#format = 2
let g:airline#extensions#tagbar#flags = 'f'
let g:airline#extensions#tagbar#searchmethod = 'nearest-stl'
let g:airline_stl_path_style = 'short'

" Less janky exiting insert mode (rather than Ctrl-C).
" vim-easyescape requires Vim compiled with +python3 (it errors without it);
" Neovim uses better-escape.nvim (vim/lua/dotfiles/ui.lua) instead.
Plug 'zhou13/vim-easyescape'
let g:easyescape_chars = { "j": 1, "k": 1 }
let g:easyescape_timeout = 200
cnoremap jk <ESC>

" Indentation Highlighting.
" Neovim uses indent-blankline.nvim (vim/lua/dotfiles/ui.lua).
Plug 'nathanaelkane/vim-indent-guides'
" default toggle is <leader>ig
let g:indent_guides_enable_on_vim_startup = 1
" g:indent_guides_start_level = 2
let g:indent_guides_guide_size = 1
let g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red   ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=green ctermbg=236

" Show Git line changes.
" Neovim uses gitsigns.nvim (vim/lua/dotfiles/ui.lua).
Plug 'airblade/vim-gitgutter'

" Easily comment out code.
" Neovim has built-in commenting (gc/gcc) since 0.10.
Plug 'tpope/vim-commentary'
