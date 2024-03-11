output "api_body" {
  value = aws_api_gateway_rest_api.this.body
}

output "integration_lambda_names" {
  value = flatten([for integration in var.integrations : [for detail in integration.details : split(":", detail.lambda_arn)[6]]])
}

output "swagger_url" {
  value = aws_api_gateway_rest_api.this.execution_arn
}
