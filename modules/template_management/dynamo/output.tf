output "dynamo_table_name" {
  value = module.template_index_table.dynamodb_table_id
}

output "dynamo_table_arn" {
  value = module.template_index_table.dynamodb_table_arn
}
