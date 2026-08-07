#!/usr/bin/env bash
#
# pre-push guard: the tree must still compile with warnings treated as errors.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
PROJECT="${PROJECT_DIR}/src/Showcase/Showcase.csproj"

if ! command -v dotnet >/dev/null 2>&1; then
  echo "dotnet is not on PATH; skip with SKIP=dotnet-build git push" >&2
  exit 1
fi

dotnet build "${PROJECT}" \
  --nologo \
  --configuration Release \
  -warnaserror
