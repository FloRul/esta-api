output "api_body" {
  value = jsondecode(module.esta_api.api_body)
}

output "integration_lambda_names" {
  value = module.esta_api.integration_lambda_names
}

output "swagger_url" {
  value = module.esta_api.swagger_url
}
