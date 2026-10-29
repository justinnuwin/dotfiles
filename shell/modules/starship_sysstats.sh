#!/bin/sh
# Export JNSHELL_STARSHIP_SYSSTATS (CPU, memory, and disk usage percentages,
# with the tmux2k cpu/ram/storage icons) for the starship prompt. CPU is the busy share of time since the previous refresh, memory is
# MemTotal minus MemAvailable, and disk is the usage of the filesystem holding
# $HOME. Disk is refreshed at most once a minute because it runs df.
#
# Under zsh an idle prompt refreshes every 5 seconds via starship_clock.sh's
# tick functions, and once the prompt goes idle the last values are grayed out
# as JNSHELL_STARSHIP_SYSSTATS_STALE until the next refresh. Under
# bash the stats are refreshed each time the prompt is drawn.

typeset -gi __jnshell_sysstats_cpu_total=0
typeset -gi __jnshell_sysstats_cpu_idle=0
typeset -g __jnshell_sysstats_disk=
typeset -gi __jnshell_sysstats_disk_at=-60

function __jnshell_sysstats_refresh() {
  local _cpu user nice system idle iowait irq softirq steal _rest
  read -r _cpu user nice system idle iowait irq softirq steal _rest </proc/stat
  local -i total=$(( user + nice + system + idle + iowait + irq + softirq + steal ))
  local -i idle_all=$(( idle + iowait ))
  local -i d_total=$(( total - __jnshell_sysstats_cpu_total ))
  local -i d_idle=$(( idle_all - __jnshell_sysstats_cpu_idle ))
  __jnshell_sysstats_cpu_total=$total
  __jnshell_sysstats_cpu_idle=$idle_all
  local -i cpu=0
  if (( d_total > 0 )); then
    cpu=$(( 100 * (d_total - d_idle) / d_total ))
  fi

  local key value _unit
  local -i mem_total=0 mem_avail=0
  while read -r key value _unit; do
    case "$key" in
      MemTotal:) mem_total=$value ;;
      MemAvailable:)
        mem_avail=$value
        break
        ;;
    esac
  done </proc/meminfo
  local -i mem=0
  if (( mem_total > 0 )); then
    mem=$(( 100 * (mem_total - mem_avail) / mem_total ))
  fi

  if (( SECONDS - __jnshell_sysstats_disk_at >= 60 )); then
    local _fs _size _used _avail pct _mount
    { read -r _fs; read -r _fs _size _used _avail pct _mount; } < <(df -P "$HOME" 2>/dev/null)
    __jnshell_sysstats_disk=$pct
    __jnshell_sysstats_disk_at=$SECONDS
  fi

  unset JNSHELL_STARSHIP_SYSSTATS_STALE
  export JNSHELL_STARSHIP_SYSSTATS=" ${cpu}  ${mem} 󰋊 ${__jnshell_sysstats_disk%\%}"
}

function __jnshell_sysstats_stale() {
  export JNSHELL_STARSHIP_SYSSTATS_STALE="$JNSHELL_STARSHIP_SYSSTATS"
  unset JNSHELL_STARSHIP_SYSSTATS
}

# The stats segment draws its own transition into the clock block.
export JNSHELL_STARSHIP_CLOCK_OPEN=

if jnshell_is_zsh; then
  jnshell_tick_functions+=(__jnshell_sysstats_refresh)
  jnshell_idle_functions+=(__jnshell_sysstats_stale)
  if (( jnshell_tick_seconds == 0 || jnshell_tick_seconds > 5 )); then
    jnshell_tick_seconds=5
  fi
elif jnshell_is_bash; then
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}__jnshell_sysstats_refresh"
else
  jnshell_warn "starship_sysstats.sh only supports bash and zsh; skipping"
fi
