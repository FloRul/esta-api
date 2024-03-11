output "get_templates_lambda_arn" {
  value = module.lambdas.get_templates_lambda_arn
}

output "delete_template_lambda_arn" {
  value = module.lambdas.delete_template_lambda_arn
}

output "post_template_lambda_arn" {
  value = module.lambdas.post_template_lambda_arn
}

output "template_dynamo_table_name" {
  value = module.dynamo_index.table_name
}

output "template_dynamo_table_arn" {
  value = module.dynamo_index.table_arn
}
