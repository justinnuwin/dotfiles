#!/bin/sh
# Claude Code status line — gruvbox palette.
#   line 1: path  session-name  PR#(link)  vim-mode
#   line 2: model  +lines/-lines  ctx-bar%  $cost  wall|api  cache-r/w
#   line 3: 5h/7d rate-limit bars + reset times (only when rate_limits present)

input=$(cat)

# --- extract JSON fields ---
cwd=$(echo "$input"         | jq -r '.cwd // .workspace.current_dir // ""')
session=$(echo "$input"     | jq -r '.session_name // ""')
vim_mode=$(echo "$input"    | jq -r '.vim.mode // ""')
model=$(echo "$input"       | jq -r '.model.display_name // ""')
used_pct=$(echo "$input"    | jq -r '.context_window.used_percentage // 0')
total_cost=$(echo "$input"  | jq -r '.cost.total_cost_usd // 0')
wall_ms=$(echo "$input"     | jq -r '.cost.total_duration_ms // 0')
api_ms=$(echo "$input"      | jq -r '.cost.total_api_duration_ms // 0')
lines_add=$(echo "$input"   | jq -r '.cost.total_lines_added // 0')
lines_rm=$(echo "$input"    | jq -r '.cost.total_lines_removed // 0')
cache_r=$(echo "$input"     | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_w=$(echo "$input"     | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
rl_5h_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage // empty')
rl_5h_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
rl_7d_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage // empty')
rl_7d_reset=$(echo "$input" | jq -r '.rate_limits.seven_day.resets_at // empty')

# --- truncate cwd to 4 path components ---
dir_short=$(echo "$cwd" | awk -F/ '{
  n=NF; start=n-3;
  if (start < 1) start=1;
  out="";
  for (i=start; i<=n; i++) {
    if (out != "") out = out "/" $i; else out = $i;
  }
  if ($1 == "" && start == 1) out = "/" out;
  print out
}')

# --- PR lookup (cached per cwd, refreshed every 60s) ---
pr_num=""; pr_url=""
if [ -n "$cwd" ] && command -v gh >/dev/null 2>&1; then
  cache_key=$(echo "$cwd" | tr '/' '-')
  pr_cache="/tmp/claude-pr${cache_key}"
  now=$(date +%s)
  if [ -f "$pr_cache" ]; then
    cache_age=$(( now - $(stat -c %Y "$pr_cache" 2>/dev/null || echo 0) ))
  else
    cache_age=9999
  fi
  if [ "$cache_age" -gt 60 ]; then
    gh -C "$cwd" pr view --json number,url 2>/dev/null > "$pr_cache" || printf '' > "$pr_cache"
  fi
  pr_json=$(cat "$pr_cache" 2>/dev/null)
  if [ -n "$pr_json" ]; then
    pr_num=$(echo "$pr_json" | jq -r '.number // empty')
    pr_url=$(echo "$pr_json"  | jq -r '.url // empty')
  fi
fi

# --- helpers ---
ms_to_str() {
  s=$(($1 / 1000))
  h=$((s / 3600)); m=$(( (s % 3600) / 60 )); sec=$((s % 60))
  if   [ "$h" -gt 0 ]; then printf '%dh%dm' "$h" "$m"
  elif [ "$m" -gt 0 ]; then printf '%dm%ds' "$m" "$sec"
  else                      printf '%ds' "$sec"
  fi
}

fmt_k() {
  echo "$1" | awk '{ if ($1>=1000) printf "%.1fk",$1/1000; else printf "%d",$1 }'
}

# --- 10-char shade bar from a 0-100 percentage (uses BAR_FULL/BAR_EMPTY) ---
make_bar() {
  f=$(( $1 * 10 / 100 ))
  [ "$f" -gt 10 ] && f=10
  [ "$f" -lt 0 ] && f=0
  out=""; j=0
  while [ "$j" -lt 10 ]; do
    if [ "$j" -lt "$f" ]; then out="${out}${BAR_FULL}"
    else                       out="${out}${BAR_EMPTY}"
    fi
    j=$((j + 1))
  done
  printf '%s' "$out"
}

# --- gruvbox green/amber/red for a 0-100 percentage (literal escape text) ---
bar_color() {
  if   [ "$1" -ge 80 ]; then printf '%s' '\033[31m'
  elif [ "$1" -ge 50 ]; then printf '%s' '\033[33m'
  else                       printf '%s' '\033[32m'
  fi
}

# --- unix epoch seconds -> local human-readable date-time (GNU date) ---
fmt_reset() {
  [ -z "$1" ] && return
  date -d "@$1" '+%a %b %-d %H:%M' 2>/dev/null
}

# --- OSC 8 hyperlink: ESC]8;;URL ST text ESC]8;; ST  (ST = ESC\) ---
make_link() {
  printf '\033]8;;%s\033\\%s\033]8;;\033\\' "$1" "$2"
}

# --- unicode glyphs (hex-escaped so source stays ASCII) ---
BAR_FULL=$(printf '\xe2\x96\x93')   # U+2593 DARK SHADE
BAR_EMPTY=$(printf '\xe2\x96\x91')  # U+2591 LIGHT SHADE
ARR_D=$(printf '\xe2\x86\x93')      # U+2193 DOWN ARROW
ARR_U=$(printf '\xe2\x86\x91')      # U+2191 UP ARROW
BULL=$(printf '\xc2\xb7')           # U+00B7 MIDDLE DOT
CLK=$(printf '\xe2\x86\xbb')         # U+21BB CLOCKWISE ARROW (reset)

# --- context bar (10 chars) ---
ctx_int=$(printf '%.0f' "$used_pct")
bar=$(make_bar "$ctx_int")

# --- ANSI colors (gruvbox-inspired) ---
RESET='\033[0m'
DIM='\033[2m'
Y='\033[1;33m'   # bold yellow  — path
W='\033[37m'     # white        — session name
G='\033[32m'     # green        — lines added, vim insert
R='\033[31m'     # red          — lines removed
M='\033[35m'     # magenta      — model
A='\033[33m'     # amber/yellow — cost, pr link
C='\033[36m'     # cyan         — time, vim normal
B='\033[34m'     # blue         — cache

CTX_C=$(bar_color "$ctx_int")

# --- formatted values ---
cost_str=$(printf '$%.2f' "$total_cost")
wall_str=$(ms_to_str "$wall_ms")
api_str=$(ms_to_str "$api_ms")
cache_r_str=$(fmt_k "$cache_r")
cache_w_str=$(fmt_k "$cache_w")

# --- vim mode indicator ---
seg_vim=""
if [ -n "$vim_mode" ]; then
  case "$vim_mode" in
    NORMAL)  seg_vim="${C}NRM${RESET}" ;;
    INSERT)  seg_vim="${G}INS${RESET}" ;;
    REPLACE) seg_vim="${R}REP${RESET}" ;;
    VISUAL*) seg_vim="${A}VIS${RESET}" ;;
    *)       seg_vim="${DIM}$(printf '%s' "$vim_mode" | cut -c1-3)${RESET}" ;;
  esac
