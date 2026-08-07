# Ansible

## What runs

| Hook | Notes |
| --- | --- |
| `ansible-lint` | `production` profile, `strict: true` |
| `check-yaml` | excludes vaulted files and `.j2` templates |
| `no-plaintext-vault` (repo-local) | refuses an unencrypted file in a vault path |
| `detect-private-key` | the classic Ansible mistake |

## Local setup

```bash
pip install pre-commit ansible-core ansible-lint
ansible-galaxy collection install -r requirements.yml
pre-commit install --install-hooks
```

## Gotchas

**`files:` does nothing on the ansible-lint hook.** The upstream hook is
declared `pass_filenames: false` + `always_run: true` — it discovers playbooks
and roles from the project structure rather than accepting a file list. In a
monorepo it will happily wander into directories that are not Ansible at all.
Scope it with an explicit project directory and path:

```yaml
- id: ansible-lint
  args: [--project-dir, stacks/ansible, stacks/ansible]
```

**ansible-lint already runs yamllint.** If you also enable the standalone
`yamllint` hook over the same tree, you get every finding twice, from two config
files that will eventually disagree with each other. Pick one owner per file
type. Here, ansible-lint owns YAML under the Ansible tree.

**Start at the `production` profile and relax down.** The ladder is `min` →
`basic` → `moderate` → `safety` → `shared` → `production`. Starting strict and
recording each exception in `skip_list` with a reason produces a config someone
can audit later. Starting at `min` and promising to tighten it produces a config
nobody ever tightens.

**`strict: true` is what makes it a gate.** Without it ansible-lint exits 0 on
warnings.

**Role variables must be prefixed with the role name.** The production profile
enforces `var-naming[no-role-prefix]`, so a role called `baseline` must declare
`baseline_motd_owner`, not `motd_owner`. This looks like bureaucracy and is not:
Ansible variables live in one global namespace at runtime, so two roles that both
define `motd_owner` silently overwrite each other, and the winner depends on
include order.

**Vaulted files need special handling everywhere.** They are ciphertext, so
`check-yaml` must exclude them. And the recurring accident —
`ansible-vault decrypt`, edit, commit, forget to re-encrypt — is not something
`gitleaks` reliably catches, because the plaintext is ordinary config rather
than a recognisable token. Hence
[`check-vault-encrypted.sh`](scripts/check-vault-encrypted.sh), which just
asserts the file starts with `$ANSIBLE_VAULT`.

## Run it

```bash
pre-commit run --all-files
ansible-lint
ansible-playbook --syntax-check playbooks/site.yml
```
