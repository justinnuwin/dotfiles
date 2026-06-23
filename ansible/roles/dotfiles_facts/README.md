# dotfiles_facts

Owns the consolidated `/etc/ansible/facts.d/dotfiles.fact` file. Responsibilities:

1. **Hydrate** the play-level vars i.e. `rust_installed`, `nvm_installed`, `starship_installed` from `set_fact` (if an install role ran earlier in this play) or from `ansible_local.dotfiles` (last run's persisted state).
2. **Persist** those vars to the consolidated INI file under `/etc/ansible/facts.d/`. This requires `become: true`.

After this role runs, every later consumer role (currently `bash` and `zsh`, but anything in the play below this role) sees the three `*_installed` vars set as play-level facts. Consumer roles do NOT need to hydrate themselves.

## Placement in the playbook

This role MUST be listed in the play AFTER every role that contributes a fact (`toolchain`, `starship`) and BEFORE every role that consumes one (`bash`, `zsh`). The current order in `first_time_setup.yml` is:

```yaml
roles:
  - toolchain
  - starship
  - dotfiles_facts   # <-- here
  - bash
  - zsh
  - tmux
  - terminals
```

## Adding a new fact

1. Add an `ansible.builtin.set_fact` that produces `<name>_installed: true` from the new contributor role.
2. Append a hydration line in `tasks/main.yml` (mirror an existing one).
3. Add a `[<name>] installed = {{ <name>_installed | default(false) | bool }}` section to `templates/dotfiles.fact.j2`.
4. Optionally consume the var in `templates/localshell.j2` (the bash/zsh blockinfile template).

## Sudo

The fact-write tasks use `become: true` because `/etc/ansible/facts.d/` is root-owned. Local-connection runs (`local_first_time_setup.sh`) need `--ask-become-pass` or NOPASSWD sudo. Molecule runs as root inside the container, so become is transparent there.

## Required for dependency-driven invocations

Any play that pulls this role must use `gather_facts: true` so `ansible_local.dotfiles` is populated. The bootstrap play (`first_time_setup.yml`) sets this explicitly.
