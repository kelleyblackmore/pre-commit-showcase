# Two patterns: one root config, or one per project

This repo maintains both, side by side, so you can compare them on the same
eight stacks.

## Pattern A — root config, `files:` scoped (monorepo)

[`/.pre-commit-config.yaml`](../.pre-commit-config.yaml)

```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.8.4
  hooks:
    - id: ruff
      files: ^stacks/python/
```

**Use when** several languages live in one repository.

- Contributors run `pre-commit install` once, at the root. There is no way to
  end up with hooks installed for some subprojects and not others.
- Only hooks whose `files:` pattern matches something in the commit actually
  run. A one-line Terraform change never waits for ESLint to boot a Node
  environment.
- One `pre-commit autoupdate` bumps every stack's revisions together.
- CI is a single `pre-commit run --all-files`.

### Costs

- Every hook needs a `files:` (or `exclude:`) pattern, and a wrong one fails
  open — the hook simply never runs, silently. This is the main hazard of the
  pattern, and the reason the [CI setup](ci-integration.md) here also runs each
  stack in isolation.
- Tool configs still live in the subproject (`stacks/python/pyproject.toml`), so
  hooks that read a config file need an explicit path in `args:`, which is one
  more thing to keep in sync.
- One enormous file. This repo's root config is ~250 lines for eight stacks.

## Pattern B — one config per project (polyrepo)

[`stacks/python/.pre-commit-config.yaml`](../stacks/python/.pre-commit-config.yaml)
and its seven siblings.

```yaml
- repo: https://github.com/astral-sh/ruff-pre-commit
  rev: v0.8.4
  hooks:
    - id: ruff
```

**Use when** each project is its own repository — which is the normal case.

- No path scoping, because there is nothing to scope against. Configs are
  shorter and much harder to get subtly wrong.
- The config sits next to the code and the tool config it refers to.
- Copy-pasteable. Every file under `stacks/*/` here is a config you can drop
  into a real repo unchanged.

### Costs

- `rev:` pins drift apart across repos. Solve it with
  [pre-commit.ci](https://pre-commit.ci/) or a scheduled `autoupdate` PR, not
  with discipline.
- Shared policy (your secret-scanning config, your commit-message rules) gets
  copy-pasted N times. See below.

## Sharing hooks across many repos

When you have twenty repositories that all need the same six baseline hooks,
neither pattern helps. Publish your own hook repository instead:

```yaml
# .pre-commit-hooks.yaml in github.com/your-org/pre-commit-hooks
- id: org-baseline
  name: org baseline checks
  entry: org-baseline
  language: python
```

Consumers then get one line each:

```yaml
- repo: https://github.com/your-org/pre-commit-hooks
  rev: v1.4.0
  hooks:
    - id: org-baseline
```

[writing-custom-hooks.md](writing-custom-hooks.md) covers how to build that.

## What this repo does, and why it is a bit unusual

Both. The root config is the one that runs on commit; the per-stack configs are
the artifacts being showcased. That means every hook is declared twice, which
would be an obvious mistake in a real repo — here it is the deliverable.

CI [verifies both](ci-integration.md): one job runs the root config over the
whole tree, and a matrix job copies each `stacks/<name>/` into a scratch git
repo and runs its standalone config there. Without that second job, a
copy-pasteable config would silently rot the first time someone edited only the
root one.
