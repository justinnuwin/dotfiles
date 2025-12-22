vim9script

import g:dotfilesDirectory .. '/vim/navigation.vim'

g:fzf_preview_window = ['right,50%,<70(up,40%)']

# Open fzf popup with the git worktree
nnoremap <leader>/ :GFiles <CR>

# Open fzf popupt ripgrep-ing the CWD
# NOTE: Requires ripgrep to be installed
nnoremap <leader>g :Rg <CR>

# Open fzf popup for the bazel-bin
nnoremap <leader>b :execute 'Files ' .. GetBazelBinPath() <CR>

# Open fzf popup for the bazel-out
nnoremap <leader>B :execute 'Files ' .. GetBazelOutPath() <CR>

# Open fzf popup for the current buffers
nnoremap <leader>l :Buffers <CR>

# Open fzf popup to change directory to one in the current git worktree
def FzfCdCurrentGRootDirs()
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
nnoremap <leader>c <cmd>call <SID>FzfCdCurrentGRootDirs()<CR>

# Open fzf popup to change directory to one in the current CWD
def g:FzfCdCwd()
  var cmd = navigation.GetDirectoriesFromCwdCmd()
  echo cmd
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
