#!/bin/bash
# Run shellcheck against the shell scripts in this repo.
#
# Modes:
#   - Full (default): lint every tracked shell script we know about.
#   - Staged: when invoked from a git commit hook (GIT_INDEX_FILE set), or
#     with --staged, lint only the shell files staged for commit.
#
# Binary location:
#   By default invokes ~/shellcheck-stable/shellcheck. Override with
#   SHELLCHECK_BIN=/path/to/shellcheck if your binary lives elsewhere.

set -euo pipefail

SHELLCHECK_BIN="${SHELLCHECK_BIN:-$HOME/shellcheck-stable/shellcheck}"

if [[ ! -x "$SHELLCHECK_BIN" ]]; then
  echo "shellcheck not found at $SHELLCHECK_BIN; see utils/shellcheck/README.md" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "must be run from inside the dotfiles git repo" >&2
  exit 1
}
cd "$repo_root"

# Files we lint by default. The set is intentionally narrow: it covers the
# files introduced or restructured by the modular shell refactor. Several
# pre-existing files (shell/bazel_utils.sh, shell/fun.sh, shell/fzf_aliases.sh,
# shell/path_utils.sh, shell/macos_gnu.sh, githooks/post-checkout) have
# accumulated style debt and are excluded pending a follow-up cleanup pass.
# shell/zshrc and shell/p10k.zsh are excluded permanently — shellcheck has no
# zsh dialect mode.
shell_paths=(
  'shell/jnshell_utils.sh'
  'shell/justinShell.sh'
  'shell/bashrc'
  'shell/modules/*.sh'
  'utils/shellcheck/run.sh'
  'githooks/pre-commit'
)

# Regex matching the same set, used for filtering staged files.
shell_regex='^(shell/(jnshell_utils\.sh|justinShell\.sh|bashrc|modules/[^/]+\.sh)|utils/shellcheck/run\.sh|githooks/pre-commit)$'

# Decide mode.
mode="full"
if [[ "${1:-}" == "--staged" ]] || [[ -n "${GIT_INDEX_FILE:-}" ]]; then
  mode="staged"
fi

files=()
if [[ "$mode" == "staged" ]]; then
  while IFS= read -r line; do
    [[ -n "$line" ]] && files+=("$line")
  done < <(git diff --cached --name-only --diff-filter=ACM | grep -E "$shell_regex" || true)
else
  while IFS= read -r line; do
    [[ -n "$line" ]] && files+=("$line")
  done < <(git ls-files "${shell_paths[@]}")
fi

if [[ ${#files[@]} -eq 0 ]]; then
  exit 0
fi

# All our files target bash (zshrc is excluded above, and the hook scripts /
# bashrc are bash-compatible).
#   --rcfile  : pin the project shellcheck config (auto-discovery looks in the
#               input file's directory, which would miss our utils/shellcheck/
#               location).
#   -x        : enable external-source following (also set in the rcfile, but
#               we pass it explicitly for shellcheck < 0.7).
#   -P        : when a script does `# shellcheck source=foo`, look for foo in
#               the script's own directory.
exec "$SHELLCHECK_BIN" \
  --rcfile="$repo_root/utils/shellcheck/.shellcheckrc" \
  --shell=bash \
  -x \
  -P SCRIPTDIR \
  "${files[@]}"
