#!/usr/bin/env python3
"""Keep the root README's stack table in sync with the ``stacks/`` directory.

The failure mode this prevents is mundane and extremely common: someone adds
``stacks/rust/``, and the README's index silently keeps claiming there are
eight stacks.

Runs at the ``pre-push`` stage rather than ``pre-commit``. It is a whole-repo
consistency check, and there is no value in re-running it on every single
commit of a branch - only on the state that is about to leave the machine.
See docs/stages.md for when to prefer each stage.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

README = Path("README.md")
STACKS_DIR = Path("stacks")

# Matches a Markdown link into a stack directory: [anything](stacks/python/)
LINK_RE = re.compile(r"\]\(\s*stacks/(?P<name>[A-Za-z0-9_.-]+)/?[^)]*\)")


def main() -> int:
    if not README.is_file():
        print("error: README.md is missing", file=sys.stderr)
        return 1
    if not STACKS_DIR.is_dir():
        print("error: stacks/ is missing", file=sys.stderr)
        return 1

    on_disk = {p.name for p in STACKS_DIR.iterdir() if p.is_dir()}
    linked = set(LINK_RE.findall(README.read_text(encoding="utf-8")))

    undocumented = sorted(on_disk - linked)
    dangling = sorted(linked - on_disk)

    for name in undocumented:
        print(
            f"README.md: stacks/{name}/ exists but is not linked from the README",
            file=sys.stderr,
        )
    for name in dangling:
        print(
            f"README.md: links to stacks/{name}/, which does not exist",
            file=sys.stderr,
        )

    if undocumented or dangling:
        return 1

    print(f"ok: README documents all {len(on_disk)} stacks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
