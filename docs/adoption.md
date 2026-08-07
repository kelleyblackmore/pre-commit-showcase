# Adopting pre-commit on an existing codebase

Adding a formatter to a five-year-old repo produces a 40,000-line diff, and
adding a strict linter produces 12,000 findings. Both are true, and neither is a
reason not to do it. This is the sequence that works.

## 1. Land the reformat as its own commit

Run the formatter over everything, commit it alone, with a message that says
what it is:

```bash
pre-commit run ruff-format --all-files
git commit -am "style: apply ruff-format across the tree

Mechanical reformat, no behaviour change. Ignored via .git-blame-ignore-revs."
```

Then hide it from blame:

```bash
git rev-parse HEAD >> .git-blame-ignore-revs
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

GitHub reads `.git-blame-ignore-revs` automatically. Without it you have
destroyed `git blame` for the whole repository, which is a real cost people
underestimate.

Do this on a quiet day. Every open PR will conflict.

## 2. Turn linters on in report-only mode first

Get the number before you argue about the policy:

```bash
pre-commit run --all-files --hook-stage manual 2>&1 | tee baseline.txt
```

## 3. Ratchet, do not boil the ocean

For a linter with thousands of findings, enable it on new and changed code only.

**Path scoping** — the simplest ratchet. Enforce on the module being actively
worked on, expand as you go:

```yaml
- id: mypy
  files: ^src/(billing|auth)/
```

**Per-rule baselining** — turn on the whole rule set, then explicitly ignore the
rules you cannot meet yet, with a count and an owner:

```toml
[tool.ruff.lint]
select = ["E", "F", "B", "SIM", "D"]
ignore = [
  # TODO(#412, platform-team): 340 findings, fixing module by module.
  "D103",
]
```

That comment is the difference between a plan and a permanent exception.

**Tool-native baselines** — some tools support this directly. `detect-secrets`
has `--baseline`, mypy has `--incremental` plus per-module overrides. Prefer
these where they exist.

## 4. Secret scanning is retrospective, and pre-commit is not enough

`gitleaks` in a hook only sees the commit in front of it. Secrets already in
history stay there, and a hook cannot help you. Scan the full history
separately, once:

```bash
gitleaks detect --source . --log-opts="--all"
```

Anything it finds must be **rotated**, not deleted. Rewriting history with
`git filter-repo` does not help once a value has been pushed to a shared remote
— assume it is compromised and cycle the credential. Removing it afterwards is
hygiene, not remediation.

## 5. Make it non-optional at the boundary

Local hooks are advisory: `--no-verify` exists, and the GitHub web editor has no
hooks at all. The enforcement point is CI plus a required status check.
[ci-integration.md](ci-integration.md).

## 6. Ship the onboarding line

Put it in the README, not in a wiki page nobody reads:

```bash
pip install pre-commit && pre-commit install --install-hooks
```

And check the negative case: does a fresh clone with no toolchain installed give
a *useful* error? The `system` hooks in this repo
([dotnet](../stacks/csharp/scripts/dotnet-format.sh),
[helm](../stacks/helm/scripts/helm-lint.sh)) print the install URL and the
`SKIP=` line to bypass. "command not found: helm" does not.

## Rollout order, if you want a default

1. `trailing-whitespace`, `end-of-file-fixer`, `check-merge-conflict`,
   `check-added-large-files` — uncontroversial, tiny diff.
2. `gitleaks` / `detect-private-key` — highest value, near-zero false positives.
3. The formatter for your main language — one big diff, then permanent quiet.
4. Fast linters, scoped, ratcheting outward.
5. Type checking and security linters, on new code first.
6. `conventional-pre-commit` — only if you are actually going to generate
   changelogs from it. Format rules with no consumer are just friction.
