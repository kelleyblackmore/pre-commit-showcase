output "deployment_id" {
  description = "Random identifier assigned to this deployment."
  value       = random_id.deployment.hex
}

output "instance_names" {
  description = "Generated instance names."
  value       = random_pet.instance[*].id
}

output "inventory_path" {
  description = "Path to the generated inventory file."
  value       = local_file.inventory.filename
}

output "tags" {
  description = "Effective tag set applied to resources."
  value       = local.tags
}
