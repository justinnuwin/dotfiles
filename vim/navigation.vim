" TODO: The '-printf' option is not POSIX and won't be available on i.e. Macos
let s:findOpts = ' -mindepth 1 -type d -printf "%P\n"'

function! GetDirectoriesFromCwdCmd()
    return "find " . getcwd() . s:findOpts
endfunction


function! GetDirectoriesFromGRootCmd()
    " Note the returned path is relative to the repo root
    let l:gitRoot = trim(system('git rev-parse --show-toplevel'))
    if v:shell_error != 0
        throw "Could not get git repo root: " . getcwd()
    endif
    return "find " . l:gitRoot . s:findOpts
endfunction
