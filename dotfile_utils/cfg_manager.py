from os.path import abspath
from configparser import ConfigParser


DOTFILES_LIST_PATH = abspath('dotfiles.cfg')
print(DOTFILES_LIST_PATH)
parser = ConfigParser()
parser.read(DOTFILES_LIST_PATH)

def get_paths():
    path_list = parser['Dotfiles']['paths']
    path_list = path_list.split(',')
    path_list = [item.strip() for item in path_list]
    return path_list


def get_backup_path():
    path = parser['Backup']['backup_location']
    if path[-1] != '/':
        path += '/'
    return path

