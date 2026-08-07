#!/usr/bin/env bash
#
# Run one stack's STANDALONE config the way a real single-language repo would.
#
#     ./scripts/run-stack.sh terraform
#
# Copies stacks/<name>/ into a scratch directory, `git init`s it, and runs
# pre-commit there. That isolation is the point: a config full of
# `files: ^stacks/foo/` scoping would pass at the monorepo root and fail here,
# and a config referencing ../../ would break. If it passes here, it is genuinely
# copy-pasteable.
#
# CI runs this for all eight stacks - see .github/workflows/stacks.yml.
#
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

usage() {
  echo "usage: $0 <stack> [pre-commit args...]" >&2
  echo >&2
  echo "available stacks:" >&2
  find "${REPO_ROOT}/stacks" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; >&2
  exit 2
}

[[ $# -ge 1 ]] || usage

STACK="$1"
shift

SRC="${REPO_ROOT}/stacks/${STACK}"
[[ -d ${SRC} ]] || usage
[[ -f "${SRC}/.pre-commit-config.yaml" ]] || {
  echo "error: ${SRC}/.pre-commit-config.yaml does not exist" >&2
  exit 1
}

WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

# node_modules is huge, machine-specific, and the bootstrap below reinstalls it.
cp -R "${SRC}/." "${WORKDIR}/"
# `${WORKDIR:?}` so an unset variable can never turn this into `rm -rf /bin`.
rm -rf "${WORKDIR:?}/node_modules" "${WORKDIR:?}/.terraform" "${WORKDIR:?}/bin" "${WORKDIR:?}/obj"

cd "${WORKDIR}"

git init --quiet --initial-branch=main
git config user.email "ci@example.invalid"
git config user.name "pre-commit showcase"
# Match the Linux CI runner rather than the developer's Windows checkout.
git config core.autocrlf false
git add --all

echo "==> ${STACK}: $(git ls-files | wc -l) files in ${WORKDIR}"

# A stack may need its toolchain installed before the hooks can run - the
# JavaScript stack lints with the project's own ESLint, so node_modules must
# exist. This is the same setup a real contributor performs after cloning.
if [[ -x scripts/precommit-bootstrap.sh ]]; then
  echo "==> ${STACK}: bootstrap"
  ./scripts/precommit-bootstrap.sh
fi

# --all-files reads `git ls-files`, so staged-but-uncommitted is enough.
pre-commit run --all-files --show-diff-on-failure --color=always "$@"
