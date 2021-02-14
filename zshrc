#            _              
#    _______| |__  _ __ ___ 
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__ 
# (_)___|___/_| |_|_|  \___|
#                           

export LANG="en_US.UTF-8"
export TERM="xterm-256color"
source ~/.dotfiles/justinShell
export GPG_TTY=$(tty)

# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=50000
setopt appendhistory extendedglob notify
unsetopt autocd beep nomatch
bindkey -v
bindkey '^R' history-incremental-search-backward
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/justin/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

source $HOME/.dotfiles/powerlevel10k/powerlevel10k.zsh-theme
POWERLEVEL9K_MODE='nerdfont-complete'
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(ssh virtualenv dir vcs prompt_char)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status root_indicator background_jobs history time)
POWERLEVEL9K_SHORTEN_DIR_LENGTH=4
POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=7
POWERLEVEL9K_PROMPT_CHAR_OK_VIINS_FOREGROUND=39
POWERLEVEL9K_PROMPT_CHAR_OK_VICMD_FOREGROUND=39
POWERLEVEL9K_PROMPT_CHAR_OK_VIVIS_FOREGROUND=39
POWERLEVEL9K_PROMPT_CHAR_OK_VIOWR_FOREGROUND=39
POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_ETC_ICON=''
POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=''
POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=''
ZLE_RPROMPT_INDENT=0    # Fix extra space after right prompt
POWERLEVEL9K_LEGACY_ICON_SPACING=true
POWERLEVEL9K_VCS_BOOKMARK_ICON=''
# POWERLEVEL9K_VCS_BRANCH_ICON=''
POWERLEVEL9K_VCS_BRANCH_ICON=''
POWERLEVEL9K_VCS_COMMIT_ICON=''
POWERLEVEL9K_VCS_GIT_BITBUCKET_ICON=''
POWERLEVEL9K_VCS_GIT_GITHUB_ICON=''
POWERLEVEL9K_VCS_GIT_GITLAB_ICON=''
POWERLEVEL9K_VCS_GIT_ICON=''
POWERLEVEL9K_VCS_HG_ICON=''
POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON=' '
POWERLEVEL9K_VCS_LOADING_ICON=''
POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON=' '
POWERLEVEL9K_VCS_REMOTE_BRANCH_ICON=''
POWERLEVEL9K_VCS_STAGED_ICON=' '
POWERLEVEL9K_VCS_STASH_ICON=''
POWERLEVEL9K_VCS_SVN_ICON=''
POWERLEVEL9K_VCS_TAG_ICON=''

