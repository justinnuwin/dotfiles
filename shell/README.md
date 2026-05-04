# Shell setup

## Premise

Every script in this directory assumes the dotfiles repo is checked out at
`$HOME/.dotfiles`. Paths inside the scripts are hard-coded against that
location. If the repo lives somewhere else, things will not work.

## Shell compatibility

Everything is intended to be compatible with both **bash** and **zsh** unless
explicitly noted.

## Entry-point chain

```
~/.bashrc or ~/.zshrc            (symlinks installed by ansible)
        |
        v
shell/bashrc  or  shell/zshrc    (shell-specific setup)
        |
        v
shell/justinShell.sh             (common entry point)
        |
        |--- shell/jnshell_utils.sh   (warn / flag / require helpers)
        |--- shell/path_utils.sh
        |--- shell/bazel_utils.sh
        |--- aliases, git helpers
        |--- shell/macos_gnu.sh   (only on Darwin)
        |--- ~/.localshell        (per-host overrides, OPTIONAL)
        |--- shell/modules/common_aliases.sh  (DEFAULT ON)
        |--- shell/modules/git_aliases.sh     (DEFAULT ON)
        |--- shell/fzf_aliases.sh (if fzf is installed)
        |--- shell/modules/ssh_socket.sh  (if JNSHELL_LONG_LIVED_REMOTE=true)
        |--- shell/modules/nvm.sh         (if JNSHELL_USE_NVM=true)
        |--- shell/modules/rust.sh        (if JNSHELL_USE_RUST=true)
        '--- shell/modules/prompt.sh      (always; dispatches on JNSHELL_PROMPT)
```

`~/.localshell` is sourced **before** any feature module, so flags and
variables set there take effect for the rest of startup.

## Per-host overrides

Copy `shell/localshell.example` to `~/.localshell` and uncomment / edit the
lines you want. The file is gitignored implicitly (it lives in `$HOME`, not in
the repo) so per-host settings don't leak across machines.

## Feature flags

Every flag is read from `~/.localshell`. A flag is "enabled" when its value is
the literal string `true`. Each gated feature verifies its own prerequisites;
if anything is missing you get a warning on stderr and the feature is skipped
- the shell still starts.

See the example file `shell/localshell.example` for the full list of feature
flags and their description.

## Linting

Shell scripts in this repo are linted with shellcheck. See
[`utils/shellcheck/README.md`](../utils/shellcheck/README.md) for how to run
the linter and how to wire it as a pre-commit hook.
