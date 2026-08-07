# Deliberately provider-light: `random` and `local` need no credentials, so
# `terraform init` and `terraform validate` run in CI and on a laptop without
# anyone holding a cloud account. The hooks being demonstrated are identical
# whether the resources below are random pets or production VPCs.

locals {
  default_tags = {
    environment = var.environment
    managed_by  = "terraform"
    repository  = "pre-commit-showcase"
  }

  tags = merge(local.default_tags, var.tags)
}

resource "random_pet" "instance" {
  count = var.instance_count

  prefix    = "${var.name_prefix}-${var.environment}"
  length    = 2
  separator = "-"
}

resource "random_id" "deployment" {
  byte_length = 4
}

resource "local_file" "inventory" {
  filename        = "${path.module}/generated/inventory.json"
  file_permission = "0644"

  content = jsonencode({
    deployment_id = random_id.deployment.hex
    environment   = var.environment
    tags          = local.tags
    instances = [
      for pet in random_pet.instance : {
        name = pet.id
      }
    ]
  })
}
