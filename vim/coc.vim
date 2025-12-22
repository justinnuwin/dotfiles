vim9script

# Directory for coc-settings.json
g:coc_config_home = '~/.dotfiles/vim'

# coc Extensions
# List installed extensions with ':CocList extensions'
# List of extensions can be found here: https://github.com/neoclide/coc.nvim/wiki/Using-coc-extensions#implemented-coc-extensions
g:coc_global_extensions = ['coc-clangd', 'coc-json', 'coc-pydocstring', 'coc-pyright', 'coc-snippets']

# Less distracting coloring of inlay hints
highlight CocInlayHint cterm=italic ctermfg=darkgray ctermbg=black

# Disable Coc when it gets too noisy
map <C-S> :call CocAction('diagnosticToggle')<CR>

# Shorten default update time
set updatetime=300

# Avoid unnecessary default-vim completion messages
set shortmess+=c

# Use tab to select current completion shown, expand or jump if available, or insert tab if following whitespace
# Remember to set "suggest.noselect": true in coc config
def Tab(): string
  if coc#pum#visible()
    # NOTE: For some reason this doesn't work with coc#_select_confirm()
    var info = coc#pum#info()
    coc#pum#select(info.index == -1 ? 0 : info.index, true, true)
    return coc#pum#confirm()
  endif
  if coc#jumpable()
    return NextSnippet()
  endif
  return CheckBackspace() ? "\<TAB>" : coc#refresh()
enddef
inoremap <silent> <Tab> <cmd>call <SID>Tab()<CR>

# Accept completion if the popup menu is open
# NOTE: \<C-g>u is used to break undo level.
inoremap <silent><expr> <CR> coc#pum#visible() && coc#pum#info()['index'] != -1 ? coc#pum#confirm() : "\<C-g>u\<CR>"

# Next completion or next snippet placeholder if one has already been expanded
inoremap <silent><expr> <C-j>
  \ coc#pum#visible() ? coc#pum#next(0) : coc#snippet#next()

# Previous completion or previous snippet placeholder if one has been expanded
inoremap <silent><expr> <C-k>
  \ coc#pum#visible() ? coc#pum#prev(0) : coc#snippet#prev()

# Cancel the shown completion (but does not stop it - so we can still continue the snippet)
inoremap <silent><expr> <C-e> coc#pum#visible() ? coc#pum#cancel() : coc#inline#visible() ? coc#inline#cancel() : ""

# Next snippet placeholder
def NextSnippet(): string
  echom "next snippet"
  coc#refresh()
  coc#pum#visible() ? coc#pum#cancel() : coc#inline#visible() ? coc#inline#cancel() : ""
  coc#snippet#next()
  return ""
enddef
inoremap <silent> <C-l> <cmd>call <SID>NextSnippet()<CR>
snoremap <silent> <C-l> <cmd>call <SID>NextSnippet()<CR>

# Previous snippet placeholder
def PrevSnippet()
  coc#refresh()
  coc#pum#visible() ? coc#pum#cancel() : coc#inline#visible() ? coc#inline#cancel() : ""
  coc#snippet#prev()
enddef
inoremap <silent> <C-h> <cmd>call <SID>PrevSnippet()<CR>
snoremap <silent> <C-h> <cmd>call <SID>PrevSnippet()<CR>

# Previous completion or outdent
inoremap <silent><expr> <S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

# Check if the character before the cursor is a whitespace
def CheckBackspace(): bool
  var col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
enddef

# Go to definition/uses
nmap <silent><nowait> gd <Plug>(coc-definition)
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)

# Show documentation preview for the curent symbol
def ShowDocumentation()
  if g:CocAction('hasProvider', 'hover')
    call g:CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
enddef
nnoremap <silent> K <cmd>call <SID>ShowDocumentation()<CR>

