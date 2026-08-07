#!/usr/bin/env bash
#
# Render each chart and validate the resulting manifests against the Kubernetes
# OpenAPI schemas.
#
# `helm lint` only checks that the chart is well-formed. It will happily accept
# `apiVersion: apps/v1beta1` or a misspelled `readinessProbe.httpGett`.
# kubeconform catches both, because it checks the rendered output against the
# real API schema.
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STACK_DIR="$(dirname "${SCRIPT_DIR}")"
CHARTS_DIR="${STACK_DIR}/charts"

# The oldest cluster version this chart claims to support (Chart.yaml kubeVersion).
KUBE_VERSION="${KUBE_VERSION:-1.27.0}"

for tool in helm kubeconform; do
  if ! command -v "${tool}" >/dev/null 2>&1; then
    cat >&2 <<EOF
${tool} is not on PATH.

  * helm:        https://helm.sh/docs/intro/install/
  * kubeconform: https://github.com/yannh/kubeconform#installation
  * Or skip:     SKIP=kubeconform git push
EOF
    exit 1
  fi
done

status=0
for chart in "${CHARTS_DIR}"/*/; do
  [[ -f "${chart}Chart.yaml" ]] || continue
  echo "==> kubeconform $(basename "${chart}")"
  if ! helm template release-under-test "${chart}" --kube-version "${KUBE_VERSION}" |
    kubeconform \
      -strict \
      -summary \
      -kubernetes-version "${KUBE_VERSION}" \
      -schema-location default \
      -; then
    status=1
  fi
done

exit "${status}"
