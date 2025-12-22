#!/bin/bash

# A little bit of Linus madness every day
linus_rants_path="$dotfiles/shell/zsh_plugins/linus-rants/linus-rants.plugin.zsh"
if [[ -f "$linus_rants_path" ]] && \
   $(which shuf > /dev/null) && $(which cowsay > /dev/null) && $(which lolcat > /dev/null); then  # Check dependencies since the plugin doesn't
        source $linus_rants_path
fi
