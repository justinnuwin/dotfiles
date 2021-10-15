"         _                    
"  __   _(_)_ __ ___  _ __ ___ 
"  \ \ / / | '_ ` _ \| '__/ __|
"   \ V /| | | | | | | | | (__ 
"  (_)_/ |_|_| |_| |_|_|  \___|
"

" Leader key
let mapleader = ","

let usePlugins = 1

if usePlugins
    " Plug
    call plug#begin('~/.vim/plugins')
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    " Plug 'vim-syntastic/syntastic'
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'tpope/vim-fugitive'
    Plug 'lervag/vimtex'
    " Plug 'sirver/ultisnips'
    Plug 'justinmk/vim-sneak'
    Plug 'unblevable/quick-scope' 
    Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
    Plug 'kshenoy/vim-signature'
    Plug 'zhou13/vim-easyescape'
    Plug 'nathanaelkane/vim-indent-guides'
    Plug 'airblade/vim-gitgutter'
    Plug 'tpope/vim-obsession'
    Plug 'tpope/vim-commentary'
    Plug 'vim-utils/vim-man'
    Plug 'vim-utils/vim-troll-stopper'
    Plug 'preservim/tagbar'
    call plug#end()

    " CoC Settings
    " set cmdheight=2
    set updatetime=300
    set shortmess+=c
    inoremap <silent><expr> <TAB>
        \ pumvisible() ? "\<C-n>" :
        \ <SID>check_back_space() ? "\<TAB>" :
        \ coc#refresh()
    inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"

    function! s:check_back_space() abort
        let col = col('.') - 1
        return !col || getline('.')[col - 1]  =~# '\s'
    endfunction
    
    " Syntastic Settings
    let g:syntastic_check_on_open = 1
    let g:syntastic_check_on_wq = 0
    map <C-S> :SyntasticToggleMode<CR>

    " Nerd Tree Settings
    map <leader>o :NERDTreeToggle<CR>
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

    " Vim Airline Settings
    let g:airline_powerline_fonts = 1

    " VimTex Settings
    let g:tex_flavor='latex'
    " let g:vimtex_view_method='skim'
    let g:vimtex_quickfix_mode=0
    autocmd Filetype tex setlocal conceallevel=1
    let g:tex_conceal='abdmg'

    " UltiSnips Settings
    let g:UltiSnipsExpandTrigger = '<c-tab>'
    let g:UltiSnipsJumpForwardTrigger = '<c-tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
    
    " Vim-Sneak Settings
    let g:sneak#s_next = 1
    
    " Quickscope Settings
    let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

    " Easy Escape Settings
    let g:easyescape_chars = { "j": 1, "k": 1 }
    let g:easyescape_timeout = 100
    cnoremap jk <ESC>

    " Vim Indent Guide Settings (default toggle is <leader>ig)
    let g:indent_guides_enable_on_vim_startup = 1
    " let g:indent_guides_start_level = 2
    let g:indent_guides_guide_size = 1
    let g:indent_guides_auto_colors = 0
    autocmd VimEnter,Colorscheme * :hi IndentGuidesOdd  guibg=red   ctermbg=235
    autocmd VimEnter,Colorscheme * :hi IndentGuidesEven guibg=green ctermbg=236
    
    " Tagbar Settings
    nnoremap <leader>f :TagbarToggle<CR>
else
    " Bind jk to escape because it's too damn far away!
    imap jk <Esc>
endif

" Ask to save rather than error on unsaved changes
set confirm

" Helps force plugins to load correctly when it is turned back on below
filetype off

" Turn on syntax highlighting
syntax on

" For plugins to load correctly
filetype plugin indent on

" Spelling
set spell spelllang=en_us
setlocal spell spelllang=en_us
set nospell
map <leader>s :setlocal spell! spell?<CR>

" Security
set modeline
set modelines=2

" Show line numbers
set number

" Show file stats
set ruler

" Encoding
set encoding=utf-8

" Whitespace
set wrap
set linebreak
set nolist
set textwidth=120
set wrapmargin=0
set formatoptions=tcqrn1
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set noshiftround

" Folding
" Use zR to make all folds go away
set foldmethod=indent
set foldlevel=3
set foldclose=all

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs
runtime! macros/matchit.vim
set mouse=a 

" Move up/down display lines for wrapped text
nnoremap j gj
nnoremap k gk

" Allow hidden buffers
set hidden

" Rendering
set ttyfast

" Status bar
set laststatus=2

" Last line
set showmode
set showcmd

" Hilight Current line
set cursorline

" Visual Autocomplete for command menu
set wildmenu

" Don't beep or flash
set visualbell
set t_vb=

" Searching
nnoremap / /\v
vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
map <leader><space> :noh<CR>

" Formatting
map <leader>q gqip

" Visualize tabs and newlines
" Old   tab:▸\ ,eol:¬
set showbreak=↪
set listchars=tab:→\ ,eol:↲,space:·,nbsp:␣,trail:·,extends:›,precedes:‹
map <leader>L :set list!<CR> " Toggle tabs and EOL

" Color scheme (terminal)
set t_Co=256
set background=dark
let g:solarized_termcolors=256
let g:solarized_termtrans=1

" Correctly map the backspace key to what you expect
set t_kb=^?
fixdel
inoremap <Char-0x07F> <BS>
nnoremap <Char-0x07F> <BS>

" Don't delete leading whitespace on empty line on <CR> or exiting Insert mode
" TODO: This shouldn't be ignored by easy escape, probably do a PR for Indent
" Guides to not be soley based off of existing whitespace characters
inoremap <CR> <CR>x<BS>
nnoremap o ox<BS>
nnoremap O Ox<BS>

" Set conceal level to 2 for JSON since there are quote EVERYWHERE
autocmd Filetype json setlocal conceallevel=2

" Color characters at column 81
highlight ColorColumn ctermbg=gray
call matchadd('ColorColumn', '\%81v', 100)"

" Search for ctags in the current file, working directory, and up
set tags=./tags;,tags;
