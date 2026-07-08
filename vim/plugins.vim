" Vim Plug
call plug#begin(g:pluginDirectory)

" Plugins used by both classic Vim and Neovim live here. Editor-specific plugins
" are loaded near the end of this file: classic Vim sources vim/vim8/plugins.vim,
" while Neovim registers its lua-configured set from vim/lua/dotfiles/.

" File Tree
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
map <leader>o :NERDTreeFind<CR>
map <leader>O :NERDTreeCWD<CR>
map <leader>P :NERDTreeClose<CR>
" Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif
" Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

" Git Bindings.
" Use GBrowse! to display the url without opening a browse (i.e. when SSHed)
Plug 'tpope/vim-fugitive'
" Enables Git-Browse with GitHub
Plug 'tpope/vim-rhubarb'
" TODO: Create PR upstream to get this via default remote 'origin'
let g:github_enterprise_urls = ['https://git.zooxlabs.com']

" Show Git line changes in the sign column
Plug 'airblade/vim-gitgutter'

" Better Latex Syntax Highlighting
Plug 'lervag/vimtex'
let g:tex_flavor = 'latex'
" g:vimtex_view_method = 'skim'
let g:vimtex_quickfix_mode = 0
autocmd Filetype tex setlocal conceallevel=1
let g:tex_conceal = 'abdmg'

" Snip-style Macros
" Plug 'sirver/ultisnips'
let g:UltiSnipsExpandTrigger = '<c-tab>'
let g:UltiSnipsJumpForwardTrigger = '<c-tab>'
let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

" Movement with 2 characters
Plug 'justinmk/vim-sneak'
let g:sneak#s_next = 1

" Highlighting for horizontal f/F movements
Plug 'unblevable/quick-scope'
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

" Display Marks
Plug 'kshenoy/vim-signature'

" View and search man pages
Plug 'vim-utils/vim-man'

" Highlight bad unicode characters
Plug 'vim-utils/vim-troll-stopper'

" Display ctags to help navigate large files
Plug 'preservim/tagbar'
nnoremap <leader>f :TagbarToggle<CR>

" Fuzzy search file finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
execute 'source' g:dotfilesDirectory . '/vim/fzf.vim'

" Editor-specific plugins. Classic Vim gets vim/vim8/plugins.vim (coc.nvim,
" airline, easyescape, ...); Neovim registers its lua-configured set (built-in
" LSP, completion, and the faster lua UI plugins). Both run inside this
" plug#begin/end block.
if has('nvim')
  lua require('dotfiles.plugins')
else
  execute 'source' g:dotfilesDirectory . '/vim/vim8/plugins.vim'
endif

call plug#end()

" Configure the Neovim-only plugins now that plug#end put them on the
" runtimepath. Ordered so completion capabilities exist before the LSP client
" advertises them.
if has('nvim')
  lua require('dotfiles.completion')
  lua require('dotfiles.lsp')
  lua require('dotfiles.ui')
endif
