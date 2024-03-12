output "db_subnet_group_name" {
  value = module.vpc.database_subnet_group_name
}

output "vpc_sg_ids" {
  value = {
    "bedrock_sg"  = aws_security_group.bedrock_sg.id
    "database_sg" = aws_security_group.database_sg.id
    "bastion_sg"  = aws_security_group.bastion_sg.id
  }
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
