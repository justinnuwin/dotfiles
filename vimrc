"         _                    
"  __   _(_)_ __ ___  _ __ ___ 
"  \ \ / / | '_ ` _ \| '__/ __|
"   \ V /| | | | | | | | | (__ 
"  (_)_/ |_|_| |_| |_|_|  \___|
"
                            
" Plug
call plug#begin('~/.vim/plugins')
Plug 'vim-syntastic/syntastic'
Plug 'valloric/YouCompleteMe'
Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'tpope/vim-fugitive'
Plug 'vim-airline/vim-airline' | Plug 'vim-airline/vim-airline-themes'
call plug#end()


" Syntastic Settings
set statusline+=%#warningmsg#
set statusline+=%{SyntasticStatuslineFlag()}
set statusline+=%*
let g:syntastic_mode_map = { 'mode': 'passive', 'active_filetypes': [],'passive_filetypes': [] }
nnoremap <C-w>E :SyntasticCheck<CR> :SyntasticToggleMode<CR>

let g:syntastic_always_populate_loc_list = 1
let g:syntastic_auto_loc_list = 1
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 1

" YCM Settings
let g:ycm_global_ycm_extra_conf = "~/.ycm_extra_conf.py"

" Nerd Tree Settings
map <C-o> :NERDTreeToggle<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif

" Vim Airline Settings
let g:airline_powerline_fonts = 1


" Don't try to be vi compatible
set nocompatible

" Helps force plugins to load correctly when it is turned back on below
filetype off

" Turn on syntax highlighting
syntax on

" For plugins to load correctly
filetype plugin indent on

" TODO: Pick a leader key
" let mapleader = ","

" Spelling
set spell spelllang=en_us
setlocal spell spelllang=en_us
set nospell

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
set foldlevel=1
set foldclose=all

" Cursor motion
set scrolloff=3
set backspace=indent,eol,start
set matchpairs+=<:> " use % to jump between pairs
runtime! macros/matchit.vim
set mouse=a

" Move up/down editor lines
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

" Searching
nnoremap / /\v
vnoremap / /\v
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
map <leader><space> :let @/=''<cr> " clear search

" Remap help key.
inoremap <F1> <ESC>:set invfullscreen<CR>a
nnoremap <F1> :set invfullscreen<CR>
vnoremap <F1> :set invfullscreen<CR>

" Textmate holdouts

" Formatting
map <leader>q gqip

" Visualize tabs and newlines
set listchars=tab:▸\ ,eol:¬
" Uncomment this to enable by default:
" set list " To enable by default
" Or use your leader key + l to toggle on/off
map <leader>l :set list!<CR> " Toggle tabs and EOL

" Color scheme (terminal)
set t_Co=256
set background=dark
let g:solarized_termcolors=256
let g:solarized_termtrans=1
" put https://raw.github.com/altercation/vim-colors-solarized/master/colors/solarized.vim
" in ~/.vim/colors/ and uncomment:
" colorscheme solarized

" Correctly map the backspace key to what you expect
set t_kb=^?
fixdel
inoremap <Char-0x07F> <BS>
nnoremap <Char-0x07F> <BS>
