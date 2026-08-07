# Helm

## What runs

| Hook | Stage | Needs |
| --- | --- | --- |
| `helm lint --strict` | pre-commit | `helm` |
| `helm-docs` | pre-commit | vendored by the hook |
| `check-yaml` / `yamllint` | pre-commit | — (excluding `templates/`) |
| `check-json` | pre-commit | validates `values.schema.json` |
| `kubeconform` | pre-push | `helm`, `kubeconform`, network |

## Local setup

```bash
# https://helm.sh/docs/intro/install/
brew install helm kubeconform   # or your platform's equivalent
pre-commit install --install-hooks
```

## Gotchas

**`templates/*.yaml` is not YAML.** This is the one that catches everyone:

```yaml
{{- if .Values.ingress.enabled }}
```

is a Go template. `check-yaml`, `yamllint`, `check-jsonschema` and every other
parser will reject it, and the fix is not to make the templates parseable — it
is to exclude them and validate the *rendered* output instead:

```yaml
- id: check-yaml
  exclude: ^charts/[^/]+/templates/
```

Correctness comes from `helm lint` (renders the chart) and `kubeconform`
(validates the render against real Kubernetes schemas). The root config of this
repo excludes `stacks/helm/charts/*/templates/` globally for the same reason.

**`helm lint` without `--strict` exits 0 on warnings.** A missing icon, an
unrecognised value, a chart with no maintainers — all warnings, all exit 0. A
hook that cannot fail is decoration. Always `--strict`.

**Add `values.schema.json`.** Helm validates `values.yaml` against it during
`lint`, `template` and `install`, so a typo'd `--set image.pullPolciy=Always` is
rejected before it reaches a cluster rather than being silently ignored. This is
the highest-leverage file in a chart and most charts do not have one.

**`helm-docs` rewrites `charts/*/README.md`.** The values table in a chart README
goes stale within about a week of being written by hand. helm-docs regenerates
it from `Chart.yaml` plus the `# --` comments in `values.yaml`, which is why
those comments are written in that specific style. Because the hook *modifies*
files, its first run on a new chart fails and stages the new README — that is
normal pre-commit behaviour, not an error.

One consequence worth planning for: the generated README will not satisfy your
Markdown linter, and you cannot fix it, because the generator rewrites the file
on every run. Exclude generated output from the linter rather than fighting it —
this repo does that in
[`.markdownlint-cli2.yaml`](../../.markdownlint-cli2.yaml), and marks the file
`linguist-generated` in [`.gitattributes`](../../.gitattributes) so it collapses
in pull request diffs.

**Never put version in `selectorLabels`.** A Deployment's `spec.selector` is
immutable; if the app version is in there, the next `helm upgrade` fails with a
field-is-immutable error. See
[`_helpers.tpl`](charts/echo/templates/_helpers.tpl).

## Run it

```bash
pre-commit run --all-files
pre-commit run --hook-stage pre-push --all-files

helm template release-under-test charts/echo | less
helm lint --strict charts/echo
```
