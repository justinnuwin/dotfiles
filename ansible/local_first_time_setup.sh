#!/bin/bash
# Interactive bootstrap: prompts for opt-in toolchain installs, then runs the
# first_time_setup.yml playbook against localhost.
#
# Usage:
#   ./local_first_time_setup.sh                       # interactive
#   ./local_first_time_setup.sh --no-prompt           # skip prompts (use defaults)
#   ./local_first_time_setup.sh -- -e install_rust=true   # forward args to ansible-playbook
#
# Defaults (applied in both interactive and --no-prompt mode):
#   install_rust:   no
#   install_nvm:    YES
#   starship/toolchain force-reinstall: no
#
# Anything after a literal `--` is forwarded verbatim to ansible-playbook AFTER
# the prompt-derived -e flags, so explicit overrides win.

set -eo pipefail

script_path="$(readlink -f "${BASH_SOURCE[0]}")"
cd "$(dirname "$script_path")"

# --- Arg parsing ------------------------------------------------------------
no_prompt=false
forward_args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-prompt)
      no_prompt=true
      shift
      ;;
    -h|--help)
      sed -n '2,17p' "$script_path" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --)
      shift
      forward_args+=("$@")
      break
      ;;
    *)
      forward_args+=("$1")
      shift
      ;;
  esac
done

# Stdin not a tty (CI, piped input) -> skip prompts.
if [[ ! -t 0 ]]; then
  no_prompt=true
fi

# --- Venv setup -------------------------------------------------------------
if [[ ! -d venv ]]; then
  python -m venv venv
  # shellcheck source=/dev/null
  source venv/bin/activate
  pip install -r requirements.txt
else
  # shellcheck source=/dev/null
  source venv/bin/activate
fi

# --- Interactive prompts ----------------------------------------------------
prompt_yes_no() {
  # prompt_yes_no "Question?" [Y|N]    (default arg is the default answer)
  local question="$1"
  local default="${2:-N}"
  local hint reply
  if [[ "$default" == "Y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  read -r -p "$question $hint " reply
  if [[ -z "$reply" ]]; then
    [[ "$default" == "Y" ]]
  else
    [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
  fi
}

# Defaults applied in both interactive and --no-prompt modes. Edit these to
# change what happens when a user just presses Enter / runs --no-prompt.
default_install_rust=N
default_install_nvm=Y
default_starship_force=N
default_toolchain_force=N

# Resolved answers — start at defaults, then prompts may override.
install_rust="$default_install_rust"
install_nvm="$default_install_nvm"
starship_force="$default_starship_force"
toolchain_force="$default_toolchain_force"

if [[ "$no_prompt" != "true" ]]; then
  echo
  echo "Configure optional installs (press Enter to accept defaults):"
  prompt_yes_no "  Install rust toolchain (rustup, pinned to default version)?" "$default_install_rust" \
    && install_rust=Y || install_rust=N
  prompt_yes_no "  Install nvm (Node Version Manager)?" "$default_install_nvm" \
    && install_nvm=Y || install_nvm=N
  prompt_yes_no "  Force-reinstall starship (e.g. to upgrade)?" "$default_starship_force" \
    && starship_force=Y || starship_force=N
  prompt_yes_no "  Force-reinstall toolchains (rust/nvm if already present)?" "$default_toolchain_force" \
    && toolchain_force=Y || toolchain_force=N
  echo
fi

extra_vars=()
[[ "$install_rust"    == "Y" ]] && extra_vars+=("-e" "install_rust=true")
[[ "$install_nvm"     == "Y" ]] && extra_vars+=("-e" "install_nvm=true")
[[ "$starship_force"  == "Y" ]] && extra_vars+=("-e" "starship_run_first_time_setup=true")
[[ "$toolchain_force" == "Y" ]] && extra_vars+=("-e" "toolchain_run_first_time_setup=true")
true   # ensure success exit-status before the playbook invocation

# --- Run --------------------------------------------------------------------
# --ask-become-pass: dotfiles_facts writes to /etc/ansible/facts.d/ which
# requires sudo. Skip with `-e ansible_become_pass=...` (after `--`) if you
# have NOPASSWD sudo configured.
ansible-playbook first_time_setup.yml \
  --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 \
  --ask-become-pass \
  "${extra_vars[@]+"${extra_vars[@]}"}" \
  "${forward_args[@]+"${forward_args[@]}"}"
