# C# / .NET

## What runs

| Hook | Stage | Notes |
| --- | --- | --- |
| `dotnet format whitespace` | pre-commit | `.editorconfig` layout rules |
| `dotnet format style` | pre-commit | `IDExxxx` code-style rules |
| `dotnet format analyzers` | pre-commit | `CAxxxx` analyzer rules — the slow one |
| `dotnet build -warnaserror` | pre-push | the tree still compiles clean |
| `check-xml` | pre-commit | `.csproj` / `.props` / `.targets` are XML |

## Local setup

Install the [.NET SDK](https://dotnet.microsoft.com/download), then:

```bash
pre-commit install --install-hooks
```

## Gotchas

**There is no vendored .NET hook, and there is not going to be one.** The SDK is
a ~200 MB install with its own version selection via `global.json`; no
pre-commit `language:` can reasonably reproduce that. So the hooks here are
`language: script` wrappers that shell out to the `dotnet` on your `PATH`. That
means contributors need the SDK before they can commit — call that out in your
CONTRIBUTING file.

**The wrappers fail loudly when `dotnet` is missing, on purpose.** The tempting
alternative is `command -v dotnet || exit 0`, which turns a missing toolchain
into a green commit and an unformatted diff. If you genuinely need to bypass it:

```bash
SKIP=dotnet-format git commit -m "chore: ..."
```

**`dotnet format` is three sub-commands now.** Since .NET 6, bare `dotnet
format` only does whitespace. `style` and `analyzers` must be invoked
separately, and `analyzers` is by far the slowest — it is a full analyzer pass
over the project. If commits get sluggish, move that one to `pre-push`.

**`--verify-no-changes` makes it a checker, not a fixer.** Drop the flag if you
would rather the hook rewrite files in place, but then you also need
`pre-commit` to see the rewritten files — which it does, by failing the run and
leaving the changes staged for you to review.

**`.editorconfig` is the single source of truth.** `dotnet format`, Visual
Studio, Rider and the `EnforceCodeStyleInBuild` analyzers all read it. Never
duplicate a rule into hook `args:`.

## Run it

```bash
pre-commit run --all-files
dotnet run --project src/Showcase/Showcase.csproj
```
