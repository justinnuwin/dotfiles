#! /bin/python3

import os
from shutil import copy2

from dotfile_cfg import get_paths


def get_dirs_from_path(path):
    if '/' in path:
        dirs_path = ""
        tokens = path.split('/')
        for token in tokens[:-1]:
            dirs_path += token + '/'
        return dirs_path 
    else:
        return path


def friendly_paths(path):
    if path[0] == '.':
        return path[1:]


def copy_to_repo(repo_path=".."):
    if repo_path[-1] != '/':
        repo_path += '/'
    home = os.path.expanduser('~') + '/'
    for path in get_paths():
        if '/' in path:
            dirs = repo_path + friendly_paths(get_dirs_from_path(path))
            try:
                os.makedirs(dirs)
            except FileExistsError:
                pass
            else:
                print("mkdir " + repo_path + friendly_paths(get_dirs_from_path(path)))
        print("~/" + path + " -> " + repo_path + friendly_paths(path))
        copy2(home + path, repo_path + friendly_paths(path))


if __name__ == "__main__":
    copy_to_repo()
