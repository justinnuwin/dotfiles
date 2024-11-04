vim9script

import g:dotfilesDirectory .. '/vim/navigation.vim'

# Vim Plug
call plug#begin(g:pluginDirectory)

# Code Completion
Plug 'neoclide/coc.nvim', {'branch': 'release'}
g:coc_config_home = '~/.dotfiles/vim'
# List installed extensions with ':CocList extensions'
# List of extensions can be found here: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions#implemented-coc-extensions
g:coc_global_extensions = ['coc-clangd', 'coc-json', 'coc-pydocstring', 'coc-pyright', 'coc-snippets']
# set cmdheight=2
set updatetime=300
set shortmess+=c
# Remember to set "suggest.noselect": true in coc config
inoremap <silent><expr> <TAB>
  \ coc#pum#visible() ? coc#pum#next(1) :
  \ CheckBackspace() ? "\<Tab>" :
  \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"
def CheckBackspace(): bool
  var col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
enddef

# Syntax Checking
# Plug 'vim-syntastic/syntastic'
g:syntastic_check_on_open = 1
g:syntastic_check_on_wq = 0
map <C-S> :SyntasticToggleMode<CR>

# File Tree
Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
map <leader>o :NERDTreeToggle<CR>
map <leader>O :NERDTreeToggleVCS<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

# Git Bindings.
# Use GBrowse! to display the url without opening a browse (i.e. when SSHed)
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-rhubarb'   # Enables Git-Browse with GitHub
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

# Vim Bar Theme
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
g:airline_powerline_fonts = 1
g:airline_extensions = ['branch', 'coc', 'tagbar']
g:airline_skip_empty_sections = 1
g:airline_section_y = [] # Disable default ffenc section
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
g:fzf_preview_window = ['right,50%,<70(up,40%)']
nnoremap <C-/> :Files ../../../<CR>
nnoremap <leader>/ :GFiles <CR>
# Rg requires ripgrep to be installed
nnoremap <leader>g :Rg <CR>
nnoremap <leader>b :execute 'Files ' .. GetBazelBinPath() <CR>
nnoremap <leader>B :execute 'Files ' .. GetBazelOutPath() <CR>
nnoremap <leader>l :Buffers <CR>
def g:FzfCdCurrentGRootDirs()
  # cd's to the selected directory from a fzf list of directories
  # in the current Git repo's
  var cmd = navigation.GetDirectoriesFromGRootCmd()
  const gitRoot = trim(system('git rev-parse --show-toplevel'))
  fzf#run(fzf#wrap({
    'source': cmd,
    'sink': (p) => {
      execute 'cd ' .. gitRoot .. '/' .. p
      pwd
    },
    'options': '--prompt=" cd> "'
  }))
enddef
nnoremap <leader>c :call FzfCdCurrentGRootDirs() <CR>
def g:FzfCdCwd()
  # cd's to the selected directory from a fzf list of directories
  # in the cwd
  var cmd = navigation.GetDirectoriesFromCwdCmd()
  fzf#run(fzf#wrap({
    'source': cmd,
    'sink': (p) => {
      execute 'cd ' .. p
      pwd
    },
    'options': '--prompt="cd> "'
  }))
enddef
nnoremap <leader>C :call FzfCdCwd() <CR>
nnoremap <BS> <C-H>

call plug#end()
