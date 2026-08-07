#!/usr/bin/env bash
#
# Manual-stage clang-tidy wrapper.
#
# clang-tidy needs a compilation database. Rather than failing with a cryptic
# "Could not auto-detect compilation database", this script explains what to do.
#
#   pre-commit run --hook-stage manual clang-tidy --all-files
#
set -euo pipefail

BUILD_DIR="${BUILD_DIR:-build}"
COMPILE_DB="${BUILD_DIR}/compile_commands.json"

if ! command -v clang-tidy >/dev/null 2>&1; then
  echo "clang-tidy is not installed. Install LLVM/clang-tools and retry." >&2
  exit 1
fi

if [[ ! -f ${COMPILE_DB} ]]; then
  cat >&2 <<EOF
No compilation database at ${COMPILE_DB}.

Configure the build once, then re-run:

    cmake -B ${BUILD_DIR} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

EOF
  exit 1
fi

# pre-commit passes the changed files as positional arguments.
if [[ $# -eq 0 ]]; then
  echo "no files to check"
  exit 0
fi

clang-tidy -p "${BUILD_DIR}" "$@"
