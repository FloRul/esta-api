output "api_body" {
  value = aws_api_gateway_rest_api.this.body
}

output "integration_lambda_names" {
  value = [for integration in var.integrations : split(":", integration.lambda_arn)[6]]
}
