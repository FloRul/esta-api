
module "integrations" {
  source               = "./lambda_integration"
  for_each             = toset(var.integrations)
  api_id               = aws_api_gateway_rest_api.this.id
  aws_region           = var.aws_region
  lambda_arn           = each.value.lambda_arn
  lambda_name          = each.value.lambda_name
  api_root_resource_id = aws_api_gateway_resource.api_gateway_resource.id
  api_path_part        = each.value.api_path_part
  http_method          = each.value.http_method
}
