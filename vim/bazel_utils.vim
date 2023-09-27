" Get the Bazel BUILD file containing target using the given source file
" sourceFilePath: Full path to a source file
" Throws error if source file not used in any Bazel BUILD files
function! GetBazelBuildDef(sourceFilePath)
    let l:sourceFilePath = expand(a:sourceFilePath)
    let l:buildFile = systemlist('source ~/.dotfiles/shell/bazel_utils.sh; get_build_file_using_src_file ' . l:sourceFilePath)
    if v:shell_error != 0
        throw "Could not find '" . fnamemodify(l:sourceFilePath, ':t') . "' in any BUILD files"
    endif
    return l:buildFile[0]
endfunction

" Open the Bazel BUILD file containing a target using the given source file
function! OpenBazelBuildDef()
    let l:currentFile = expand('%:p')
    let l:filename = expand('%:t')
    try
        let buildFile = GetBazelBuildDef(l:currentFile)
    catch /.*/
        echo v:exception
        return
    endtry
    execute 'edit' buildFile
    call search(l:filename)
endfunction

" In a split, open the Bazel BUILD file containing a target using the given source file
function! OpenSplitBazelBuildDef()
    let l:currentFile = expand('%:p')
    let l:filename = expand('%:t')
    try
        let buildFile = GetBazelBuildDef(l:currentFile)
    catch /.*/
        echo v:exception
        return
    endtry
    split
    execute 'edit' buildFile
    call search(l:filename)
endfunction

" Get the bazel-bin (previous output path) of the current workspace
function! GetBazelBinPath()
    let l:workspaceDir = systemlist('source ~/.dotfiles/shell/path_utils.sh; traverse_up ' . getcwd() . ' WORKSPACE')
    if v:shell_error != 0
        throw "Could not find Bazel WORKSPACE from cwd: " . getcwd()
    endif
    return l:workspaceDir[0] . '/bazel-bin'
endfunction

" Get the bazel-out path of the current workspace
function! GetBazelOutPath()
    let l:workspaceDir = systemlist('source ~/.dotfiles/shell/path_utils.sh; traverse_up ' . getcwd() . ' WORKSPACE')
    if v:shell_error != 0
        throw "Could not find Bazel WORKSPACE from cwd: " . getcwd()
    endif
    return l:workspaceDir[0] . '/bazel-out'
endfunction
