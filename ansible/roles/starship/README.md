# Starship

Installs the [starship](https://starship.rs/) prompt via the official installer. The installer ships a pre-built binary, so this role has no toolchain dependency.

The role only sets an in-process fact — the consolidated `/etc/ansible/facts.d/dotfiles.fact` is written by the `dotfiles_facts` role later in the play.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `starship_run_first_time_setup` | `false` | Force re-install even when starship is already recorded as installed |
| `starship_version` | `v1.21.1` | Numerical starship release tag passed to the installer's `-v` flag |
| `starship_bin_dir` | `~/.local/bin` | Where the installer drops the binary (user-writable, no sudo needed) |

## Gating

| Scenario | `starship_installed` (from ansible_local) | `starship_run_first_time_setup` | `first_time_setup.yml` runs? |
|---|---|---|---|
| Fresh host | undefined | any | YES |
| Already installed | `true` | `false` | no |
| Already installed, force | `true` | `true` | YES |

## Force a re-install on a specific host

```bash
ansible-playbook first_time_setup.yml --limit <host> -e starship_run_first_time_setup=true
```

To pin a different version:

```bash
ansible-playbook first_time_setup.yml -e starship_version=v1.22.0 -e starship_run_first_time_setup=true
```

## Required for dependency-driven invocations

Plays that pull this role must use `gather_facts: true` so `ansible_local.dotfiles.starship` is populated.

## Canonical install command

```bash
curl -sS https://starship.rs/install.sh | \
  sh -s -- -b {{ starship_bin_dir }} -v {{ starship_version }} -y
```
