[![pre-commit](https://github.com/kelleyblackmore/pre-commit-showcase/actions/workflows/pre-commit.yml/badge.svg)](https://github.com/kelleyblackmore/pre-commit-showcase/actions/workflows/pre-commit.yml)
[![stacks](https://github.com/kelleyblackmore/pre-commit-showcase/actions/workflows/stacks.yml/badge.svg)](https://github.com/kelleyblackmore/pre-commit-showcase/actions/workflows/stacks.yml)
[![pre-commit enabled](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://pre-commit.com/)

# pre-commit showcase

A working reference for [pre-commit](https://pre-commit.com/) across eight kinds
of repository. Every config in here is real, runs in CI on every push, and is
written to be copied.

The thing most pre-commit examples get wrong is showing you a config without the
context: which hooks are safe on every commit and which will make your team
reach for `--no-verify`, which tools the hook vendors and which it expects you
to install, and what to do when the same file type means different things in
different stacks. That context is the point of this repo — the configs are
commented at the level of "why this argument", not "this is the trailing
whitespace hook".

New to pre-commit? **[How pre-commit works](docs/how-it-works.md)** has the
diagrams, a commit traced step by step, and an honest account of the benefits
and the costs.

## The stacks

| Stack | Hooks that matter | The thing that trips people up |
| --- | --- | --- |
| [Python](stacks/python/) | `ruff`, `ruff-format`, `mypy`, `bandit` | mypy runs in its own venv and cannot see your deps |
| [JavaScript / TypeScript](stacks/javascript/) | `prettier`, `eslint` | plugins must be listed in `additional_dependencies`, twice-maintained |
| [C / C++](stacks/cpp/) | `clang-format`, `cpplint`, `cmake-format` | `clang-tidy` needs a compile DB, so it cannot be a commit hook |
| [C# / .NET](stacks/csharp/) | `dotnet format` (whitespace/style/analyzers) | no mirror ships the SDK — these are `system` hooks |
| [Containers](stacks/container/) | `hadolint`, compose schema, image-tag policy | use `hadolint-py`, not the Docker-in-Docker variant |
| [Helm](stacks/helm/) | `helm lint --strict`, `helm-docs`, `kubeconform` | `templates/*.yaml` is Go template, not YAML — exclude it everywhere |
| [Ansible](stacks/ansible/) | `ansible-lint` (production profile) | the hook ignores `files:`; scope it with `--project-dir` |
| [Terraform](stacks/terraform/) | `fmt`, `validate`, `docs`, `tflint`, `trivy` | hook order is not alphabetical, and it matters |

Each directory has its own `README.md` and a **standalone**
`.pre-commit-config.yaml` you can drop into a single-language repo unchanged.

## Quick start

```bash
pip install pre-commit
git clone https://github.com/kelleyblackmore/pre-commit-showcase
cd pre-commit-showcase
pre-commit install --install-hooks
```

Run everything once, the way CI does:

```bash
pre-commit run --all-files
```

Run one stack's hooks against a real single-language checkout:

```bash
./scripts/run-stack.sh terraform
```

That script copies `stacks/terraform/` into a temporary git repo and runs its
standalone config there — which is the only honest way to prove a config is
actually copy-pasteable. CI runs the same script for all eight stacks.

## Two patterns, both shown here

**Root config (monorepo).** One [`.pre-commit-config.yaml`](.pre-commit-config.yaml)
at the top, with each stack's hooks narrowed by `files: ^stacks/<name>/`.
Contributors run `pre-commit install` once. Only hooks matching the files you
touched actually execute, so a one-line Terraform change never waits on ESLint.

**Per-stack config (polyrepo).** Eight self-contained configs, one per
`stacks/*/` directory, with no path scoping because a single-language repo has
nothing to scope against.

Both are maintained here on purpose, and
[docs/two-patterns.md](docs/two-patterns.md) covers the trade-off and the
duplication problem it creates.

## What it costs

`pre-commit` is only useful if people leave it installed, and people uninstall
slow hooks. Measured on this repo (`pre-commit run --all-files`, warm cache):

| Stage | When it runs | Budget |
| --- | --- | --- |
| `pre-commit` | every `git commit` | under ~2s on a typical commit |
| `commit-msg` | every `git commit` | instant — conventional-commit format check |
| `pre-push` | every `git push` | a few seconds — whole-repo consistency checks |
| `manual` | CI, or when you ask | unbounded — `pip-audit`, `checkov`, `clang-tidy` |

Anything that hits the network, needs a build directory, or downloads a
vulnerability database belongs at `manual`, not on the commit path.
[docs/stages.md](docs/stages.md) has the full decision table.

## Custom hooks

Three hooks are implemented in this repo rather than pulled from upstream, as
worked examples of the three shapes you will need:

| Hook | Shape | Source |
| --- | --- | --- |
| `no-mutable-image-tags` | takes a file list, prints `path:line: message` | [hooks/no_mutable_image_tags.py](hooks/no_mutable_image_tags.py) |
| `check-stack-layout` | `always_run`, inspects repo structure | [hooks/check_stack_layout.py](hooks/check_stack_layout.py) |
| `check-readme-toc` | `pre-push`, whole-repo consistency | [hooks/check_readme_toc.py](hooks/check_readme_toc.py) |

They have [tests](hooks/tests/), which is not optional for code that can block
every commit in a repository. See
[docs/writing-custom-hooks.md](docs/writing-custom-hooks.md).

## Docs

- **[How pre-commit works](docs/how-it-works.md)** — diagrams, a commit traced
  end to end, and what you actually get out of it. Start here.
- [Two patterns: root config vs per-stack config](docs/two-patterns.md)
- [Choosing a stage: pre-commit, commit-msg, pre-push, manual](docs/stages.md)
- [Writing and testing your own hooks](docs/writing-custom-hooks.md)
- [Running pre-commit in CI](docs/ci-integration.md)
- [Adopting pre-commit on an existing codebase](docs/adoption.md)
- [Troubleshooting](docs/troubleshooting.md)

## Licence

[MIT](LICENSE).
