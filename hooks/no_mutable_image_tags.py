#!/usr/bin/env python3
"""Reject container images that are not pinned to an immutable reference.

Mutable references (``:latest``, or no tag at all) make builds
irreproducible and silently re-point at new content, so this hook rejects:

* ``FROM ubuntu``            - no tag
* ``FROM ubuntu:latest``     - mutable tag
* ``image: nginx:latest``    - same, in Kubernetes / Helm / Compose YAML

and accepts anything carrying a digest, plus tags that are not ``latest``:

* ``FROM ubuntu:24.04@sha256:...``
* ``image: nginx:1.27.3``

This is the standard shape of a repo-local hook: read the files pre-commit
passes as ``argv``, print ``path:line: message`` for each violation, exit
non-zero if there were any.
"""

from __future__ import annotations

import re
import sys

# FROM <image>[:tag][@digest] [AS name]
FROM_RE = re.compile(
    r"^\s*FROM\s+(?:--\S+\s+)*(?P<ref>\S+)(?:\s+[Aa][Ss]\s+\S+)?\s*$",
)
# image: <ref>   (quotes optional) in YAML
IMAGE_RE = re.compile(
    r"^\s*-?\s*image:\s*[\"']?(?P<ref>[^\s\"'#]+)[\"']?",
)

# Build-stage names (`FROM x AS builder` ... `FROM builder`) and `scratch` are
# not registry references and must not be flagged.
ALWAYS_OK = {"scratch"}

# `${VAR}` / `{{ .Values.x }}` references are resolved elsewhere; skip them.
TEMPLATED = re.compile(r"\$\{|\$\(|\{\{")


def collect_stage_names(lines: list[str]) -> set[str]:
    names: set[str] = set()
    for line in lines:
        match = re.search(r"^\s*FROM\s+.*\s+[Aa][Ss]\s+(?P<name>\S+)\s*$", line)
        if match:
            names.add(match.group("name").lower())
    return names


def check_reference(ref: str) -> str | None:
    """Return an error message if *ref* is mutable, else None."""
    if "@sha256:" in ref:
        return None  # digest-pinned, immutable by construction
    if TEMPLATED.search(ref):
        return None

    # Strip the registry host before looking for a tag separator, so that
    # `registry.example.com:5000/app` is not mistaken for image `registry`
    # with tag `5000/app`.
    last_segment = ref.rsplit("/", 1)[-1]
    if ":" not in last_segment:
        return f"'{ref}' has no tag - pin an explicit version or a digest"

    tag = last_segment.rsplit(":", 1)[-1]
    if tag.lower() in {"latest", "main", "master", "edge", "stable"}:
        return f"'{ref}' uses the mutable tag ':{tag}' - pin a version or a digest"
    return None


def check_file(path: str) -> list[str]:
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            lines = handle.read().splitlines()
    except OSError as exc:  # unreadable file is the caller's problem, not ours
        return [f"{path}: {exc}"]

    is_dockerfile = FROM_RE.search("\n".join(lines)) is not None
    stage_names = collect_stage_names(lines) if is_dockerfile else set()

    errors: list[str] = []
    for lineno, line in enumerate(lines, start=1):
        if line.lstrip().startswith("#"):
            continue

        for pattern in (FROM_RE, IMAGE_RE):
            match = pattern.match(line)
            if not match:
                continue
            ref = match.group("ref")
            if ref.lower() in ALWAYS_OK or ref.lower() in stage_names:
                break
            problem = check_reference(ref)
            if problem:
                errors.append(f"{path}:{lineno}: {problem}")
            break

    return errors


def main(argv: list[str]) -> int:
    errors: list[str] = []
    for path in argv:
        errors.extend(check_file(path))

    for error in errors:
        print(error, file=sys.stderr)
    return 1 if errors else 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
