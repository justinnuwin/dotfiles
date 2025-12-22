function initialize_powerlevel10k() {

  if [[ ! -f $1 ]]
  then
    echo "Powerlevel10k zsh theme not found: $1"
    exit 1
  fi

  # Souece the Powerlevel10k theme
  source $1

  # Set the font mode
  POWERLEVEL9K_MODE=nerdfont-complete

  # Set the icon padding
  POWERLEVEL9K_ICON_PADDING=none

  # Set the prompt elements
  function my_custom_p10k_precmd() {
    width=$(stty size 2>/dev/null | awk '{print $2}')
    if [[ "$width" -le 180 ]]; then
      # Set variables for two-line prompt in Git repos
      POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs newline prompt_char)
    else
      # Set variables for one-line prompt otherwise
      POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs prompt_char)
    fi
  }
  precmd_functions+=(my_custom_p10k_precmd)
  POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status virtualenv command_execution_time background_jobs time)

  # Prompt settings
  POWERLEVEL9K_PROMPT_CHAR_BACKGROUND=253
  POWERLEVEL9K_PROMPT_CHAR_FOREGROUND=39
  POWERLEVEL9K_PROMPT_CHAR_VIINS_CONTENT_EXPANSION='❯'
  POWERLEVEL9K_PROMPT_CHAR_VICMD_CONTENT_EXPANSION='❮'
  POWERLEVEL9K_PROMPT_CHAR_VIVIS_CONTENT_EXPANSION='V'
  POWERLEVEL9K_PROMPT_CHAR_VIOWR_CONTENT_EXPANSION='▶'
  POWERLEVEL9K_TRANSIENT_PROMPT=never
  POWERLEVEL9K_INSTANT_PROMPT=verbose
  ZLE_RPROMPT_INDENT=0    # Fix extra space after right prompt

  # Context setting
  POWERLEVEL9K_CONTEXT_REMOTE_TEMPLATE=''
  POWERLEVEL9K_CONTEXT_TEMPLATE=''
  POWERLEVEL9K_CONTEXT_BACKGROUND=236
  POWERLEVEL9K_CONTEXT_FOREGROUND=3

  # Previous status setting
  POWERLEVEL9K_STATUS_OK_BACKGROUND=236
  POWERLEVEL9K_STATUS_ERROR_BACKGROUND=1
  POWERLEVEL9K_SHORTEN_DIR_LENGTH=4

  # Folder icon settings
  POWERLEVEL9K_HOME_ICON=''
  POWERLEVEL9K_HOME_SUB_ICON=''
  POWERLEVEL9K_FOLDER_ICON=''
  POWERLEVEL9K_ETC_ICON=''

  # VCS Settings
  POWERLEVEL9K_VCS_BOOKMARK_ICON=''
  POWERLEVEL9K_VCS_BRANCH_ICON=''
  POWERLEVEL9K_VCS_COMMIT_ICON='' # Default: ''
  POWERLEVEL9K_VCS_GIT_BITBUCKET_ICON='' # Default: ''
  POWERLEVEL9K_VCS_GIT_GITHUB_ICON='' # Default: ''
  POWERLEVEL9K_VCS_GIT_GITLAB_ICON='' # Default: ''
  POWERLEVEL9K_VCS_GIT_ICON='' # Default: ''
  POWERLEVEL9K_VCS_HG_ICON='' # Default: ''
  POWERLEVEL9K_VCS_WIP_ICON=' '
  POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON='  '
  POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON='  '
  POWERLEVEL9K_VCS_LOADING_ICON=''
  POWERLEVEL9K_VCS_REMOTE_BRANCH_ICON=''
  POWERLEVEL9K_VCS_STAGED_ICON='  '
  POWERLEVEL9K_VCS_UNTRACKED_ICON='  '
  POWERLEVEL9K_VCS_UNSTAGED_ICON='  '
  POWERLEVEL9K_VCS_CONFLICT_ICON=' 󱡝 '
  POWERLEVEL9K_VCS_STASH_ICON='  '
  POWERLEVEL9K_VCS_SVN_ICON=''
  POWERLEVEL9K_VCS_TAG_ICON='  '

  # Formatter for Git status.
  function my_git_formatter() {
    emulate -L zsh

    if [[ "$P9K_CONTENT" == "loading" ]]; then
      # If P9K_CONTENT is not empty, use it if it's loading. Otherwise it's from vcs_info
      typeset -g my_git_format=$P9K_CONTENT
      return
    fi

    # Styling for different parts of Git status.
    local       meta='%7F' # white foreground
    local      clean='%0F' # black foreground
    local   modified='%0F' # black foreground
    local  untracked='%0F' # black foreground
    local conflicted='%1F' # red foreground

    local res

    if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
      local branch=${(V)VCS_STATUS_LOCAL_BRANCH}
      res+="${clean}${(g::)POWERLEVEL9K_VCS_BRANCH_ICON}${branch//\%/%%}"
    fi

    if [[ -n $VCS_STATUS_TAG
          # Show tag only if not on a branch.
          && -z $VCS_STATUS_LOCAL_BRANCH
        ]]; then
      local tag=${(V)VCS_STATUS_TAG}
      res+="${meta}#${clean}${POWERLEVEL9K_VCS_TAG_ICON}${tag//\%/%%}"
    fi

    # Display the current Git commit if there is no branch and no tag.
    [[ -z $VCS_STATUS_LOCAL_BRANCH && -z $VCS_STATUS_TAG ]] &&
      res+="${meta}@${clean}${VCS_STATUS_COMMIT[1,8]}"

    # Show tracking branch name if it differs from local branch.
    if [[ -n ${VCS_STATUS_REMOTE_BRANCH:#$VCS_STATUS_LOCAL_BRANCH} ]]; then
      # Original: Show the remote (upstream tracking) branch as local:remote
      # res+="${meta}:${clean}${(V)VCS_STATUS_REMOTE_BRANCH//\%/%%}"
      res+=" ${clean}${POWERLEVEL9K_VCS_REMOTE_BRANCH_ICON}"
    fi

    # Display "wip" if the latest commit's summary contains "wip" or "WIP".
    if [[ $VCS_STATUS_COMMIT_SUMMARY == (|*[^[:alnum:]])(wip|WIP)(|[^[:alnum:]]*) ]]; then
      res+="${modified}${POWERLEVEL9K_VCS_WIP_ICON}"
    fi

    if (( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )); then
      # ⇣42 if behind the remote.
      (( VCS_STATUS_COMMITS_BEHIND )) && res+="${clean}${POWERLEVEL9K_VCS_INCOMING_CHANGES_ICON}${VCS_STATUS_COMMITS_BEHIND}"
      # ⇡42 if ahead of the remote; no leading space if also behind the remote: ⇣42⇡42.
      (( VCS_STATUS_COMMITS_AHEAD && !VCS_STATUS_COMMITS_BEHIND )) && res+=" "
      (( VCS_STATUS_COMMITS_AHEAD  )) && res+="${clean}${POWERLEVEL9K_VCS_OUTGOING_CHANGES_ICON}${VCS_STATUS_COMMITS_AHEAD}"
    elif [[ -n $VCS_STATUS_REMOTE_BRANCH ]]; then
      # Tip: Uncomment the next line to display '=' if up to date with the remote.
      # res+=" ${clean}="
    fi

    # ⇠42 if behind the push remote.
    (( VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+="${clean}⇠${VCS_STATUS_PUSH_COMMITS_BEHIND}"
    (( VCS_STATUS_PUSH_COMMITS_AHEAD && !VCS_STATUS_PUSH_COMMITS_BEHIND )) && res+=" "
    # ⇢42 if ahead of the push remote; no leading space if also behind: ⇠42⇢42.
    (( VCS_STATUS_PUSH_COMMITS_AHEAD  )) && res+="${clean}⇢${VCS_STATUS_PUSH_COMMITS_AHEAD}"
    # *42 if have stashes.
    (( VCS_STATUS_STASHES        )) && res+="${clean}${POWERLEVEL9K_VCS_STASH_ICON}${VCS_STATUS_STASHES}"
    # 'merge' if the repo is in an unusual state.
    [[ -n $VCS_STATUS_ACTION     ]] && res+=" ${conflicted}${VCS_STATUS_ACTION}"
    # ~42 if have merge conflicts.
    (( VCS_STATUS_NUM_CONFLICTED )) && res+=" ${conflicted}${POWERLEVEL9K_VCS_CONFLICT_ICON}${VCS_STATUS_NUM_CONFLICTED}"
    # +42 if have staged changes.
    (( VCS_STATUS_NUM_STAGED     )) && res+="${modified}${POWERLEVEL9K_VCS_STAGED_ICON}${VCS_STATUS_NUM_STAGED}"
    # !42 if have unstaged changes.
    (( VCS_STATUS_NUM_UNSTAGED   )) && res+="${modified}${POWERLEVEL9K_VCS_UNSTAGED_ICON}${VCS_STATUS_NUM_UNSTAGED}"
    # ?42 if have untracked files
    (( VCS_STATUS_NUM_UNTRACKED  )) && res+="${untracked}${(g::)POWERLEVEL9K_VCS_UNTRACKED_ICON}${VCS_STATUS_NUM_UNTRACKED}"
    # "─" if the number of unstaged files is unknown. This can happen due to
    # POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY (see below) being set to a non-negative number lower
    # than the number of files in the Git index, or due to bash.showDirtyState being set to false
    # in the repository config. The number of staged and untracked files may also be unknown
    # in this case.
    (( VCS_STATUS_HAS_UNSTAGED == -1 )) && res+=" ${modified}─"

    typeset -g my_git_format=$res
  }
  functions -M my_git_formatter 2>/dev/null
  POWERLEVEL9K_VCS_CONTENT_EXPANSION='${$((my_git_formatter()))+${my_git_format}}'

  # Python venv Settings
  POWERLEVEL9K_VIRTUALENV_VISUAL_IDENTIFIER_EXPANSION=''
  POWERLEVEL9K_VIRTUALENV_SHOW_PYTHON_VERSION=false

  # Time
  POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION=''

  # Connector for multi-line prompts
  POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX='%242F╭─'
  POWERLEVEL9K_MULTILINE_NEWLINE_PROMPT_PREFIX='%242F├─'
  POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX='%242F╰─'
  # Filler between the left and right prompts
  POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_CHAR='•'
  POWERLEVEL9K_MULTILINE_FIRST_PROMPT_GAP_FOREGROUND=235
}
