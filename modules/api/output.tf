output "api_body" {
  value = aws_api_gateway_rest_api.this.body
}

output "api_url" {
  value = aws_api_gateway_deployment.this.invoke_url
}
