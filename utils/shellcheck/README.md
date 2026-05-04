# shellcheck

Lints the shell scripts in this repo (`shell/`, `utils/shellcheck/run.sh`,
`githooks/*`). Intended use: pre-commit cleanup so syntax / quoting
regressions don't land on `master`.

## Prerequisite

The runner expects a shellcheck binary at:

```
~/shellcheck-stable/shellcheck
```

Download a prebuilt static binary from the project's releases page if you
don't already have one: <https://github.com/koalaman/shellcheck/releases>.
Extract the `shellcheck` binary into `~/shellcheck-stable/` and make sure it's
executable.

If your binary lives somewhere else, override the path:

```bash
export SHELLCHECK_BIN=/usr/local/bin/shellcheck
```

The runner does not install shellcheck for you — if the binary is missing it
exits 1 with a pointer back to this file.

## Standalone use

From the repo root (or anywhere inside it):

```bash
utils/shellcheck/run.sh
```

This lints every tracked shell file the runner knows about (see the
`shell_paths` array in `run.sh`). `shell/zshrc` and `shell/p10k.zsh` are
intentionally excluded — shellcheck has no `zsh` dialect mode and the false
positives drown out real findings.

To lint only staged shell files (useful while iterating):

```bash
utils/shellcheck/run.sh --staged
```

## Pre-commit hook

A drop-in example hook is provided at `githooks/pre-commit`. To enable it for
this repo:

```bash
ln -s ../../githooks/pre-commit .git/hooks/pre-commit
```

Once linked, every `git commit` runs shellcheck against the staged shell
files. The commit aborts on findings; clean diffs commit normally. If the
shellcheck binary is missing, the commit also aborts (with a pointer to this
file) — install/locate the binary, then retry.

> Note: `git config core.hooksPath githooks` would enable every hook in
> `githooks/` at once, but `githooks/post-checkout` is currently a stub with
> literal placeholders. Stick to the per-hook symlink above until that stub is
> fixed.
