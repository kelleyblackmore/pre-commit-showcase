terraform {
  # tflint's terraform_required_version rule wants this pinned to a range, not
  # left open. An unbounded constraint means a major release can break CI on a
  # commit that changed nothing.
  required_version = "~> 1.9"

  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
