# Add an isolated macOS molecule scenario via Tart

## Context

The current molecule setup gives us isolated Linux coverage (Ubuntu 22.04
in Docker via `molecule/default/`). We have no comparable isolated harness
for macOS, which is the primary target for these dotfiles — the only way
to verify a macOS deployment today is to run `local_first_time_setup.sh`
on a real Mac, which mutates the developer's actual home directory. We
want a way to spin up a clean, throwaway macOS environment, run
`first_time_setup.yml` against it, verify the result, and tear it down —
the same shape as the current Docker scenario.

This machine is an Apple M4 Pro (Apple Silicon), so the native fit is
**Tart** (Cirrus Labs): an OCI-style macOS VM tool that's CLI-driven,
publishes prebuilt base images on GHCR, and runs natively on Apple
hardware (Apple's macOS EULA permits VMs only on Apple hardware, which
Tart respects). Molecule's built-in `delegated` driver lets us own the
create/destroy lifecycle via plain ansible tasks — no third-party
molecule plugin required.

The new scenario lives **alongside** the existing Ubuntu scenario, not in
place of it: `molecule -s default test` continues to give Linux coverage
(the Ghostty XDG path is Linux-only); `molecule -s macos test` adds
real macOS coverage (the iTerm2 debug message and the
`~/Library/Application Support/com.mitchellh.ghostty/config` path).

## Prerequisites (one-time, host setup)

These are installed manually before running the scenario; they're not
managed by the playbook.

1. **Tart** — install via Homebrew:
   ```sh
   brew install cirruslabs/cli/tart
   ```
2. **Base image** — pull once (~50 GB; cached between runs):
   ```sh
   tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
   ```
   The image ships with Xcode CLT (so `git` is present), SSH enabled, and
   default credentials `admin` / `admin`.

The molecule scenario's `create.yml` will re-run `tart pull` idempotently
so a missed manual step still recovers; this list is documentation, not a
hard gate.

## New files

### `ansible/molecule/macos/molecule.yml`
Driver `delegated` (we manage lifecycle); single platform.
```yaml
---
driver:
  name: default      # 'delegated' lifecycle via custom create/destroy
platforms:
  - name: dotfiles-mac
    image: ghcr.io/cirruslabs/macos-sequoia-base:latest
scenario:
  name: macos
  test_sequence:
    - destroy
    - create
    - prepare
    - converge
    - verify
    - destroy
provisioner:
  name: ansible
  playbooks:
    create: create.yml
    destroy: destroy.yml
    prepare: prepare.yml
    converge: converge.yml
    verify: verify.yml
verifier:
  name: ansible
```

### `ansible/molecule/macos/create.yml`
Pulls the base image idempotently, clones a working VM from it, starts
the VM headless in the background, waits for an IP and for SSH, and
writes the instance config molecule expects so subsequent plays inherit
the inventory.

Key tasks:
- `tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest` —
  `changed_when: false`.
- `tart clone macos-sequoia-base dotfiles-mac` — guarded by
  `tart list | grep dotfiles-mac` so re-runs don't error.
- `tart run --no-graphics dotfiles-mac` — `async: 0  poll: 0` so it
  detaches.
- Poll `tart ip dotfiles-mac` until non-empty (60s budget).
- `ansible.builtin.wait_for` on `port: 22` for SSH (120s budget).
- `ansible.builtin.copy` an `instance_config.yml` to
  `{{ molecule_ephemeral_directory }}/instance_config.yml` containing:
  ```yaml
  - instance: dotfiles-mac
    address: <ip>
    user: admin
    port: 22
    identity_file: ""
    connection: ansible_connection=ssh ansible_ssh_pass=admin ansible_become_pass=admin
  ```

### `ansible/molecule/macos/destroy.yml`
- `tart stop dotfiles-mac` — `failed_when: false` (idempotent on already-stopped).
- `tart delete dotfiles-mac` — `failed_when: false`.
- Remove `instance_config.yml` from the ephemeral dir.

### `ansible/molecule/macos/prepare.yml`
On macOS, the base image already has `git` (via Xcode CLT) and Python.
The only prep is to seed `known_hosts` so SSH doesn't prompt; molecule
already disables host-key checking via the inventory, so this play is a
near no-op:
```yaml
- name: Bootstrap macOS VM
  hosts: all
  gather_facts: false
  tasks:
    - name: Wait for VM Python to be available
      ansible.builtin.raw: /usr/bin/python3 --version
      changed_when: false
```

### `ansible/molecule/macos/converge.yml`
Mirrors the existing default-scenario converge, just runs the same root
playbook against the macOS VM:
```yaml
---
- name: Converge
  ansible.builtin.import_playbook: ../../first_time_setup.yml
```

