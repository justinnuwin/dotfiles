#            _              
#    _______| |__  _ __ ___ 
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__ 
# (_)___|___/_| |_|_|  \___|
#                           


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


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

# Powerlevel10k theme
source $HOME/.dotfiles/zsh_plugins/powerlevel10k/powerlevel10k.zsh-theme
POWERLEVEL9K_MODE=nerdfont-complete
POWERLEVEL9K_ICON_PADDING=moderate
POWERLEVEL9K_LEGACY_ICON_SPACING=true
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(ssh dir vcs prompt_char)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv command_execution_time background_jobs time)
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
POWERLEVEL9K_VCS_STAGED_ICON=''
POWERLEVEL9K_VCS_STASH_ICON=' '
POWERLEVEL9K_VCS_SVN_ICON=''
POWERLEVEL9K_VCS_TAG_ICON=''
POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=''
POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false
POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=''
POWERLEVEL9K_TRANSIENT_PROMPT=same-dir
POWERLEVEL9K_INSTANT_PROMPT=verbose
ZLE_RPROMPT_INDENT=0    # Fix extra space after right prompt

# Zsh Autocomplete
zstyle ':autocomplete:*' min-input 3
zstyle ':autocomplete:*' min-delay -1   # Only show the autocomplete menu when prompted (with tab). Use Ctrl-Space to open the big menu
zstyle ':autocomplete:*' list-lines 8
zstyle ':autocomplete:*' widget-style menu-complete
source $HOME/.dotfiles/zsh_plugins/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# A little bit of Linus madness every day
linus_rants_path=$HOME/.dotfiles/zsh_plugins/linus-rants/linus-rants.plugin.zsh
if [ -d $linus_rants_path ]
then
    source $linus_rants_path
fi
