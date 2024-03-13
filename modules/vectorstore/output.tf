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

output "bastion_state" {
  value = aws_ec2_instance_state.bastion_state.state
}

output "rds_instance_config" {
  value = {
    db_host            = aws_db_instance.vectorstore.address
    db_port            = aws_db_instance.vectorstore.port
    db_name            = aws_db_instance.vectorstore.db_name
    db_pass_secret_arn = aws_db_instance.vectorstore.master_user_secret[0].secret_arn
  }
}
