# fzf ** completion lists the immediate directory first, then streams in
# everything below it.
if (( $+commands[fd] )); then
    # Arg 1: Directory to search
    # Remaining args: Extra fd options
    fzf_fd_shallow_first() {
        local root="$1"
        shift
        fd --hidden --follow --exclude .git --exclude node_modules --max-depth 1 "$@" . "$root"
        fd --hidden --follow --exclude .git --exclude node_modules --min-depth 2 "$@" . "$root"
    }
    _fzf_compgen_path() { fzf_fd_shallow_first "$1" }
    _fzf_compgen_dir() { fzf_fd_shallow_first "$1" --type d }
fi

# ssh host completion, with and without **, lists ~/.ssh/config hosts in file
# order, then the destinations of ssh commands in history, most recent first.
__fzf_list_hosts() {
    local -aU hosts
    local -a words
    local line
    local -i i
    for line in ${(f)"$(command cat ~/.ssh/config ~/.ssh/config.d/*(N) 2>/dev/null)"}; do
        words=(${=line%%\#*})
        [[ ${(L)words[1]} == host ]] && hosts+=(${words[2,-1]:#*[*?%!]*})
    done
    for line in ${(f)"$(fc -lnr 1)"}; do
        words=(${(z)line})
        [[ $words[1] == ssh ]] || continue
        for (( i = 2; i <= $#words; i++ )); do
            case $words[i] in
                # Options that take the next word as their argument
                -[BbcDEeFIiJLlmOoPpQRSWw]) (( i++ )) ;;
                -*) ;;
                *)
                    hosts+=(${${${(Q)words[i]}#ssh://}#*@})
                    break
                    ;;
            esac
        done
    done
    print -rl -- $hosts
}
zstyle -e ':completion:*:(ssh|scp|sftp):*' hosts 'reply=(${(f)"$(__fzf_list_hosts)"})'
# Local accounts are offered as login names otherwise.
zstyle ':completion:*:(ssh|scp|sftp):*' users
zstyle ':completion:*:(ssh|scp|sftp):*' sort false
