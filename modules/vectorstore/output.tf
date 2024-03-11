output "rds_instance_endpoint" {
  value = aws_db_instance.vectorstore.endpoint
}

output "vectorstore_admin_username" {
  value = aws_db_instance.vectorstore.username
}
