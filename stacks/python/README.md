# Python

Copy [`.pre-commit-config.yaml`](.pre-commit-config.yaml) and
[`pyproject.toml`](pyproject.toml) into a Python repo and you are done.

## What runs

| Hook | Replaces | Notes |
| --- | --- | --- |
| `ruff` | flake8, isort, pyupgrade, pydocstyle, autoflake, pep8-naming | one Rust binary, ~100× faster than the tools it replaces |
| `ruff-format` | black | byte-compatible with black for almost all input |
| `mypy` | — | `--strict`, `src/` only |
| `bandit` | — | security linter, `src/` only |
| `debug-statements` | — | catches a stray `breakpoint()` |
| `name-tests-test` | — | test files must be `test_*.py`, or pytest silently skips them |
| `pip-audit` | — | **manual stage** — dependency CVEs, hits the network |

## Local setup

```bash
pip install pre-commit
pre-commit install --install-hooks
```

## Gotchas

**mypy cannot see your dependencies.** pre-commit builds an isolated virtualenv
per hook. Your project's site-packages is not on the path, so mypy resolves
every third-party import as `Any` unless you list the stubs explicitly:

```yaml
- id: mypy
  additional_dependencies: [types-requests, pydantic>=2]
```

That list is a second dependency manifest you now have to keep in step with
`pyproject.toml`. It is the single biggest maintenance cost of running mypy
through pre-commit, and the reason some teams run mypy only in CI, where it can
use the real environment. Both are defensible; pick one deliberately.

**Order ruff before ruff-format.** `ruff --fix` can leave a line the formatter
wants to rewrap. Lint first, format second, so the formatter has the last word.
Reversing them produces a hook that fails, fixes, and fails again on the next
run.

**Ruff config lives in `pyproject.toml`, not in the hook args.** That way your
editor's ruff extension, the hook, and CI all read identical settings. Passing
rules via `args:` guarantees they will drift.

**`select = ["D"]` on an existing codebase will produce thousands of findings.**
See [adoption.md](../../docs/adoption.md) for the ratchet approach.

## Run it

```bash
pre-commit run --all-files
pre-commit run --hook-stage manual pip-audit --all-files
python -m pytest tests -q
```
