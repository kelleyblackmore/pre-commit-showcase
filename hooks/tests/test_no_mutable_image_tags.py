"""Tests for the repo-local hooks.

Hooks are code that can block every commit in the repository. A hook with a
false positive is worse than no hook at all, because the first thing a blocked
contributor reaches for is ``--no-verify``. Test them like production code.

Run with::

    python -m pytest hooks/tests -q
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from no_mutable_image_tags import check_file, check_reference


@pytest.mark.parametrize(
    "ref",
    [
        "ubuntu:24.04",
        "nginx:1.27.3-alpine",
        "registry.example.com:5000/team/app:2.1.0",
        "ubuntu@sha256:abc123",
        "ubuntu:24.04@sha256:abc123",
        "${BASE_IMAGE}",
        "{{ .Values.image.repository }}",
    ],
)
def test_accepts_pinned_references(ref: str) -> None:
    assert check_reference(ref) is None


@pytest.mark.parametrize(
    "ref",
    [
        "ubuntu",
        "ubuntu:latest",
        "nginx:LATEST",
        "ghcr.io/org/app:main",
        "registry.example.com:5000/team/app",
    ],
)
def test_rejects_mutable_references(ref: str) -> None:
    assert check_reference(ref) is not None


def test_multistage_build_stage_names_are_not_registry_refs(tmp_path: Path) -> None:
    """`FROM builder` refers to an earlier stage, not an untagged image."""
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text(
        "FROM golang:1.23.4 AS builder\n"
        "RUN go build -o /app\n"
        "FROM gcr.io/distroless/static:nonroot\n"
        "COPY --from=builder /app /app\n",
        encoding="utf-8",
    )
    assert check_file(str(dockerfile)) == []


def test_reports_path_and_line_number(tmp_path: Path) -> None:
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text("# comment\nFROM ubuntu:latest\n", encoding="utf-8")

    errors = check_file(str(dockerfile))

    assert len(errors) == 1
    assert errors[0].startswith(f"{dockerfile}:2:")


def test_commented_out_lines_are_ignored(tmp_path: Path) -> None:
    dockerfile = tmp_path / "Dockerfile"
    dockerfile.write_text("FROM ubuntu:24.04\n# FROM ubuntu:latest\n", encoding="utf-8")
    assert check_file(str(dockerfile)) == []


def test_kubernetes_yaml_image_key(tmp_path: Path) -> None:
    manifest = tmp_path / "deploy.yaml"
    manifest.write_text(
        "spec:\n  containers:\n    - name: web\n      image: nginx:latest\n",
        encoding="utf-8",
    )

    errors = check_file(str(manifest))

    assert len(errors) == 1
    assert "nginx:latest" in errors[0]
