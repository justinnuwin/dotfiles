vim9script

const findOpts = ' -mindepth 1 -type d -printf "%P\n"'

export def GetDirectoriesFromCwdCmd(): string
    return "find " .. getcwd() .. findOpts
enddef


export def GetDirectoriesFromGRootCmd(): string
    # Note the returned path is relative to the repo root
    const gitRoot = trim(system('git rev-parse --show-toplevel'))
    if v:shell_error != 0
        throw "Could not get git repo root: " .. getcwd()
    endif
    return "find " .. gitRoot .. findOpts
enddef
