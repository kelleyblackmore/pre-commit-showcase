#!/usr/bin/env bash
#
# Picked up automatically by scripts/run-stack.sh (and by CI) before the hooks
# run.
#
# Only the manual-stage clang-tidy hook needs this: clang-tidy is a compiler
# front end and cannot analyse a translation unit without knowing how it is
# compiled. That knowledge lives in compile_commands.json, which only exists
# once CMake has configured the build.
#
# It is deliberately cheap - configure only, no compilation.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "${SCRIPT_DIR}")"

cd "${STACK_DIR}"

# Best-effort on purpose. The pre-commit-stage hooks (clang-format, cpplint,
# cmake-format) are all vendored and need no toolchain at all, so a missing
# compiler must not block them. Only clang-tidy needs this, and that hook
# already fails with an actionable message when the database is absent.
if ! command -v cmake >/dev/null 2>&1; then
  echo "cmake not found - skipping compile-database generation" >&2
  exit 0
fi

if ! cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON >/dev/null 2>&1; then
  echo "cmake configure failed (no compiler?) - skipping compile-database generation" >&2
  exit 0
fi

echo "compile database: ${STACK_DIR}/build/compile_commands.json"
