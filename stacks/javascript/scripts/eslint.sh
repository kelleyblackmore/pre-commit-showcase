#!/usr/bin/env bash
#
# Run the PROJECT's ESLint, not a pre-commit-vendored one.
#
# Why not `pre-commit/mirrors-eslint`? Because a flat config that imports
# anything cannot work with it:
#
#     import js from '@eslint/js';   // eslint.config.mjs
#
# pre-commit installs `additional_dependencies` into its own isolated Node
# environment, but Node resolves a bare import in eslint.config.mjs relative to
# THE CONFIG FILE - it looks in stacks/javascript/node_modules, then walks up.
# pre-commit's environment is never on that path, so you get:
#
#     Error [ERR_MODULE_NOT_FOUND]: Cannot find package '@eslint/js'
#     imported from .../stacks/javascript/eslint.config.mjs
#
# The trap is that it *appears* to work the moment you have run `npm install`,
# because then the imports resolve from your real node_modules - while the
# eslint BINARY still comes from pre-commit's environment. Two dependency
# sources, two versions, no warning. It then fails on any fresh clone and in CI.
#
# The mirror is fine for a config with no imports. This one has imports, so we
# use the project's own toolchain and get a single source of truth.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "${SCRIPT_DIR}")"
ESLINT_BIN="${STACK_DIR}/node_modules/.bin/eslint"

if [[ ! -x ${ESLINT_BIN} ]]; then
  cat >&2 <<EOF
ESLint is not installed in ${STACK_DIR}/node_modules.

  cd ${STACK_DIR} && npm ci

  (or skip this hook once: SKIP=eslint git commit ...)
EOF
  exit 1
fi

# pre-commit hands us paths relative to the repository root. Make them absolute
# before changing directory, so the same wrapper works whether it was invoked
# from the monorepo root or from stacks/javascript itself.
files=()
for arg in "$@"; do
  if [[ -e ${arg} ]]; then
    files+=("$(cd "$(dirname "${arg}")" && pwd)/$(basename "${arg}")")
  fi
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "no files to lint"
  exit 0
fi

cd "${STACK_DIR}"
exec "${ESLINT_BIN}" --max-warnings 0 "${files[@]}"
