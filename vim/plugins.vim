vim9script

# Vim Plug
call plug#begin(g:pluginDirectory)


# Code Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
execute 'source' g:dotfilesDirectory .. '/vim/coc.vim'

# Snippets core engine from 'SirVer/ultisnips' not needed since we can use coc
# Include popular snippets
Plug 'honza/vim-snippets'

# File Tree
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'
map <leader>o :NERDTreeFind<CR>
map <leader>O :NERDTreeCWD<CR>
map <leader>P :NERDTreeClose<CR>
# Close the tab if NERDTree is the only window remaining in it.
autocmd BufEnter * if winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif
# Exit Vim if NERDTree is the only window remaining in the only tab.
autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | call feedkeys(":quit\<CR>:\<BS>") | endif

# Git Bindings.
# Use GBrowse! to display the url without opening a browse (i.e. when SSHed)
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'   # Enables Git-Browse with GitHub
# TODO: Create PR upstream to get this via default remote 'origin'
g:github_enterprise_urls = ['https://git.zooxlabs.com']

# Better Latex Syntax Highlighting
Plug 'lervag/vimtex'
g:tex_flavor = 'latex'
# g:vimtex_view_method = 'skim'
g:vimtex_quickfix_mode = 0
autocmd Filetype tex setlocal conceallevel=1
g:tex_conceal = 'abdmg'

# Snip-style Macros
# Plug 'sirver/ultisnips'
g:UltiSnipsExpandTrigger = '<c-tab>'
g:UltiSnipsJumpForwardTrigger = '<c-tab>'
g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

# Movement with 2 characters
Plug 'justinmk/vim-sneak'
g:sneak#s_next = 1

# Highlighting for horizontal f/F movements
Plug 'unblevable/quick-scope' 
g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

# Powerline Status Bar
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
g:airline_powerline_fonts = 1
g:airline_extensions = ['branch']
g:airline_skip_empty_sections = 1
g:airline_section_y = [] # Disable default ffenc section
g:airline_section_z = '%l/%L %c'  # Disable the file percentage
g:airline#extensions#branch#displayed_head_limit = 20
g:airline#extensions#branch#format = 2
g:airline#extensions#tagbar#flags = 'f'
g:airline#extensions#tagbar#searchmethod = 'nearest-stl'
g:airline_stl_path_style = 'short'

# Display Marks
Plug 'kshenoy/vim-signature'

# Less janky exiting insert mode (rather than Ctrl-C)
Plug 'zhou13/vim-easyescape'
g:easyescape_chars = { "j": 1, "k": 1 }
g:easyescape_timeout = 200
cnoremap jk <ESC>

# Indentation Highlighting
Plug 'nathanaelkane/vim-indent-guides'
# default toggle is <leader>ig
g:indent_guides_enable_on_vim_startup = 1
# g:indent_guides_start_level = 2
g:indent_guides_guide_size = 1
g:indent_guides_auto_colors = 0
autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red   ctermbg=235
autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=green ctermbg=236

# Show Git line changes
Plug 'airblade/vim-gitgutter'

# Easily comment out code
Plug 'tpope/vim-commentary'

# View and search man pages
Plug 'vim-utils/vim-man'

# Highlight bad unicode characters
Plug 'vim-utils/vim-troll-stopper'

# Display ctags to help navigate large files
Plug 'preservim/tagbar'
nnoremap <leader>f :TagbarToggle<CR>

# Fuzzy search file finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
execute 'source' g:dotfilesDirectory .. '/vim/fzf.vim'

call plug#end()
