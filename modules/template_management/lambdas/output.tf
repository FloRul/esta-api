output "get_templates_lambda_arn" {
  value = module.get_templates.lambda_function_arn
}

output "delete_template_lambda_arn" {
  value = module.delete_template.lambda_function_arn
}

output "post_template_lambda_arn" {
  value = module.post_template.lambda_function_arn

}
