output "table_name" {
  value = module.template_index_table.dynamodb_table_id
}

output "table_arn" {
  value = module.template_index_table.dynamodb_table_arn
}
