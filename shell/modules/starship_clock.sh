#!/bin/sh
# Export JNSHELL_STARSHIP_TIME for the starship prompt clock. Under zsh an idle
# prompt shows %H:%M, redrawn at each minute boundary, and an accepted prompt
# is redrawn with %H:%M:%S to record when its command started. Under bash the
# clock is the time the prompt was drawn.
#
# Under zsh, once a prompt has sat idle for 5 minutes each function named in
# jnshell_idle_functions runs, the prompt is redrawn once with the clock
# grayed out as JNSHELL_STARSHIP_TIME_STALE, and the minute redraws stop until
# the next prompt is drawn.
#
# Under zsh each function named in jnshell_tick_functions runs whenever the
# clock is refreshed, before the redraw. Setting jnshell_tick_seconds redraws
# an idle prompt at least that often.

if jnshell_is_zsh; then
  zmodload zsh/datetime || return
  autoload -Uz add-zsh-hook add-zle-hook-widget
  typeset -ga jnshell_idle_functions
  typeset -ga jnshell_tick_functions
  typeset -gi jnshell_tick_seconds
  typeset -gi __jnshell_prompt_drawn_at

  # Also runs the tick functions and re-arms the redraw timer for the next
  # minute boundary or tick, whichever comes first.
  function __jnshell_starship_time_idle() {
    unset JNSHELL_STARSHIP_TIME_STALE
    strftime -s JNSHELL_STARSHIP_TIME '%H:%M' "$EPOCHSECONDS"
    export JNSHELL_STARSHIP_TIME
    local fn
    for fn in "${jnshell_tick_functions[@]}"; do
      "$fn"
    done
    TMOUT=$(( 60 - EPOCHSECONDS % 60 ))
    if (( jnshell_tick_seconds > 0 && jnshell_tick_seconds < TMOUT )); then
      TMOUT=$jnshell_tick_seconds
    fi
  }

  function __jnshell_starship_time_started() {
    unset JNSHELL_STARSHIP_TIME_STALE
    strftime -s JNSHELL_STARSHIP_TIME '%H:%M:%S' "$EPOCHSECONDS"
    export JNSHELL_STARSHIP_TIME
    zle .reset-prompt
  }

  function __jnshell_starship_time_prompt() {
    __jnshell_prompt_drawn_at=$EPOCHSECONDS
    __jnshell_starship_time_idle
  }

  function __jnshell_starship_time_stale() {
    export JNSHELL_STARSHIP_TIME_STALE="$JNSHELL_STARSHIP_TIME"
    unset JNSHELL_STARSHIP_TIME
    TMOUT=0
  }

  # A non-zero return would abort the line being edited.
  function TRAPALRM() {
    if (( EPOCHSECONDS - __jnshell_prompt_drawn_at >= 300 )); then
      local fn
      for fn in "${jnshell_idle_functions[@]}"; do
        "$fn"
      done
      __jnshell_starship_time_stale
    else
      __jnshell_starship_time_idle
    fi
    if [[ "$WIDGET" != *complete* && "$WIDGET" != fzf-* ]] && zle; then
      zle .reset-prompt
    fi
    return 0
  }

  add-zsh-hook precmd __jnshell_starship_time_prompt
  add-zle-hook-widget line-finish __jnshell_starship_time_started
elif jnshell_is_bash; then
  function __jnshell_starship_time_prompt() {
    printf -v JNSHELL_STARSHIP_TIME '%(%H:%M:%S)T' -1
    export JNSHELL_STARSHIP_TIME
  }

  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}__jnshell_starship_time_prompt"
else
  jnshell_warn "starship_clock.sh only supports bash and zsh; skipping"
fi
