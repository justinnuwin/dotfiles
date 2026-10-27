#!/bin/sh
# Export JNSHELL_STARSHIP_TIME for the starship prompt clock. Under zsh an idle
# prompt shows %H:%M, redrawn at each minute boundary, and an accepted prompt
# is redrawn with %H:%M:%S to record when its command started. Under bash the
# clock is the time the prompt was drawn.

if jnshell_is_zsh; then
  zmodload zsh/datetime || return
  autoload -Uz add-zsh-hook add-zle-hook-widget

  # Also re-arms the redraw timer for the next minute boundary.
  function __jnshell_starship_time_idle() {
    strftime -s JNSHELL_STARSHIP_TIME '%H:%M' "$EPOCHSECONDS"
    export JNSHELL_STARSHIP_TIME
    TMOUT=$(( 60 - EPOCHSECONDS % 60 ))
  }

  function __jnshell_starship_time_started() {
    strftime -s JNSHELL_STARSHIP_TIME '%H:%M:%S' "$EPOCHSECONDS"
    export JNSHELL_STARSHIP_TIME
    zle .reset-prompt
  }

  # A non-zero return would abort the line being edited.
  function TRAPALRM() {
    __jnshell_starship_time_idle
    if [[ "$WIDGET" != *complete* && "$WIDGET" != fzf-* ]] && zle; then
      zle .reset-prompt
    fi
    return 0
  }

  add-zsh-hook precmd __jnshell_starship_time_idle
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
