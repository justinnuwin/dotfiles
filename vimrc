"         _                    
"  __   _(_)_ __ ___  _ __ ___ 
"  \ \ / / | '_ ` _ \| '__/ __|
"   \ V /| | | | | | | | | (__ 
"  (_)_/ |_|_| |_| |_|_|  \___|
"

let usePlugins = 1

if usePlugins
    " Plug
    call plug#begin('~/.vim/plugins')
    Plug 'neoclide/coc.nvim', {'branch': 'release'}
    Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
    Plug 'Xuyuanp/nerdtree-git-plugin'
    Plug 'tpope/vim-fugitive'
    Plug 'lervag/vimtex'
    " Plug 'sirver/ultisnips'
    Plug 'justinmk/vim-sneak'
    Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
    Plug 'kshenoy/vim-signature'
    Plug 'zhou13/vim-easyescape'
    Plug 'nathanaelkane/vim-indent-guides'
    call plug#end()

    " coc.nvim Settings
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

    " Nerd Tree Settings
    map <C-o> :NERDTreeToggle<CR>
    autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

    " Vim Airline Settings
    let g:airline_powerline_fonts = 1
    if has("gui_running")
        set guifont=Hack:h12
    endif

    " VimTex Settings
    let g:tex_flavor='latex'
    " let g:vimtex_view_method='skim'
    let g:vimtex_quickfix_mode=0
    set conceallevel=1
    let g:tex_conceal='abdmg'

    " UltiSnips Settings
    let g:UltiSnipsExpandTrigger = '<c-tab>'
    let g:UltiSnipsJumpForwardTrigger = '<c-tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'

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
else
    " Bind jk to escape because it's too damn far away!
    " Note that Ctrl-i also works
    imap jk <Esc>
endif

" Leader key
let mapleader = ","

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

" Don't beep
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
