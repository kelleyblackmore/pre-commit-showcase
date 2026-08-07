# Choosing a stage

> For the wider picture — where the stages sit in a commit, and how a hook is
> resolved and run — see [how-it-works.md](how-it-works.md).

The most common way to fail at pre-commit is to put good checks at the wrong
stage. Commits start taking 45 seconds, people discover `--no-verify`, and
within a month the hooks are decorative.

Budget for the commit path: **under about two seconds.** Everything else moves.

## The stages

| Stage | Fires on | Use for |
| --- | --- | --- |
| `pre-commit` | `git commit`, on staged files | formatters, fast linters, secret scanning |
| `commit-msg` | `git commit`, on the message | conventional-commit format, ticket references |
| `pre-push` | `git push` | whole-repo consistency, compile checks, schema validation |
| `manual` | only when asked, or in CI | anything slow, networked, or needing a build |
| `post-checkout`, `post-merge`, `post-rewrite` | after those git ops | regenerating derived files, warning about dependency drift |

> Names changed in pre-commit 3.2. `commit` → `pre-commit`, `push` → `pre-push`,
> `merge-commit` → `pre-merge-commit`. The old names still work but warn.

## The decision table

Ask, in order:

**Does it need the network?** → `manual`.
`pip-audit`, `checkov`, `trivy` with a fresh DB, `kubeconform` fetching schemas.
Committing on a train should work.

**Does it need a build directory or a compiled artifact?** → `manual` or
`pre-push`.
`clang-tidy` needs `compile_commands.json`. `dotnet build` needs a restore. On a
fresh clone these fail with errors that look nothing like the real cause.

**Is it slower than ~2 seconds on a typical change?** → `pre-push`.
`dotnet format analyzers`, type-aware ESLint, a full test suite.

**Does it examine the whole repository rather than the changed files?** →
`pre-push`.
Anything with `always_run: true` and `pass_filenames: false` — this repo's
[`check_readme_toc.py`](../hooks/check_readme_toc.py) is the example. There is
no value in re-checking global consistency on each of the twelve commits in a
branch; check it once, before the branch leaves.

**Otherwise** → `pre-commit`.

## Syntax

```yaml
# Whole hook moves stage
- id: pip-audit
  stages: [manual]

# Same hook, two stages, different arguments
- id: mypy
  stages: [pre-commit]
  args: [--ignore-missing-imports]
- id: mypy
  alias: mypy-strict          # `alias` is required to declare the id twice
  stages: [pre-push]
  args: [--strict]
```

Install the extra hook types — plain `pre-commit install` only wires up
`pre-commit`:

```bash
pre-commit install --hook-type pre-commit --hook-type commit-msg --hook-type pre-push
```

Or declare it once in the config, so a bare `pre-commit install` does the right
thing:

```yaml
default_install_hook_types: [pre-commit, commit-msg, pre-push]
```

## Running a non-default stage by hand

```bash
pre-commit run --hook-stage manual --all-files          # every manual hook
pre-commit run --hook-stage manual pip-audit --all-files # one of them
pre-commit run --hook-stage pre-push --all-files
```

## When someone does need to bypass

Give them the targeted escape hatch before they find the blunt one:

```bash
SKIP=dotnet-format,helm-lint git commit -m "fix: ..."   # skip named hooks
git commit --no-verify                                  # skip everything
```

`SKIP` is strictly better — it is visible in shell history, it names what was
skipped, and it leaves the rest of the hooks doing their job. If a hook is
routinely in someone's `SKIP` list, that is data: the hook is at the wrong
stage, or it is wrong.
