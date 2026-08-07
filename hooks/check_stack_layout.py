#!/usr/bin/env python3
"""Enforce the per-stack layout contract.

Every directory under ``stacks/`` must ship:

* ``README.md``                — what the stack demonstrates and how to run it
* ``.pre-commit-config.yaml``  — a *standalone* config, copy-pasteable into a
  single-language repo of that type

This is a ``pass_filenames: false`` + ``always_run: true`` hook: it inspects
repository structure rather than a list of changed files, so pre-commit has
nothing useful to hand it.

Exit code 0 means the tree is fine; 1 means at least one stack is incomplete.
"""

from __future__ import annotations

import sys
from pathlib import Path

REQUIRED_FILES = ("README.md", ".pre-commit-config.yaml")
STACKS_DIR = Path("stacks")


def main() -> int:
    if not STACKS_DIR.is_dir():
        print(f"error: {STACKS_DIR}/ does not exist", file=sys.stderr)
        return 1

    stacks = sorted(p for p in STACKS_DIR.iterdir() if p.is_dir())
    if not stacks:
        print(f"error: {STACKS_DIR}/ contains no stacks", file=sys.stderr)
        return 1

    problems: list[str] = []
    for stack in stacks:
        for required in REQUIRED_FILES:
            candidate = stack / required
            if not candidate.is_file():
                problems.append(f"{candidate}: missing")
            elif candidate.stat().st_size == 0:
                problems.append(f"{candidate}: empty")

    for problem in problems:
        print(problem, file=sys.stderr)

    if problems:
        print(
            f"\n{len(problems)} problem(s) across {len(stacks)} stacks. "
            "Each stacks/<name>/ needs a README.md and a standalone "
            ".pre-commit-config.yaml.",
            file=sys.stderr,
        )
        return 1

    print(f"ok: {len(stacks)} stacks, all complete")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
