# Ansible Dotfiles Deployment

This directory contains Ansible playbooks and roles for deploying dotfiles to target machines. The setup uses Docker-based testing with Molecule to ensure reliable deployments.

## Overview

The Ansible configuration manages the deployment of shell configurations (bash, zsh), terminal multiplexer settings (tmux), and ensures the dotfiles repository is properly cloned and initialized with all required git submodules.

## Structure

```
ansible/
├── first_time_setup.yml      # Main playbook for deploying dotfiles
├── local_first_time_setup.sh # Script for local deployment
├── run_tests.sh              # Script to run Molecule tests
├── requirements.txt          # Python dependencies
├── tasks/
│   └── ensure_repository.yml # Common task: ensure dotfiles repo exists
├── molecule/
│   └── default/             # Molecule test configuration
│       ├── molecule.yml      # Molecule configuration
│       ├── prepare.yml       # Container bootstrap (packages for the test image)
│       ├── converge.yml      # Imports first_time_setup.yml
│       └── verify.yml        # Verification tests
└── roles/
    ├── bash/                 # Bash shell configuration
    ├── zsh/                  # Zsh shell configuration
    └── tmux/                 # Tmux configuration
```

## Playbooks

### first_time_setup.yml

The main playbook that orchestrates the deployment of all dotfiles. It:

1. **Pre-tasks**: Ensures the dotfiles repository is available (cloned if needed, submodules initialized)
2. **Roles**: Applies the following roles in order:
   - `bash` - Sets up bash configuration
   - `zsh` - Sets up zsh configuration
   - `tmux` - Sets up tmux configuration

**Usage:**
```bash
ansible-playbook first_time_setup.yml --connection=local --inventory 127.0.0.1, --limit 127.0.0.1
```

Or use the convenience script:
```bash
./local_first_time_setup.sh
```

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

**Quick test (recommended):**
```bash
./run_tests.sh
```

This script will:
1. Create/activate the virtual environment
2. Install all dependencies from `requirements.txt`
3. Run the full Molecule test suite

**Manual testing:**

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
- Dotfiles repository exists at `~/.dotfiles`
- Dotfiles repository is a valid git repository

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

# Run multiple tags
ansible-playbook first_time_setup.yml --tags setup-bash,setup-zsh
```

## Notes

- The default clone URL is HTTPS in `tasks/ensure_repository.yml`; set `dotfiles_git_repo` to use SSH or another remote
- All roles assume the dotfiles repository is located at `~/.dotfiles`
- The zsh role requires git submodules to be initialized (handled automatically by `ensure_repository.yml`)
- The tmux role installs TPM but requires manual plugin installation after deployment (use `<prefix> + I` in tmux)
