# Toolchain

Installs opt-in language toolchains on a host (currently rust and nvm). Each tool is gated by its own `install_*` flag, and the role short-circuits on the next run when the tool is already recorded as installed.

The role only sets in-process facts — the consolidated `/etc/ansible/facts.d/dotfiles.fact` is written by the `dotfiles_facts` role later in the play.

## Variables

| Variable | Default | Purpose |
|---|---|---|
| `install_rust` | `false` | Opt in to rust install via rustup |
| `install_nvm` | `false` | Opt in to nvm install |
| `toolchain_run_first_time_setup` | `false` | Force re-install even when the tool is already recorded as installed |
| `rust_version` | `1.83.0` | Numerical rust version passed to `rustup --default-toolchain` |
| `nvm_version` | `v0.40.1` | Tag of the nvm install script |

## Per-tool gating

The role uses the variable + state-file pattern from the ansible-feature-gating skill, but gates **per-tool** rather than per-role. This lets a host that previously installed only rust later flip on `install_nvm: true` and have nvm install on the next run.

| Scenario | `install_<tool>` | `<tool>_installed` (from ansible_local) | force | install runs? |
|---|---|---|---|---|
| Caller did not opt in | `false` | any | any | no |
| Opt-in, never installed | `true` | undefined / false | any | YES |
| Opt-in, already installed | `true` | `true` | `false` | no |
| Opt-in, already installed, force | `true` | `true` | `true` | YES |

## Force a re-install on a specific host

```bash
ansible-playbook first_time_setup.yml --limit <host> \
  -e install_rust=true \
  -e toolchain_run_first_time_setup=true
```

## Required for dependency-driven invocations

Plays consuming this role (or `dotfiles_facts` downstream) must use `gather_facts: true`. Without it, `ansible_local.dotfiles` is never loaded and the gate degenerates to "always re-install".

## Canonical install commands

```bash
# Rust:
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
  sh -s -- --no-modify-path -y --default-toolchain {{ rust_version }}

# NVM:
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/{{ nvm_version }}/install.sh | bash
```
