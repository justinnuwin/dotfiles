#!/bin/zsh
# Run gitstatusd (from p10k) and export raw VCS state as GSD_* env vars
# for starship custom modules to consume. Starship handles all rendering.
# The original source for this is the following gist:
# https://gist.github.com/junosuarez/400a66bcb90d8a9238303fb072a1ae98

autoload -Uz add-zsh-hook
source "$dotfiles/shell/zsh_plugins/powerlevel10k/gitstatus/gitstatus.plugin.zsh" || return

gitstatusd_instance='GSD'

function __gitstatus_prompt_update_impl() {
  unset GSD_NOT_REPO GSD_ON GSD_REPO GSD_REMOTE_URL GSD_ACTION
  unset GSD_AHEAD GSD_BEHIND
  unset GSD_STAGED GSD_UNSTAGED GSD_UNTRACKED GSD_CONFLICTED GSD_DELETED GSD_STASHES

  gitstatus_query $gitstatusd_instance || return 1
  [[ $VCS_STATUS_RESULT == 'ok-sync' ]] || {
    export GSD_NOT_REPO=1
    return 0
  }

  if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
    export GSD_ON=$VCS_STATUS_LOCAL_BRANCH
  else
    export GSD_ON=${VCS_STATUS_COMMIT[1,7]}
  fi

  local repo
  repo=$(basename "$VCS_STATUS_REMOTE_URL" | sed 's|\.git$||')
  export GSD_REPO=${repo:-$(basename "$VCS_STATUS_WORKDIR")}

  export GSD_REMOTE_URL=$VCS_STATUS_REMOTE_URL
  [[ -n $VCS_STATUS_ACTION ]] && export GSD_ACTION=$VCS_STATUS_ACTION

  [[ $VCS_STATUS_COMMITS_AHEAD     -gt 0 ]] && export GSD_AHEAD=$VCS_STATUS_COMMITS_AHEAD
  [[ $VCS_STATUS_COMMITS_BEHIND    -gt 0 ]] && export GSD_BEHIND=$VCS_STATUS_COMMITS_BEHIND
  [[ $VCS_STATUS_NUM_STAGED        -gt 0 ]] && export GSD_STAGED=$VCS_STATUS_NUM_STAGED
  [[ $VCS_STATUS_NUM_UNSTAGED      -gt 0 ]] && export GSD_UNSTAGED=$VCS_STATUS_NUM_UNSTAGED
  [[ $VCS_STATUS_NUM_UNTRACKED     -gt 0 ]] && export GSD_UNTRACKED=$VCS_STATUS_NUM_UNTRACKED
  [[ $VCS_STATUS_NUM_CONFLICTED    -gt 0 ]] && export GSD_CONFLICTED=$VCS_STATUS_NUM_CONFLICTED
  [[ $VCS_STATUS_NUM_UNSTAGED_DELETED -gt 0 ]] && export GSD_DELETED=$VCS_STATUS_NUM_UNSTAGED_DELETED
  [[ $VCS_STATUS_STASHES           -gt 0 ]] && export GSD_STASHES=$VCS_STATUS_STASHES

  __gsd_maybe_refresh
}

function __gsd_maybe_refresh() {
  local last_refreshed now elapsed
  last_refreshed=$(git config --local --get gsd.refresh 2>/dev/null || true)
  now=$(date +%s)
  elapsed=$(( now - ${last_refreshed:-0} ))
  if [[ $elapsed -gt 2 ]]; then
    git config --local --replace-all gsd.refresh $now
    (&>/dev/null nohup grep -q .biz /etc/resolv.conf && git remote | grep -q origin && git fetch origin $MAIN_BRANCH --quiet &)
  fi
}

function gitstatusd_up() {
  gitstatus_stop "$gitstatusd_instance" && gitstatus_start -s -1 -u -1 -c -1 -d -1 "$gitstatusd_instance"
}

gitstatusd_up
add-zsh-hook precmd __gitstatus_prompt_update_impl