fi

# --- PR segment (OSC 8 link) ---
seg_pr=""
if [ -n "$pr_num" ] && [ -n "$pr_url" ]; then
  pr_link=$(make_link "$pr_url" "#${pr_num}")
  seg_pr="${A}${pr_link}${RESET}"
fi

# --- separator ---
D=" ${DIM}${BULL}${RESET} "

# --- line 1: workspace context ---
line1="${Y}${dir_short}${RESET}"
[ -n "$session" ]  && line1="${line1}${D}${W}${session}${RESET}"
[ -n "$seg_pr" ]   && line1="${line1}${D}${seg_pr}"
[ -n "$seg_vim" ]  && line1="${line1}${D}${seg_vim}"

# --- line 2: session stats ---
seg_model="${M}${model}${RESET}"
seg_lines="${G}+${lines_add}${RESET} ${R}-${lines_rm}${RESET}"
seg_ctx="${CTX_C}${bar}${RESET} ${DIM}${ctx_int}%${RESET}"
seg_cost="${A}${cost_str}${RESET}"
seg_time="${C}${wall_str}${DIM}|${RESET}${C}${api_str}${RESET}"
seg_cache="${B}${cache_r_str}${ARR_D} ${cache_w_str}${ARR_U}${RESET}"

line2="${seg_model}${D}${seg_lines}${D}${seg_ctx}${D}${seg_cost}${D}${seg_time}${D}${seg_cache}"

# --- line 3: rate-limit windows (only present for subscription auth) ---
rl_window() {
  label=$1; pct=$2; reset=$3
  [ -z "$pct" ] && return
  pint=$(printf '%.0f' "$pct")
  rcol=$(bar_color "$pint")
  rbar=$(make_bar "$pint")
  rtime=$(fmt_reset "$reset")
  seg="${DIM}${label}${RESET} ${rcol}${rbar}${RESET} ${DIM}${pint}%${RESET}"
  [ -n "$rtime" ] && seg="${seg} ${DIM}${CLK} ${rtime}${RESET}"
  printf '%s' "$seg"
}

line3=""
seg_5h=$(rl_window "5h" "$rl_5h_pct" "$rl_5h_reset")
seg_7d=$(rl_window "7d" "$rl_7d_pct" "$rl_7d_reset")
[ -n "$seg_5h" ] && line3="$seg_5h"
[ -n "$seg_7d" ] && { [ -n "$line3" ] && line3="${line3}${D}${seg_7d}" || line3="$seg_7d"; }

if [ -n "$line3" ]; then
  printf "%b\n%b\n%b\n" "$line1" "$line2" "$line3"
else
  printf "%b\n%b\n" "$line1" "$line2"
fi
