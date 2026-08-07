# Terraform / OpenTofu

## What runs

| Hook | Order | Needs |
| --- | --- | --- |
| `terraform_fmt` | 1 — rewrites files | `terraform` |
| `terraform_validate` | 2 — needs `init` | `terraform` |
| `terraform_docs` | 3 — regenerates this README | `terraform-docs` |
| `terraform_tflint` | 4 | `tflint` |
| `terraform_trivy` | 5 — slowest | `trivy` |
| `terraform_providers_lock` | manual | `terraform` |
| `no-terraform-state` | any | — (blocks `*.tfstate`) |

## Local setup

None of the tools are vendored by the hooks — install them yourself:

```bash
brew install terraform terraform-docs tflint trivy   # or your platform's equivalent
pre-commit install --install-hooks
terraform init -backend=false
```

## Gotchas

**Hook order is not alphabetical, and it matters.** `fmt` rewrites files, so
anything that reads them must come after. `docs` must read post-`fmt` source or
it regenerates a diff on the next run. `validate` needs `terraform init` to have
resolved providers. Getting this wrong produces the maddening failure where
`pre-commit run --all-files` fails, fixes something, and fails again.

**`terraform_validate` needs an initialised working directory.** On a fresh
clone there is no `.terraform/`, and the hook fails with a provider-resolution
error that looks nothing like the real cause. The
`--retry-once-with-cleanup=true` hook-config handles the stale-cache variant;
for the fresh-clone case, run `terraform init -backend=false` once, and say so
in CONTRIBUTING.

**Do not enable tflint cloud rulesets in a commit hook.** `plugin "aws"`,
`plugin "azurerm"` and friends are downloaded plugins requiring `tflint --init`.
A hook that silently hits the network on a fresh clone is a bad hook — and it
fails entirely on an air-gapped runner. [`.tflint.hcl`](.tflint.hcl) uses only
the `terraform` ruleset, which ships inside the binary. Run the cloud rulesets
in CI, where the download is explicit.

**A committed `.tfstate` is a credential leak.** State contains every attribute
of every resource, including values you marked `sensitive` in the config —
passwords, private keys, connection strings. The `language: fail` hook here is
the cheapest possible guard: any file matching `*.tfstate` fails the commit with
a fixed message. `language: fail` is the right tool whenever "this path must
never exist" is the whole rule.

**`terraform_docs` writes into this file.** Everything between the markers below
is generated. Edit `variables.tf` / `outputs.tf`, not the table.

## Run it

```bash
terraform init -backend=false
pre-commit run --all-files
terraform plan
```

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
