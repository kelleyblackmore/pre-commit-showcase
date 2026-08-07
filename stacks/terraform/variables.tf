variable "environment" {
  description = "Deployment environment these resources belong to."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "name_prefix" {
  description = "Prefix applied to every generated resource name."
  type        = string
  default     = "showcase"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric with hyphens, 2-21 characters, starting with a letter."
  }
}

variable "instance_count" {
  description = "Number of synthetic instances to generate identifiers for."
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "instance_count must be between 1 and 10."
  }
}

variable "tags" {
  description = "Additional tags merged into the default tag set."
  type        = map(string)
  default     = {}
}
