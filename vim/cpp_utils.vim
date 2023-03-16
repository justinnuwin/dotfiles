" Gets the source file (of a given header file) or header file (of a given
" source file) 
" filePath: Full path to a source/header file
" Throws if no C/C++ extension is found
" Throws if replacing the C/C++ extension with the source/header alternative
"   results in a non-existing file
function! GetCppHeaderSourceFile(filePath)
    let l:sourceExts = ['c', 'C', 'cpp', 'CPP', 'cxx', 'CXX', 'cc', 'CC']
    let l:headerExts = ['h', 'H', 'hpp', 'HPP', 'hxx', 'HXX', 'hh', 'HH']

    let l:filePath = expand(a:filePath)

    let l:filename = fnamemodify(l:filePath, ':t')
    let l:filenameParts = split(l:filename, '\.')

    " Get the part of the filename that contains the C/C++ extension
    " (l:partExtIdx) and the list of source/header alternative extensions
    " (l:otherExtsList)
    let l:partExtIdx = 0
    for l:part in l:filenameParts
        let l:idx = index(l:sourceExts, l:part)
        if (l:idx > -1)
            let l:otherExtsList = l:headerExts
            break
        endif
        let l:idx = index(l:headerExts, l:part)
        if (l:idx > -1)
            let l:otherExtsList = l:sourceExts
            break
        endif
        let l:partExtIdx += 1
    endfor
    if (l:idx == -1)
        throw l:filename . ' is not a C/C++ file.'
    endif

    " Replace the extension in the filename with the extensions from the other
    " extensions list and see if the file exists
    let l:dirname = fnamemodify(l:filePath, ':h')
    for l:ext in l:otherExtsList
        let l:filenameParts[l:partExtIdx] = l:ext
        let l:otherFilePath = l:dirname . '/' . join(l:filenameParts, '.')
        if filereadable(l:otherFilePath)
            return l:otherFilePath
        endif
    endfor
    throw 'Could not find header/source alternative for ' . l:filename
endfunction

" Open the alternative header/source file for the current C/C++ file
function! OpenCppHeaderSourceFile()
    let l:currentFile = expand('%:p')
    try
        let l:otherFile = GetCppHeaderSourceFile(l:currentFile)
    catch /.*/
        echo v:exception
        return
    endtry
    " TODO: Go to the currently highlighted C++ decl/def
    " let currentWord = expand("<cword>")
    execute 'edit' l:otherFile 
endfunction

" In a split, open the alternative header/source file for the current C/C++ file
function! OpenSplitCppHeaderSourceFile()
    let l:currentFile = expand('%:p')
    try
        let l:otherFile = GetCppHeaderSourceFile(l:currentFile)
    catch /.*/
        echo v:exception
        return
    endtry
    split
    execute 'edit' l:otherFile 
endfunction
