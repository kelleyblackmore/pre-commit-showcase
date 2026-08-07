config {
  call_module_type = "local"
  force            = false
}

# The `terraform` ruleset ships inside the tflint binary, so this block needs no
# `tflint --init`. Any other ruleset (aws, azurerm, google) is a downloaded
# plugin and does - which is why they are not enabled here: a pre-commit hook
# that silently hits the network on a fresh clone is a bad hook.
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}
