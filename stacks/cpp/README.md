# C / C++

## What runs

| Hook | Needs a build? | Stage |
| --- | --- | --- |
| `clang-format` | no | pre-commit |
| `cpplint` | no | pre-commit |
| `cmake-format` / `cmake-lint` | no | pre-commit |
| `clang-tidy` | **yes** — `compile_commands.json` | manual |

## Local setup

```bash
pre-commit install --install-hooks

# Only needed for the manual-stage clang-tidy hook:
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
pre-commit run --hook-stage manual clang-tidy --all-files
```

## Gotchas

**clang-tidy cannot be a commit hook.** It is a compiler front end: it needs a
compilation database, and it is slow — seconds per translation unit on a real
codebase. Put it behind `stages: [manual]` and run it in CI. A team whose
commits take 40 seconds will stop committing, or start using `--no-verify`,
which is worse than not having the hook.

**Pin the clang-format version and never let it float.** clang-format's output
changes between major releases. If one developer has clang-format 17 and CI has
19, they will fight over the same file forever. `mirrors-clang-format` vendors a
specific version, which is exactly why it is preferable to a `system` hook that
picks up whatever is on `PATH`.

**cpplint walks up looking for `CPPLINT.cfg`.** Without `set noparent` in
[`CPPLINT.cfg`](CPPLINT.cfg), it keeps climbing past this directory into the
monorepo root and picks up settings that have nothing to do with C++.

**`#pragma once` vs include guards.** cpplint's `build/header_guard` rule wants
a guard macro derived from the file path, which breaks the moment a file moves
or the repo root changes. This stack uses `#pragma once` and filters the rule
off. If your compilers are old enough to need real guards, drop the filter
instead.

## Run it

```bash
pre-commit run --all-files
cmake -B build && cmake --build build && ./build/ring_buffer_demo
```
