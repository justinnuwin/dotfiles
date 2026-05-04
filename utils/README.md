# utils/

Developer utilities for working on this repo. Things in here are **not** part
of the deployed dotfiles and are **not** touched by the Ansible playbooks —
they're local tooling for editing and reviewing shell code.

Tools used here are assumed to be installed by the developer (see each
subdirectory's README for what's expected and where).

## Contents

- [`shellcheck/`](shellcheck/) — runs shellcheck against the shell scripts in
  this repo. Designed to plug into `githooks/pre-commit` so syntax/style
  regressions are caught before they're committed.
