#!/bin/bash

dotfile="$HOME/.dotfiles"
source "$dotfile/shell/path_utils.sh"

get_bazel_root() {
    traverse_up "$(pwd)" WORKSPACE
}
alias broot=get_bazel_root

# Get Bazel targets quickly. This searches for explicitly named targets in BUILD
# files as opposed to using Bazel query which is glacially slow
# Arg 1: Optional path to search along. If '//', search from the workspace root.
#   If empty, will recursively search from the cwd. Can take relative paths and
#   Bazel style paths (without support for '...')
get_bazel_targets() {
    local path_to_search="$1"

    local bazel_root
    bazel_root="$(get_bazel_root)"
    if (( $? > 0 )); then
        return 1;
    fi

    if [[ -z "$path_to_search" ]]; then
        path_to_search="$(pwd)"
    elif [[ "$path_to_search" = "//"  ]]; then
        path_to_search="$(get_bazel_root)"
    elif [[ "${path_to_search:0:2}" = "//" ]]; then
        path_to_search="$(get_bazel_root)/${path_to_search:2}"
    else
        path_to_search="$(readlink --canonicalize "$path_to_search")"
    fi
    local targets="$(find "$path_to_search" -name BUILD \
                     | xargs grep -E "name[[:space:]]*=[[:space:]]*['\"](.+)['\"]" \
                     | sed "s/\/BUILD//" \
                     | sed "s/[[:space:]]*name\s*=\s*//" \
                     | tr --delete ",'\"")"
    local subpackages="$(echo "$targets" \
                         | sed "s|:.*|/...|" \
                         | uniq)"
    local alls="$(echo "$targets" \
                  | sed "s/:.*/:all/" \
                  | uniq)"
    echo "$targets\n$subpackages\n$alls" \
    | sed "s|$(get_bazel_root | escape_path_sep)/|//|" \
    | sort
}

# Get the BUILD file declaring a target with the given source file
# Arg 1: The source file which is used in a bazel target
get_build_file_using_src_file() {
    local src_file="$(basename $1)"
    local current_path="$(dirname $(readlink --canonicalize $1))"
    local build_file
    local max_depth=50
    for (( i=0; i < $max_depth; i++ )); do
        current_path="$(traverse_up "$current_path" BUILD)"
        if (( $?  > 0 )); then
            break
        fi
        grep -q "\"$src_file\"" "$current_path/BUILD"
        if (( $? == 0 )); then
            echo "$current_path/BUILD"
            return 0
        else
            current_path="$(dirname $current_path)"
        fi
    done
    return 1   
}
