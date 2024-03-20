
resource "aws_vpc_endpoint" "bedrock_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.bedrock-runtime"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.bedrock_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}
resource "aws_vpc_endpoint" "ec2messages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ec2messages"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages_endpoint" {
  vpc_id              = module.vpc.vpc_id
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ssmmessages"
  security_group_ids  = [aws_security_group.bastion_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "rds" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.rds"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.database_sg.id]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secret_manager" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.secret_manager_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "dynamo_db" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.public_route_table_ids
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id              = module.vpc.vpc_id
  service_name        = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = [aws_security_group.s3_sg.id]
  subnet_ids          = module.vpc.public_subnets
  private_dns_enabled = true
}
