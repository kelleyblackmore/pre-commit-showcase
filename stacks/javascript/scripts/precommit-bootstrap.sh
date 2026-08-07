#!/usr/bin/env bash
#
# Picked up automatically by scripts/run-stack.sh (and by CI) before the hooks
# run. The JavaScript stack is the only one that needs it: its ESLint hook uses
# the project's own toolchain, so node_modules has to exist first.
#
# This is the honest cost of linting JS properly - your plugins, parsers and
# shareable configs live in package.json, and something has to install them.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${STACK_DIR}"

if [[ -f package-lock.json ]]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi
