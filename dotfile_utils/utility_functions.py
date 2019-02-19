import os
from shutil import copy2

def get_dirs_from_path(path):
    if '/' in path:
        dirs_path = ""
        tokens = path.split('/')
        for token in tokens[:-1]:
            dirs_path += token + '/'
        return dirs_path 
    else:
        return path


def makedirs(dirs):
    try:
        os.makedirs(dirs)
    except FileExistsError:
        pass
    else:
        print("mkdir " + dirs)


def copy_parents(src, dst):
    """ Python implementation of GNU cp with the --parents flag """
    src_dirs = get_dirs_from_path(src)
    makedirs(src_dirs)
    dst_dirs = get_dirs_from_path(dst)
    makedirs(dst_dirs)
    print(src + " -> " + dst)
    copy2(src, dst)

