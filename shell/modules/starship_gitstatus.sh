#!/bin/sh
# Run gitstatusd and export raw VCS state as GSD_* env vars for starship
# custom modules to consume. Starship handles all rendering. Queries are
# asynchronous under zsh and blocking under bash. Shared by both
# bash and zsh; the underlying gitstatus.plugin.{sh,zsh} bindings differ (zsh
# supports named daemon instances, bash only a single one), so gitstatusd_instance
# is empty under bash and passed as an argument under zsh.
# The original source for this is the following gist:
# https://gist.github.com/junosuarez/400a66bcb90d8a9238303fb072a1ae98

export GSD_READY=1

gitstatus_dir="$dotfiles/shell/gitstatus"
if [[ ! -x "$gitstatus_dir/usrbin/gitstatusd" ]]; then
  jnshell_warn "gitstatusd not built; run: $gitstatus_dir/build -w (submodule not initialized? git -C $dotfiles submodule update --init --recursive)"
  return 0
fi

if jnshell_is_zsh; then
  # shellcheck disable=SC1091  # dynamically resolved path
  source "$gitstatus_dir/gitstatus.plugin.zsh" || return
  gitstatusd_instance='GSD'
elif jnshell_is_bash; then
  # shellcheck disable=SC1091  # dynamically resolved path
  source "$gitstatus_dir/gitstatus.plugin.sh" || return
  gitstatusd_instance=
else
  jnshell_warn "starship_gitstatus.sh only supports bash and zsh; skipping"
  return 0
fi

function __gsd_export() {
  unset GSD_STALE GSD_LOADING GSD_NOT_REPO GSD_ON GSD_REPO GSD_REMOTE_URL GSD_ACTION
  unset GSD_AHEAD GSD_BEHIND
  unset GSD_STAGED GSD_UNSTAGED GSD_UNTRACKED GSD_CONFLICTED GSD_DELETED GSD_STASHES
  unset GSD_STALE_ON GSD_STALE_ACTION GSD_STALE_AHEAD GSD_STALE_BEHIND
  unset GSD_STALE_STAGED GSD_STALE_UNSTAGED GSD_STALE_UNTRACKED GSD_STALE_CONFLICTED GSD_STALE_DELETED GSD_STALE_STASHES
  export GSD_READY=1

  [[ "$VCS_STATUS_RESULT" == ok-* ]] || {
    export GSD_NOT_REPO=1
    return 0
  }

  if [[ -n "$VCS_STATUS_LOCAL_BRANCH" ]]; then
    export GSD_ON="$VCS_STATUS_LOCAL_BRANCH"
  else
    export GSD_ON="${VCS_STATUS_COMMIT:0:7}"
  fi

  local repo
  repo=$(basename "$VCS_STATUS_REMOTE_URL" | sed 's|\.git$||')
  export GSD_REPO="${repo:-$(basename "$VCS_STATUS_WORKDIR")}"

  export GSD_REMOTE_URL="$VCS_STATUS_REMOTE_URL"
  [[ -n "$VCS_STATUS_ACTION" ]] && export GSD_ACTION="$VCS_STATUS_ACTION"

  [[ "$VCS_STATUS_COMMITS_AHEAD"     -gt 0 ]] && export GSD_AHEAD="$VCS_STATUS_COMMITS_AHEAD"
  [[ "$VCS_STATUS_COMMITS_BEHIND"    -gt 0 ]] && export GSD_BEHIND="$VCS_STATUS_COMMITS_BEHIND"
  [[ "$VCS_STATUS_NUM_STAGED"        -gt 0 ]] && export GSD_STAGED="$VCS_STATUS_NUM_STAGED"
  [[ "$VCS_STATUS_NUM_UNSTAGED"      -gt 0 ]] && export GSD_UNSTAGED="$VCS_STATUS_NUM_UNSTAGED"
  [[ "$VCS_STATUS_NUM_UNTRACKED"     -gt 0 ]] && export GSD_UNTRACKED="$VCS_STATUS_NUM_UNTRACKED"
  [[ "$VCS_STATUS_NUM_CONFLICTED"    -gt 0 ]] && export GSD_CONFLICTED="$VCS_STATUS_NUM_CONFLICTED"
  [[ "$VCS_STATUS_NUM_UNSTAGED_DELETED" -gt 0 ]] && export GSD_DELETED="$VCS_STATUS_NUM_UNSTAGED_DELETED"
  [[ "$VCS_STATUS_STASHES"           -gt 0 ]] && export GSD_STASHES="$VCS_STATUS_STASHES"

  __gsd_maybe_refresh
}

