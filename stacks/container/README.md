# Containers

## What runs

| Hook | Needs a daemon? | Stage |
| --- | --- | --- |
| `hadolint` (via `hadolint-py`) | no | pre-commit |
| `shellcheck` | no | pre-commit |
| `check-jsonschema` against the compose spec | no | pre-commit |
| `no-mutable-image-tags` (repo-local) | no | pre-commit |
| `checkov --framework dockerfile` | no | manual |

## Local setup

```bash
pre-commit install --install-hooks
```

Nothing else. That is the point of the tool choices below.

## Gotchas

**Use `AleksaC/hadolint-py`, not `hadolint/hadolint`'s `hadolint-docker` hook.**
The Docker variant shells out to `docker run hadolint/hadolint`, so it needs a
running daemon and a socket the user can talk to. That is fine on a laptop and
fails on every hardened CI runner, in every rootless-Podman setup, and inside
devcontainers. `hadolint-py` is a pip package that bundles the static binary —
same linter, no runtime.

**Do not put the image build in a commit hook.** `docker build` on a real
Dockerfile is minutes, not seconds. Lint the Dockerfile on commit, build it in
CI. This repo builds the image in
[`.github/workflows/stacks.yml`](../../.github/workflows/stacks.yml).

**Silence hadolint rules inline, not globally.** Adding a rule to `ignored:` in
`.hadolint.yaml` disables it for every Dockerfile in the repo, forever, with no
record of why. An inline comment is scoped to the one line that needs it:

```dockerfile
# hadolint ignore=DL3018
RUN apk add --no-cache curl
```

[`.hadolint.yaml`](.hadolint.yaml) here has an empty `ignored:` list on purpose —
the Dockerfile is written to satisfy every default rule.

**`:latest` is the bug this stack is really about.** A mutable tag means the
image you tested is not the image you shipped, and a rebuild months later
produces something different with no diff to show for it.
[`no_mutable_image_tags.py`](../../hooks/no_mutable_image_tags.py) enforces the
policy across Dockerfiles *and* Kubernetes/compose YAML, and knows the
difference between an untagged image and a multi-stage `FROM builder`
reference — a distinction naive greps get wrong.

**Digests are the strongest pin.** `FROM python:3.13.1-alpine3.21@sha256:...`
cannot change under you. Both Renovate and Dependabot understand and bump that
form. This repo's Dockerfile uses plain version tags so it stays buildable as a
public example; production should use digests.

## Run it

```bash
pre-commit run --all-files
pre-commit run --hook-stage manual checkov --all-files

docker build -t precommit-showcase/echo:0.1.0 .
docker run --rm -p 8080:8080 precommit-showcase/echo:0.1.0
curl localhost:8080/healthz
```
