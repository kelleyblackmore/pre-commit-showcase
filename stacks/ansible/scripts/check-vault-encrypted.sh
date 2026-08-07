#!/usr/bin/env bash
#
# Refuse to commit a plaintext file in a location reserved for Ansible Vault.
#
# The failure this prevents: someone runs `ansible-vault decrypt` to edit a
# secrets file, fixes the value, and commits before re-encrypting. gitleaks may
# not fire - the contents are legitimate config, not a recognisable token - but
# the file is now plaintext in git history forever.
#
set -euo pipefail

status=0

for file in "$@"; do
  [[ -f ${file} ]] || continue

  # shellcheck disable=SC2016
  # The single quotes are deliberate: `$ANSIBLE_VAULT` is a literal string at
  # the start of the file, not a shell variable to expand.
  if ! head -c 14 "${file}" | grep -q '^\$ANSIBLE_VAULT'; then
    cat >&2 <<EOF
${file}: expected an ansible-vault encrypted file, found plaintext.

  Re-encrypt it:  ansible-vault encrypt ${file}
EOF
    status=1
  fi
done

exit "${status}"
