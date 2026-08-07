# JavaScript / TypeScript

## What runs

| Hook                 | Runs from                            | Notes                                                            |
| -------------------- | ------------------------------------ | ---------------------------------------------------------------- |
| `prettier`           | vendored mirror                      | no config imports, so no `npm install` needed                    |
| `eslint`             | **the project's own `node_modules`** | ESLint 10 flat config, `--max-warnings 0` — see below            |
| `pretty-format-json` | vendored                             | normalises JSON, excludes lockfiles and `tsconfig*.json` (JSON5) |
| `check-json`         | vendored                             | catches a broken `package.json` before npm does                  |

## Local setup

```bash
npm ci
pre-commit install --install-hooks
```

`npm ci` is not optional here — the ESLint hook runs the project's own ESLint.
The hook fails with an explicit message if `node_modules` is missing rather than
passing silently.

## Gotchas

**Use `rbubley/mirrors-prettier`, not `pre-commit/mirrors-prettier`.** The
upstream mirror was archived in April 2024 and is frozen at Prettier 3.1.
rbubley's fork is the maintained continuation and is what the Prettier docs now
point at.

**`mirrors-eslint` cannot run a flat config that imports anything.** This is the
big one, and it is worth understanding exactly, because the failure mode is
deceptive.

`additional_dependencies` installs packages into pre-commit's _isolated Node
environment_. But your config is a real ES module:

```js
import js from '@eslint/js'; // eslint.config.mjs
```

and Node resolves that bare specifier **relative to the file doing the
importing** — `stacks/javascript/node_modules`, then upward. pre-commit's
environment is never on that path. So you get:

```text
Error [ERR_MODULE_NOT_FOUND]: Cannot find package '@eslint/js'
imported from .../stacks/javascript/eslint.config.mjs
```

The trap: the moment you run `npm install`, it starts passing — because now the
imports resolve from your real `node_modules`, while the eslint _binary_ still
comes from pre-commit. Two dependency sources, two versions, no warning. Then it
fails on every fresh clone and in CI, and the error points at the config file
rather than at the hook.

The mirror is genuinely fine for a config with **no imports**. This one has
imports, so the hook runs the project's own ESLint instead — see
[`scripts/eslint.sh`](scripts/eslint.sh). One toolchain, one version, and
`npm run lint` and the hook cannot disagree. The cost is that `npm ci` must run
before the hooks do; [`scripts/precommit-bootstrap.sh`](scripts/precommit-bootstrap.sh)
is what CI calls to do that.

Prettier keeps using the mirror, because it needs no config imports — so
formatting still works from a fresh clone with no `npm install`.

**`types:` is ANDed with `files:`, and manifests set it.** `mirrors-eslint`
declares `types: [javascript]`, so `.ts` and `.tsx` are dropped no matter how
permissive your regex is — and the hook reports success, because it had nothing
to check. Overriding it needs both keys:

```yaml
- id: eslint
  types: [file] # clear the manifest's types
  types_or: [javascript, ts, tsx] # opt the ones you want back in
```

**Do not put type-aware ESLint rules on the commit path.**
`tseslint.configs.recommendedTypeChecked` needs a `project:` tsconfig, and
pre-commit invokes ESLint with a partial file list. Any file not in the tsconfig
`include` produces `was not found by the project service`. Keep syntactic rules
in the hook and run type-aware rules over the whole tree in CI. That split is
why [`eslint.config.mjs`](eslint.config.mjs) uses plain `recommended`.

**`tsconfig.json` is JSON5, not JSON.** Comments and trailing commas are legal
there and illegal to `check-json`/`pretty-format-json`, hence the exclude.

## Should you use husky + lint-staged instead?

If the repo is only JavaScript, husky is the more native fit: the tooling is
already `npm install`ed, contributors need no Python, and `lint-staged` passes
staged file paths straight to your local binaries — so there is no second
dependency list to maintain.

Use pre-commit when the repo is polyglot (this one is), when your other repos
already standardise on it, or when you want the same runner in CI regardless of
language. `pre-commit` also handles hook isolation and tool installation, which
husky leaves entirely to you.

## Run it

```bash
pre-commit run --all-files
npm run lint
npm run format:check
```