### `ansible/molecule/macos/verify.yml`
Mac-specific symlink targets (note paths under `/Users/admin/`, not
`/root/`, and the macOS Ghostty path):
```yaml
---
- name: Verify
  hosts: all
  gather_facts: false
  tasks:
    - name: Verify .bashrc symlink exists
      ansible.builtin.stat:
        path: /Users/admin/.bashrc
      register: bashrc_stat
      failed_when: not bashrc_stat.stat.islnk

    - name: Verify .zshrc symlink exists
      ansible.builtin.stat:
        path: /Users/admin/.zshrc
      register: zshrc_stat
      failed_when: not zshrc_stat.stat.islnk

    - name: Verify .tmux.conf symlink exists
      ansible.builtin.stat:
        path: /Users/admin/.tmux.conf
      register: tmux_conf_stat
      failed_when: not tmux_conf_stat.stat.islnk

    - name: Verify Ghostty config symlink exists (macOS path)
      ansible.builtin.stat:
        path: "/Users/admin/Library/Application Support/com.mitchellh.ghostty/config"
      register: ghostty_config_stat
      failed_when: not ghostty_config_stat.stat.islnk

    - name: Verify dotfiles repository exists
      ansible.builtin.stat:
        path: /Users/admin/.dotfiles/.git
      register: dotfiles_git_stat
      failed_when: not dotfiles_git_stat.stat.exists
```
The iTerm2 import message is a `debug` task — it doesn't materialize a
file, so there's nothing to verify here. We rely on the converge log
showing it (manual eyeball check during dev; not test-asserted).

## Modified files

### `ansible/requirements.txt`
The `delegated` driver ships with molecule core — no new pip package
needed. **No edit required**, but call this out explicitly so the next
person doesn't add `molecule-tart` (no such plugin) speculatively.

### `ansible/README.md`
Add a "macOS scenario" subsection under "Testing with Molecule":
- Prerequisites: `brew install cirruslabs/cli/tart` and
  `tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest`.
- Disk/RAM expectations (~50 GB image, ~8 GB RAM in use during the run).
- Invocation: `molecule -s macos test`.
- Note that this scenario clones the dotfiles repo *from GitHub HEAD*
  inside the VM (matching the Ubuntu scenario's behavior via
  `tasks/ensure_repository.yml`), so unpushed local changes are not
  exercised — push first or use `--scenario-name default` for fast
  iteration on the playbook itself.
- Update the directory tree to show `molecule/macos/` alongside
  `molecule/default/`.

## Critical files (read for context, not edited)

- `ansible/molecule/default/molecule.yml` — pattern reference for the
  `delegated`-style scenario layout (test sequence, provisioner stanzas).
- `ansible/molecule/default/verify.yml` — exact pattern for the verify
  tasks; the macOS verify mirrors it with adjusted paths.
- `ansible/tasks/ensure_repository.yml` — clone-from-GitHub logic that
  runs inside the VM; explains why local changes need to be pushed first.
- `ansible/first_time_setup.yml` — the playbook converge runs.
- `ansible/roles/terminals/vars/main.yml` — confirms the macOS Ghostty
  path that verify.yml will check.

## Reused utilities / patterns

- Molecule's built-in `delegated` driver — no new plugin in
  `requirements.txt`.
- The existing `verify.yml` task shape (`stat` + `failed_when:
  not <stat>.stat.islnk`) — copied with adjusted paths.
- `first_time_setup.yml` — imported as-is by `converge.yml`. No playbook
  change needed; the `terminals` role's existing
  `ansible_facts['os_family'] == 'Darwin'` branch already does the right
  thing on the Mac VM.
- Cirrus Labs' published base image (`macos-sequoia-base:latest`) —
  comes preloaded with the deps the playbook needs (git, python3, ssh).

## Verification

1. **Host prereqs (one-time):**
   ```sh
   brew install cirruslabs/cli/tart
   tart pull ghcr.io/cirruslabs/macos-sequoia-base:latest
   ```
2. **Run the new scenario:**
   ```sh
   cd ansible
   source venv/bin/activate
   molecule -s macos test 2>&1 | tee tmp_macos_test.log
   ```
   Expected: full sequence (destroy → create → prepare → converge →
   verify → destroy) exits 0.
3. **Confirm Linux scenario still works (regression check):**
   ```sh
   molecule -s default test
   ```
4. **Spot-check the iTerm message:** in `tmp_macos_test.log`, grep for
   `iTerm2 profile available at` — should appear once during converge.
5. **Iteration mode (faster than full `test`):**
   ```sh
   molecule -s macos create     # boot once
   molecule -s macos converge   # re-run playbook against the live VM
   molecule -s macos verify     # re-run verify
   molecule -s macos destroy    # tear down when done
   ```
   Useful while developing the scenario itself.

## Out of scope / known limitations

- **Local working copy:** the VM clones from GitHub HEAD, same as the
  Ubuntu scenario. Testing unpushed changes would require either bind-
  mounting the repo via `tart run --dir=dotfiles:/Users/junguyen/.dotfiles`
  and overriding `ensure_repository.yml`, or rsync'ing in `prepare.yml`.
  Punting that as a follow-up — it's a real ergonomic gap but matches
  current Linux behavior.
- **Cross-OS coverage CI:** no GitHub Actions wiring in this plan.
  Adding a workflow that runs both scenarios in CI is a separate task.
- **Image staleness:** `tart pull :latest` is idempotent but doesn't
  force-refresh. If a base image update is needed, `tart delete
  macos-sequoia-base && tart pull …` re-fetches.
