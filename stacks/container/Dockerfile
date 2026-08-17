# syntax=docker/dockerfile:1
#
# Written to pass hadolint with an empty ignore list. Every choice below is one
# hadolint would otherwise flag:
#
#   DL3006  base images carry an explicit tag (never bare, never :latest)
#   DL3007  no :latest
#   DL3025  CMD/ENTRYPOINT in exec form, so signals reach PID 1
#   DL3045  COPY has an explicit destination and WORKDIR is set first
#   DL4006  SHELL sets pipefail before any piped RUN
#
# For production, take the pinning one step further and add a digest, which is
# the only truly immutable reference:
#
#   FROM python:3.14.0-alpine3.21@sha256:<digest> AS builder
#
# Renovate and Dependabot both understand and bump that form.

# ---------- build stage -------------------------------------------------------
FROM python:3.14.1-alpine3.21 AS builder

WORKDIR /build

COPY app/ ./app/

# Byte-compile ahead of time so the runtime image never writes to its own
# filesystem and can run with a read-only root.
RUN python -m compileall -q ./app

# ---------- runtime stage -----------------------------------------------------
FROM python:3.14.1-alpine3.21 AS runtime

# hadolint DL4006: without this, a failure in the left side of a pipe is silently
# swallowed for every RUN below.
SHELL ["/bin/ash", "-o", "pipefail", "-c"]

LABEL org.opencontainers.image.title="precommit-showcase-echo" \
      org.opencontainers.image.description="Minimal stdlib-only HTTP echo server." \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.source="https://github.com/kelleyblackmore/pre-commit-showcase"

# Non-root, no shell, no home directory to litter.
RUN addgroup -S -g 10001 app \
    && adduser -S -u 10001 -G app -H -s /sbin/nologin app

WORKDIR /srv

COPY --from=builder --chown=10001:10001 /build/app/ /srv/app/

USER 10001:10001

EXPOSE 8080

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["python", "-c", "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8080/healthz', timeout=2).status == 200 else 1)"]

ENTRYPOINT ["python", "-m", "app.server"]
