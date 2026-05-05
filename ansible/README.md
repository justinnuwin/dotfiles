# Ansible Dotfiles Deployment

This directory contains Ansible playbooks and roles for deploying dotfiles to target machines. The setup uses Docker-based testing with Molecule to ensure reliable deployments.

## Overview

The Ansible configuration manages the deployment of shell configurations (bash, zsh), terminal multiplexer settings (tmux), terminal emulator configurations (Ghostty, iTerm2), and ensures the dotfiles repository is properly cloned and initialized with all required git submodules.

## Structure

```
ansible/
├── first_time_setup.yml      # Main playbook for deploying dotfiles
├── local_first_time_setup.sh # Script for local deployment
├── requirements.txt          # Python dependencies
├── tasks/
│   └── ensure_repository.yml # Common task: ensure dotfiles repo exists
├── molecule/
│   └── default/             # Molecule test configuration
│       ├── molecule.yml      # Molecule configuration
│       ├── prepare.yml       # Container bootstrap (packages for the test image)
│       ├── converge.yml      # Imports first_time_setup.yml
│       └── verify.yml        # Verification tests
├── templates/
│   └── localshell.j2        # Shared Jinja2 template for ~/.localshell managed block
└── roles/
    ├── toolchain/           # Opt-in language toolchains (rust, nvm)
    ├── starship/            # Starship prompt (pre-built binary, no rust dep)
    ├── dotfiles_facts/      # Owns /etc/ansible/facts.d/dotfiles.fact
    ├── bash/                # Bash shell configuration + localshell render
    ├── zsh/                 # Zsh shell configuration + localshell render
    ├── tmux/                # Tmux configuration
    └── terminals/           # Terminal emulator configuration (Ghostty, iTerm2)
```

## Playbooks

### first_time_setup.yml

The main playbook that orchestrates the deployment of all dotfiles. It:

1. **Pre-tasks**: Ensures the dotfiles repository is available (cloned if needed, submodules initialized)
2. **Roles**: Applies the following roles in order:
   - `toolchain` - Opt-in language toolchain installs (rust, nvm); sets in-process facts
   - `starship` - Starship prompt install (pre-built binary, no rust dep); sets in-process fact
   - `dotfiles_facts` - Hydrates and persists `/etc/ansible/facts.d/dotfiles.fact` for next-run gating
   - `bash` - Sets up bash configuration + renders ansible-managed block in `~/.localshell`
   - `zsh` - Sets up zsh configuration + renders ansible-managed block in `~/.localshell`
   - `tmux` - Sets up tmux configuration
   - `terminals` - Sets up terminal emulator configuration (Ghostty, iTerm2)

**Usage:**
```bash
# --ask-become-pass: dotfiles_facts writes /etc/ansible/facts.d/ which needs sudo.
ansible-playbook first_time_setup.yml \
  --connection=local --inventory 127.0.0.1, --limit 127.0.0.1 \
  --ask-become-pass
```

Or use the convenience script:
```bash
./local_first_time_setup.sh
```

> **Sudo**: This is the project's first sudo escalation — `dotfiles_facts` writes the consolidated fact file to `/etc/ansible/facts.d/dotfiles.fact`, which is root-owned. Use `--ask-become-pass`, or set `ansible_become_pass` per-host, or rely on NOPASSWD sudo.

## Toolchains and prompt

Three roles — `toolchain`, `starship`, and `dotfiles_facts` — work together to install language toolchains + the starship prompt and surface that state to the rest of the play:

- **`toolchain`** is per-tool opt-in. Set `install_rust=true` and/or `install_nvm=true` (in `~/.localshell`-equivalent host vars, group_vars, or `-e`) to install. Pinned versions (`rust_version`, `nvm_version`) live in `roles/toolchain/defaults/main.yml`.
- **`starship`** has no opt-in flag; being listed in the playbook means it installs on first run. Pinned `starship_version` lives in `roles/starship/defaults/main.yml`. The role uses the official `https://starship.rs/install.sh` installer (pre-built binary into `~/.local/bin` — no toolchain dependency).
- **`dotfiles_facts`** writes the consolidated `/etc/ansible/facts.d/dotfiles.fact`. It also hydrates the `*_installed` vars used by the bash/zsh roles to render `~/.localshell`.

`bash` and `zsh` then render an ansible-managed block of `JNSHELL_*` flags inside `~/.localshell` based on which tools were installed. The block is wrapped in `# BEGIN/END ANSIBLE MANAGED BLOCK (dotfiles)` markers — content above and below is user-owned and preserved across runs.

### Force re-install on a specific host

```bash
ansible-playbook first_time_setup.yml --limit <host> \
  -e install_rust=true -e toolchain_run_first_time_setup=true
ansible-playbook first_time_setup.yml --limit <host> -e starship_run_first_time_setup=true
```

### Bumping a pinned version

Edit the relevant `defaults/main.yml`, then rerun the play with the matching `_run_first_time_setup` flag.

### Per-tool gating semantics

See `roles/toolchain/README.md` and `roles/starship/README.md` for the full decision matrices.

---

## Roles

### bash

Deploys bash shell configuration by creating a symlink from `~/.dotfiles/shell/bashrc` to `~/.bashrc`.

**Tasks:**
- Symlinks `shell/bashrc` to `~/.bashrc`

**Tag:** `setup-bash`

### zsh

Deploys zsh shell configuration by creating a symlink from `~/.dotfiles/shell/zshrc` to `~/.zshrc`.

**Tasks:**
- Symlinks `shell/zshrc` to `~/.zshrc`

