# Writing and testing your own hooks

Three hooks in this repo are local implementations rather than upstream
dependencies, chosen to cover the three shapes you will actually need.

## Shape 1 — takes a file list, reports `path:line: message`

The default and the one you want most of the time. pre-commit passes the staged
files that matched `files:`/`types:` as `argv`; you print findings and exit
non-zero if there were any.

[`hooks/no_mutable_image_tags.py`](../hooks/no_mutable_image_tags.py):

```yaml
- id: no-mutable-image-tags
  name: no :latest / untagged container images
  entry: python hooks/no_mutable_image_tags.py
  language: python
  files: (^|/)(Dockerfile|Containerfile)(\..*)?$|\.ya?ml$
```

Why this shape is worth the effort: it scales with the change, not the repo, and
the `path:line:` format is what editors and GitHub annotations parse.

## Shape 2 — inspects repo structure, ignores the file list

[`hooks/check_stack_layout.py`](../hooks/check_stack_layout.py) checks that every
`stacks/*/` has a README and a config. A file list is meaningless for that
question.

```yaml
- id: check-stack-layout
  entry: python hooks/check_stack_layout.py
  language: python
  pass_filenames: false
  always_run: true
```

`always_run: true` is what makes it fire even when no matching file changed —
without it, deleting `stacks/python/README.md` would not trigger the check,
because deletions do not produce a staged file to match.

## Shape 3 — no code at all

For "this path must never exist", `language: fail` needs zero implementation.
The `entry:` is the error message.

```yaml
- id: no-terraform-state
  name: never commit terraform state
  entry: terraform state files must not be committed
  language: fail
  files: \.tfstate(\.backup)?$
```

Note it must live in a `repo: local` block. Nesting a hook you invented under an
upstream `- repo:` block gives you `InvalidManifestError: hook id not found`,
and `pre-commit validate-config` will not catch it — that command checks the
schema, not the upstream manifests.

There is also `language: pygrep` for regex rules:

```yaml
- id: no-focused-tests
  name: no .only() left in tests
  entry: '\b(describe|it|test)\.only\('
  language: pygrep
  types: [javascript]
```

## Choosing a `language:`

| `language:` | pre-commit does | Use when |
| --- | --- | --- |
| `python`, `node`, `golang`, `ruby`, `rust` | builds an isolated env and installs `additional_dependencies` | the tool is installable from a package registry |
| `script` | runs the file directly; it must be executable | you are wrapping a tool the user installs (`helm`, `dotnet`, `terraform`) |
| `system` | runs `entry` as a command on `PATH` | same, but no wrapper file needed |
| `docker`, `docker_image` | runs it in a container | last resort — needs a daemon, breaks on hardened runners |
| `fail`, `pygrep` | no environment at all | the rule is "this must not exist" or a regex |

Prefer `python`/`node` over `system` wherever possible: pre-commit pins the tool
version, so every developer and CI runs the identical binary. `system` picks up
whatever happens to be installed, which is how two developers end up reformatting
each other's files forever.

## Making a hook installable by other repos

Add `.pre-commit-hooks.yaml` to the root of the repo that holds the hook:

```yaml
- id: no-mutable-image-tags
  name: no :latest / untagged container images
  description: Rejects mutable container image references.
  entry: no-mutable-image-tags
  language: python
  files: (^|/)(Dockerfile|Containerfile)(\..*)?$|\.ya?ml$
```

Package it (a `pyproject.toml` with a console-script entry point), tag a
release, and consumers get:

```yaml
- repo: https://github.com/your-org/pre-commit-hooks
  rev: v1.0.0
  hooks:
    - id: no-mutable-image-tags
```

Tag real releases. `rev:` pointing at a branch is refused by
`pre-commit autoupdate` and makes every consumer's build non-reproducible.

## Test your hooks

A hook is code that can block every commit in the repository. A false positive
does not merely annoy — it is the specific event that teaches a team to type
`--no-verify`, after which none of your hooks work.

[`hooks/tests/`](../hooks/tests/) covers the cases that actually bite:

- **The multi-stage `FROM builder` case.** A naive "does the image have a tag"
  check flags every second stage of every multi-stage Dockerfile.
- **The registry-port case.** `registry.example.com:5000/app` has a colon that is
  not a tag separator.
- **Commented-out lines.**
- **Templated references** (`${BASE_IMAGE}`, `{{ .Values.image }}`) that are
  resolved somewhere else.

```bash
python -m pytest hooks/tests -q
```

CI runs these before running the hooks themselves — a broken hook should fail as
a test, with a useful message, rather than as a mysterious commit rejection.

## Practical notes

**`require_serial: true`** when the tool cannot run concurrently with itself
(most build tools, anything writing to a shared cache). pre-commit otherwise
shards the file list across cores.

**Hooks that modify files should exit non-zero when they modify.** That is the
convention every formatter hook follows: fail the commit, leave the fix in the
working tree, let the developer review and re-stage. Silent rewriting means
committing code you never looked at.

**Keep the `name:` short and legible.** It is what the developer sees at 5pm
next to `Failed`. `name: no :latest / untagged container images` tells them what
is wrong; `name: run policy check` does not.
