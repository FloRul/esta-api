output "rds_instance_endpoint" {
  value = aws_db_instance.vectorstore.endpoint
}

output "vectorstore_admin_username" {
  value = aws_db_instance.vectorstore.username
}

output "vectorstore_address" {
  value = aws_db_instance.vectorstore.address
}

output "bastion_id" {
  value = aws_instance.bastion.id
}
