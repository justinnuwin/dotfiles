# Project overview

This document is a quick onboarding reference for the repository — useful
for both humans and LLM agents starting a fresh session. Read this first
before diving into the code.

## What this is

Personal `*nix` dotfiles, deployed via Ansible. The repo contains the
config files themselves and a small Ansible setup that symlinks them
into the right places on a target machine. Primary target is macOS and Linux
based systems.

## Top-level layout

| Path | Contents |
|---|---|
| `ansible/` | Playbooks, roles, molecule scenarios, Python deps |
| `shell/` | `bashrc`, `zshrc`, plugins (managed as git submodules) |
| `tmux/` | `tmux.conf` |
| `vim/` | vim configuration (the ansible role is a stub) |
| `terminals/` | Ghostty (`config.ghostty`) and iTerm2 (`iterm_profile.json`) configs |
| `config/` | Misc tool configs (e.g. wtfutil) |
| `githooks/` | Git hooks |
| `docs/` | This file plus `docs/plans/` for in-flight / future design docs |

Top-level config files (`gitconfig`, `Xresources`, `xprofile`,
`xbindkeysrc`, `gdbinit`, `pylintrc`) are referenced directly or by other
roles.

## Deployment model

- Entry point: `ansible/first_time_setup.yml`. Run it locally via
  `ansible/local_first_time_setup.sh` (handles venv + invocation).
- Pre-task `ansible/tasks/ensure_repository.yml` clones this repo to
  `~/.dotfiles` (if missing) and initializes submodules.
- Roles run in order: `bash` → `zsh` → `tmux` → `terminals`.
- Each role uses `ansible.builtin.file` with `state: link, force: true`
  to symlink files from `~/.dotfiles/...` into `$HOME` or other
  platform-appropriate locations.

## Where to look first

- `ansible/README.md` — detailed ansible / molecule reference (roles,
  tags, test commands, dependencies).
- `ansible/first_time_setup.yml` — the playbook entry point.
- `ansible/roles/<role>/tasks/main.yml` — what each role does.
- `ansible/molecule/default/verify.yml` — what gets asserted in CI-style
  tests.
- `docs/plans/` — proposed work that hasn't shipped yet.
