execute 'source' g:dotfilesDirectory . '/vim/navigation.vim'

let g:fzf_preview_window = ['right,50%,<70(up,40%)']

" Open fzf popup with the git worktree
nnoremap <leader>/ :GFiles <CR>

" Open fzf popupt ripgrep-ing the CWD
" NOTE: Requires ripgrep to be installed
nnoremap <leader>g :Rg <CR>

" Open fzf popup for the bazel-bin
nnoremap <leader>b :execute 'Files ' . GetBazelBinPath() <CR>

" Open fzf popup for the bazel-out
nnoremap <leader>B :execute 'Files ' . GetBazelOutPath() <CR>

" Open fzf popup for the current buffers
nnoremap <leader>l :Buffers <CR>

" Sink for FzfCdCurrentGRootDirs: cd to the selected path relative to the git root
function! s:CdGRootSink(gitRoot, p)
  execute 'cd ' . a:gitRoot . '/' . a:p
  pwd
endfunction

" Open fzf popup to change directory to one in the current git worktree
function! s:FzfCdCurrentGRootDirs()
  let l:cmd = GetDirectoriesFromGRootCmd()
  let l:gitRoot = trim(system('git rev-parse --show-toplevel'))
  call fzf#run(fzf#wrap({
    \ 'source': l:cmd,
    \ 'sink': function('s:CdGRootSink', [l:gitRoot]),
    \ 'options': '--prompt=" cd> "'
    \ }))
endfunction
nnoremap <leader>c <cmd>call <SID>FzfCdCurrentGRootDirs()<CR>

" Sink for FzfCdCwd: cd to the selected path
function! s:CdCwdSink(p)
  execute 'cd ' . a:p
  pwd
endfunction

" Open fzf popup to change directory to one in the current CWD
function! g:FzfCdCwd()
  let l:cmd = GetDirectoriesFromCwdCmd()
  echo l:cmd
  call fzf#run(fzf#wrap({
    \ 'source': l:cmd,
    \ 'sink': function('s:CdCwdSink'),
    \ 'options': '--prompt="cd> "'
    \ }))
endfunction
nnoremap <leader>C :call FzfCdCwd() <CR>
nnoremap <BS> <C-H>
