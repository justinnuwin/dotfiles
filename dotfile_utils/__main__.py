#! /bin/python3

import sys

from .copy_to_from_repo import copy_to_repo, copy_to_local, backup_dotfiles, restore_backup

def usage():
    print("Usage: python3 -m dotfile_utils -[h] <backup | restore | sync [local | repo] | help>")
    print("Dotfile Utils for managing dotfiles.")
    print("Examples:")
    print("\tpython3 -mdotfile_utils backup \t# Make a backup of registered dotfiles to backup location")
    print("\tpython3 -mdotfile_utils restore\t# Restore dotfiles in backup location to local filesystem")
    print("\tpython3 -mdotfile_utils sync local\t# Copy repo dotfiles to the local filesystem")
    print("\tpython3 -mdotfile_utils sync repo \t# Copy dotfiles from the local filesystem to the repo")

if __name__ == "__main__":
    if "--help" in sys.argv or "-h" in sys.argv or "help" in sys.argv:
        usage()
    elif "backup" in sys.argv:
        backup_dotfiles()
    elif "restore" in sys.argv:
        restore_backup()
    elif "sync" in sys.argv:
        if "local" in sys.argv:
            copy_to_local()
        elif "repo" in sys.argv:
            copy_to_repo()
        else:
            usage()
    else:
        usage()

