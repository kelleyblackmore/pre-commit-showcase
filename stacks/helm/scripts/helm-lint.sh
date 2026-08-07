#!/usr/bin/env bash
#
# Lint every chart under charts/.
#
# Resolves its own location, so the same script serves both the monorepo root
# config and the standalone stacks/helm config.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "${SCRIPT_DIR}")"
CHARTS_DIR="${STACK_DIR}/charts"

if ! command -v helm >/dev/null 2>&1; then
  cat >&2 <<'EOF'
helm is not on PATH.

  * Install:  https://helm.sh/docs/intro/install/
  * Or skip:  SKIP=helm-lint git commit ...
EOF
  exit 1
fi

status=0
for chart in "${CHARTS_DIR}"/*/; do
  [[ -f "${chart}Chart.yaml" ]] || continue
  echo "==> helm lint ${chart}"
  # --strict promotes lint warnings to errors. Without it, `helm lint` exits 0
  # on things like a missing icon or an unrecognised value, which defeats the
  # purpose of putting it in a hook.
  if ! helm lint --strict "${chart}"; then
    status=1
  fi
done

exit "${status}"
