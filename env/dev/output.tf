
output "bastion_id" {
  value = module.vectorstore.bastion_id
}

output "bastion_state" {
  value = module.vectorstore.bastion_state
}

output "api_url" {
  value = module.esta_api.api_url
}

output "rds_config" {
  value = module.vectorstore.rds_instance_config
}
