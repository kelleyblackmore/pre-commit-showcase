#!/usr/bin/env bash
#
# `dotnet format` wrapper for pre-commit.
#
# Resolves its own location so the same script works whether pre-commit invokes
# it from the monorepo root (root .pre-commit-config.yaml) or from
# stacks/csharp/ (the standalone config).
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "${SCRIPT_DIR}")"
PROJECT="${PROJECT_DIR}/src/Showcase/Showcase.csproj"

# Checking for the `dotnet` binary is not enough: the runtime-only install
# provides `dotnet` but no SDK, and `dotnet format` then fails with a confusing
# "The application 'format' does not exist".
if ! command -v dotnet >/dev/null 2>&1 || ! dotnet --list-sdks 2>/dev/null | grep -q .; then
  cat >&2 <<'EOF'
No .NET SDK found, so the C# hooks cannot run.
(`dotnet` may be installed as runtime-only - that is not enough.)

  * Install the .NET SDK:  https://dotnet.microsoft.com/download
  * Verify:                dotnet --list-sdks
  * Or skip this one hook: SKIP=dotnet-format git commit ...

Failing loudly rather than passing silently: a hook that no-ops when its tool is
missing gives you a green commit and an unformatted diff.
EOF
  exit 1
fi

# --verify-no-changes turns `format` from a fixer into a checker. Drop it (and
# re-stage the files) if you would rather the hook rewrite code in place.
dotnet format whitespace "${PROJECT}" --verify-no-changes
dotnet format style "${PROJECT}" --verify-no-changes
dotnet format analyzers "${PROJECT}" --verify-no-changes
