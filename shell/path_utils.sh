#!/bin/bash

# Traverse a given path upward until a certain file/directory is found
# Arg 1: Start path
# Arg 2: File/directory name to search for before exiting
# Stdout: Path containing the given file/directory name
# Returns: 0 if the file/directory was found, 1 otherwise
traverse_up() {
    local current_path="$(readlink --canonicalize "$1")"
    local search_name="$2"
    find "$current_path" -maxdepth 1 -name "$search_name" \
    | grep -q "$search_name"
    if (( $? == 0 )); then
        echo "$current_path"
        return 0
    elif [[ "$current_path" = "/" ]]; then
        return 1
    else
        traverse_up "$(dirname $current_path)" "$search_name"
        return $?
    fi
}

# Escape path separators. Takes a path via stdin and echos the escaped path
escape_path_sep() {
    sed "s|/|\\\/|g"
}