**Tag:** `setup-zsh`

### tmux

Deploys tmux configuration and sets up the tmux plugin manager (TPM).

**Tasks:**
- Installs tmux plugin manager (TPM) if not already installed
- Symlinks `tmux/tmux.conf` to `~/.tmux.conf`
- Displays instructions for installing tmux plugins

**Tag:** `setup-tmux`

### terminals

Deploys terminal emulator configuration. Cross-platform: the Ghostty
config is installed on both macOS and Linux; the iTerm2 profile is
referenced via a manual-import message on macOS only.

**Tasks:**
- Symlinks `terminals/config.ghostty` to the platform-specific Ghostty
  config path:
  - macOS: `~/Library/Application Support/com.mitchellh.ghostty/config`
  - Linux: `~/.config/ghostty/config`
- On macOS, displays a message pointing to
  `terminals/iterm_profile.json` so it can be imported manually via
  iTerm → Preferences → Profiles → Other Actions → Import.

**Tag:** `setup-terminals`

## Common Tasks

### ensure_repository.yml

A reusable task file that ensures the dotfiles repository is available on the target machine. This task:

1. Checks if the dotfiles repository exists at `~/.dotfiles`
2. Clones the repository from `https://github.com/justinnuwin/dotfiles.git` if it doesn't exist (override with `dotfiles_git_repo` for SSH or another remote)
3. Initializes and updates all git submodules (required for zsh themes and plugins)

This task is automatically run as a pre-task in the main playbook, ensuring the repository is available before any roles attempt to create symlinks.

## Testing with Molecule

Molecule provides containerized testing for Ansible playbooks, allowing you to test deployments in isolated Docker containers before applying them to real systems.

### Prerequisites

- Docker installed and running
- Python 3.11+
- Virtual environment (created automatically by test script)

### Running Tests

1. Activate the virtual environment:
```bash
source venv/bin/activate
```

2. Install dependencies (if not already installed):
```bash
pip install -r requirements.txt
```

3. Run Molecule commands:

```bash
# Create the test container
molecule create

# Bootstrap packages in the container (test harness)
molecule prepare

# Run the playbook in the container
molecule converge

# Run verification tests
molecule verify

# Destroy the container
molecule destroy

# Run all steps (create, prepare, converge, verify, destroy)
molecule test
```

### Test Configuration

The Molecule configuration (`molecule/default/molecule.yml`) uses:
- **Driver:** Docker
- **Platform:** Ubuntu 22.04 (image from ECR Public; see `molecule.yml`)
- **Provisioner:** Ansible (`prepare.yml` bootstraps the container, then `converge.yml` imports `first_time_setup.yml`)
- **Verifier:** Ansible (runs `verify.yml` to check deployment)

### Verification Tests

The verification playbook (`molecule/default/verify.yml`) checks:
- `.bashrc` symlink exists and is valid
- `.zshrc` symlink exists and is valid
- `.tmux.conf` symlink exists and is valid
- `~/.config/ghostty/config` symlink exists and is valid
- Dotfiles repository exists at `~/.dotfiles`
- Dotfiles repository is a valid git repository
- `/etc/ansible/facts.d/dotfiles.fact` exists (consolidated fact file)
- `~/.localshell` contains the ansible-managed block markers
- `~/.local/bin/starship` exists (starship is in the bootstrap roles list, so it always installs)

## Dependencies

All dependencies are listed in `requirements.txt`:

- `ansible==12.2.0` - Ansible package
- `ansible-core==2.19.4` - Core Ansible functionality
- `molecule>=6.0.0` - Testing framework
- `molecule-plugins[docker]>=2.0.0` - Docker driver for Molecule
- `docker>=7.0.0` - Docker Python SDK

Install dependencies:
```bash
pip install -r requirements.txt
```

## Deployment

### Local Deployment

For deploying to the local machine (where Ansible is running):

```bash
./local_first_time_setup.sh
```

This script:
1. Sets up/activates the virtual environment
2. Installs dependencies
3. Runs the playbook against localhost

### Remote Deployment

For deploying to remote machines, create an inventory file and run:

```bash
ansible-playbook -i inventory.yml first_time_setup.yml
```

## Tagged Execution

You can run specific roles using tags:

```bash
# Run only bash setup
ansible-playbook first_time_setup.yml --tags setup-bash

# Run only zsh setup
ansible-playbook first_time_setup.yml --tags setup-zsh

# Run only tmux setup
ansible-playbook first_time_setup.yml --tags setup-tmux

# Run only terminals setup
ansible-playbook first_time_setup.yml --tags setup-terminals

# Run only the toolchain installs (e.g. with -e install_rust=true)
ansible-playbook first_time_setup.yml --tags setup-toolchain -e install_rust=true

# Run only the starship install
ansible-playbook first_time_setup.yml --tags setup-starship

# Run only the fact-file refresh
ansible-playbook first_time_setup.yml --tags setup-dotfiles_facts

# Run multiple tags (note: setup-dotfiles_facts must precede setup-bash/zsh
# if you want the localshell block to reflect newly-installed tools)
ansible-playbook first_time_setup.yml --tags setup-bash,setup-zsh
```

## Notes

- The default clone URL is HTTPS in `tasks/ensure_repository.yml`; set `dotfiles_git_repo` to use SSH or another remote
- All roles assume the dotfiles repository is located at `~/.dotfiles`
- The zsh role requires git submodules to be initialized (handled automatically by `ensure_repository.yml`)
- The tmux role installs TPM but requires manual plugin installation after deployment (use `<prefix> + I` in tmux)
