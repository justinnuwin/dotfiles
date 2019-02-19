#! /bin/python3

import os
from shutil import copy2

from .utility_functions import copy_parents
from .cfg_manager import get_paths, get_backup_path


def friendly_path(path):
    if path[0] == '.':
        return path[1:]


def copy_to_repo(repo_path=".."):
    if repo_path[-1] != '/':
        repo_path += '/'
    home = os.path.expanduser('~') + '/'
    for path in get_paths():
        copy_parents(home + path, repo_path + friendly_path(path))


def copy_to_local(repo_path=".."):
    if repo_path[-1] != '/':
        repo_path += '/'
    home = os.path.expanduser('~') + '/'
    for path in get_paths():
        copy_parents(repo_path + friendly_path(path), home + path)


def backup_dotfiles():
    backup_path = get_backup_path()
    copy_to_repo(backup_path)


def restore_backup():
    backup_path = get_backup_path()
    copy_to_local(backup_path)

