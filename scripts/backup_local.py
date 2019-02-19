#! /bin/python3

import os
from shutil import copy2

from copy_to_repo import copy_to_repo
from dotfile_cfg import get_backup_path


def backup_dotfiles():
    backup_path = get_backup_path()
    copy_to_repo(backup_path)


if __name__ == '__main__':
    backup_dotfiles()

