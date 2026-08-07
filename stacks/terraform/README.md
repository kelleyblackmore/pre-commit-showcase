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

**Commit `.terraform.lock.hcl`.** For a root module it is the dependency
lockfile, and leaving it out has a non-obvious second cost here: the generated
Providers table above records *resolved* versions, so without a lock every
upstream provider release silently rewrites this README and turns CI red on a
commit that changed nothing. Generate hashes for every platform in use, or
`terraform init` fails on the ones you missed:

```bash
terraform providers lock -platform=linux_amd64 -platform=darwin_arm64 -platform=windows_amd64
```

That is what the manual-stage `terraform_providers_lock` hook automates.

## Run it

```bash
terraform init -backend=false
pre-commit run --all-files
terraform plan
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 2.5 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.6 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_local"></a> [local](#provider\_local) | 2.9.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [local_file.inventory](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file) | resource |
| [random_id.deployment](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [random_pet.instance](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment these resources belong to. | `string` | `"dev"` | no |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of synthetic instances to generate identifiers for. | `number` | `2` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix applied to every generated resource name. | `string` | `"showcase"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged into the default tag set. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | Random identifier assigned to this deployment. |
| <a name="output_instance_names"></a> [instance\_names](#output\_instance\_names) | Generated instance names. |
| <a name="output_inventory_path"></a> [inventory\_path](#output\_inventory\_path) | Path to the generated inventory file. |
| <a name="output_tags"></a> [tags](#output\_tags) | Effective tag set applied to resources. |
<!-- END_TF_DOCS -->