function __gsd_maybe_refresh() {
  local last_refreshed now elapsed
  last_refreshed=$(git config --local --get gsd.refresh 2>/dev/null || true)
  now=$(date +%s)
  elapsed=$(( now - ${last_refreshed:-0} ))
  if [[ $elapsed -gt 2 ]]; then
    git config --local --replace-all gsd.refresh "$now"
    (&>/dev/null nohup grep -q .biz /etc/resolv.conf && git remote | grep -q origin && git fetch origin "$MAIN_BRANCH" --quiet &)
  fi
}

# Moves each rendered GSD_* value to GSD_STALE_* so starship draws the git
# section grayed out. zsh only.
function __gsd_mark_stale() {
  local name val
  for name in ON ACTION AHEAD BEHIND STAGED UNSTAGED UNTRACKED CONFLICTED DELETED STASHES; do
    # 'eval' for indirect expansion because bash uses ${!var} and zsh uses ${(P)var}.
    eval "val=\${GSD_$name:-}"
    [[ -n "$val" ]] || continue
    export "GSD_STALE_$name=$val"
    unset "GSD_$name"
  done
  unset GSD_READY
  export GSD_STALE=1
}

# Grays out the git section until the pending query completes. zsh only.
function __gsd_mark_loading() {
  __gsd_mark_stale
  export GSD_LOADING=1
}

function __gsd_on_async_result() {
  __gsd_export
  zle && zle .reset-prompt
}

function gitstatusd_up() {
  # shellcheck disable=SC2086  # intentional word-split: empty under bash, 'GSD' under zsh
  gitstatus_stop $gitstatusd_instance && gitstatus_start -s -1 -u -1 -c -1 -d -1 $gitstatusd_instance
}

# Runs from TRAPALRM while zle is polling gitstatusd's response fd. Calling
# gitstatus_stop here closes that fd under zle, which then spins on POLLNVAL,
# so kill the daemon and let gitstatus's zle -F handler stop it on EOF.
function __gsd_idle_stop() {
  [[ "$GITSTATUS_DAEMON_PID_GSD" -gt 0 ]] && kill -- -"$GITSTATUS_DAEMON_PID_GSD" 2>/dev/null
  __gsd_mark_stale
  unset GSD_LOADING
}

# On zsh, restarts gitstatusd if it was stopped for idleness, waits briefly
# for it, and otherwise shows the previous values as stale until
# __gsd_on_async_result redraws the prompt.
function __gitstatus_prompt_update_impl() {
  if jnshell_is_zsh; then
    gitstatus_check GSD || gitstatusd_up || return 1
    gitstatus_query -t 0.01 -c __gsd_on_async_result GSD || return 1
    if [[ "$VCS_STATUS_RESULT" == 'tout' ]]; then
      __gsd_mark_loading
      return 0
    fi
  else
    gitstatus_query || return 1
  fi
  __gsd_export
}

gitstatusd_up

if jnshell_is_zsh; then
  typeset -ga jnshell_idle_functions
  jnshell_idle_functions+=(__gsd_idle_stop)
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd __gitstatus_prompt_update_impl
elif jnshell_is_bash; then
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}__gitstatus_prompt_update_impl"
else
  jnshell_warn "starship_gitstatus.sh only supports bash and zsh; skipping"
  return 0
fi
