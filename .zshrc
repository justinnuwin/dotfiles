#            _              
#    _______| |__  _ __ ___ 
#   |_  / __| '_ \| '__/ __|
#  _ / /\__ \ | | | | | (__ 
# (_)___|___/_| |_|_|  \___|
#                           

export LANG="en_US.UTF-8"
source ~/.justinShell

# Lines configured by zsh-newuser-install
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=50000
setopt appendhistory extendedglob notify
unsetopt autocd beep nomatch
# bindkey -v
# End of lines configured by zsh-newuser-install
# The following lines were added by compinstall
zstyle :compinstall filename '/home/justin/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

source ~/.config/powerlevel9k/powerlevel9k.zsh-theme
POWERLEVEL9K_MODE='awesome-patched'
