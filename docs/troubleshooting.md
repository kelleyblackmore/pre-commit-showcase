# Troubleshooting

## "My hook does not run"

`pre-commit run --all-files` says `(no files to check) Skipped`.

Your `files:` regex does not match. It is a **Python regex matched against the
repo-root-relative path**, not a glob:

```yaml
files: ^stacks/python/.*\.py$   # right
files: stacks/python/*.py       # wrong - that is a glob, and it matches nothing
```

Debug it directly:

```bash
pre-commit run ruff --all-files --verbose
python -c "import re; print(bool(re.search(r'^stacks/python/', 'stacks/python/src/x.py')))"
```

Note it is `re.search`, not `re.match`, so an unanchored pattern matches
anywhere in the path. Anchor with `^`.

Also check: is the hook at a non-default stage? A `stages: [manual]` hook never
runs on commit, and `pre-commit run --all-files` will not run it either — you
need `--hook-stage manual`.

## "It passes locally and fails in CI"

Almost always one of four things:

1. **The file was never staged.** Hooks see the *staged* content. `git add -A`
   and try again.
2. **A different tool version.** `system` hooks use whatever is on `PATH`. Pin
   the tool in the hook (`language: python` with `additional_dependencies`)
   instead, so everyone runs the same binary.
3. **Case sensitivity.** `Foo.py` and `foo.py` are the same file on macOS and
   Windows, and two files on the Linux runner. `check-case-conflict` catches
   this before it happens.
4. **Line endings.** A Windows checkout with `core.autocrlf=true` gives the hook
   CRLF; the runner sees LF. `mixed-line-ending --fix=lf` plus a `.gitattributes`
   with `* text=auto eol=lf` settles it permanently.

## "mypy cannot find my imports"

pre-commit runs every hook in an isolated virtualenv. Your project's
dependencies are not installed in it.

```yaml
- id: mypy
  additional_dependencies: [types-requests, pydantic>=2, sqlalchemy>=2]
```

You now maintain that list alongside `pyproject.toml`. If that is unacceptable,
run mypy in CI against the real environment and leave it out of the hook. Both
are legitimate; silently living with `--ignore-missing-imports` swallowing
everything is not.

The same applies to ESLint plugins and any hook with a plugin architecture.

## "The hook rewrote my files and failed"

Working as designed. Formatter hooks fix the file, exit non-zero, and leave the
change in your working tree so you can look at it before committing:

```bash
git diff        # review what it did
git add -u
git commit
```

A hook that rewrote and passed would mean committing code you never saw.

## "check-yaml fails on my Helm templates / GitHub Actions"

**Helm templates are not YAML.** `{{- if .Values.x }}` is a Go template. Exclude
`templates/` and validate the rendered output with `helm lint` instead. See
[the Helm stack](../stacks/helm/README.md).

**GitHub Actions `on:`** — YAML 1.1 parses the bare word `on` as boolean `True`,
so yamllint's `truthy` rule fires. Fix it in `.yamllint.yaml`:

```yaml
rules:
  truthy:
    check-keys: false
```

**Multi-document files** need `args: [--allow-multiple-documents]`.

**Custom tags** (`!Ref`, `!vault`) need `args: [--unsafe]`, which checks syntax
only and does not build the object graph.

## "Everything is slow"

```bash
# Per-hook timings
pre-commit run --all-files --verbose
```

Then move the slow ones — see [stages.md](stages.md). Also:

- Clear a corrupt or bloated cache: `pre-commit clean && pre-commit gc`
- `require_serial: true` disables parallelism for that hook. Remove it unless the
  tool genuinely cannot run concurrently.
- The first run after any `rev:` change rebuilds environments. That cost is
  expected; if CI pays it every run, your [cache key](ci-integration.md) is
  wrong.

## "`pre-commit autoupdate` skips a repo"

It only moves `rev:` to tags. A `rev:` pointing at a branch name or a raw SHA is
left alone, and a `repo: local` block has nothing to update.

## "InvalidManifestError / hook id not found"

The `rev:` you pinned predates the hook id — or the id lives in a different
repo than you think. Two distinct causes:

**The tag is too old for the id.** Check the upstream
`.pre-commit-hooks.yaml` at that exact tag:

```bash
curl -s https://raw.githubusercontent.com/astral-sh/ruff-pre-commit/v0.16.1/.pre-commit-hooks.yaml
```

`ruff-pre-commit` is the usual culprit: `ruff-format` only exists from `v0.1.2`,
and `ruff` was renamed to `ruff-check`, with `ruff` kept as a deprecated alias —
so `autoupdate` will never tell you that you are on the old name.

**You put a hook you invented under an upstream `- repo:` block.** Hooks you
define yourself must live under `- repo: local`. Note that
`pre-commit validate-config` will *not* catch this: it validates the schema, not
the upstream manifests. To check the manifests, run `pre-commit install-hooks`,
or fetch `.pre-commit-hooks.yaml` as above.

## "The hook skips my TypeScript / my file type"

`types:` and `files:` are ANDed, and the upstream manifest may already set a
`types:` you did not notice. `mirrors-eslint` declares `types: [javascript]`, so
`.ts` and `.tsx` are skipped no matter how permissive your `files:` regex is.
Widening it takes both keys:

```yaml
- id: eslint
  types: [file]                      # clear the manifest's `types`
  types_or: [javascript, ts, tsx]    # then opt the types back in
```

Check what pre-commit thinks a file is:

```bash
python -c "import identify.identify as i; print(i.tags_from_path('src/app.ts'))"
```

## "The commit-msg hook never fires"

`pre-commit install` installs only the `pre-commit` hook type. You need:

```bash
pre-commit install --hook-type commit-msg --hook-type pre-push
```

or, better, declare it in the config so a bare `install` does the right thing:

```yaml
default_install_hook_types: [pre-commit, commit-msg, pre-push]
```

Check what is actually installed: `ls .git/hooks/`.

## Escape hatches

```bash
SKIP=mypy,helm-lint git commit -m "wip: ..."   # skip named hooks
git commit --no-verify                          # skip all hooks
pre-commit uninstall                            # remove the git hooks entirely
```

Prefer `SKIP`. It names what was bypassed and leaves the other hooks working.
