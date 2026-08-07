# Running pre-commit in CI

Local hooks are a convenience; CI is the enforcement. Someone will commit with
`--no-verify`, and someone will edit a file in the GitHub web UI where no hook
exists at all.

## The minimum

```yaml
- uses: actions/checkout@v4
- uses: actions/setup-python@v5
  with:
    python-version: "3.12"
- uses: pre-commit/action@v3.0.1
```

`pre-commit/action` handles the cache and runs `pre-commit run --all-files`.

## What this repo actually runs

Two workflows, because they answer different questions.

**[`pre-commit.yml`](../.github/workflows/pre-commit.yml)** — does the root
config pass over the whole tree? This is the gate.

**[`stacks.yml`](../.github/workflows/stacks.yml)** — does each stack's
*standalone* config still work on its own? Each matrix leg copies
`stacks/<name>/` into a fresh temp directory, `git init`s it, and runs the
config there. Without this, the copy-pasteable configs would rot the first time
someone edited only the root config, and nobody would notice until a reader
tried to use one.

## Run every stage in CI, not just `pre-commit`

A hook parked at `pre-push` or `manual` is still a hook, and if CI only ever
runs the default stage it rots quietly. The first person to actually type
`pre-commit run --hook-stage manual` then discovers it has been broken for
months — which is precisely the failure that made you move it off the commit
path in the first place.

Both workflows here exercise the other stages too. Name the hook explicitly:

```bash
pre-commit run --hook-stage manual clang-tidy --all-files
```

not

```bash
pre-commit run --hook-stage manual --all-files
```

because a hook with no `stages:` key runs at **every** stage — so the bare form
re-runs your entire pre-commit set on top of the manual ones, which is slow and
makes the log hard to read.

Two of these hooks need setup that the commit path does not: `clang-tidy` needs
a configured CMake build, and `kubeconform` needs its binary. That setup is the
same thing a contributor does after cloning, so it lives in a
`scripts/precommit-bootstrap.sh` per stack rather than only in the workflow.

## Things that will bite you

### `no-commit-to-branch` fails every CI run

The hook is `always_run`, CI checks out `main`, and the hook's entire job is to
refuse `main`. Skip it in CI only:

```yaml
env:
  SKIP: no-commit-to-branch
```

### gitleaks in CI checks nothing, by default

The `gitleaks` hook's entry is `gitleaks protect --staged` — it scans *staged
changes*. In CI nothing is staged, so `pre-commit run --all-files` runs it and it
passes trivially. That is correct behaviour for a commit hook and useless as a CI
gate.

If you want CI to actually scan, run gitleaks separately over the history:

```bash
gitleaks detect --source . --log-opts="--all"
```

and remember that anything it finds must be **rotated**, not just deleted —
see [adoption.md](adoption.md).

### `fetch-depth: 0` for anything that reads history

`gitleaks` in full-history mode, `commitizen check --rev-range`, and any hook
that diffs against a base ref need real history. `actions/checkout` defaults to
a depth-1 clone.

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
```

### Cache the hook environments

Building eight isolated environments from scratch takes minutes. The cache key
must include the config files, or you will serve a stale environment after a
`rev:` bump:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.cache/pre-commit
    key: pre-commit-${{ runner.os }}-py${{ steps.py.outputs.python-version }}-${{ hashFiles('.pre-commit-config.yaml', 'stacks/*/.pre-commit-config.yaml') }}
```

### `system` hooks need their tools installed

`terraform_*`, `helm-lint`, `dotnet-format` and `clang-tidy` all shell out to
binaries the hooks do not vendor. Install them in the job before running
pre-commit, or the hook fails with "not on PATH" and everyone assumes the config
is broken. See the matrix `setup` steps in
[`stacks.yml`](../.github/workflows/stacks.yml).

### Show the diff when a formatter fires

`--show-diff-on-failure` turns "prettier failed" into an actual patch in the log,
so a contributor can see what to change without reproducing locally:

```bash
pre-commit run --all-files --show-diff-on-failure --color=always
```

## Keeping `rev:` pins fresh

`pre-commit autoupdate` bumps every `rev:` to the latest tag. Automate it, or it
never happens:

- **[pre-commit.ci](https://pre-commit.ci/)** — free for public repos. Opens an
  autoupdate PR weekly and auto-fixes formatting on PRs by pushing a commit.
  Note that it cannot run `system`/`docker` hooks, so this repo's Terraform,
  Helm and .NET hooks would need `skip:` entries in a `ci:` block.
- **Dependabot** — supports the `pre-commit` package ecosystem, opens one PR per
  outdated hook repo.
- **[`autoupdate.yml`](../.github/workflows/autoupdate.yml)** — a scheduled
  workflow that runs `pre-commit autoupdate` and opens a PR. What this repo
  uses, since it needs the non-vendored tools that pre-commit.ci cannot provide.

## Do not run the hooks twice

If your CI already runs `ruff`, `eslint` and `terraform fmt` as separate steps,
delete those steps and run pre-commit instead. Two definitions of "is this code
formatted" will disagree eventually, and the failure is genuinely confusing —
the hook passes and the CI step fails, on the same file, in the same commit.
